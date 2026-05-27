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
import time

def call_openai_compat(model, endpoint, api_key, system_prompt, prompt_text):
    """Handles both Google's OpenAI-compatible endpoint and OpenRouter."""
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt_text}
        ],
        "temperature": 0.3
    }
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}',
        'HTTP-Referer': 'https://github.com/ironclaw',
        'X-Title': 'IronClaw AI'
    }
    
    req = urllib.request.Request(endpoint, data=json.dumps(payload).encode('utf-8'), headers=headers)
    with urllib.request.urlopen(req, timeout=15) as response:
        result = json.loads(response.read().decode('utf-8'))
        return result['choices'][0]['message']['content'].strip()

def run_draft():
    try:
        raw_payload = sys.argv[1] if len(sys.argv) > 1 else ""
        if not raw_payload:
            print(json.dumps({"status": "error", "errors": "No payload provided."}))
            return

        # Safely parse JSON
        try:
            if raw_payload.strip().startswith('{'):
                parsed_args = json.loads(raw_payload)
                article_context = parsed_args.get("article_context", raw_payload).strip()
            else:
                article_context = raw_payload.strip()
        except Exception:
            article_context = raw_payload.strip()

        # MEMORY PATCH: Robust URL Extraction (Clean, uncorrupted URL parsing)
        clean_url = ""
        try:
            if raw_payload.strip().startswith('{'):
                parsed_args = json.loads(raw_payload)
                if "target_url" in parsed_args:
                    clean_url = parsed_args['target_url'].replace("TARGET_URL:", "").strip()
        except Exception:
            pass

        if not clean_url:
            for line in article_context.split('\n'):
                if line.startswith("TARGET_URL:"):
                    clean_url = line.replace("TARGET_URL:", "").strip()
                    break

        # 🌟 UPDATED SYSTEM PROMPT: Expanded to the 7-Persona Menu
        system_prompt = """You are the IronClaw engagement agent. You focus on objective, thought-provoking insights. Avoid shallow PR spin, but do not use aggressive, hostile roasts. You prefer to convince people using calm common sense. Strictly avoid AI buzzwords (delve, tapestry, crucial, robust).
        
CRITICAL STEP 1: You MUST open a `<Thinking>` block on your very first line of output. Inside it, perform this analysis:
- Category: Classify the article into [Geopolitics, Automotive, Tech, Markets, Startups, Media, Sports, Entertainment, General].
- Persona: Select the matching persona:
  * Geopolitics -> Macro Strategist (Analytical and calm; raises deep questions about long-term strategic leverage and the hidden economic forces behind global moves).
  * Automotive -> The Realist Mechanic (Witty and grounded; uses gentle irony to contrast flash modern car tech or EV promises with practical, everyday ownership reality).
  * Tech -> The Dev Philosopher (Calmly skeptical; cuts through tech-bro buzzwords by asking reflective questions about actual utility vs. corporate hype).
  * Markets -> The Value Observer (Sophisticated and measured; highlights retail traps and institutional optimism by appealing to simple, unyielding economic math).
  * Startups -> The Bootstrap Realist (Clever and grounded; gently highlights the irony of venture-backed cash burn compared to building a quiet, genuinely profitable business).
  * Media -> The Meta-Critic (Calm and hyper-aware; pulls back the curtain to let readers reflect on algorithm design, manufactured outrage, and how platforms capture attention).
  * Sports -> The Economics Fan (Objective and insightful; shifts focus from team tribalism to look at the business engineering, media rights, and institutional shifts shaping the game).
  * Entertainment -> The Culture Realist (Reflective; highlights the structural challenges of modern Hollywood, broken streaming models, and franchise fatigue with calm insight).
  * General -> News Anchor (Objective, clean; delivers a punchy overview of the core impact).
- Reasoning: State why you chose this in 1 short sentence.
Close the block with `</Thinking>`.

CRITICAL STEP 2: Write exactly 3 lines separated by double line breaks (\\n\\n) using ONLY the chosen persona's voice. Keep it under 400 characters."""

        prompt_text = f"Read this article and draft the tweet:\n{article_context}"
        
        # Pull configurations
        free_model = os.getenv("X_CLOUD_MODEL", "")
        free_endpoint = os.getenv("X_CLOUD_ENDPOINT", "")
        free_api_key = os.getenv("X_CLOUD_API_KEY", "")
        
        paid_model = os.getenv("X_PAID_CLOUD_MODEL", "")
        paid_endpoint = os.getenv("X_PAID_CLOUD_ENDPOINT", "")
        paid_api_key = os.getenv("X_PAID_CLOUD_API_KEY", "")

        cloud_draft = ""
        max_attempts = 3
        draft_success = False

        # --- TIER 1: Try Free API ---
        for attempt in range(max_attempts):
            try:
                cloud_draft = call_openai_compat(free_model, free_endpoint, free_api_key, system_prompt, prompt_text)
                draft_success = True
                break 
            except Exception as e:
                if attempt < max_attempts - 1:
                    print(f"⚠️ [DEBUG] Free Tier ({free_model}) failed, retrying {attempt + 1}/{max_attempts}...")
                    time.sleep(3)
                else:
                    print(f"⚠️ [DEBUG] Free Tier failed completely: {str(e)}. Switching to PAID tier...")

        # --- TIER 2: Try Paid API (OpenRouter) ---
        if not draft_success and paid_model and paid_api_key:
            for attempt in range(max_attempts):
                try:
                    cloud_draft = call_openai_compat(paid_model, paid_endpoint, paid_api_key, system_prompt, prompt_text)
                    draft_success = True
                    break
                except Exception as e:
                    if attempt < max_attempts - 1:
                        print(f"⚠️ [DEBUG] Paid Tier ({paid_model}) failed, retrying {attempt + 1}/{max_attempts}...")
                        time.sleep(3)
                    else:
                        print(json.dumps({"status": "error", "errors": f"429: Cloud drafting failed on BOTH tiers. Last error: {str(e)}"}))
                        return
                        
        if not draft_success:
            print(json.dumps({"status": "error", "errors": "429: Free tier failed and Paid tier not configured."}))
            return

        # Visual Verification (For terminal monitoring)
        print("\n" + "═"*50)
        print("📝 [DEBUG] CLOUD MODEL DRAFT GENERATED:")
        print("═"*50)
        print(cloud_draft)
        print("═"*50 + "\n")

        # 6. OUTPUT EXTRACTION: Split Thinking block and ensure clean payload passing
        if "</Thinking>" in cloud_draft:
            parts = cloud_draft.split("</Thinking>")
            thinking_block = parts[0] + "</Thinking>"
            raw_tweet = parts[1].strip()
            
            if clean_url:
                final_text = f"{thinking_block}\n\nTARGET_URL: {clean_url}\n\n--- FAST TRACK DRAFT ---\n{raw_tweet}"
            else:
                final_text = f"{thinking_block}\n\n--- FAST TRACK DRAFT ---\n{raw_tweet}"
        else:
            # Fallback if cloud model strips thinking tags
            if clean_url:
                final_text = f"TARGET_URL: {clean_url}\n\n--- FAST TRACK DRAFT ---\n{cloud_draft}"
            else:
                final_text = f"--- FAST TRACK DRAFT ---\n{cloud_draft}"
            
        print(json.dumps({"status": "success", "data": final_text, "errors": ""}))

    except Exception as e:
        print(json.dumps({"status": "error", "errors": f"Python Script Error: {str(e)}"}))

