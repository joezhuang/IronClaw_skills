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
        script_path = os.path.abspath(os.path.join(skill_root, "engage.py"))
        
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
        
        # Pulling single strings, not arrays
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
                feed_urls = [
                    "https://x.com/home",
                    "https://x.com/i/lists/2056906333920837714"
                ]
                chosen_feed = random.choice(feed_urls)
                
                print(f"🎯 Randomly selected feed for this run: {chosen_feed}")
                await page.goto(chosen_feed)
                await asyncio.sleep(6)
                
                print("📜 Scrolling timeline to load 10 posts...")
                for _ in range(4):
                    await page.mouse.wheel(0, 900)
                    await asyncio.sleep(2.0)
                
                articles = await page.query_selector_all("article")
                
                if not articles:
                    print("No posts found. Ensure you are logged in.")
                    await context.close()
                    return

                for i, article in enumerate(articles[:10]):
                    try:
                        show_more_btn = await article.query_selector('[data-testid="tweet-text-show-more-link"]')
                        if show_more_btn:
                            await show_more_btn.click(force=True)
                            await asyncio.sleep(0.5)
                    except Exception:
                        pass
                        
                    text = await article.inner_text()
                    
                    url = "Unknown URL"
                    links = await article.query_selector_all("a[href*='/status/']")
                    if links:
                        href = await links[0].get_attribute("href")
                        url = f"https://x.com{href}"

                    article_context = ""
                    try:
                        card_link = await article.query_selector('div[data-testid="card.wrapper"] a')
                        if card_link:
                            ext_url = await card_link.get_attribute("href")
                            if ext_url and "x.com" not in ext_url and "twitter.com" not in ext_url:
                                print(f"  🕵️‍♂️ Peeking at external article for Post {i+1}...")
                                new_tab = await context.new_page()
                                try:
                                    await new_tab.goto(ext_url, timeout=8000, wait_until="domcontentloaded")
                                    page_summary = await new_tab.evaluate('''() => {
                                        let meta = document.querySelector('meta[name="description"]') || document.querySelector('meta[property="og:description"]');
                                        let title = document.title || "No title found";
                                        let summary = meta ? (title + " - " + meta.content) : title;
                                        
                                        // Built-in Paywall Check
                                        let lowerSummary = summary.toLowerCase();
                                        if (lowerSummary.includes("subscribe to read") || lowerSummary.includes("paywall") || lowerSummary.includes("log in to")) {
                                            return "PAYWALL DETECTED - IGNORE THIS POST";
                                        }
                                        return summary;
                                    }''')
                                    article_context = f"\n\n[BOT X-RAY: {page_summary}]"
                                except Exception:
                                    pass 
                                finally:
                                    await new_tab.close()
                    except Exception:
                        pass

                    text += article_context

                    print(f"--- Post {i+1} ---")
                    print(f"URL: {url}")
                    print(text)
                    print("-" * 30)
            
            elif action == "reply":
                if not target_url or not reply_text:
                    print("Error: target_url and reply_text are required for reply action.")
                    await context.close()
                    return
                
                # Clean URL just in case the LLM grabbed analytics tags
                clean_target_url = target_url.split('/analytics')[0].split('/photo/')[0].split('/video/')[0]
                
                print(f"▶️ Navigating to target tweet: {clean_target_url}")
                await page.goto(clean_target_url)
                await asyncio.sleep(5)
                
                print("Checking for popups...")
                await page.keyboard.press("Escape")
                await asyncio.sleep(1.5)
                
                try:
                    close_buttons = await page.query_selector_all('[aria-label="Close"], [data-testid="app-bar-close"]')
                    for btn in close_buttons:
                        if await btn.is_visible():
                            await btn.click(force=True)
                            await asyncio.sleep(1.5)
                except Exception:
                    pass

                reply_button = await page.query_selector('[data-testid="reply"]')
                if reply_button:
                    await reply_button.click(force=True)
                    await asyncio.sleep(random.uniform(1.5, 3.0))
                    
                    compose_box = await page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=5000)
                    
                    # Fast typing, 90-second timeout ceiling to prevent Playwright crashes
                    await compose_box.type(reply_text, delay=random.randint(10, 40), timeout=90000)
                    
                    print("⏳ Waiting 60 seconds for initial review...")
                    await asyncio.sleep(60)

                    # 🧠 SMART WAIT: Check if user is actively typing!
                    is_active = True
                    while is_active:
                        try:
                            current_text = await compose_box.input_value(timeout=2000)
                            await asyncio.sleep(5) 
                            new_text = await compose_box.input_value(timeout=2000)
                            
                            if current_text != new_text:
                                print("⌨️ User is actively typing! Granting 20 extra seconds...")
                                await asyncio.sleep(20)
                            else:
                                is_active = False 
                        except Exception:
                            is_active = False 
                    
                    try:
                        submit_button = await page.wait_for_selector('[data-testid="tweetButton"]', timeout=3000)
                        await submit_button.click(force=True)
                        post_status = "Auto-submitted by bot"
                    except Exception:
                        post_status = "Manually submitted/edited by user"
                    
                    print("\n" + "="*40)
                    print(f"✅ POST COMPLETE")
                    print(f"💬 Sent Reply: {reply_text}")
                    print(f"🤖 Status: {post_status}")
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
            "scraped_posts": process.stdout.strip(),
            "errors": process.stderr.strip()
        }
        print(json.dumps(result))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run_task()
EOF