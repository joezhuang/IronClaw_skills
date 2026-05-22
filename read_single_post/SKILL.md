# read_single_post Skill

This skill navigates to a specific X (Twitter) post to extract its full text and perform a deep read of any attached external articles.

### Functionality:

1. **Automation**: Uses Playwright to open the user's persistent Chrome profile and navigate directly to a targeted post URL.
2. **Thread Expansion**: Automatically detects and clicks "Show more" to ensure long-form tweets are fully expanded and captured.
3. **Deep Article Extraction**: Detects external article cards, opens them in a new tab, and extracts up to 3,000 characters of the actual article body, title, and metadata.
4. **Output**: Returns a highly detailed text block containing both the raw post content and the deep article context, providing high-resolution data for LLM analysis without cluttering the context window.
