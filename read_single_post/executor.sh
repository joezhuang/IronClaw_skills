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
from playwright.async_api import async_playwright

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
            await page.goto(target_url, wait_until="domcontentloaded")
            await asyncio.sleep(4)
            
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
                    await asyncio.sleep(1)
            except Exception: pass
            
            result["post_text"] = await main_article.inner_text()
            
            # Look for an external article card
            try:
                card_link = await main_article.query_selector('div[data-testid="card.wrapper"] a')
                if card_link:
                    ext_url = await card_link.get_attribute("href")
                    if ext_url and "x.com" not in ext_url and "twitter.com" not in ext_url:
                        print(f"🔗 Found external link, reading...", file=sys.stderr)
                        new_tab = await context.new_page()
                        try:
                            await new_tab.goto(ext_url, timeout=15000, wait_until="domcontentloaded")
                            await asyncio.sleep(3)
                            
                            article_data = await new_tab.evaluate('''() => {
                                let title = document.title;
                                let meta = document.querySelector('meta[name="description"]');
                                let desc = meta ? meta.content : "";
                                
                                // Grab a generous chunk of the actual article body
                                let pTexts = Array.from(document.querySelectorAll('p'))
                                    .map(p => p.innerText.trim())
                                    .filter(text => text.length > 50)
                                    .join('\\n\\n');
                                    
                                return `TITLE: ${title}\\nDESC: ${desc}\\n\\nBODY:\\n${pTexts}`.substring(0, 3000);
                            }''')
                            result["article_context"] = article_data
                        except Exception as e:
                            result["article_context"] = f"Failed to load external article: {str(e)}"
                        finally:
                            await new_tab.close()
            except Exception: pass
            
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
        final_text = f"--- RAW POST CONTENT ---\n{output['post_text']}\n\n--- DEEP ARTICLE READ ---\n{output['article_context']}"
        print(json.dumps({"status": "success", "data": final_text.strip(), "errors": ""}))
EOF