if __name__ == "__main__":
    run_draft()
EOF
# #!/bin/bash

# # 1. Automatically load and export variables from a .env file
# if [ -f .env ]; then
#     export $(cat .env | grep -v '^#' | xargs)
# fi

# if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
#     EXEC_CMD="$SKILL_VENV_PATH"
# else
#     EXEC_CMD="python3"
# fi

# "$EXEC_CMD" - "$1" <<'EOF'
# import sys
# import os
# import json
# import urllib.request
# import time

# def call_openai_compat(model, endpoint, api_key, system_prompt, prompt_text):
#     """Handles both Google's OpenAI-compatible endpoint and OpenRouter."""
#     payload = {
#         "model": model,
#         "messages": [
#             {"role": "system", "content": system_prompt},
#             {"role": "user", "content": prompt_text}
#         ],
#         "temperature": 0.3
#     }
#     headers = {
#         'Content-Type': 'application/json',
#         'Authorization': f'Bearer {api_key}',
#         'HTTP-Referer': 'https://github.com/ironclaw',
#         'X-Title': 'IronClaw AI'
#     }
    
#     req = urllib.request.Request(endpoint, data=json.dumps(payload).encode('utf-8'), headers=headers)
#     with urllib.request.urlopen(req, timeout=15) as response:
#         result = json.loads(response.read().decode('utf-8'))
#         return result['choices'][0]['message']['content'].strip()

