#!/bin/bash

# IronClaw injects parameters either as arguments or environment variables.
# We map the target_url parameter here.
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
from playwright.async_api import async_playwright
# from playwright_stealth import stealth_async # 🌟 Add this import

async def run_read(target_url):
    result = {"url": target_url, "post_text": "", "article_context": "No external link found."}
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
            print(f"▶️ Navigating to: {target_url}", file=sys.stderr)
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

            await page.goto(target_url, wait_until="domcontentloaded")
            # await asyncio.sleep(4)
            await asyncio.sleep(random.uniform(3.2, 6.8))
            
            # The main post is always the first <article> on a status page
            articles = await page.query_selector_all("article")
            if not articles:
                result["error"] = "No post found. Ensure the URL is correct and logged in."
                await context.close()
                return result
            
            main_article = articles[0]
            
            # Expand "Show more" for long-form tweets
            try:
                btn = await main_article.query_selector('[data-testid="tweet-text-show-more-link"]')
                if btn:
                    await btn.click(force=True)
                    # await asyncio.sleep(1)
                    await asyncio.sleep(random.uniform(1, 1.5))

            except Exception: pass
            
            result["post_text"] = await main_article.inner_text()

            # 🛑 THE DUAL-LINK HUNTER: Look for cards first, then fallback to inline text links
            try:
                ext_url = None
                
                # Attempt 1: The Twitter Card (Rich Preview)
                card_link = await main_article.query_selector('div[data-testid="card.wrapper"] a')
                if card_link:
                    ext_url = await card_link.get_attribute("href")
                
                # Attempt 2: The Inline Text Link (Fallback)
                if not ext_url:
                    inline_links = await main_article.query_selector_all('div[data-testid="tweetText"] a')
                    for link in inline_links:
                        href = await link.get_attribute("href")
                        # X wraps external links in t.co. Ignore hashtags/mentions.
                        if href and ("t.co" in href or ("http" in href and "x.com" not in href and "twitter.com" not in href)):
                            ext_url = href
                            break # Grab the first valid external link and stop

                # If we successfully found a link using either method, go read it
                if ext_url and "x.com" not in ext_url and "twitter.com" not in ext_url:
                    print(f"🔗 Found external link: {ext_url}, reading...", file=sys.stderr)
                    new_tab = await context.new_page()
                    try:
                        await new_tab.goto(ext_url, timeout=15000, wait_until="domcontentloaded")
                        # await asyncio.sleep(4)
                        await asyncio.sleep(random.uniform(3.2, 6.8))
                        
                        article_data = await new_tab.evaluate('''() => {
                            let title = document.title;
                            let meta = document.querySelector('meta[name="description"]');
                            let desc = meta ? meta.content : "";
                            
                            let junkSelectors = ['nav', 'footer', 'aside', 'header', '.sidebar', '.menu', '.cookie-banner', '#cookie-consent', '.newsletter', '.ad-container', '[role="navigation"]'];
                            document.querySelectorAll(junkSelectors.join(',')).forEach(el => el.remove());
                            
                            let container = document.querySelector('article') || 
                                            document.querySelector('main') || 
                                            document.querySelector('.story-body') || 
                                            document.querySelector('.article-body') || 
                                            document.body; 
                            
                            let rawText = container.innerText || "";
                            return `TITLE: ${title}\\nDESC: ${desc}\\n\\nBODY:\\n${rawText}`.substring(0, 6000);
                        }''')
                        result["article_context"] = article_data
                    except Exception as e:
                        result["article_context"] = f"Failed to load external article: {str(e)}"
                    finally:
                        await new_tab.close()
            except Exception as e: 
                pass # Fail silently and rely on the default "No external link found."
            
            
            await context.close()
            return result
    except Exception as e:
        result["error"] = str(e)
        return result

if __name__ == '__main__':
    raw_target = sys.argv[1] if len(sys.argv) > 1 else ""
    target_url = raw_target
    
    # Safely parse JSON if IronClaw passed a raw JSON object
    try:
        if raw_target.strip().startswith('{'):
            import json
            parsed_args = json.loads(raw_target)
            target_url = parsed_args.get("target_url", raw_target)
    except Exception:
        pass

    if not target_url:
        import json
        print(json.dumps({"status": "error", "errors": "Missing target_url parameter."}))
        sys.exit(1)
        
    output = asyncio.run(run_read(target_url))
    
    import json
    if "error" in output and output["error"]:
        print(json.dumps({"status": "error", "errors": output["error"]}))
    else:
        article_text = output.get('article_context', '')
        
        # 🛑 THE BAILOUT INTERCEPTOR
        # If no link was found, output ONLY the bailout string.
        # This completely hides the "DEEP ARTICLE READ" trigger from the LLM.
        if "No external link found" in article_text:
            final_text = "🛑 BAILOUT: NO EXTERNAL LINK FOUND"
        else:
            # 🛑 MEMORY PATCH: Inject the URL at the very top of the payload
            final_text = f"TARGET_URL: {target_url}\n--- RAW POST CONTENT ---\n{output['post_text']}\n\n--- DEEP ARTICLE READ ---\n{article_text}"
            
        print(json.dumps({"status": "success", "data": final_text.strip(), "errors": ""}))
EOF