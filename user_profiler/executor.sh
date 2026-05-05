#!/bin/bash

# 1. Get the absolute path of the directory this script lives in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 2. Safely navigate up one folder from the script to find the .venv
VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python"

if [ -f "$VENV_PYTHON" ]; then
    EXEC_CMD="$VENV_PYTHON"
else
    echo "ERROR: Virtual environment not found at $VENV_PYTHON"
    EXEC_CMD="python3"
fi

# We pass $1 (The JSON Payload) AND $SCRIPT_DIR to Python
$EXEC_CMD - "$1" "$SCRIPT_DIR" << 'EOF'
import sys, json, urllib.request, struct, os
import sqlite3
import sqlite_vec

# sys.argv[1] is the JSON payload. sys.argv[2] is the SCRIPT_DIR we passed from Bash.
script_dir = sys.argv[2]

# Lock the database path absolutely to the skills folder!
DB_FILE = os.path.abspath(os.path.join(script_dir, "../ironclaw_memory.db"))
SKILL_NAME = "user_profiler"

def get_embedding(text):
    """Instantly ping local Ollama for the 768-dimensional vector."""
    url = "http://localhost:11434/api/embeddings"
    payload = json.dumps({
        "model": "nomic-embed-text",
        "prompt": text
    }).encode("utf-8")
    
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        return res["embedding"]

def serialize_vec(vector):
    """Pack the Python float array into binary for sqlite-vec."""
    return struct.pack(f'{len(vector)}f', *vector)

def init_db():
    db = sqlite3.connect(DB_FILE)
    db.enable_load_extension(True)
    sqlite_vec.load(db)
    db.enable_load_extension(False)
    
    # Text table
    db.execute('CREATE TABLE IF NOT EXISTS facts (id INTEGER PRIMARY KEY AUTOINCREMENT, skill TEXT, fact TEXT)')
    # Vector table (768 dimensions for nomic)
    db.execute('CREATE VIRTUAL TABLE IF NOT EXISTS vec_memory USING vec0(embedding float[768])')
    db.commit()
    return db

try:
    args = json.loads(sys.argv[1])
    action = args.get("action", "")
    db = init_db()
    cursor = db.cursor()

    if action == "save_preference":
        facts = args.get("extracted_facts", [])
        if not facts and args.get("extracted_fact", ""):
            facts = [args.get("extracted_fact", "")]

        if not facts:
            print("Error: No facts provided.")
        else:
            logs = []
            for fact in facts:
                vector = get_embedding(fact)
                serialized = serialize_vec(vector)
                
                # Use vec_distance_cosine for semantic accuracy. 
                # We sort by distance and take the single closest result.
                cursor.execute('''
                    SELECT 
                        facts.id, 
                        vec_distance_cosine(vec_memory.embedding, ?) as distance 
                    FROM vec_memory
                    LEFT JOIN facts ON facts.id = vec_memory.rowid
                    WHERE facts.skill = ?
                    ORDER BY distance ASC
                    LIMIT 1
                ''', (serialized, SKILL_NAME))
                
                closest = cursor.fetchone()

                # DEBUG: Cosine distance is now 0.0 (identical) to 1.0 (different)
                if closest: 
                    print(f"DEBUG: Cosine Distance found was {closest[1]:.4f}")
                
                # CALIBRATED THRESHOLDS for Cosine Distance:
                # < 0.10: Basically identical
                # < 0.20: Same concept, different words (Update)
                if closest and closest[1] < 0.10:
                    logs.append(f"- SKIPPED: '{fact}' (Already known)")
                elif closest and closest[1] < 0.20:
                    old_id = closest[0]
                    cursor.execute('UPDATE facts SET fact = ? WHERE id = ?', (fact, old_id))
                    cursor.execute('UPDATE vec_memory SET embedding = ? WHERE rowid = ?', (serialized, old_id))
                    logs.append(f"- UPDATED: '{fact}' (Replaced similar record)")
                else:
                    cursor.execute('INSERT INTO facts (skill, fact) VALUES (?, ?)', (SKILL_NAME, fact))
                    row_id = cursor.lastrowid
                    cursor.execute('INSERT INTO vec_memory (rowid, embedding) VALUES (?, ?)', (row_id, serialized))
                    logs.append(f"- SAVED: '{fact}'")
            
            db.commit()
            print(f"--- TYPE: PROFILE UPDATE ---\nSTATUS: SUCCESS\n" + "\n".join(logs))

    elif action == "search_profile":
        query = args.get("search_query", "")
        if query:
            query_vector = get_embedding(query)
            # Use the MATCH syntax here for speed, it's efficient for Top-K retrieval
            cursor.execute('''
                SELECT facts.fact 
                FROM vec_memory
                LEFT JOIN facts ON facts.id = vec_memory.rowid
                WHERE vec_memory.embedding MATCH ? AND k = 5
                AND facts.skill = ?
            ''', (serialize_vec(query_vector), SKILL_NAME))
            
            rows = cursor.fetchall()
            if not rows:
                print("--- TYPE: PROFILE SEARCH ---\nSTATUS: EMPTY\nNo relevant facts found.")
            else:
                formatted = "\n".join([f"- {row[0]}" for row in rows])
                print(f"--- TYPE: PROFILE SEARCH ---\nSTATUS: OK\nRELEVANT FACTS FOUND:\n{formatted}")
        else:
            print("Error: No search query provided.")

except Exception as e:
    print(f"Execution Error: {e}")
finally:
    if 'db' in locals():
        db.close()
EOF