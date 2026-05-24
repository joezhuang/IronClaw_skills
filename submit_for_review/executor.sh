#!/bin/bash

# 1. Automatically load and export variables from a .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 2. Setup Python Environment
if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

# 3. Execute the Python logic (passing $1 which contains the JSON payload)
"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import os
from datetime import datetime

def run_task():
    try:
        if len(sys.argv) < 2:
            print(json.dumps({"status": "error", "errors": "No payload provided to the script."}))
            return

        payload = json.loads(sys.argv[1])
        draft_text = payload.get("draft_text", "").strip()

        if not draft_text:
            print(json.dumps({"status": "error", "errors": "draft_text parameter is empty."}))
            return

        lower_draft = draft_text.lower()
        critique = ""
        has_error = False

        # 1. BASH LEVEL RADIOACTIVE BAN
        radioactive_words = ["dead", "die", "dies", "fatal", "killed", "gunfire", "shooting", "explosion", "casualty", "attack"]
        if any(word in lower_draft for word in radioactive_words):
            has_error = True
            critique += "RADIOACTIVE BAN TRIGGERED: Your draft contains words related to violence or death. Pivot immediately, pick a new URL, and start over. "

        # 2. BASH LEVEL DYNAMIC LENGTH ENFORCER
        account_type = os.getenv("X_ACCOUNT_TYPE", "free").lower()
        max_chars = 280 if account_type == "free" else 25000
        
        if len(draft_text) > max_chars:
            has_error = True
            if account_type == "free":
                critique += f"LENGTH FAILED: Your draft is {len(draft_text)} chars. You MUST keep it under 280 chars (Free Account). Cut the fluff. "
            else:
                critique += f"LENGTH FAILED: Your draft is {len(draft_text)} chars. You MUST keep it under {max_chars} chars. "

        # 3. BASH LEVEL SPAM EMOJI ENFORCER
        banned_emojis = ["🚨", "🚀", "📣", "🔥", "💯", "👇"]
        found_banned = [e for e in banned_emojis if e in draft_text]
        if found_banned:
            has_error = True
            critique += f"EMOJI FAILED: You used banned spam emojis ({', '.join(found_banned)}). Remove them immediately to maintain the cynical persona. "

        # 4. BASH LEVEL HOOK ENFORCER
        last_char = draft_text[-1]
        valid_ends = ["?", "!", "📉", "🧐", "🦐", "🇺🇸", "🤔", "👀"]
        if last_char not in valid_ends:
            has_error = True
            critique += "HOOK FAILED: Your draft must end with a question mark, exclamation point, or an approved emoji. "

        # 5. BASH LEVEL FORMATTING ENFORCER (No Walls of Text)
        if "\n" not in draft_text:
            has_error = True
            critique += "FORMAT FAILED: You wrote a wall of text. You MUST use line breaks to separate distinct thoughts. Rewrite it with hard returns. "

        # 6. RETURN RESULTS TO IRONCLAW
        if has_error:
            # Hard reject. Force the LLM to rewrite.
            print(json.dumps({"status": "error", "errors": critique.strip()}))
        else:
            # Success! Log it to your approved replies file
            log_file = os.path.expanduser("~/ironclaw_approved_replies.log")
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"=== APPROVED ON: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")
                f.write(f"{draft_text}\n")
                f.write("====================================\n\n")

            # Return the green light to the relay
            print(json.dumps({
                "status": "success", 
                "data": "APPROVED_PROCEED", 
                "logs": "✅ Draft approved by gatekeeper. You may now call post_x_reply."
            }))

    except json.JSONDecodeError:
        print(json.dumps({"status": "error", "errors": "Failed to parse JSON payload."}))
    except Exception as e:
        print(json.dumps({"status": "error", "errors": str(e)}))

if __name__ == "__main__":
    run_task()
EOF

# #!/bin/bash

# # 1. Automatically load and export variables from a .env file
# if [ -f .env ]; then
#     export $(cat .env | grep -v '^#' | xargs)
# fi

# # 2. Setup Python Environment
# if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
#     EXEC_CMD="$SKILL_VENV_PATH"
# else
#     EXEC_CMD="python3"
# fi

# # 3. Execute the Python logic (passing $1 which contains the JSON payload)
# "$EXEC_CMD" - "$1" <<'EOF'
# import sys
# import json
# import os
# from datetime import datetime

# def run_task():
#     try:
#         if len(sys.argv) < 2:
#             print(json.dumps({"status": "error", "errors": "No payload provided to the script."}))
#             return

#         payload = json.loads(sys.argv[1])
#         draft_text = payload.get("draft_text", "").strip()

#         if not draft_text:
#             print(json.dumps({"status": "error", "errors": "draft_text parameter is empty."}))
#             return

#         lower_draft = draft_text.lower()
#         critique = ""
#         has_error = False

#         # 1. BASH LEVEL RADIOACTIVE BAN
#         radioactive_words = ["dead", "die", "dies", "fatal", "killed", "gunfire", "shooting", "explosion", "casualty", "attack"]
#         if any(word in lower_draft for word in radioactive_words):
#             has_error = True
#             critique += "RADIOACTIVE BAN TRIGGERED: Your draft contains words related to violence or death. Pivot immediately, pick a new URL, and start over. "

#         # 2. BASH LEVEL LENGTH ENFORCER (Twitter 280 Limit)
#         if len(draft_text) > 280:
#             has_error = True
#             critique += f"LENGTH FAILED: Your draft is {len(draft_text)} characters. You MUST keep it under 280 characters. Cut the fluff. "

#         # 3. BASH LEVEL SPAM EMOJI ENFORCER
#         banned_emojis = ["🚨", "🚀", "📣", "🔥", "💯", "👇"]
#         found_banned = [e for e in banned_emojis if e in draft_text]
#         if found_banned:
#             has_error = True
#             critique += f"EMOJI FAILED: You used banned spam emojis ({', '.join(found_banned)}). Remove them immediately to maintain the cynical persona. "

#         # 4. BASH LEVEL HOOK ENFORCER
#         last_char = draft_text[-1]
#         valid_ends = ["?", "!", "📉", "🧐", "🦐", "🇺🇸", "🤔", "👀"]
#         if last_char not in valid_ends:
#             has_error = True
#             critique += "HOOK FAILED: Your draft must end with a question mark, exclamation point, or an approved emoji. "

#         # 5. RETURN RESULTS TO IRONCLAW
#         if has_error:
#             # Hard reject. Force the LLM to rewrite.
#             print(json.dumps({"status": "error", "errors": critique.strip()}))
#         else:
#             # Success! Log it to your approved replies file
#             log_file = os.path.expanduser("~/ironclaw_approved_replies.log")
#             with open(log_file, "a", encoding="utf-8") as f:
#                 f.write(f"=== APPROVED ON: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")
#                 f.write(f"{draft_text}\n")
#                 f.write("====================================\n\n")

#             # Return the green light to the relay
#             print(json.dumps({
#                 "status": "success", 
#                 "data": "APPROVED_PROCEED", 
#                 "logs": "✅ Draft approved by gatekeeper. You may now call post_x_reply."
#             }))

#     except json.JSONDecodeError:
#         print(json.dumps({"status": "error", "errors": "Failed to parse JSON payload."}))
#     except Exception as e:
#         print(json.dumps({"status": "error", "errors": str(e)}))

# if __name__ == "__main__":
#     run_task()
# EOF