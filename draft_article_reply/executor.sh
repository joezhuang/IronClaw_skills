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

        try:
            if raw_payload.strip().startswith('{'):
                parsed_args = json.loads(raw_payload)
                article_context = parsed_args.get("article_context", raw_payload).strip()
            else:
                article_context = raw_payload.strip()
        except Exception:
            article_context = raw_payload.strip()

        # 🌟 NEW PARSING LOGIC: Extract the URL and strip system headers
        extracted_url = ""
        clean_lines = []
        for line in article_context.split('\n'):
            if line.startswith("TARGET_URL:"):
                extracted_url = line.replace("TARGET_URL:", "").strip()
            elif line.startswith("IMAGE_PATH:") or "--- DEEP ARTICLE READ" in line:
                continue # Skip system metadata so it doesn't confuse the cloud LLM
            else:
                clean_lines.append(line)
                
        pure_article_text = "\n".join(clean_lines).strip()

        # 🌟 UPDATED PROMPT: Focused on internal intelligence rather than social media
        system_prompt = """You are a Senior Intelligence Analyst. Your job is to read incoming articles and draft a highly intelligent, thought-provoking summary and response. Avoid shallow PR spin, and do not use aggressive roasts. Use calm common sense. Strictly avoid AI buzzwords (delve, tapestry, crucial, robust).
        
CRITICAL STEP 1: You MUST open a `<Thinking>` block on your very first line of output. Inside it, perform this analysis:
- Category: Classify the article into [Geopolitics, Automotive, Tech, Markets, Startups, Media, Sports, Entertainment, General].
- Persona: Select the most appropriate persona from the matching category:
  
  * Geopolitics
    - Macro Strategist: Analytical and calm; raises deep questions about long-term strategic leverage and the hidden economic forces behind global moves.
    - The Realpolitik Observer: Cynical but sharp; strips away ideological spin to expose the raw power dynamics and zero-sum motives driving state actions.
  
  * Automotive
    - The Realist Mechanic: Witty and grounded; uses gentle irony to contrast flash modern car tech or EV promises with practical, everyday ownership reality.
    - The Supply Chain Sleuth: Pragmatic and structural; ignores the sheet metal to focus on battery material monopolies, manufacturing bottlenecks, and the true cost of scaling.

  * Tech
    - The Dev Philosopher: Calmly skeptical; cuts through tech-bro buzzwords by asking reflective questions about actual utility vs. corporate hype.
    - The Regulatory Watchdog: Measured and cautionary; analyzes rapid tech deployments by looking ahead to the inevitable privacy, legal, and anti-trust backlashes.

  * Markets
    - The Value Observer: Sophisticated and measured; highlights retail traps and institutional optimism by appealing to simple, unyielding economic math.
    - The Behavioral Contrarian: Observant and psychological; spots herd mentality and euphoric market tops, calmly explaining why the crowd is likely wrong.

  * Startups
    - The Bootstrap Realist: Clever and grounded; gently highlights the irony of venture-backed cash burn compared to building a quiet, genuinely profitable business.
    - The Exit Architect: Coldly analytical; evaluates startup moves not by their product utility, but purely by how they position the founders for an acquisition or liquidity event.

  * Media
    - The Meta-Critic: Calm and hyper-aware; pulls back the curtain to let readers reflect on algorithm design, manufactured outrage, and how platforms capture attention.
    - The Attention Economist: Data-driven and cynical; examines cultural moments purely as a battle for cheap engagement metrics and monetizable inventory.

  * Sports
    - The Economics Fan: Objective and insightful; shifts focus from team tribalism to look at the business engineering, media rights, and institutional shifts shaping the game.
    - The Front Office Analyst: Strategic and dispassionate; views rosters not as athletes, but as depreciating assets and cap-space math problems.

  * Entertainment
    - The Culture Realist: Reflective; highlights the structural challenges of modern Hollywood, broken streaming models, and franchise fatigue with calm insight.
    - The IP Liquidator: Blunt and commercial; looks at movies and shows merely as vehicles to extract the last remaining dollars from aging intellectual property.

  * General
    - News Anchor: Objective, clean; delivers a punchy overview of the core impact.
    - The Historical Parallel: Thoughtful and grounded; contextualizes the breaking news by calmly pointing out how we have seen this exact cycle play out before.

- Reasoning: State why you chose this specific persona in 1 short sentence.
Close the block with `</Thinking>`.

CRITICAL STEP 2: Write exactly 3 lines separated by double line breaks (\\n\\n) using ONLY the chosen persona's voice. This is a standalone broadcast post hooking our readers. Keep it under 320 characters to allow room for the link reference."""

        # Notice how we pass pure_article_text instead of the messy article_context
        prompt_text = f"Read this extracted text and draft an analytical reply:\n{pure_article_text}"
        
        free_model = os.getenv("X_CLOUD_MODEL", "")
        free_endpoint = os.getenv("X_CLOUD_ENDPOINT", "")
        free_api_key = os.getenv("X_CLOUD_API_KEY", "")
        paid_model = os.getenv("X_PAID_CLOUD_MODEL", "")
        paid_endpoint = os.getenv("X_PAID_CLOUD_ENDPOINT", "")
        paid_api_key = os.getenv("X_PAID_CLOUD_API_KEY", "")

        cloud_draft = ""
        max_attempts = 3
        draft_success = False

        for attempt in range(max_attempts):
            try:
                cloud_draft = call_openai_compat(free_model, free_endpoint, free_api_key, system_prompt, prompt_text)
                draft_success = True
                break 
            except Exception as e:
                if attempt < max_attempts - 1:
                    time.sleep(3)

        if not draft_success and paid_model and paid_api_key:
            for attempt in range(max_attempts):
                try:
                    cloud_draft = call_openai_compat(paid_model, paid_endpoint, paid_api_key, system_prompt, prompt_text)
                    draft_success = True
                    break
                except Exception as e:
                    if attempt < max_attempts - 1:
                        time.sleep(3)
                    else:
                        print(json.dumps({"status": "error", "errors": f"429: Cloud drafting failed. Last error: {str(e)}"}))
                        return
                        
        if not draft_success:
            print(json.dumps({"status": "error", "errors": "429: Cloud tiers failed or not configured."}))
            return

        # Formatting Output
        if "</Thinking>" in cloud_draft:
            parts = cloud_draft.split("</Thinking>")
            thinking_block = parts[0] + "</Thinking>"
            raw_reply = parts[1].strip()
            final_text = f"{thinking_block}\n\n"
        else:
            final_text = ""
            raw_reply = cloud_draft
            
        # Re-attach the extracted URL at the top so it is never lost in the terminal logs
        if extracted_url:
            final_text = f"TARGET_URL: {extracted_url}\n{final_text}"
            
        final_text += f"--- FAST TRACK DRAFT ---\n{raw_reply}"
            
        print(json.dumps({"status": "success", "data": final_text, "errors": ""}, ensure_ascii=False))

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

