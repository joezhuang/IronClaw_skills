#!/bin/bash

# 1. Automatically load and export variables from a .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import os
import urllib.request
from datetime import datetime

# Configure your local evaluator model here (must be pulled in Ollama)
# A fast 3B to 8B model is perfect for this.
JUDGE_MODEL = "qwen2.5:3b" 
OLLAMA_URL = "http://localhost:11434/api/generate"

def ask_senior_editor(draft_text):
    """Passes the draft to a local LLM to judge the tone."""
    system_prompt = """You are the Senior Editor at 'Briefly News'. Your job is to ruthlessly critique drafted tweets.
The brand voice is cynical, sharp, and highly skeptical of PR spin. 
Rules:
1. If the draft sounds like a generic AI, uses bureaucratic fluff (e.g., "sparks a debate", "raises questions"), or is boring, you MUST reject it.
2. If the draft is approved, reply with EXACTLY the word: PASS
3. If the draft is rejected, reply with 'FAIL: ' followed by a harsh, 1-sentence instruction on how to fix the tone."""

    payload = {
        "model": JUDGE_MODEL,
        "prompt": f"Draft to review:\n{draft_text}",
        "system": system_prompt,
        "stream": False,
        "options": {
            "temperature": 0.1 # Keep it strictly analytical
        }
    }

    try:
        req = urllib.request.Request(OLLAMA_URL, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=15) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result.get('response', 'FAIL: Judge failed to respond.').strip()
    except Exception as e:
        return f"FAIL: LLM Judge offline or error - {str(e)}"

def run_task():
    try:
        if len(sys.argv) < 2:
            print(json.dumps({"status": "error", "errors": "No payload provided."}))
            return

        # Safely parse the incoming JSON payload
        raw_payload = sys.argv[1]
        try:
            if raw_payload.strip().startswith('{'):
                payload = json.loads(raw_payload)
                draft_text = payload.get("draft_text", raw_payload).strip()
            else:
                draft_text = raw_payload.strip()
        except Exception:
            draft_text = raw_payload.strip()

        if not draft_text:
            print(json.dumps({"status": "error", "errors": "draft_text parameter is empty."}))
            return

        # 🛑 MEMORY PATCH: Extract the URL from the draft text so it survives the review
        target_url_line = ""
        clean_draft_text = ""
        for line in draft_text.split('\n'):
            if line.startswith("TARGET_URL:"):
                target_url_line = line.strip()
            else:
                clean_draft_text += line + "\n"
        
        draft_text = clean_draft_text.strip()

        # 1. BASH LEVEL RADIOACTIVE BAN (Keep this as a hard safety net)
        lower_draft = draft_text.lower()
        radioactive_words = ["dead", "die", "dies", "fatal", "killed", "gunfire", "shooting", "explosion", "casualty", "attack"]
        if any(word in lower_draft for word in radioactive_words):
            print(json.dumps({"status": "error", "errors": "RADIOACTIVE BAN TRIGGERED: Contains violence/death. Abort."}))
            return

        # 2. THE LLM QUALITY JUDGE (Grades only the clean text)
        evaluation = ask_senior_editor(draft_text)

        if evaluation.startswith("FAIL"):
            # Pass the Judge's harsh critique directly back to the main agent
            print(json.dumps({"status": "error", "errors": f"SENIOR EDITOR REJECTED: {evaluation}"}))
            return

        # 3. SUCCESS! Log it and proceed
        log_file = os.path.expanduser("~/ironclaw_approved_replies.log")
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"=== APPROVED ON: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")
            if target_url_line:
                f.write(f"{target_url_line}\n")
            f.write(f"{draft_text}\n")
            f.write("====================================\n\n")

        # 🛑 MEMORY PATCH: Re-attach the URL to the approval string
        if target_url_line:
            final_output = f"{target_url_line}\nAPPROVED_PROCEED"
        else:
            final_output = "APPROVED_PROCEED"

        print(json.dumps({
            "status": "success", 
            "data": final_output, 
            "logs": "✅ Draft approved by Senior Editor. You may now call post_x_reply."
        }))

    except Exception as e:
        print(json.dumps({"status": "error", "errors": str(e)}))

if __name__ == "__main__":
    run_task()
EOF