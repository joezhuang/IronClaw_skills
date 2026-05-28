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

# async def run_read(target_url):
#     result = {"url": target_url, "cluster_context": "", "image_url": ""}
#     try:
#         chrome_data_dir = os.path.expanduser("~/ironclaw_chrome_profile")
#         async with async_playwright() as p:
#             context = await p.chromium.launch_persistent_context(
#                 user_data_dir=chrome_data_dir,
#                 headless=False,
#                 args=[
#                     "--profile-directory=Default", 
#                     "--disable-blink-features=AutomationControlled",
#                     "--disable-infobars",
#                     "--no-sandbox",
#                     "--disable-dev-shm-usage"
#                 ],
#                 ignore_default_args=["--enable-automation"]
#             )
            
#             page = await context.new_page()
            
#             # Anti-detection context mapping
#             await page.add_init_script('''
#                 Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
#                 window.navigator.chrome = { runtime: {}, app: {}, csid: {}, loadTimes: function() {} };
#                 Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3] });
#             ''')

#             print(f"▶️ Ingesting Briefly Cluster: {target_url}", file=sys.stderr)
#             await page.goto(target_url, wait_until="domcontentloaded")
#             await asyncio.sleep(random.uniform(2.5, 4.5))
            
#             # 1. Extract the cluster text context
#             cluster_data = await page.evaluate('''() => {
#                 let title = document.title;
#                 let junkSelectors = ['nav', 'footer', 'aside', 'header', '.sidebar', '.menu', '.cookie-banner', '#cookie-consent', '.newsletter', '.ad-container'];
#                 document.querySelectorAll(junkSelectors.join(',')).forEach(el => el.remove());
                
#                 let container = document.querySelector('article') || 
#                                 document.querySelector('main') || 
#                                 document.querySelector('#root') || 
#                                 document.body; 
                
#                 let rawText = container.innerText || "";
#                 return `CLUSTER TITLE: ${title}\\n\\nFACTS & SUMMARY:\\n${rawText}`.substring(0, 6000);
#             }''')
#             result["cluster_context"] = cluster_data
            
#             # 2. Extract the hidden destination link and load the source website directly inside Playwright
#             source_url = ""
#             if "/story/" in target_url:
#                 raw_source = target_url.split("/story/")[1]
#                 if "storyIdx=" in raw_source:
#                     raw_source = raw_source.split("?storyIdx=")[0].split("&storyIdx=")[0]
#                 source_url = urllib.parse.unquote(raw_source)

#             if source_url.startswith("http"):
#                 print(f"🚀 Playwright pivot: Opening source website -> {source_url}", file=sys.stderr)
#                 try:
#                     # Navigate the same window straight to the source link
#                     await page.goto(source_url, wait_until="domcontentloaded", timeout=12000)
#                     await asyncio.sleep(1.5)
                    
#                     # Pull image URL from actual rendered page
#                     image_url = await page.evaluate('''() => {
#                         let ogImage = document.querySelector('meta[property="og:image"]');
#                         return ogImage ? ogImage.content : "";
#                     }''')
#                     result["image_url"] = image_url
#                 except Exception as src_err:
#                     print(f"⚠️ Playwright direct image pivot failed: {src_err}", file=sys.stderr)
            
#             await context.close()
#             return result
            
#     except Exception as e:
#         result["error"] = str(e)
#         return result

async def run_read(target_url):
    result = {"url": target_url, "cluster_context": "", "image_url": ""}
    try:
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

            # 1. IMMEDIATELY find the source URL from the Briefly link
            source_url = ""
            if "/story/" in target_url:
                raw_source = target_url.split("/story/")[1]
                if "storyIdx=" in raw_source:
                    raw_source = raw_source.split("?storyIdx=")[0].split("&storyIdx=")[0]
                source_url = urllib.parse.unquote(raw_source)

            # ADD THIS LINE:
            result["source_url"] = source_url

            # 2. Pivot straight to the source website (BBC, TechCrunch, etc.)
            if source_url.startswith("http"):
                print(f"🚀 Playwright pivot: Opening source website -> {source_url}", file=sys.stderr)
                await page.goto(source_url, wait_until="domcontentloaded", timeout=15000)
                await asyncio.sleep(2.5) # Give the article time to render
                
                # 3. Extract the image from the actual article
                image_url = await page.evaluate('''() => {
                    let ogImage = document.querySelector('meta[property="og:image"]');
                    return ogImage ? ogImage.content : "";
                }''')
                result["image_url"] = image_url

                # 4. Extract the clean text context from the actual article
                cluster_data = await page.evaluate('''() => {
                    let title = document.title;
                    let junkSelectors = ['nav', 'footer', 'aside', 'header', '.sidebar', '.menu', '.cookie-banner', '#cookie-consent', '.newsletter', '.ad-container'];
                    document.querySelectorAll(junkSelectors.join(',')).forEach(el => el.remove());
                    
                    let container = document.querySelector('article') || 
                                    document.querySelector('main') || 
                                    document.querySelector('#root') || 
                                    document.body; 
                    
                    let rawText = container.innerText || "";
                    return `CLUSTER TITLE: ${title}\\n\\nFACTS & SUMMARY:\\n${rawText}`.substring(0, 6000);
                }''')
                result["cluster_context"] = cluster_data

            else:
                result["error"] = "Could not decode source URL from Briefly link."
            
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

    # Download the image via urllib using a solid browser user-agent string
    image_path = ""
    image_url = output.get("image_url", "")
    
    if image_url:
        try:
            image_path = f"/tmp/briefly_img_{int(time.time())}.jpg"
            req = urllib.request.Request(image_url, headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'})
            with urllib.request.urlopen(req, timeout=10) as response:
                with open(image_path, 'wb') as f:
                    f.write(response.read())
            print(f"🖼️ Successfully downloaded source article image to: {image_path}", file=sys.stderr)
        except Exception as e:
            print(f"⚠️ Failed to download image from CDN: {e}", file=sys.stderr)
            image_path = "" 

    # if "error" in output and output["error"]:
    #     print(json.dumps({"status": "error", "errors": output["error"]}))
    # else:
    #     cluster_text = output.get('cluster_context', '').strip()
        
    #     if not cluster_text or len(cluster_text) < 50:
    #         print(json.dumps({"status": "error", "errors": "Empty payload extracted from cluster page."}))
    #     else:
    #         final_text = ""
    #         if image_path and os.path.exists(image_path):
    #             final_text += f"IMAGE_PATH: {image_path}\n"
                
    #         final_text += f"TARGET_URL: {target_url}\n\n--- DEEP ARTICLE READ ---\n{cluster_text}"
    #         print(json.dumps({"status": "success", "data": final_text.strip(), "errors": ""}))

    if "error" in output and output["error"]:
        print(json.dumps({"status": "error", "errors": output["error"]}))
    else:
        cluster_text = output.get('cluster_context', '').strip()
        
        if not cluster_text or len(cluster_text) < 50:
            print(json.dumps({"status": "error", "errors": "Empty payload extracted from cluster page."}))
        else:
            # 1. Handle the Image
            safe_image = image_path if image_path and os.path.exists(image_path) else "NONE"
            
            # 2. Extract the true source URL (Fallback to the briefly link if it fails)
            final_link = output.get("source_url", "")
            if not final_link:
                final_link = target_url
            
            # 3. Assemble the final text using the true canonical article link
            final_text = f"TARGET_URL: {final_link}\nIMAGE_PATH: {safe_image}\n\n--- DEEP ARTICLE READ ---\n{cluster_text}"
            
            print(json.dumps({"status": "success", "data": final_text.strip(), "errors": ""}))
EOF