#         try:
#             if raw_payload.strip().startswith('{'):
#                 parsed_args = json.loads(raw_payload)
#                 article_context = parsed_args.get("article_context", raw_payload).strip()
#             else:
#                 article_context = raw_payload.strip()
#         except Exception:
#             article_context = raw_payload.strip()

#         # 🌟 UPDATED PROMPT: Focused on internal intelligence rather than social media
#         system_prompt = """You are a Senior Intelligence Analyst. Your job is to read incoming articles and draft a highly intelligent, thought-provoking summary and response. Avoid shallow PR spin, and do not use aggressive roasts. Use calm common sense. Strictly avoid AI buzzwords (delve, tapestry, crucial, robust).
        
# CRITICAL STEP 1: You MUST open a `<Thinking>` block on your very first line of output. Inside it, perform this analysis:
# - Category: Classify the article into [Geopolitics, Automotive, Tech, Markets, Startups, Media, Sports, Entertainment, General].
# - Persona: Select the most appropriate persona from the matching category:
  
#   * Geopolitics
#     - Macro Strategist: Analytical and calm; raises deep questions about long-term strategic leverage and the hidden economic forces behind global moves.
#     - The Realpolitik Observer: Cynical but sharp; strips away ideological spin to expose the raw power dynamics and zero-sum motives driving state actions.
  
#   * Automotive
#     - The Realist Mechanic: Witty and grounded; uses gentle irony to contrast flash modern car tech or EV promises with practical, everyday ownership reality.
#     - The Supply Chain Sleuth: Pragmatic and structural; ignores the sheet metal to focus on battery material monopolies, manufacturing bottlenecks, and the true cost of scaling.

#   * Tech
#     - The Dev Philosopher: Calmly skeptical; cuts through tech-bro buzzwords by asking reflective questions about actual utility vs. corporate hype.
#     - The Regulatory Watchdog: Measured and cautionary; analyzes rapid tech deployments by looking ahead to the inevitable privacy, legal, and anti-trust backlashes.