# def run_draft():
#     try:
#         raw_payload = sys.argv[1] if len(sys.argv) > 1 else ""
#         if not raw_payload:
#             print(json.dumps({"status": "error", "errors": "No payload provided."}))
#             return

#         # Safely parse JSON
#         try:
#             if raw_payload.strip().startswith('{'):
#                 parsed_args = json.loads(raw_payload)
#                 article_context = parsed_args.get("article_context", raw_payload).strip()
#             else:
#                 article_context = raw_payload.strip()
#         except Exception:
#             article_context = raw_payload.strip()

#         # # MEMORY PATCH: Extract URL
#         # target_url_line = ""
#         # for line in article_context.split('\n'):
#         #     if line.startswith("TARGET_URL:"):
#         #         target_url_line = line.strip()
#         #         break

#         # MEMORY PATCH: Robust URL Extraction
#         target_url_line = ""
#         try:
#             if raw_payload.strip().startswith('{'):
#                 parsed_args = json.loads(raw_payload)
#                 # Check if target_url was explicitly passed in the JSON structure
#                 if "target_url" in parsed_args:
#                     target_url_line = f"TARGET_URL: {parsed_args['target_url']}"
#         except Exception:
#             pass

#         if not target_url_line:
#             for line in article_context.split('\n'):
#                 if line.startswith("TARGET_URL:"):
#                     target_url_line = line.strip()
#                     break

#         # 🌟 UPDATED SYSTEM PROMPT: Expanded to the 7-Persona Menu
#         system_prompt = """You are the IronClaw engagement agent. You focus on objective, thought-provoking insights. Avoid shallow PR spin, but do not use aggressive, hostile roasts. You prefer to convince people using calm common sense. Strictly avoid AI buzzwords (delve, tapestry, crucial, robust).
        
# CRITICAL STEP 1: You MUST open a `<Thinking>` block on your very first line of output. Inside it, perform this analysis:
# - Category: Classify the article into [Geopolitics, Automotive, Tech, Markets, Startups, Media, Sports, Entertainment, General].
# - Persona: Select the matching persona:
#   * Geopolitics -> Macro Strategist (Analytical and calm; raises deep questions about long-term strategic leverage and the hidden economic forces behind global moves).
#   * Automotive -> The Realist Mechanic (Witty and grounded; uses gentle irony to contrast flash modern car tech or EV promises with practical, everyday ownership reality).
#   * Tech -> The Dev Philosopher (Calmly skeptical; cuts through tech-bro buzzwords by asking reflective questions about actual utility vs. corporate hype).
#   * Markets -> The Value Observer (Sophisticated and measured; highlights retail traps and institutional optimism by appealing to simple, unyielding economic math).
#   * Startups -> The Bootstrap Realist (Clever and grounded; gently highlights the irony of venture-backed cash burn compared to building a quiet, genuinely profitable business).
#   * Media -> The Meta-Critic (Calm and hyper-aware; pulls back the curtain to let readers reflect on algorithm design, manufactured outrage, and how platforms capture attention).
#   * Sports -> The Economics Fan (Objective and insightful; shifts focus from team tribalism to look at the business engineering, media rights, and institutional shifts shaping the game).
#   * Entertainment -> The Culture Realist (Reflective; highlights the structural challenges of modern Hollywood, broken streaming models, and franchise fatigue with calm insight).
#   * General -> News Anchor (Objective, clean; delivers a punchy overview of the core impact).
# - Reasoning: State why you chose this in 1 short sentence.
# Close the block with `</Thinking>`.

# CRITICAL STEP 2: Write exactly 3 lines separated by double line breaks (\\n\\n) using ONLY the chosen persona's voice. Keep it under 400 characters."""

#         prompt_text = f"Read this article and draft the tweet:\n{article_context}"
        
#         # Pull configurations
#         free_model = os.getenv("X_CLOUD_MODEL", "")
#         free_endpoint = os.getenv("X_CLOUD_ENDPOINT", "")
#         free_api_key = os.getenv("X_CLOUD_API_KEY", "")
        
#         paid_model = os.getenv("X_PAID_CLOUD_MODEL", "")
#         paid_endpoint = os.getenv("X_PAID_CLOUD_ENDPOINT", "")
#         paid_api_key = os.getenv("X_PAID_CLOUD_API_KEY", "")

#         cloud_draft = ""
#         max_attempts = 3
#         draft_success = False

