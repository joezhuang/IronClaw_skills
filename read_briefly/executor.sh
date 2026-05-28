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
from playwright.async_api import async_playwright

async def run_read(target_url):
    result = {"url": target_url, "cluster_context": ""}
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
            print(f"▶️ Ingesting Briefly Cluster: {target_url}", file=sys.stderr)

            await page.goto(target_url, wait_until="domcontentloaded")
            await asyncio.sleep(random.uniform(2.5, 4.5))
            
            # Extract the raw cluster context while cleaning out standard header/footer junk
            cluster_data = await page.evaluate('''() => {
                let title = document.title;
                
                // Clear away interface clutter to ensure high signal-to-noise ratio
                let junkSelectors = ['nav', 'footer', 'aside', 'header', '.sidebar', '.menu', '.cookie-banner', '#cookie-consent', '.newsletter', '.ad-container'];
                document.querySelectorAll(junkSelectors.join(',')).forEach(el => el.remove());
                
                // Target core body area or fallback gracefully to page text
                let container = document.querySelector('article') || 
                                document.querySelector('main') || 
                                document.querySelector('#root') || 
                                document.body; 
                
                let rawText = container.innerText || "";
                return `CLUSTER TITLE: ${title}\\n\\nFACTS & SUMMARY:\\n${rawText}`.substring(0, 6000);
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
        cluster_text = output.get('cluster_context', '').strip()
        
        if not cluster_text or len(cluster_text) < 50:
            print(json.dumps({"status": "error", "errors": "Empty payload extracted from cluster page."}))
        else:
            # Format perfectly wraps the data with the exact trigger strings your planner expects
            final_text = f"TARGET_URL: {target_url}\n\n--- DEEP ARTICLE READ ---\n{cluster_text}"
            print(json.dumps({"status": "success", "data": final_text.strip(), "errors": ""}))
EOF