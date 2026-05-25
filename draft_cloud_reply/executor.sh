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
import os
import json
import urllib.request
import time # Make sure this is imported at the top

def run_draft():
    try:
        # 1. Parse Input Payload
        raw_payload = sys.argv[1] if len(sys.argv) > 1 else ""
        if not raw_payload:
            print(json.dumps({"status": "error", "errors": "No payload provided."}))
            return

        parsed_args = json.loads(raw_payload)
        article_context = parsed_args.get("article_context", "").strip()

        if not article_context:
            print(json.dumps({"status": "error", "errors": "Missing article_context parameter."}))
            return

        # 2. Check Cloud Config
        provider = os.getenv("X_CLOUD_PROVIDER", "").lower()
        model = os.getenv("X_CLOUD_MODEL", "")
        endpoint = os.getenv("X_CLOUD_ENDPOINT", "")
        api_key = os.getenv("X_CLOUD_API_KEY", "")

        if not all([provider, model, endpoint, api_key]):
            print(json.dumps({"status": "error", "errors": "Cloud config missing. Check X_CLOUD_* env vars."}))
            return

        # 3. System Prompt (The Persona)
        system_prompt = """You are a veteran, burnt-out financial and tech journalist for 'Briefly News'. 
You hate PR spin and corporate jargon. 
Rule 1: No AI buzzwords (delve, tapestry, crucial, robust). 
Rule 2: Write exactly 3 lines separated by double line breaks (\n\n). 
Line 1: Brutal summary. Line 2: The unspoken truth or financial motive. Line 3: A sharp, cynical question. 
Rule 3: Keep it strictly under 250 characters."""

        prompt_text = f"Read this article and draft the tweet:\n{article_context}"
        cloud_draft = ""

        # 4. Route the API Request with built-in RETRY logic
        max_attempts = 3
        cloud_draft = ""
        
        for attempt in range(max_attempts):
            try:
                if provider == "google":
                    api_url = f"{endpoint.rstrip('/')}/{model}:generateContent?key={api_key}"
                    payload = {
                        "system_instruction": {"parts": [{"text": system_prompt}]},
                        "contents": [{"parts": [{"text": prompt_text}]}],
                        "generationConfig": {"temperature": 0.7}
                    }
                    req = urllib.request.Request(api_url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
                    with urllib.request.urlopen(req, timeout=15) as response:
                        result = json.loads(response.read().decode('utf-8'))
                        cloud_draft = result['candidates'][0]['content']['parts'][0]['text'].strip()

                elif provider == "openai" or provider == "groq":
                    payload = {
                        "model": model,
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": prompt_text}
                        ],
                        "temperature": 0.7
                    }
                    headers = {
                        'Content-Type': 'application/json',
                        'Authorization': f'Bearer {api_key}'
                    }
                    req = urllib.request.Request(endpoint, data=json.dumps(payload).encode('utf-8'), headers=headers)
                    with urllib.request.urlopen(req, timeout=15) as response:
                        result = json.loads(response.read().decode('utf-8'))
                        cloud_draft = result['choices'][0]['message']['content'].strip()
                else:
                    print(json.dumps({"status": "error", "errors": f"Unsupported provider: {provider}"}))
                    return
                
                # If it succeeds, break out of the retry loop
                break 

            except Exception as e:
                if attempt < max_attempts - 1:
                    print(f"⚠️ [DEBUG] Cloud timeout, retrying {attempt + 1}/{max_attempts}...", file=sys.stderr)
                    time.sleep(3) # Wait 3 seconds before retrying
                else:
                    print(json.dumps({"status": "error", "errors": f"Cloud drafting failed after {max_attempts} attempts: {str(e)}"}))
                    return

        # # 4. Route the API Request
        # try:
        #     if provider == "google":
        #         api_url = f"{endpoint.rstrip('/')}/{model}:generateContent?key={api_key}"
        #         payload = {
        #             "system_instruction": {"parts": [{"text": system_prompt}]},
        #             "contents": [{"parts": [{"text": prompt_text}]}],
        #             "generationConfig": {"temperature": 0.7}
        #         }
        #         req = urllib.request.Request(api_url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
        #         with urllib.request.urlopen(req, timeout=15) as response:
        #             result = json.loads(response.read().decode('utf-8'))
        #             cloud_draft = result['candidates'][0]['content']['parts'][0]['text'].strip()

        #     elif provider == "openai" or provider == "groq":
        #         payload = {
        #             "model": model,
        #             "messages": [
        #                 {"role": "system", "content": system_prompt},
        #                 {"role": "user", "content": prompt_text}
        #             ],
        #             "temperature": 0.7
        #         }
        #         headers = {
        #             'Content-Type': 'application/json',
        #             'Authorization': f'Bearer {api_key}'
        #         }
        #         req = urllib.request.Request(endpoint, data=json.dumps(payload).encode('utf-8'), headers=headers)
        #         with urllib.request.urlopen(req, timeout=15) as response:
        #             result = json.loads(response.read().decode('utf-8'))
        #             cloud_draft = result['choices'][0]['message']['content'].strip()
            
        #     else:
        #         print(json.dumps({"status": "error", "errors": f"Unsupported provider: {provider}"}))
        #         return

        #     # 🛑 MEMORY PATCH: Extract the URL from the incoming context to keep the chain alive
        #     target_url_line = ""
        #     for line in article_context.split('\n'):
        #         if line.startswith("TARGET_URL:"):
        #             target_url_line = line.strip()
        #             break

        #     # 🛑 VISUAL VERIFICATION LOGGER (Prints to terminal)
        #     print("\n" + "═"*50, file=sys.stderr)
        #     print("📝 [DEBUG] CLOUD MODEL DRAFT GENERATED:", file=sys.stderr)
        #     print("═"*50, file=sys.stderr)
        #     print(cloud_draft, file=sys.stderr)
        #     print("═"*50 + "\n", file=sys.stderr)

        #     # 5. Output Success back to IronClaw, ensuring the URL rides along
        #     if target_url_line:
        #         final_text = f"{target_url_line}\n--- FAST TRACK DRAFT ---\n{cloud_draft}"
        #     else:
        #         final_text = f"--- FAST TRACK DRAFT ---\n{cloud_draft}"
                
        #     print(json.dumps({"status": "success", "data": final_text, "errors": ""}))
                
        # except Exception as e:
        #     print(json.dumps({"status": "error", "errors": f"Cloud drafting failed: {str(e)}"}))

    except Exception as e:
        print(json.dumps({"status": "error", "errors": f"Script error: {str(e)}"}))

if __name__ == "__main__":
    run_draft()
EOF