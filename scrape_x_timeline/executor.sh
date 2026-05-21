#!/bin/bash

if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - <<'EOF'
import sys
import json
import os
import subprocess

def run_task():
    try:
        skill_root = os.getcwd() 
        script_path = os.path.abspath(os.path.join(skill_root, "scrape_timeline.py"))
        
        script_content = r"""import asyncio
import os
import sys
import random
from playwright.async_api import async_playwright

async def run_scrape():
    try:
        chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")
        async with async_playwright() as p:
            context = await p.chromium.launch_persistent_context(
                user_data_dir=chrome_data_dir,
                headless=False,
                args=["--profile-directory=Default", "--disable-blink-features=AutomationControlled"],
                ignore_default_args=["--enable-automation"]
            )
            
            page = await context.new_page()
            
            feed_urls = ["https://x.com/home", "https://x.com/i/lists/2056906333920837714"]
            chosen_feed = random.choice(feed_urls)
            print(f"🎯 Selected feed: {chosen_feed}")
            
            await page.goto(chosen_feed)
            await asyncio.sleep(6)
            
            for _ in range(4):
                await page.mouse.wheel(0, 900)
                await asyncio.sleep(2.0)
            
            articles = await page.query_selector_all("article")
            if not articles:
                print("No posts found. Ensure login.")
                await context.close()
                return

            for i, article in enumerate(articles[:10]):
                try:
                    btn = await article.query_selector('[data-testid="tweet-text-show-more-link"]')
                    if btn:
                        await btn.click(force=True)
                        await asyncio.sleep(0.5)
                except Exception: pass
                    
                text = await article.inner_text()
                url = "Unknown URL"
                links = await article.query_selector_all("a[href*='/status/']")
                if links: url = f"https://x.com{await links[0].get_attribute('href')}"

                article_context = ""
                try:
                    card_link = await article.query_selector('div[data-testid="card.wrapper"] a')
                    if card_link:
                        ext_url = await card_link.get_attribute("href")
                        if ext_url and "x.com" not in ext_url and "twitter.com" not in ext_url:
                            new_tab = await context.new_page()
                            try:
                                await new_tab.goto(ext_url, timeout=8000)
                                summary = await new_tab.evaluate('''() => {
                                    let meta = document.querySelector('meta[name="description"]');
                                    let content = meta ? meta.content : document.title;
                                    if(content.toLowerCase().includes("subscribe") || content.toLowerCase().includes("paywall")) return "PAYWALL DETECTED";
                                    return content;
                                }''')
                                article_context = f"\n\n[BOT X-RAY: {summary}]"
                            except Exception: pass
                            finally: await new_tab.close()
                except Exception: pass

                print(f"--- Post {i+1} ---\nURL: {url}\n{text}{article_context}\n{'-'*30}")
            
            await context.close()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(run_scrape())
"""
        with open(script_path, "w") as f:
            f.write(script_content)

        process = subprocess.run([sys.executable, script_path], capture_output=True, text=True)
        print(json.dumps({"status": "success", "data": process.stdout.strip(), "errors": process.stderr.strip()}))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run_task()
EOF