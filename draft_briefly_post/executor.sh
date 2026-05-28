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
import re

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

        # MEMORY PATCH: Pull target URL cleanly out of the context stream
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

        # 🌟 BRIEFLY BROADCAST PROMPT: Tweaked to focus on standalone platform posting
        system_prompt = """You are the Briefly News broadcast agent. Your job is to post an update to our X platform followers about a trending news cluster. You focus on objective, thought-provoking insights. Avoid shallow PR spin, but do not use aggressive, hostile roasts. You prefer to convince people using calm common sense. Strictly avoid AI buzzwords (delve, tapestry, crucial, robust).
        
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

CRITICAL STEP 2: Write exactly 3 lines separated by double line breaks (\\n\\n) using ONLY the chosen persona's voice. This is a standalone broadcast post hooking our readers. Keep it under 350 characters to allow room for the link reference."""

        prompt_text = f"Read this compiled news cluster and draft a standalone update tweet:\n{article_context}"
        
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

        # Output Construction: Places TARGET_URL perfectly back at the TOP of the data payload
        if "</Thinking>" in cloud_draft:
            parts = cloud_draft.split("</Thinking>")
            thinking_block = parts[0] + "</Thinking>"
            raw_tweet = parts[1].strip()
            
            if clean_url:
                final_text = f"{thinking_block}\n\nTARGET_URL: {clean_url}\n\n--- FAST TRACK DRAFT ---\n{raw_tweet}"
            else:
                final_text = f"{thinking_block}\n\n--- FAST TRACK DRAFT ---\n{raw_tweet}"
        else:
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