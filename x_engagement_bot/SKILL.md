# x_engagement_bot Skill

This skill creates and executes a Python automation script named `engage.py` on your macOS system. 

### Functionality:
1. **Script Creation**: Generates `~/engage.py` containing Playwright logic.
2. **Chrome Integration**: Uses your local Chrome User Data directory (`~/Library/Application Support/Google/Chrome`) and the `Default` profile.
3. **Timeline Scraping**: Navigates to `https://x.com/home`, waits 5 seconds, and extracts text from the first 5 visible posts (`article` elements).
4. **Non-Headless**: Runs in a visible browser window so you can see the results.

### Prerequisites:
- **Playwright**: Must be installed in your Python environment (`pip install playwright`).
- **Chromium Driver**: Must be installed via Playwright (`playwright install chromium`).
- **Chrome Profile**: You should be logged into X (Twitter) on your Default Chrome profile for the timeline to load correctly.