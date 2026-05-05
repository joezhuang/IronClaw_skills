#!/bin/bash

# The '-' tells Python to read from the EOF block below, and "$1" safely passes your JSON payload!
python3 - "$1" << 'EOF'
import sys, json, os, urllib.request

try:
    args = json.loads(sys.argv[1])
    coin = args.get("coin_id", "solana").lower()
    currency = args.get("vs_currency", "aud").lower()
    api_key = os.environ.get("COINGECKO_API_KEY")

    # --- Fetch Market Data ---
    url = f"https://api.coingecko.com/api/v3/coins/markets?vs_currency={currency}&ids={coin}&order=market_cap_desc&sparkline=false&price_change_percentage=24h"
    
    headers = {"Accept": "application/json"}
    if api_key:
        headers["x-cg-demo-api-key"] = api_key

    req = urllib.request.Request(url, headers=headers)
    
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())

    if not data:
        print(f"No data found for {coin}. Please check the symbol.")
    else:
        res = data[0]
        formatted = "--- TYPE: CRYPTO MARKET DATA ---\n"
        formatted += f"Coin: {res.get('name')} ({res.get('symbol').upper()})\n"
        formatted += f"Current Price: {res.get('current_price')} {currency.upper()}\n"
        formatted += f"24h Change: {res.get('price_change_percentage_24h')}%\n"
        formatted += f"24h High: {res.get('high_24h')} | 24h Low: {res.get('low_24h')}\n"
        formatted += f"Market Cap: {res.get('market_cap')}\n"
        formatted += f"Total Volume: {res.get('total_volume')}\n"
        print(formatted)

except Exception as e:
    print(f"Execution Error: {e}")
EOF