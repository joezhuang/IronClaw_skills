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
import urllib.parse
import urllib.error
from datetime import datetime, date

def get_condition(code):
    if code is None: return "Unknown"
    # WMO Weather interpretation codes (WW)
    codes = {
        0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
        45: "Fog", 48: "Depositing rime fog",
        51: "Light drizzle", 53: "Moderate drizzle", 55: "Dense drizzle",
        61: "Slight rain", 63: "Moderate rain", 65: "Heavy rain",
        71: "Slight snow fall", 73: "Moderate snow fall", 75: "Heavy snow fall",
        77: "Snow grains", 80: "Slight rain showers", 81: "Moderate rain showers",
        82: "Violent rain showers", 85: "Slight snow showers", 86: "Heavy snow showers",
        95: "Thunderstorm", 96: "Thunderstorm with slight hail", 99: "Thunderstorm with heavy hail"
    }
    return codes.get(int(code), f"Code {code}")

try:
    # Parse raw JSON input
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No parameters provided."}))
        sys.exit(0)
        
    args = json.loads(sys.argv[1])
    location = args.get("location")
    date_input = args.get("date")
    
    if not location or not date_input:
        print(json.dumps({"error": "Missing required parameters: 'location' and 'date'."}))
        sys.exit(0)

    # Validate date format (YYYY-MM-DD)
    try:
        target_dt = datetime.strptime(date_input, "%Y-%m-%d").date()
    except ValueError:
        print(json.dumps({"error": "Invalid date format. Please use YYYY-MM-DD."}))
        sys.exit(0)

    headers = {"User-Agent": "IronClawSkill/1.0 (macOS; WeatherTool)"}
    
    # 1. Geocoding: Get Lat/Lon for the location
    geo_url = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(location)}&count=1&language=en&format=json"
    req_geo = urllib.request.Request(geo_url, headers=headers)
    with urllib.request.urlopen(req_geo) as resp:
        geo_data = json.loads(resp.read().decode())
    
    if not geo_data.get("results"):
        print(json.dumps({"error": f"Location '{location}' could not be resolved."}))
        sys.exit(0)
        
    res0 = geo_data["results"][0]
    lat, lon = res0["latitude"], res0["longitude"]
    full_loc_name = f"{res0.get('name', location)}, {res0.get('country', '')}"

    # 2. Determine API Endpoint (Forecast vs Archive)
    today = date.today()
    delta_days = (target_dt - today).days
    
    # Open-Meteo Forecast API handles ~16 days ahead and ~90 days past.
    # Archive API handles everything older.
    if delta_days > 16:
        print(json.dumps({"error": f"Date {date_input} is too far in the future. Forecasts are available up to 16 days ahead."}))
        sys.exit(0)
    
    if delta_days < -1:
        base_url = "https://archive-api.open-meteo.com/v1/archive"
    else:
        base_url = "https://api.open-meteo.com/v1/forecast"

    # 3. Fetch Weather Data
    weather_url = (f"{base_url}?latitude={lat}&longitude={lon}"
                   f"&daily=temperature_2m_max,temperature_2m_min,weather_code"
                   f"&start_date={date_input}&end_date={date_input}&timezone=auto")
    
    req_weather = urllib.request.Request(weather_url, headers=headers)
    with urllib.request.urlopen(req_weather) as resp:
        weather_data = json.loads(resp.read().decode())

    daily = weather_data.get("daily", {})
    if not daily or not daily.get("temperature_2m_max"):
        print(json.dumps({"error": f"No weather data found for {date_input} at {full_loc_name}."}))
    else:
        # Successfully retrieved data
        output = {
            "location": full_loc_name,
            "date": date_input,
            "max_temp": daily["temperature_2m_max"][0],
            "min_temp": daily["temperature_2m_min"][0],
            "temp_unit": weather_data.get("daily_units", {}).get("temperature_2m_max", "°C"),
            "condition": get_condition(daily.get("weather_code", [None])[0])
        }
        print(json.dumps(output))

except urllib.error.HTTPError as e:
    print(json.dumps({"error": f"API request failed: {e.reason}. Check if date/location is valid."}))
except Exception as e:
    print(json.dumps({"error": f"Unexpected error: {str(e)}"}))
EOF