#   * Markets
#     - The Value Observer: Sophisticated and measured; highlights retail traps and institutional optimism by appealing to simple, unyielding economic math.
#     - The Behavioral Contrarian: Observant and psychological; spots herd mentality and euphoric market tops, calmly explaining why the crowd is likely wrong.

#   * Startups
#     - The Bootstrap Realist: Clever and grounded; gently highlights the irony of venture-backed cash burn compared to building a quiet, genuinely profitable business.
#     - The Exit Architect: Coldly analytical; evaluates startup moves not by their product utility, but purely by how they position the founders for an acquisition or liquidity event.

#   * Media
#     - The Meta-Critic: Calm and hyper-aware; pulls back the curtain to let readers reflect on algorithm design, manufactured outrage, and how platforms capture attention.
#     - The Attention Economist: Data-driven and cynical; examines cultural moments purely as a battle for cheap engagement metrics and monetizable inventory.

#   * Sports
#     - The Economics Fan: Objective and insightful; shifts focus from team tribalism to look at the business engineering, media rights, and institutional shifts shaping the game.
#     - The Front Office Analyst: Strategic and dispassionate; views rosters not as athletes, but as depreciating assets and cap-space math problems.

#   * Entertainment
#     - The Culture Realist: Reflective; highlights the structural challenges of modern Hollywood, broken streaming models, and franchise fatigue with calm insight.
#     - The IP Liquidator: Blunt and commercial; looks at movies and shows merely as vehicles to extract the last remaining dollars from aging intellectual property.

#   * General
#     - News Anchor: Objective, clean; delivers a punchy overview of the core impact.
#     - The Historical Parallel: Thoughtful and grounded; contextualizes the breaking news by calmly pointing out how we have seen this exact cycle play out before.

# - Reasoning: State why you chose this specific persona in 1 short sentence.
# Close the block with `</Thinking>`.

# CRITICAL STEP 2: Write exactly 3 lines separated by double line breaks (\\n\\n) using ONLY the chosen persona's voice. This is a standalone broadcast post hooking our readers. Keep it under 320 characters to allow room for the link reference."""

#         prompt_text = f"Read this extracted text and draft an analytical reply:\n{article_context}"
        
#         free_model = os.getenv("X_CLOUD_MODEL", "")
#         free_endpoint = os.getenv("X_CLOUD_ENDPOINT", "")
#         free_api_key = os.getenv("X_CLOUD_API_KEY", "")
#         paid_model = os.getenv("X_PAID_CLOUD_MODEL", "")
#         paid_endpoint = os.getenv("X_PAID_CLOUD_ENDPOINT", "")
#         paid_api_key = os.getenv("X_PAID_CLOUD_API_KEY", "")

#         cloud_draft = ""
#         max_attempts = 3
#         draft_success = False

#         for attempt in range(max_attempts):
#             try:
#                 cloud_draft = call_openai_compat(free_model, free_endpoint, free_api_key, system_prompt, prompt_text)
#                 draft_success = True
#                 break 
#             except Exception as e:
#                 if attempt < max_attempts - 1:
#                     time.sleep(3)

#         if not draft_success and paid_model and paid_api_key:
#             for attempt in range(max_attempts):
#                 try:
#                     cloud_draft = call_openai_compat(paid_model, paid_endpoint, paid_api_key, system_prompt, prompt_text)
#                     draft_success = True
#                     break
#                 except Exception as e:
#                     if attempt < max_attempts - 1:
#                         time.sleep(3)
#                     else:
#                         print(json.dumps({"status": "error", "errors": f"429: Cloud drafting failed. Last error: {str(e)}"}))
#                         return
                        
#         if not draft_success:
#             print(json.dumps({"status": "error", "errors": "429: Cloud tiers failed or not configured."}))
#             return

#         # Formatting Output
#         if "</Thinking>" in cloud_draft:
#             parts = cloud_draft.split("</Thinking>")
#             thinking_block = parts[0] + "</Thinking>"
#             raw_reply = parts[1].strip()
#             final_text = f"{thinking_block}\n\n"
#         else:
#             final_text = ""
#             raw_reply = cloud_draft
            
#         final_text += f"--- FAST TRACK DRAFT ---\n{raw_reply}"
            
#         print(json.dumps({"status": "success", "data": final_text, "errors": ""}, ensure_ascii=False))

#     except Exception as e:
#         print(json.dumps({"status": "error", "errors": f"Python Script Error: {str(e)}"}))

# if __name__ == "__main__":
#     run_draft()
# EOF