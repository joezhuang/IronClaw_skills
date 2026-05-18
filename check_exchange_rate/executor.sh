#!/bin/bash

# BASH SHEBANG
#!/bin/bash

# PYTHON VENV PIPELINE
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then EXEC_CMD="$VENV_PYTHON"; else EXEC_CMD="python3"; fi

# HEREDOC SYNTAX
$EXEC_CMD - "$1" <<'EOF'
import sys
import json
import urllib.request
import urllib.error

def run():
    try:
        # JSON INPUT PARSING
        if len(sys.argv) < 2:
            print(json.dumps({"error": "No input provided"}))
            return

        args = json.loads(sys.argv[1])
        base = args.get("base_currency", "").strip().upper()
        target = args.get("target_currency", "").strip().upper()

        if not base or not target:
            print(json.dumps({"error": "Both base_currency and target_currency are required"}))
            return

        # Edge case: same currency
        if base == target:
            print(json.dumps({"exchange_rate": f"1 {base} is worth 1.0 {target}"}))
            return

        # Identifying a reliable, free, and public API (Frankfurter)
        # Construct API call
        url = f"https://api.frankfurter.app/latest?from={base}&to={target}"
        
        headers = {"User-Agent": "Mozilla/5.0"}
        req = urllib.request.Request(url, headers=headers)
        
        # Perform request
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode())
            
            # Parse JSON response
            rates = data.get("rates", {})
            rate = rates.get(target)
            
            if rate is None:
                print(json.dumps({"error": f"Currency {target} not found for base {base}"}))
                return
            
            # CLEAN JSON OUT: Output a JSON object with a single key
            result_str = f"1 {base} is worth {rate} {target}"
            print(json.dumps({"exchange_rate": result_str}))

    except urllib.error.HTTPError as e:
        # API Error handling (e.g., 404 for invalid currency codes)
        print(json.dumps({"error": f"API Error: {e.code}. Likely an unsupported currency code (e.g. Frankfurter supports major fiat like USD, EUR, GBP)."}))
    except urllib.error.URLError as e:
        print(json.dumps({"error": f"Network error: {str(e.reason)}"}))
    except Exception as e:
        # Catch all Python errors and return them as JSON
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run()
EOF
