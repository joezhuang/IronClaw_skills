#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then EXEC_CMD="$VENV_PYTHON"; else EXEC_CMD="python3"; fi

# Ensure the positional argument $1 is passed into the Python script
$EXEC_CMD - "$1" <<'EOF'
import sys
import json
import urllib.request
import urllib.parse

def main():
    try:
        # Parse the JSON string sent from the Go Relay
        if len(sys.argv) < 2:
            print(json.dumps({"error": "No input provided"}))
            return

        input_data = json.loads(sys.argv[1]) if sys.argv[1] else {}
        
        # Look for 'suburb' OR 'suburb_name' to be safe
        suburb = input_data.get("suburb") or input_data.get("suburb_name")

        if not suburb:
            # Return what we DID receive so we can debug in the logs
            print(json.dumps({
                "error": "Missing parameter: suburb", 
                "received_keys": list(input_data.keys())
            }))
            return

        # Nominatim Search (OpenStreetMap)
        # We limit search to Australia to avoid getting 'Sydney, Canada' or similar
        query = f"{suburb}, NSW, Australia"
        encoded_query = urllib.parse.quote(query)
        url = f"https://nominatim.openstreetmap.org/search?q={encoded_query}&format=json&limit=1"
        
        headers = {"User-Agent": "IronClawGeographicTranslator/1.0"}
        
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode())

        if data:
            # We cast lat/lon to float to ensure fuel_near_me handles them correctly
            # We hardcode the radius to 5 as per your default
            result = {
                "suburb": suburb,
                "lat": float(data[0].get("lat")),
                "lon": float(data[0].get("lon")),
                "radius": 5,
                "display_name": data[0].get("display_name")
            }
            print(json.dumps(result))
        else:
            print(json.dumps({"error": f"No geographic data found for '{suburb}'"}))

    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    main()
EOF