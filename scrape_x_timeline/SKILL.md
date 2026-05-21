# scrape_x_timeline Skill

This skill extracts posts from the user's X feed.

### Functionality:

1. **Automation**: Uses Playwright to open the user's persistent Chrome profile.
2. **Data Extraction**: Extracts the text and URLs of the first 10 posts on the timeline.
3. **X-Ray Vision**: Briefly visits external links attached to posts to extract summary descriptions and detect paywalls.
4. **Output**: Returns a raw text log of the scraped posts for LLM analysis.