#         # --- TIER 1: Try Free API ---
#         for attempt in range(max_attempts):
#             try:
#                 cloud_draft = call_openai_compat(free_model, free_endpoint, free_api_key, system_prompt, prompt_text)
#                 draft_success = True
#                 break 
#             except Exception as e:
#                 if attempt < max_attempts - 1:
#                     print(f"⚠️ [DEBUG] Free Tier ({free_model}) failed, retrying {attempt + 1}/{max_attempts}...")
#                     time.sleep(3)
#                 else:
#                     print(f"⚠️ [DEBUG] Free Tier failed completely: {str(e)}. Switching to PAID tier...")

#         # --- TIER 2: Try Paid API (OpenRouter) ---
#         if not draft_success and paid_model and paid_api_key:
#             for attempt in range(max_attempts):
#                 try:
#                     cloud_draft = call_openai_compat(paid_model, paid_endpoint, paid_api_key, system_prompt, prompt_text)
#                     draft_success = True
#                     break
#                 except Exception as e:
#                     if attempt < max_attempts - 1:
#                         print(f"⚠️ [DEBUG] Paid Tier ({paid_model}) failed, retrying {attempt + 1}/{max_attempts}...")
#                         time.sleep(3)
#                     else:
#                         print(json.dumps({"status": "error", "errors": f"429: Cloud drafting failed on BOTH tiers. Last error: {str(e)}"}))
#                         return
                        
#         if not draft_success:
#             print(json.dumps({"status": "error", "errors": "429: Free tier failed and Paid tier not configured."}))
#             return

#         # 5. VISUAL VERIFICATION (For terminal only)
#         print("\n" + "═"*50)
#         print("📝 [DEBUG] CLOUD MODEL DRAFT GENERATED:")
#         print("═"*50)
#         print(cloud_draft)
#         print("═"*50 + "\n")

#         # 6. OUTPUT EXTRACTION: Ensure the delimiter splits the Thinking block from the payload
#         if "</Thinking>" in cloud_draft:
#             parts = cloud_draft.split("</Thinking>")
#             thinking_block = parts[0] + "</Thinking>"
#             raw_tweet = parts[1].strip()
            
#             if target_url_line:
#                 final_text = f"{thinking_block}\n\n--- FAST TRACK DRAFT ---\n{raw_tweet}\n\nSYSTEM DIRECTIVE: You must now execute post_x_reply. You MUST use this exact URL as the target_url argument: {target_url_line}"
#             else:
#                 final_text = f"{thinking_block}\n\n--- FAST TRACK DRAFT ---\n{raw_tweet}"
#         else:
#             # Fallback if cloud model fails to print tags
#             if target_url_line:
#                 final_text = f"--- FAST TRACK DRAFT ---\n{cloud_draft}\n\nSYSTEM DIRECTIVE: You must now execute post_x_reply. You MUST use this exact URL as the target_url argument: {target_url_line}"
#             else:
#                 final_text = f"--- FAST TRACK DRAFT ---\n{cloud_draft}"
            
#         print(json.dumps({"status": "success", "data": final_text, "errors": ""}))

#     except Exception as e:
#         print(json.dumps({"status": "error", "errors": f"Python Script Error: {str(e)}"}))

# if __name__ == "__main__":
#     run_draft()
# EOF
# #!/bin/bash

# # 1. Automatically load and export variables from a .env file
# if [ -f .env ]; then
#     export $(cat .env | grep -v '^#' | xargs)
# fi

# if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
#     EXEC_CMD="$SKILL_VENV_PATH"
# else
#     EXEC_CMD="python3"
# fi

# "$EXEC_CMD" - "$1" <<'EOF'
# import sys
# import os
# import json
# import urllib.request
# import time

# def call_openai_compat(model, endpoint, api_key, system_prompt, prompt_text):
#     """Handles both Google's OpenAI-compatible endpoint and OpenRouter."""
#     payload = {
#         "model": model,
#         "messages": [
#             {"role": "system", "content": system_prompt},
#             {"role": "user", "content": prompt_text}
#         ],
#         "temperature": 0.7
#     }
#     headers = {
#         'Content-Type': 'application/json',
#         'Authorization': f'Bearer {api_key}',
#         'HTTP-Referer': 'https://github.com/ironclaw', # Good practice for OpenRouter
#         'X-Title': 'IronClaw AI'
#     }
    
#     req = urllib.request.Request(endpoint, data=json.dumps(payload).encode('utf-8'), headers=headers)
#     with urllib.request.urlopen(req, timeout=15) as response:
#         result = json.loads(response.read().decode('utf-8'))
#         return result['choices'][0]['message']['content'].strip()

