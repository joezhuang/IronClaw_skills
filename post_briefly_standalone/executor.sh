#!/bin/bash

# Skip Bash-level validation to prevent JSON parsing crashes.
# Pass raw arguments directly to Python.
RAW_ARG_1="$1"
RAW_ARG_2="$2"

if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - "$RAW_ARG_1" "$RAW_ARG_2" <<'EOF'
import asyncio
import sys
import os
import json
import random
import re # 🌟 ADDED: Required for regex decoding
from playwright.async_api import async_playwright

async def run_publish(target_url, draft_text, image_path):
    # 1. Pull the account type from your .env file
    account_type = os.environ.get("X_ACCOUNT_TYPE", "free").lower()
    max_chars = 280 if account_type == "free" else 25000
    
    # 2. Define the static text and the Twitter link length
    append_text = "\n\nRead the full insight here: "
    twitter_link_length = 23 # X counts all URLs as exactly 23 chars
    
    # Calculate how Twitter's backend will "score" the appended string
    twitter_append_footprint = len(append_text) + twitter_link_length
    
    # 3. Safe Truncation: Check if the combined length exceeds the limit
    if len(draft_text) + twitter_append_footprint > max_chars:
        print(f"⚠️ Truncating post to fit {max_chars} chars (Account: {account_type})", file=sys.stderr)
        
        # Calculate exactly how much room we have left, minus 3 chars for the "..."
        allowed_draft_length = max_chars - twitter_append_footprint - 3
        
        # Slice the draft and add the ellipsis
        draft_text = draft_text[:allowed_draft_length].strip() + "..."
        
    # 4. Combine the safe draft with the untouched URL
    final_payload_text = f"{draft_text}{append_text}{target_url}"
    
    try:
        chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")
        async with async_playwright() as p:
            context = await p.chromium.launch_persistent_context(
                user_data_dir=chrome_data_dir,
                headless=False,
                args=[
                    "--profile-directory=Default", 
                    "--disable-blink-features=AutomationControlled",
                    "--disable-infobars"
                ],
                ignore_default_args=["--enable-automation"]
            )
            
            page = await context.new_page()
            
            # Anti-detection context mapping
            await page.add_init_script('''
                Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
                window.navigator.chrome = { runtime: {}, app: {}, csid: {}, loadTimes: function() {} };
                Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3] });
            ''')

            # 🌐 Route to the standard Home Page timeline
            home_url = "https://x.com/home"
            print(f"▶️ Navigating to X Home Page...", file=sys.stderr)
            
            await page.goto(home_url, wait_until="domcontentloaded")
            await asyncio.sleep(random.uniform(4.5, 6.5))

            # Locate the inline compose box at the top of the timeline
            editor_selector = '[data-testid="tweetTextarea_0"]'
            try:
                await page.wait_for_selector(editor_selector, timeout=10000)
            except Exception:
                # Failsafe: Click the main 'Post' side-nav button if the inline box isn't visible
                print("⚠️ Inline compose box not found, trying side-nav Post button...", file=sys.stderr)
                nav_btn = await page.query_selector('[data-testid="SideNav_NewTweet_Button"]')
                if nav_btn:
                    await nav_btn.click()
                    await asyncio.sleep(random.uniform(1.0, 2.0))
                    await page.wait_for_selector(editor_selector, timeout=10000)
                else:
                    print("❌ Compose area completely unreachable.", file=sys.stderr)
                    await context.close()
                    return {"status": "error", "errors": "Authentication wall or layout mismatch on X."}

            print("🎯 Compose editor focused. Injecting broadcast payload...", file=sys.stderr)
            await page.click(editor_selector)
            await asyncio.sleep(0.5)
            
            # 📸 NEW: Image Upload Logic
            if image_path and os.path.exists(image_path):
                print(f"🖼️ Attaching pure image payload: {image_path}", file=sys.stderr)
                # Playwright securely bypasses the UI and attaches the file directly to the hidden input
                await page.set_input_files('input[data-testid="fileInput"]', image_path)
                await asyncio.sleep(3.0) # Give X time to process the media upload

            # Type the payload securely
            await page.fill(editor_selector, final_payload_text)
            await asyncio.sleep(random.uniform(1.5, 2.5))

            # X uses different button IDs depending on if you are inline or in a modal
            post_button_selector = '[data-testid="tweetButtonInline"]'
            post_btn = await page.query_selector(post_button_selector)
            
            if not post_btn:
                post_button_selector = '[data-testid="tweetButton"]'
                post_btn = await page.query_selector(post_button_selector)

            if not post_btn:
                print("❌ Post button missing or blocked.", file=sys.stderr)
                await context.close()
                return {"status": "error", "errors": "Post button state unreachable."}

            print("🚀 Committing post to production timeline...", file=sys.stderr)
            await post_btn.click()
            
            print("⏳ Holding session for transaction verification...", file=sys.stderr)
            await asyncio.sleep(random.uniform(6.0, 9.0))
            
            await context.close()
            return {"status": "success", "posted_text": final_payload_text}

    except Exception as e:
        return {"status": "error", "errors": str(e)}

