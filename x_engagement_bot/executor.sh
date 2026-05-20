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
        # Capture raw JSON from IronClaw
        input_data = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].strip() else "{}"
        
        skill_root = os.getcwd() 
        script_path = os.path.abspath(os.path.join(skill_root, "engage.py"))
        
        # Write the STATIC Python script
        script_content = r"""import asyncio
import os
import sys
import json
import random
from playwright.async_api import async_playwright

async def run_x_bot():
    try:
        input_data = sys.argv[1] if len(sys.argv) > 1 else "{}"
        args = json.loads(input_data)
        action = args.get("action", "scrape")
        target_url = args.get("target_url", "")
        reply_text = args.get("reply_text", "")

        chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")

        async with async_playwright() as p:
            context = await p.chromium.launch_persistent_context(
                user_data_dir=chrome_data_dir,
                headless=False,
                args=["--profile-directory=Default", "--disable-blink-features=AutomationControlled"],
                ignore_default_args=["--enable-automation"]
            )
            
            page = await context.new_page()

            if action == "scrape":
                # await page.goto("https://x.com/home")
                # # 👈 Change this line from "https://x.com/home" to your List URL if needed
                # # await page.goto("https://x.com/i/lists/2056906333920837714")

                # 🎲 Flip a coin to choose between Home and the Custom List
                feed_urls = [
                    "https://x.com/home",
                    "https://x.com/i/lists/2056906333920837714"
                ]
                chosen_feed = random.choice(feed_urls)
                
                print(f"🎯 Randomly selected feed for this run: {chosen_feed}")
                await page.goto(chosen_feed)
                
                await asyncio.sleep(10)
                articles = await page.query_selector_all("article")
                
                if not articles:
                    print("No posts found. Ensure you are logged in.")
                    await context.close()
                    return

                for i, article in enumerate(articles[:10]):
                    text = await article.inner_text()
                    
                    url = "Unknown URL"
                    links = await article.query_selector_all("a[href*='/status/']")
                    if links:
                        href = await links[0].get_attribute("href")
                        url = f"https://x.com{href}"

                    print(f"--- Post {i+1} ---")
                    print(f"URL: {url}")
                    print(text)
                    print("-" * 30)
            
            elif action == "reply":
                if not target_url or not reply_text:
                    print("Error: target_url and reply_text are required for reply action.")
                    await context.close()
                    return
                
                print(f"Navigating to target tweet: {target_url}")
                await page.goto(target_url)
                await asyncio.sleep(5)
                
                print("Checking for interfering popups...")
                await page.keyboard.press("Escape")
                await asyncio.sleep(1.5)
                
                try:
                    close_buttons = await page.query_selector_all('[aria-label="Close"], [data-testid="app-bar-close"]')
                    for btn in close_buttons:
                        if await btn.is_visible():
                            await btn.click(force=True)
                            print("Dismissed popup via Close button.")
                            await asyncio.sleep(1.5)
                except Exception as e:
                    pass

                reply_button = await page.query_selector('[data-testid="reply"]')
                if reply_button:
                    await reply_button.click(force=True)
                    await asyncio.sleep(random.uniform(1.5, 3.0))
                    
                    compose_box = await page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=5000)
                    await compose_box.type(reply_text, delay=random.randint(50, 150))
                    
                    print("⏳ Waiting 120 seconds for manual typing...")
                    await asyncio.sleep(60)
                    
                    submit_button = await page.wait_for_selector('[data-testid="tweetButton"]', timeout=5000)
                    await submit_button.click(force=True)
                    
                    # 🎯 FORMATTED OUTPUT FOR CHAT LOGS
                    print("\n" + "="*40)
                    print("✅ AI ENGAGEMENT COMPLETE")
                    print(f"🔗 Target Post: {target_url}")
                    print(f"💬 Sent Reply: {reply_text}")
                    print("="*40 + "\n")
                    
                    await asyncio.sleep(random.uniform(2.0, 4.0))

            await context.close()
    except Exception as e:
        print(f"Playwright Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(run_x_bot())
"""

        with open(script_path, "w") as f:
            f.write(script_content)

        process = subprocess.run([sys.executable, script_path, input_data], capture_output=True, text=True)
        
        result = {
            "status": "success" if process.returncode == 0 else "error",
            "file_created": script_path,
            "scraped_posts": process.stdout.strip(), # This captures the formatted print statements
            "errors": process.stderr.strip()
        }
        print(json.dumps(result))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run_task()
EOF

# #!/bin/bash

# if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
#     EXEC_CMD="$SKILL_VENV_PATH"
# else
#     EXEC_CMD="python3"
# fi