# def run_draft():
#     try:
#         raw_payload = sys.argv[1] if len(sys.argv) > 1 else ""
#         if not raw_payload:
#             print(json.dumps({"status": "error", "errors": "No payload provided."}))
#             return

#         # Safely parse JSON
#         try:
#             if raw_payload.strip().startswith('{'):
#                 parsed_args = json.loads(raw_payload)
#                 article_context = parsed_args.get("article_context", raw_payload).strip()
#             else:
#                 article_context = raw_payload.strip()
#         except Exception:
#             article_context = raw_payload.strip()

#         # MEMORY PATCH: Extract URL
#         target_url_line = ""
#         for line in article_context.split('\n'):
#             if line.startswith("TARGET_URL:"):
#                 target_url_line = line.strip()
#                 break

#         system_prompt = """You are a veteran, burnt-out financial and tech journalist for 'Briefly News'. 
# You hate PR spin and corporate jargon. 
# Rule 1: No AI buzzwords (delve, tapestry, crucial, robust). 
# Rule 2: Write exactly 3 lines separated by double line breaks (\n\n). 
# Line 1: Brutal summary. Line 2: The unspoken truth or financial motive. Line 3: A sharp, cynical question. 
# Rule 3: Keep it strictly under 250 characters."""

#         prompt_text = f"Read this article and draft the tweet:\n{article_context}"
        
#         # Pull configurations
#         free_model = os.getenv("X_CLOUD_MODEL", "")
#         free_endpoint = os.getenv("X_CLOUD_ENDPOINT", "")
#         free_api_key = os.getenv("X_CLOUD_API_KEY", "")
        
#         paid_model = os.getenv("X_PAID_CLOUD_MODEL", "")
#         paid_endpoint = os.getenv("X_PAID_CLOUD_ENDPOINT", "")
#         paid_api_key = os.getenv("X_PAID_CLOUD_API_KEY", "")

#         cloud_draft = ""
#         max_attempts = 3
#         draft_success = False

#         # --- TIER 1: Try Free API ---
#         for attempt in range(max_attempts):
#             try:
#                 cloud_draft = call_openai_compat(free_model, free_endpoint, free_api_key, system_prompt, prompt_text)
#                 draft_success = True
#                 break 
#             except Exception as e:
#                 if attempt < max_attempts - 1:
#                     print(f"⚠️ [DEBUG] Free Tier ({free_model}) failed, retrying {attempt + 1}/{max_attempts}...")
#                     time.sleep(3)
#                 else:
#                     print(f"⚠️ [DEBUG] Free Tier failed completely: {str(e)}. Switching to PAID tier...")

#         # --- TIER 2: Try Paid API (OpenRouter) ---
#         if not draft_success and paid_model and paid_api_key:
#             for attempt in range(max_attempts):
#                 try:
#                     cloud_draft = call_openai_compat(paid_model, paid_endpoint, paid_api_key, system_prompt, prompt_text)
#                     draft_success = True
#                     break
#                 except Exception as e:
#                     if attempt < max_attempts - 1:
#                         print(f"⚠️ [DEBUG] Paid Tier ({paid_model}) failed, retrying {attempt + 1}/{max_attempts}...")
#                         time.sleep(3)
#                     else:
#                         print(json.dumps({"status": "error", "errors": f"429: Cloud drafting failed on BOTH tiers. Last error: {str(e)}"}))
#                         return
                        
#         if not draft_success:
#             # Failsafe if Paid tier wasn't configured
#             print(json.dumps({"status": "error", "errors": "429: Free tier failed and Paid tier not configured."}))
#             return

#         # 5. VISUAL VERIFICATION (For terminal only)
#         print("\n" + "═"*50)
#         print("📝 [DEBUG] CLOUD MODEL DRAFT GENERATED:")
#         print("═"*50)
#         print(cloud_draft)
#         print("═"*50 + "\n")

#         # 6. OUTPUT (With URL attached)
#         if target_url_line:
#             final_text = f"--- FAST TRACK DRAFT ---\n{cloud_draft}\n\nSYSTEM DIRECTIVE: You must now execute post_x_reply. You MUST use this exact URL as the target_url argument: {target_url_line}"
#         else:
#             final_text = f"--- FAST TRACK DRAFT ---\n{cloud_draft}"
            
#         print(json.dumps({"status": "success", "data": final_text, "errors": ""}))

#     except Exception as e:
#         print(json.dumps({"status": "error", "errors": f"Python Script Error: {str(e)}"}))

# if __name__ == "__main__":
#     run_draft()
# EOF