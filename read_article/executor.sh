#!/bin/bash

# IronClaw injects parameters either as arguments or environment variables.
URL="${target_url:-$1}"

if [ -z "$URL" ]; then
    echo '{"error": "Missing target_url parameter"}'
    exit 1
fi

if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - "$URL" <<'EOF'
import asyncio
import sys
import os
import json
import random
import time
import urllib.request
import urllib.parse
from playwright.async_api import async_playwright

async def run_read(input_url):
    result = {"url": input_url, "cluster_context": "", "image_url": "", "source_url": input_url}
    try:
        # 🛠️ THE INNER LOGIC: Intercept and evaluate the URL type internally
        target_scrape_url = input_url
        
        if "briefly-news-stories" in input_url and "/story/" in input_url:
            raw_source = input_url.split("/story/")[1]
            if "storyIdx=" in raw_source:
                raw_source = raw_source.split("?storyIdx=")[0].split("&storyIdx=")[0]
            decoded_source = urllib.parse.unquote(raw_source)
            if decoded_source.startswith("http"):
                target_scrape_url = decoded_source
                result["source_url"] = decoded_source
                print(f"🚀 Briefly link detected. Extracted canonical pivot -> {target_scrape_url}", file=sys.stderr)

        chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")
        async with async_playwright() as p:
            context = await p.chromium.launch_persistent_context(
                user_data_dir=chrome_data_dir,
                headless=False,
                args=[
                    "--profile-directory=Default", 
                    "--disable-blink-features=AutomationControlled",
                    "--disable-infobars",
                    "--no-sandbox",
                    "--disable-dev-shm-usage"
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

            print(f"📡 Playwright navigating to: {target_scrape_url}", file=sys.stderr)
            await page.goto(target_scrape_url, wait_until="domcontentloaded", timeout=15000)
            await asyncio.sleep(random.uniform(2.5, 4.0)) # Stable rendering window
            
            # Extract Semantic Clean Text Layout
            cluster_data = await page.evaluate('''() => {
                let title = document.title;
                let junkSelectors = ['nav', 'footer', 'aside', 'header', '.sidebar', '.menu', '.cookie-banner', '#cookie-consent', '.newsletter', '.ad-container'];
                document.querySelectorAll(junkSelectors.join(',')).forEach(el => el.remove());
                
                let container = document.querySelector('article') || 
                                document.querySelector('main') || 
                                document.querySelector('#root') || 
                                document.body; 
                
                let rawText = container.innerText || "";
                return `ARTICLE TITLE: ${title}\\n\\nCONTENT:\\n${rawText}`.substring(0, 6000);
            }''')
            result["cluster_context"] = cluster_data
            
            await context.close()
            return result
            
    except Exception as e:
        result["error"] = str(e)
        return result

if __name__ == '__main__':
    raw_target = sys.argv[1] if len(sys.argv) > 1 else ""
    target_url = raw_target
    
    try:
        if raw_target.strip().startswith('{'):
            parsed_args = json.loads(raw_target)
            target_url = parsed_args.get("target_url", raw_target)
    except Exception:
        pass

    if not target_url:
        print(json.dumps({"status": "error", "errors": "Missing target_url parameter."}))
        sys.exit(1)
        
    output = asyncio.run(run_read(target_url))

    if "error" in output and output["error"]:
        print(json.dumps({"status": "error", "errors": output["error"]}))
    else:
        cluster_text = output.get('cluster_context', '').strip()
        
        if not cluster_text or len(cluster_text) < 50:
            print(json.dumps({"status": "error", "errors": "Empty payload extracted from target site."}))
        else:
            final_link = output.get("source_url", target_url)
            
            # Formats the unified payload signature for State 2 (Keeping IMAGE_PATH: NONE to protect parsing state)
            final_text = f"TARGET_URL: {final_link}\nIMAGE_PATH: NONE\n\n--- DEEP ARTICLE READ ---\n{cluster_text}"
            print(json.dumps({"status": "success", "data": final_text.strip(), "errors": ""}, ensure_ascii=False))
EOF