if __name__ == '__main__':
    raw_payload = sys.argv[1] if len(sys.argv) > 1 else ""

    target_url = ""
    post_text = ""
    image_path = ""

    # Safely unpack the JSON payload provided by the Go backend
    try:
        if raw_payload.strip().startswith('{'):
            # strict=False helps prevent crashes if the AI sends raw newlines
            parsed = json.loads(raw_payload, strict=False)
            target_url = parsed.get("target_url", "")
            post_text = parsed.get("post_text", "")
    except Exception:
        pass

    # 🌟 THE ENCODING SANITIZER: Clean the text before it goes any further
    if post_text:
        # 1. Reverse double-escaped unicodes (e.g., \\u2019 becomes ’)
        post_text = re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), post_text)
        
        # 2. Repair Mojibake (wrong byte decoding)
        try:
            post_text = post_text.encode('latin-1').decode('utf-8')
        except Exception:
            pass
            
        # 3. Translate literal \n text into actual line breaks
        post_text = post_text.replace('\\n', '\n').replace('\\"', '"')

    # Ultimate fallback to environment variables
    if not target_url:
        target_url = os.environ.get("target_url", "")
    if not post_text:
        post_text = os.environ.get("post_text", "")

    # Extract IMAGE_PATH and clean it out of the tweet body
    search_target = raw_payload + "\n" + post_text
    for line in search_target.split('\n'):
        if line.startswith("IMAGE_PATH:"):
            image_path = line.replace("IMAGE_PATH:", "").strip()
            break
            
    # Remove the IMAGE_PATH line from the drafted text so we don't accidentally tweet the file path
    if image_path and f"IMAGE_PATH: {image_path}" in post_text:
        post_text = post_text.replace(f"IMAGE_PATH: {image_path}", "").strip()

    if not target_url or not post_text:
        print(json.dumps({"status": "error", "errors": "Fatal: Missing target_url or post_text parameter. The AI failed to map the URL."}))
        sys.exit(1)

    output = asyncio.run(run_publish(target_url, post_text, image_path))
    
    # 🧹 Janitor cleanup to delete the local image
    if image_path and os.path.exists(image_path):
        try:
            os.remove(image_path)
            print(f"🧹 Janitor: Successfully deleted temporary image {image_path}", file=sys.stderr)
        except Exception as e:
            print(f"⚠️ Janitor: Failed to delete temporary image - {e}", file=sys.stderr)
    
    if output.get("status") == "success":
        # 🌟 ADDED ensure_ascii=False so emojis and smart quotes aren't re-escaped on output
        print(json.dumps({
            "status": "success",
            "data": f"✅ Successfully published to X: {target_url}\n\nPayload:\n{output.get('posted_text')}",
            "errors": ""
        }, ensure_ascii=False))
    else:
        print(json.dumps({"status": "error", "errors": output.get("errors", "Unknown worker failure.")}))
EOF