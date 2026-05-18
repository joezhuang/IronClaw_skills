#!/bin/bash

# Ensure we have the script directory for venv resolution
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then EXEC_CMD="$VENV_PYTHON"; else EXEC_CMD="python3"; fi

# Execute the Python logic via Heredoc
"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import os

def get_latest_news():
    try:
        # Rule 2: Parse JSON input from sys.argv[1]
        if len(sys.argv) < 2:
            print(json.dumps({"error": "No input provided"}))
            return
        
        args = json.loads(sys.argv[1])
        topic = args.get('topic', '')

        if not topic:
            print(json.dumps({"error": "Parameter 'topic' is required"}))
            return

        # Use Google News RSS for high reliability and structured data without external search providers
        encoded_topic = urllib.parse.quote(topic)
        rss_url = f"https://news.google.com/rss/search?q={encoded_topic}&hl=en-US&gl=US&ceid=US:en"

        # Headers to mimic a browser request
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        req = urllib.request.Request(rss_url, headers=headers)

        with urllib.request.urlopen(req, timeout=10) as response:
            content = response.read().decode('utf-8')

        # Parse XML
        root = ET.fromstring(content)
        results = []

        # Iterate through items (headlines)
        for item in root.findall('.//item')[:10]: # Limit to top 10 results
            title = item.find('title').text if item.find('title') is not None else "No Title"
            link = item.find('link').text if item.find('link') is not None else "No URL"
            results.append({
                "headline": title,
                "url": link
            })

        # Rule 6: Output only a single JSON object
        print(json.dumps({"topic": topic, "results": results}))

    except Exception as e:
        # Rule 6: Catch errors and return as JSON
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    get_latest_news()
EOF