# "$EXEC_CMD" - "$1" <<'EOF'
# import sys
# import json
# import os
# import subprocess

# def run_task():
#     try:
#         # Capture raw JSON from IronClaw
#         input_data = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].strip() else "{}"
        
#         skill_root = os.getcwd() 
#         script_path = os.path.abspath(os.path.join(skill_root, "engage.py"))
        
#         # Write the STATIC Python script using r""" to prevent line-break errors
#         script_content = r"""import asyncio
# import os
# import sys
# import json
# import random
# from playwright.async_api import async_playwright

# async def run_x_bot():
#     try:
#         # Parse the arguments passed down from IronClaw
#         input_data = sys.argv[1] if len(sys.argv) > 1 else "{}"
#         args = json.loads(input_data)
#         action = args.get("action", "scrape")
#         target_url = args.get("target_url", "")
#         reply_text = args.get("reply_text", "")

#         chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")

#         async with async_playwright() as p:
#             context = await p.chromium.launch_persistent_context(
#                 user_data_dir=chrome_data_dir,
#                 headless=False,
#                 args=["--profile-directory=Default", "--disable-blink-features=AutomationControlled"],
#                 ignore_default_args=["--enable-automation"]
#             )
            
#             page = await context.new_page()

#             if action == "scrape":
#                 await page.goto("https://x.com/home")
#                 # 👈 Change this line from "https://x.com/home" to your List URL
#                 # await page.goto("https://x.com/i/lists/2056906333920837714")
                
#                 await asyncio.sleep(10)
#                 articles = await page.query_selector_all("article")
                
#                 if not articles:
#                     print("No posts found. Ensure you are logged in.")
#                     await context.close()
#                     return

#                 for i, article in enumerate(articles[:10]):
#                     text = await article.inner_text()
                    
#                     # Dig into the DOM to find the exact URL of this specific tweet
#                     url = "Unknown URL"
#                     links = await article.query_selector_all("a[href*='/status/']")
#                     if links:
#                         href = await links[0].get_attribute("href")
#                         url = f"https://x.com{href}"

#                     print(f"--- Post {i+1} ---")
#                     print(f"URL: {url}")
#                     print(text)
#                     print("-" * 30)
            
#             elif action == "reply":
#                 if not target_url or not reply_text:
#                     print("Error: target_url and reply_text are required for reply action.")
#                     await context.close()
#                     return
                
#                 print(f"Navigating to target tweet: {target_url}")
#                 await page.goto(target_url)
#                 await asyncio.sleep(5)
                
#                 # 🛡️ NEW: ANTI-POPUP LOGIC
#                 print("Checking for interfering popups...")
                
#                 # 1. The Human way: Hit the Escape key to close modals
#                 await page.keyboard.press("Escape")
#                 await asyncio.sleep(1.5)
                
#                 # 2. The Fallback way: Look for X's specific 'Close' buttons and click them
#                 try:
#                     close_buttons = await page.query_selector_all('[aria-label="Close"], [data-testid="app-bar-close"]')
#                     for btn in close_buttons:
#                         if await btn.is_visible():
#                             await btn.click(force=True)
#                             print("Dismissed popup via Close button.")
#                             await asyncio.sleep(1.5)
#                 except Exception as e:
#                     pass # If no popup is found, just continue smoothly
#                 # --------------------------------

#                 reply_button = await page.query_selector('[data-testid="reply"]')
#                 if reply_button:
#                     # Added force=True to bypass any invisible overlay masks left behind
#                     await reply_button.click(force=True)
#                     await asyncio.sleep(random.uniform(1.5, 3.0))
                    
#                     compose_box = await page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=5000)
#                     await compose_box.type(reply_text, delay=random.randint(50, 150))
                    
#                     # ⏳ Wait 2 full minutes so I can manually type or edit the reply!
#                     print("⏳ Waiting 120 seconds for manual typing...")
#                     await asyncio.sleep(95)
                    
#                     submit_button = await page.wait_for_selector('[data-testid="tweetButton"]', timeout=5000)
#                     await submit_button.click(force=True)
#                     print(f"🚀 Successfully posted AI reply: '{reply_text}'")
#                     await asyncio.sleep(random.uniform(2.0, 4.0))

#             await context.close()
#     except Exception as e:
#         print(f"Playwright Error: {e}", file=sys.stderr)
#         sys.exit(1)

# if __name__ == '__main__':
#     asyncio.run(run_x_bot())
# """

#         with open(script_path, "w") as f:
#             f.write(script_content)

#         # Execute the script and pass the JSON data natively
#         process = subprocess.run([sys.executable, script_path, input_data], capture_output=True, text=True)
        
