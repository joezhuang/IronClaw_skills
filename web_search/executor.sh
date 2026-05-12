#!/bin/bash

# 1. Parse the search query from the JSON argument provided by Go
QUERY=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('query', ''))" "$1")

if [ -z "$QUERY" ]; then
    echo "Error: No search query provided."
    exit 1
fi

# 2. Use a Here-Doc with native urllib to avoid ModuleNotFoundError
python3 - "$QUERY" << 'EOF'
import os
import sys
import json
import urllib.request

query = sys.argv[1]
api_key = os.getenv('TAVILY_API_KEY')

if not api_key:
    print('Error: TAVILY_API_KEY not found in environment.')
    sys.exit(1)

# Prepare the request payload
payload = json.dumps({
    'api_key': api_key,
    'query': query,
    'search_depth': 'basic',
    'max_results': 3
}).encode('utf-8')

# Configure the request
req = urllib.request.Request(
    'https://api.tavily.com/search',
    data=payload,
    headers={'Content-Type': 'application/json'},
    method='POST'
)

try:
    with urllib.request.urlopen(req) as response:
        res_data = json.loads(response.read().decode('utf-8'))
        results = res_data.get('results', [])

        if not results:
            print("RESULT: No web search results found for this query.")
        else:
            for r in results:
                title = r.get('title', 'No Title')
                content = r.get('content', 'No Content')
                url = r.get('url', '#')
                print(f"- {title}: {content} ({url})")
except Exception as e:
    print(f"Error during search execution: {e}")
    sys.exit(1)
EOF