# SKILL: web_search

## TRIGGER

Keywords: search, look up, online, internet, news, latest, URL, who is, what is
Condition: Use whenever the user asks for real-time information, recent events, or explicit factual data not in your immediate knowledge.

# OBJECTIVE

Retrieve live data and URLs from the internet using the Tavily Search API.

# EXECUTION

1. Formulate a concise, highly targeted search `query` based on the user's request.
2. Call the `web_search` tool.
3. Wait for the terminal output containing the formatted snippets and URLs.

# DATA PROCESSING

1. **TRUTH ANCHORING**: Do not hallucinate information. Base your final answer strictly on the snippets returned.
2. **CITE SOURCES**: Whenever possible, include the `(URL)` provided in the search results so the user can read more.
3. If no results are found, inform the user and optionally ask if they want you to try a different search phrase.
