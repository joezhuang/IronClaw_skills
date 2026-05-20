import asyncio
import os
import sys
try:
    from playwright.async_api import async_playwright
except ImportError:
    print('Error: "playwright" library not found. Please run "pip install playwright && playwright install chromium"', file=sys.stderr)
    sys.exit(1)

async def scrape_x():
    try:
        async with async_playwright() as p:
            # Launch persistent context using local Chrome Default profile
            context = await p.chromium.launch_persistent_context(
                user_data_dir='/Users/joe/Library/Application Support/Google/Chrome',
                headless=False,
                args=["--profile-directory=Default"]
            )
            
            page = await context.new_page()
            await page.goto("https://x.com/home")
            
            # Wait 5 seconds for the timeline to load
            await asyncio.sleep(5)
            
            # Scrape first 5 visible 'article' elements
            articles = await page.query_selector_all("article")
            
            if not articles:
                print("No posts found. Ensure you are logged into X in the Chrome profile.")
            
            for i, article in enumerate(articles[:5]):
                text = await article.inner_text()
                print(f"--- Post {i+1} ---
{text}
{'-'*30}")
            
            await context.close()
    except Exception as e:
        print(f"Playwright Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(scrape_x())
