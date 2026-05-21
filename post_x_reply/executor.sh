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

def run_task():
    try:
        input_data = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].strip() else "{}"
        
        skill_root = os.getcwd() 
        script_path = os.path.abspath(os.path.join(skill_root, "post_reply.py"))
        
        script_content = r"""import asyncio
import os
import sys
import json
import random
from playwright.async_api import async_playwright

async def run_reply():
    try:
        input_data = sys.argv[1] if len(sys.argv) > 1 else "{}"
        args = json.loads(input_data)
        target_url = args.get("target_url", "")
        reply_text = args.get("reply_text", "")

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
                
                print("⏳ Waiting 60s for review...")
                await asyncio.sleep(60)

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
            
            await context.close()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(run_reply())
"""
        with open(script_path, "w") as f:
            f.write(script_content)

        process = subprocess.run([sys.executable, script_path, input_data], capture_output=True, text=True)
        print(json.dumps({"status": "success", "logs": process.stdout.strip(), "errors": process.stderr.strip()}))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run_task()
EOF