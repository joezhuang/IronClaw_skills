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

def run():
    try:
        # Rule 2: Parse JSON input from sys.argv[1]
        if len(sys.argv) < 2:
            print(json.dumps({"error": "No input provided"}))
            return
            
        args = json.loads(sys.argv[1])
        coin_input = args.get("coin_input", "").strip()

        if not coin_input:
            print(json.dumps({"error": "coin_input parameter is required"}))
            return

        # Rule 2: Normalize the input
        # Convert to Title Case per instructions
        normalized_title = coin_input.title()

        # Mapping logic for common tickers/names to CoinGecko IDs
        # We check the Title Case version and map to the lowercase ID used by the API
        mapping = {
            "Btc": "bitcoin",
            "Bitcoin": "bitcoin",
            "Eth": "ethereum",
            "Ethereum": "ethereum",
            "Sol": "solana",
            "Solana": "solana",
            "Xrp": "ripple",
            "Ada": "cardano",
            "Cardano": "cardano",
            "Doge": "dogecoin",
            "Dogecoin": "dogecoin",
            "Dot": "polkadot",
            "Polkadot": "polkadot",
            "Matic": "matic-network",
            "Ltc": "litecoin",
            "Litecoin": "litecoin",
            "Link": "chainlink",
            "Chainlink": "chainlink",
            "Trx": "tron",
            "Tron": "tron",
            "Shib": "shiba-inu",
            "Avax": "avalanche-2",
            "Avalanche": "avalanche-2",
            "Xlm": "stellar",
            "Stellar": "stellar",
            "Atom": "cosmos",
            "Cosmos": "cosmos"
        }

        # Resolve ID: If in map, use it; otherwise, fallback to lowercase input string
        coin_id = mapping.get(normalized_title, coin_input.lower())

        # Query CoinGecko Public API (Free tier)
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin_id}&vs_currencies=usd"
        
        # Rule 7: Use urllib.request with a User-Agent
        headers = {
            'User-Agent': 'IronClawSkill/1.0 (Macintosh; Intel Mac OS X 10_15_7)'
        }
        
        req = urllib.request.Request(url, headers=headers)
        
        with urllib.request.urlopen(req, timeout=15) as response:
            res_payload = json.loads(response.read().decode())

        # Rule 6: Clean JSON out
        if coin_id in res_payload and "usd" in res_payload[coin_id]:
            result = {
                "input": coin_input,
                "normalized_name": normalized_title,
                "coingecko_id": coin_id,
                "price_usd": res_payload[coin_id]["usd"]
            }
            print(json.dumps(result))
        else:
            print(json.dumps({"error": f"Could not find price data for '{coin_input}'. Try using the full name (e.g. 'Bitcoin')."}))

    except urllib.error.URLError as e:
        print(json.dumps({"error": f"Network error connecting to API: {str(e)}"}))
    except Exception as e:
        # Rule 6: Catch all errors and return as JSON
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    run()
EOF