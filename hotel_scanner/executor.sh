#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- THE WIRETAP (Commented out for production) ---
# echo "$1" > "$SCRIPT_DIR/debug_payload.json"
# --------------------------------------------------

VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python"
[ -f "$VENV_PYTHON" ] && EXEC_CMD="$VENV_PYTHON" || EXEC_CMD="python3"

$EXEC_CMD - "$1" << 'EOF'
import sys
import json
import os
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timedelta

try:
    # 1. Load the payload from Go
    raw_payload = sys.argv[1]
    args = json.loads(raw_payload)
    
    # 2. ZERO-TRUST AUTHENTICATION
    # Grabs key from the Go relay's environment injection
    api_key = os.environ.get("RAPIDAPI_KEY")
    
    if not api_key:
        print(json.dumps([{"name": "CRITICAL_ERROR", "total_price": "MISSING_API_KEY", "rating": "0", "feature": "Go Relay Injection Failed"}]))
        sys.exit(0)

    # 3. FLEXIBLE KEY EXTRACTION
    location = args.get("location") or args.get("city")
    checkin = args.get("checkin_date") or args.get("check_in_date") or args.get("check-in")
    checkout = args.get("checkout_date") or args.get("check_out_date") or args.get("check-out")
    nights = args.get("nights")
    adults = args.get("adults", 2)

    # 4. ROBUST VALIDATION
    if not location or not checkin:
        print(json.dumps([{"name": "Error", "total_price": "Missing inputs", "rating": "N/A", "feature": f"Need Loc/Date. Got keys: {list(args.keys())}"}]))
        sys.exit(0)

    # 5. DATE CALCULATOR
    if not checkout and nights:
        in_dt = datetime.strptime(checkin, "%Y-%m-%d")
        out_dt = in_dt + timedelta(days=int(nights))
        checkout = out_dt.strftime("%Y-%m-%d")
        
    if not checkout:
        print(json.dumps([{"name": "Error", "total_price": "No duration", "rating": "N/A", "feature": "Provide checkout or nights"}]))
        sys.exit(0)

    # 6. EXECUTE API CALLS
    headers = {
        'X-RapidAPI-Key': api_key,
        'X-RapidAPI-Host': 'booking-com.p.rapidapi.com'
    }

    # Step A: Resolve Location
    safe_loc = urllib.parse.quote(location)
    loc_url = f"https://booking-com.p.rapidapi.com/v1/hotels/locations?name={safe_loc}&locale=en-gb"
    req1 = urllib.request.Request(loc_url, headers=headers)
    
    with urllib.request.urlopen(req1) as res:
        loc_data = json.loads(res.read().decode())
        if not loc_data:
            print(json.dumps([{"name": "No Match", "total_price": "N/A", "rating": "N/A", "feature": f"Could not find {location}"}]))
            sys.exit(0)
        dest_id = loc_data[0]['dest_id']
        dest_type = loc_data[0]['dest_type']

    # Step B: Search Hotels
    search_url = (f"https://booking-com.p.rapidapi.com/v1/hotels/search?"
                  f"checkin_date={checkin}&checkout_date={checkout}&units=metric&"
                  f"dest_id={dest_id}&dest_type={dest_type}&adults_number={adults}&"
                  f"order_by=popularity&room_number=1&filter_by_currency=USD&locale=en-gb")
                  
    req2 = urllib.request.Request(search_url, headers=headers)
    
    # Initialize the results container
    final_output = []
    
    with urllib.request.urlopen(req2) as res:
        data = json.loads(res.read().decode())
        results = data.get('result', [])
        
        if not results:
            final_output = [{"name": "No availability", "total_price": "N/A", "rating": "N/A", "feature": "Try different dates"}]
        else:
            for h in results[:3]:
                raw_price = h.get('min_total_price', 0)
                raw_feature = h.get('accommodation_type_name', 'Hotel')
                # Force feature to string
                if isinstance(raw_feature, list):
                    raw_feature = raw_feature[0] if raw_feature else "Hotel"
                
                final_output.append({
                    "name": str(h.get("hotel_name", "Unknown")),
                    "total_price": f"${float(raw_price):,.2f} USD" if raw_price else "N/A",
                    "rating": str(h.get("review_score", "N/A")),
                    "feature": str(raw_feature)
                })
                
    # PRINT ONLY ONCE. This ensures the Janitor gets exactly one array.
    print(json.dumps(final_output))

except urllib.error.HTTPError as e:
    print(json.dumps([{"name": "API Error", "total_price": f"HTTP {e.code}", "rating": "N/A", "feature": "Check API limits"}]))
except Exception as e:
    print(json.dumps([{"name": "Python Crash", "total_price": str(e), "rating": "N/A", "feature": "Check log"}]))
EOF