#         result = {
#             "status": "success" if process.returncode == 0 else "error",
#             "file_created": script_path,
#             "scraped_posts": process.stdout.strip(),
#             "errors": process.stderr.strip()
#         }
#         print(json.dumps(result))

#     except Exception as e:
#         print(json.dumps({"error": str(e)}))

# if __name__ == "__main__":
#     run_task()
# EOF

# #!/bin/bash

# if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
#     EXEC_CMD="$SKILL_VENV_PATH"
# else
#     EXEC_CMD="python3"
# fi

# "$EXEC_CMD" - "$1" <<'EOF'
# import sys
# import json
# import os
# import subprocess

# def run_task():
#     try:
#         # Capture raw JSON from IronClaw
#         input_data = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].strip() else "{}"
        
#         skill_root = os.getcwd() 
#         script_path = os.path.abspath(os.path.join(skill_root, "engage.py"))
        
#         # Write the STATIC Python script (No more f-string escaping needed!)
#         script_content = """import asyncio
# import os
# import sys
# import json
# import random
# from playwright.async_api import async_playwright

# async def run_x_bot():
#     try:
#         # Parse the arguments passed down from IronClaw
#         input_data = sys.argv[1] if len(sys.argv) > 1 else "{}"
#         args = json.loads(input_data)
#         action = args.get("action", "scrape")
#         target_url = args.get("target_url", "")
#         reply_text = args.get("reply_text", "")

#         chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")

#         async with async_playwright() as p:
#             context = await p.chromium.launch_persistent_context(
#                 user_data_dir=chrome_data_dir,
#                 headless=False,
#                 args=["--profile-directory=Default", "--disable-blink-features=AutomationControlled"],
#                 ignore_default_args=["--enable-automation"]
#             )
            
#             page = await context.new_page()

#             if action == "scrape":
#                 await page.goto("https://x.com/home")
#                 # 👈 Change this line from "https://x.com/home" to your List URL
#                 # await page.goto("https://x.com/i/lists/2056906333920837714")
                
#                 await asyncio.sleep(10)
#                 articles = await page.query_selector_all("article")
                
#                 if not articles:
#                     print("No posts found. Ensure you are logged in.")
#                     await context.close()
#                     return

#                 for i, article in enumerate(articles[:10]):
#                     text = await article.inner_text()
                    
#                     # Dig into the DOM to find the exact URL of this specific tweet
#                     url = "Unknown URL"
#                     links = await article.query_selector_all("a[href*='/status/']")
#                     if links:
#                         href = await links[0].get_attribute("href")
#                         url = f"https://x.com{href}"

#                     print(f"--- Post {i+1} ---")
#                     print(f"URL: {url}")
#                     print(text)
#                     print("-" * 30)
            
#             elif action == "reply":
#                 if not target_url or not reply_text:
#                     print("Error: target_url and reply_text are required for reply action.")
#                     await context.close()
#                     return
                
#                 print(f"Navigating to target tweet: {target_url}")
#                 await page.goto(target_url)
#                 await asyncio.sleep(4)
                
#                 reply_button = await page.query_selector('[data-testid="reply"]')
#                 if reply_button:
#                     await reply_button.click()
#                     await asyncio.sleep(random.uniform(1.5, 3.0))
                    
#                     compose_box = await page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=5000)
#                     await compose_box.type(reply_text, delay=random.randint(50, 150))
#                     # await asyncio.sleep(random.uniform(1.0, 2.0))
#                     # ⏳ Wait 2 full minutes so I can manually type or edit the reply!
#                     print("⏳ Waiting 120 seconds for manual typing...")
#                     await asyncio.sleep(95)
                    
#                     submit_button = await page.wait_for_selector('[data-testid="tweetButton"]', timeout=5000)
#                     await submit_button.click()
#                     print(f"🚀 Successfully posted AI reply: '{reply_text}'")
#                     await asyncio.sleep(random.uniform(2.0, 4.0))

#             await context.close()
#     except Exception as e:
#         print(f"Playwright Error: {e}", file=sys.stderr)
#         sys.exit(1)

# if __name__ == '__main__':
#     asyncio.run(run_x_bot())
# """

#         with open(script_path, "w") as f:
#             f.write(script_content)

#         # Execute the script and pass the JSON data natively
#         process = subprocess.run([sys.executable, script_path, input_data], capture_output=True, text=True)
        
#         result = {
#             "status": "success" if process.returncode == 0 else "error",
#             "file_created": script_path,
#             "scraped_posts": process.stdout.strip(),
#             "errors": process.stderr.strip()
#         }
#         print(json.dumps(result))

#     except Exception as e:
#         print(json.dumps({"error": str(e)}))

# if __name__ == "__main__":
#     run_task()
# EOF