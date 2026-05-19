#!/bin/bash
if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import urllib.request
import urllib.error
from datetime import datetime, timedelta

def run():
    try:
        # Parse JSON input from argument
        args = json.loads(sys.argv[1])
        days = args.get("days", 7)
        
        # Calculate the date N days ago
        target_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
        
        # Construct GitHub Search API URL
        # Query: created:>{date}, sorted by stars, descending, top 3
        url = f"https://api.github.com/search/repositories?q=created:>{target_date}&sort=stars&order=desc&per_page=3"
        
        # Create request with custom User-Agent to prevent 403 Forbidden
        req = urllib.request.Request(url, headers={'User-Agent': 'IronClaw-Agent'})
        
        with urllib.request.urlopen(req) as response:
            raw_data = response.read().decode('utf-8')
            data = json.loads(raw_data)
            items = data.get('items', [])
            
            formatted_results = []
            for item in items:
                formatted_results.append({
                    "name": item.get("name"),
                    "owner": item.get("owner", {}).get("login"),
                    "html_url": item.get("html_url"),
                    "stargazers_count": item.get("stargazers_count")
                })
            
            # Output the clean JSON array
            print(json.dumps(formatted_results))
            
    except urllib.error.HTTPError as e:
        print(json.dumps({"error": f"HTTP Error {e.code}: {e.reason}"}))
    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run()
EOF