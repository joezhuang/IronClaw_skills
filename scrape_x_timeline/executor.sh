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
import random

def run_task():
    try:
        skill_root = os.getcwd() 
        script_path = os.path.abspath(os.path.join(skill_root, "scrape_timeline.py"))
        
        script_content = r"""import asyncio
import os
import sys
import random
from playwright.async_api import async_playwright
# from playwright_stealth import stealth_async # 🌟 Add this import

def get_feed_urls():
    news_lists = os.getenv('X_NEWS_LISTS')
    feed_urls = os.getenv('X_FEED_URLS')
    
    target_env = news_lists if news_lists else feed_urls
    if target_env:
        clean_str = target_env.strip().strip('"').strip("'")
        return [url.strip() for url in clean_str.split(',') if url.strip()]
    return ["https://x.com/home"]

def get_memory_log():
    # Load previously engaged URLs into a set for fast lookup
    log_path = os.path.expanduser("~/ironclaw_engaged_urls.log")
    if not os.path.exists(log_path):
        return set()
    with open(log_path, "r", encoding="utf-8") as f:
        return set(line.strip() for line in f if line.strip())

async def run_scrape():
    try:
        chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")
        engaged_urls = get_memory_log()
        
        async with async_playwright() as p:
            context = await p.chromium.launch_persistent_context(
                user_data_dir=chrome_data_dir,
                headless=False,
                args=["--profile-directory=Default", "--disable-blink-features=AutomationControlled"],
                ignore_default_args=["--enable-automation"]
            )
            
            page = await context.new_page()
            # await stealth_async(page) # 🌟 Apply stealth BEFORE navigating!

            # 🌟 THE FIX: Use triple single quotes (''') here!
            await page.add_init_script('''
                // 1. Hide the WebDriver flag
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                // 2. Mock the Chrome runtime object
                window.navigator.chrome = { runtime: {} };
                // 3. Mock languages and plugins
                Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en']});
                Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
            ''')

            feed_urls = get_feed_urls()
            chosen_feed = random.choice(feed_urls)
            print(f"🎯 Selected feed: {chosen_feed}")
            
            await page.goto(chosen_feed, wait_until="domcontentloaded")
            # await asyncio.sleep(4)
            # Instead of sleep(4), wait anywhere between 3.2 and 6.8 seconds
            await asyncio.sleep(random.uniform(3.2, 6.8))
            
            for _ in range(3):
                await page.mouse.wheel(0, 900)
                # await asyncio.sleep(1.5)
                # For scrolling or dismissing popups: wait between 1.1 and 2.4 seconds
                await asyncio.sleep(random.uniform(1.1, 2.4))
            
            articles = await page.query_selector_all("article")
            if not articles:
                print("No posts found. Ensure login.")
                await context.close()
                return

            valid_posts_found = 0
            
            # Iterate through articles until we find 5 UNENGAGED posts
            for article in articles:
                if valid_posts_found >= 5:
                    break
                    
                text = await article.inner_text()
                url = "Unknown URL"
                
                try:
                    time_el = await article.query_selector("time")
                    if time_el:
                        parent = await time_el.evaluate_handle("el => el.parentElement")
                        href = await parent.get_attribute("href")
                        if href:
                            url = f"https://x.com{href}" if href.startswith("/") else href
                except Exception: 
                    pass

                # 🛑 THE NEW LINK FILTER: If there is no valid URL, skip the post entirely
                if url == "Unknown URL" or not url:
                    continue

                # 🛑 THE MEMORY FILTER: Skip if we've already engaged
                if url in engaged_urls:
                    continue

                # 🛑 THE RADIOACTIVE SOURCE FILTER: Skip violent/tragic news entirely
                lower_text = text.lower()
                radioactive_words = ["dead", "die", "dies", "fatal", "killed", "gunfire", "shooting", "explosion", "casualty", "attack", "strike", "missile", "war", "murder"]
                if any(word in lower_text for word in radioactive_words):
                    continue

                clean_text = text.replace('\n', ' ')
                short_text = clean_text[:250] + "..." if len(clean_text) > 250 else clean_text

                print(f"--- Post {valid_posts_found+1} ---\nURL: {url}\n{short_text}\n{'-'*30}")
                valid_posts_found += 1
            
            if valid_posts_found == 0:
                print("Timeline exhausted. All recent posts have already been engaged with.")
            else:
                # 🛑 THE RECENCY ANCHOR: Force the AI into Phase 2
                print("\n" + "="*40)
                print("🛑 SYSTEM COMMAND: PHASE 1 COMPLETE.")
                print("You are now in PHASE 2. You are strictly FORBIDDEN from generating conversational text.")
                print("You MUST immediately execute the `read_single_post` tool. Use the `reasoning` parameter to evaluate the posts, then pass the `target_url`.")
                print("="*40)
                
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