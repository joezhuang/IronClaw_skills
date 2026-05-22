#!/bin/bash

if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import os
import subprocess

def truncate_reply(text, limit=280):
    # 1. If it's already short enough, return it
    if len(text) <= limit:
        return text
    
    # 2. Get the substring of the allowed length
    # We leave room for the 3 dots
    truncated = text[:limit - 3]
    
    # 3. Find the last space in that string
    last_space = truncated.rfind(' ')
    
    # 4. If a space exists, cut at the space to keep the word whole
    if last_space != -1:
        return truncated[:last_space] + "..."
    
    # 5. Fallback: If no space (one giant word), force cut it
    return truncated + "..."

def run_task():
    try:
        skill_root = os.getcwd() 
        script_path = os.path.abspath(os.path.join(skill_root, "post_reply.py"))
        
        script_content = r"""import asyncio
import os
import sys
import random
from playwright.async_api import async_playwright

async def run_reply():
    try:
        # --- NEW INNER SCRIPT LOGIC (No JSON Parsing here!) ---
        target_url = sys.argv[1] if len(sys.argv) > 1 else ""
        reply_text = sys.argv[2] if len(sys.argv) > 2 else ""

        if not target_url or not reply_text:
            print("Error: target_url and reply_text are required.")
            sys.exit(1)

        clean_url = target_url.split('/analytics')[0].split('/photo/')[0]
        chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")

        async with async_playwright() as p:
            context = await p.chromium.launch_persistent_context(
                user_data_dir=chrome_data_dir,
                headless=False,
                args=["--profile-directory=Default", "--disable-blink-features=AutomationControlled"],
                ignore_default_args=["--enable-automation"]
            )
            
            page = await context.new_page()
            print(f"▶️ Navigating to: {clean_url}")
            await page.goto(clean_url)
            await asyncio.sleep(5)
            
            await page.keyboard.press("Escape")
            await asyncio.sleep(1.5)
            
            try:
                close_btns = await page.query_selector_all('[aria-label="Close"]')
                for btn in close_btns:
                    if await btn.is_visible():
                        await btn.click(force=True)
                        await asyncio.sleep(1.0)
            except Exception: pass

            reply_btn = await page.query_selector('[data-testid="reply"]')
            if reply_btn:
                await reply_btn.click(force=True)
                await asyncio.sleep(2)
                
                box = await page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=5000)
                await box.type(reply_text, delay=random.randint(10, 40))
                
                print("⏳ Waiting 40s for review...")
                await asyncio.sleep(40)

                active = True
                while active:
                    try:
                        curr = await box.input_value()
                        await asyncio.sleep(5)
                        new = await box.input_value()
                        if curr != new:
                            print("⌨️ User typing... +20s")
                            await asyncio.sleep(20)
                        else: active = False
                    except Exception: active = False
                
                try:
                    submit = await page.wait_for_selector('[data-testid="tweetButton"]', timeout=3000)
                    await submit.click(force=True)
                    status = "Auto-submitted"
                except Exception: status = "Manually submitted/edited"
                
                print(f"\n{'='*30}\n✅ POST COMPLETE\n💬 Reply: {reply_text}\n🤖 {status}\n{'='*30}\n")

            else:
                # Add this explicit failure catch!
                print(f"Error: Could not find the reply button. The URL might be broken or 404: {clean_url}", file=sys.stderr)
                sys.exit(1)
            
            await context.close()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(run_reply())
"""
        with open(script_path, "w") as f:
            f.write(script_content)

        # --- CORRECTED JSON PARSING LOGIC FOR OUTER WRAPPER ---
        target_url = ""
        reply_text = ""
        parse_error = ""
        
        raw_input = sys.argv[1] if len(sys.argv) > 1 else ""
        
        # If IronClaw passed a raw JSON object, unpack both variables
        if raw_input.strip().startswith('{'):
            try:
                # strict=False allows the LLM to use raw newlines or tabs without crashing the parser
                parsed = json.loads(raw_input, strict=False)
                target_url = parsed.get("target_url", "")
                reply_text = parsed.get("reply_text", "")
            except Exception as e:
                parse_error = str(e)
                pass
        else:
            # Fallback if passed as standard separate arguments
            target_url = raw_input
            reply_text = sys.argv[2] if len(sys.argv) > 2 else ""

        # Stop execution if we didn't successfully extract both pieces
        if not target_url or not reply_text:
            print(json.dumps({
                "status": "error", 
                "logs": f"JSON Parse Error: {parse_error}", 
                "errors": f"RAW PAYLOAD RECEIVED: {raw_input}"
            }))
            return

        # Get the account type from the environment (default to 'free')
        account_type = os.getenv("X_ACCOUNT_TYPE", "free")
        
        # Decide the length constraint
        max_chars = 280 if account_type == "free" else 25000
        
        if len(reply_text) > max_chars:
            print(f"⚠️ Truncating reply to {max_chars} chars (Account: {account_type})")
            reply_text = truncate_reply(reply_text, max_chars)

        # Execute the inner Playwright script passing TWO clean, separated arguments
        process = subprocess.run([sys.executable, script_path, target_url, reply_text], capture_output=True, text=True)
        
        print(json.dumps({"status": "success", "logs": process.stdout.strip(), "errors": process.stderr.strip()}))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run_task()
EOF
