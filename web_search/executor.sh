#!/bin/bash

# Parse the search query from Go arguments
QUERY=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('query', ''))" "$1")

if [ -z "$QUERY" ]; then
    echo "Error: No search query provided."
    exit 1
fi

# Use the TAVILY_API_KEY environment variable directly
python3 -c "
import os
import requests

api_key = os.getenv('TAVILY_API_KEY')
if not api_key:
    print('Error: TAVILY_API_KEY not found in environment.')
    exit(1)

response = requests.post('https://api.tavily.com/search', json={
    'api_key': api_key,
    'query': '$QUERY',
    'search_depth': 'basic',
    'max_results': 3
})

results = response.json().get('results', [])
for r in results:
    print(f\"- {r['title']}: {r['content']} ({r['url']})\")
"