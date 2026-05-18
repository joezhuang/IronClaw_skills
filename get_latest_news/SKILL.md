# get_latest_news Skill

This skill fetches the most recent news headlines and URLs for a given topic using the Google News RSS feed. It is designed to be lightweight and does not require external API keys for news searching.

### Requirements
- Python 3.x
- No external Python libraries are required (uses standard `urllib` and `xml.etree`).

### Functionality
1. Accepts a `topic` string.
2. Performs a search against Google News RSS.
3. Parses the XML response for the top 10 headlines.
4. Returns a JSON object containing the headline text and direct link for each item.

### Debugging
If you encounter a network error, ensure your macOS device has active internet access. This script uses standard system Python if a virtual environment is not detected.