#!/bin/bash

# 1. Automatically load and export variables from a .env file (if it exists)
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 2. Setup Python Environment
if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

# 3. Execute the Python logic
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

def get_feed_urls():
    news_lists = os.getenv('X_NEWS_LISTS')
    feed_urls = os.getenv('X_FEED_URLS')
    
    target_env = news_lists if news_lists else feed_urls
    if target_env:
        clean_str = target_env.strip().strip('"').strip("'")
        return [url.strip() for url in clean_str.split(',') if url.strip()]
    return ["https://x.com/home"]

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
            
            feed_urls = get_feed_urls()
            chosen_feed = random.choice(feed_urls)
            print(f"🎯 Selected feed: {chosen_feed}")
            
            await page.goto(chosen_feed, wait_until="domcontentloaded")
            await asyncio.sleep(4)
            
            for _ in range(3):
                await page.mouse.wheel(0, 900)
                await asyncio.sleep(1.5)
            
            articles = await page.query_selector_all("article")
            if not articles:
                print("No posts found. Ensure login.")
                await context.close()
                return

            # Capped at 8 posts. Fast scout only.
            for i, article in enumerate(articles[:5]):
                text = await article.inner_text()
                
                # BULLETPROOF URL EXTRACTOR: Target the timestamp link directly
                url = "Unknown URL"
                try:
                    time_el = await article.query_selector("time")
                    if time_el:
                        # The parent <a> tag of the timestamp is ALWAYS the exact status permalink
                        parent = await time_el.evaluate_handle("el => el.parentElement")
                        href = await parent.get_attribute("href")
                        if href:
                            url = f"https://x.com{href}" if href.startswith("/") else href
                except Exception: 
                    pass

                # Aggressive text truncation (max 250 chars) to prevent context bloat
                clean_text = text.replace('\n', ' ')
                short_text = clean_text[:250] + "..." if len(clean_text) > 250 else clean_text

                # Notice there is no external X-Ray link scraping here anymore!
                print(f"--- Post {i+1} ---\nURL: {url}\n{short_text}\n{'-'*30}")
            
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