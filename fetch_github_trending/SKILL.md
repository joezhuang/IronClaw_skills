# fetch_github_trending Skill

This skill queries the GitHub REST API to find the most popular repositories created recently.

### Functionality:
1. Calculates the date 7 days ago (or a custom number of days).
2. Sends a request to the GitHub Search API (`/search/repositories`) using `urllib`.
3. Applies a custom `User-Agent: IronClaw-Agent` to avoid rate-limiting/forbidden errors.
4. Returns a curated JSON array containing:
   - `name`: Repository name.
   - `owner`: Repository owner username.
   - `html_url`: Link to the repository.
   - `stargazers_count`: Number of stars.

### Error Handling:
- Catches API errors (403, 404, etc.) and returns a structured JSON error object.
- Handles parsing errors gracefully.