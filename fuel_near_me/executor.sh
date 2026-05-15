#!/bin/bash

# fuel_near_me Skill - NSW FuelCheck v2 API (Flattened JSON)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then EXEC_CMD="$VENV_PYTHON"; else EXEC_CMD="python3"; fi

"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import os
import urllib.request
import urllib.error
import uuid
from datetime import datetime, timezone

def get_fuel_near_me():
    try:
        input_data = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
        
        # Round and cast to string to satisfy strict .NET binding
        lat_str = str(round(float(input_data.get("lat", -33.951)), 4))
        lon_str = str(round(float(input_data.get("lon", 151.013)), 4))
        radius_str = str(input_data.get("radius", "5"))
        sort_ascending_str = "true" 
        
        requested_fuel = input_data.get("fuel_type", "all")
        ALL_FUELS = ["E10", "U91", "P95", "P98", "DL", "PDL", "LPG"]
        fuels_to_fetch = [requested_fuel] if requested_fuel in ALL_FUELS else ALL_FUELS
        
        api_key = os.environ.get("NSW_FUEL_API_KEY", "xxxxxxxx")
        basic_auth = "Basic d3pPbFplVVRHUjZJbkZiOG9KWmhETm9xY3hvbHZrYk46NUdORUhLUmltR3ljNmZiOQ=="

        token_url = "https://api.onegov.nsw.gov.au/oauth/client_credential/accesstoken?grant_type=client_credentials"
        token_headers = {"Authorization": basic_auth, "User-Agent": "IronClaw/1.0"}
        token_req = urllib.request.Request(token_url, headers=token_headers)
        
        with urllib.request.urlopen(token_req) as resp:
            access_token = json.loads(resp.read().decode()).get("access_token")

        v2_url = "https://api.onegov.nsw.gov.au/FuelPriceCheck/v2/fuel/prices/nearby"
        aggregated_prices = []
        last_error = None

        for f_type in fuels_to_fetch:
            # FIX: Flatten the payload. No "location" dictionary.
            post_data = {
                "fueltype": f_type,
                "brand": [],
                "latitude": lat_str,
                "longitude": lon_str,
                "radius": radius_str,
                "sortby": "price",
                "sortascending": sort_ascending_str
            }
            
            body = json.dumps(post_data).encode('utf-8')
            headers = {
                "Authorization": f"Bearer {access_token}",
                "apikey": api_key,
                "transactionid": str(uuid.uuid4()),
                "requesttimestamp": datetime.now(timezone.utc).strftime("%d/%m/%Y %I:%M:%S %p"),
                "Content-Type": "application/json; charset=utf-8",
                "User-Agent": "IronClaw/1.0"
            }

            try:
                req = urllib.request.Request(v2_url, data=body, headers=headers, method='POST')
                with urllib.request.urlopen(req, timeout=15) as resp:
                    data = json.loads(resp.read().decode())
                    if "prices" in data:
                        aggregated_prices.extend(data["prices"])
            except urllib.error.HTTPError as e:
                last_error = f"{f_type}: {e.read().decode()}"
                continue
            except Exception as e:
                last_error = str(e)
                continue

        if not aggregated_prices:
            if last_error:
                print(json.dumps({"error": f"API Rejected Request: {last_error}"}))
            else:
                print(json.dumps({"message": "No data returned from API."}))
        else:
            # Sort by price locally
            aggregated_prices.sort(key=lambda x: float(x.get('price', 999)))
            print(json.dumps({
                "suburb": input_data.get("suburb", "Target Area"),
                "results": aggregated_prices[:15]
            }))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    get_fuel_near_me()
EOF