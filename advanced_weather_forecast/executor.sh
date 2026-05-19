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

def get_weather():
    try:
        # Parse inputs
        args = json.loads(sys.argv[1])
        location = args.get("location", "")
        period = args.get("period", None)

        if not location:
            return {"error": "Location is required"}

        # Encode location for URL
        safe_location = urllib.parse.quote(location)
        url = f"https://wttr.in/{safe_location}?format=j1"
        
        headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}
        req = urllib.request.Request(url, headers=headers)

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode())

        # Logic based on presence of period
        if not period:
            # Return current weather (Single values)
            current = data['current_condition'][0]
            return {
                "location": location,
                "type": "current",
                "temperature_c": current['temp_C'],
                "humidity": current['humidity'],
                "condition": current['weatherDesc'][0]['value'],
                "wind_speed_kmph": current['windspeedKmph']
            }
        else:
            # Return range of values from forecast
            forecasts = data.get('weather', [])
            if not forecasts:
                return {"error": "No forecast data available for this location"}
            
            # Extract ranges across the forecasted period (usually 3 days from wttr.in)
            temps_min = [float(day['mintempC']) for day in forecasts]
            temps_max = [float(day['maxtempC']) for day in forecasts]
            
            # For humidity and others, wttr.in provides hourly data inside the day
            all_humidity = []
            for day in forecasts:
                for hour in day['hourly']:
                    all_humidity.append(float(hour['humidity']))

            return {
                "location": location,
                "type": "forecast_range",
                "requested_period": period,
                "temperature_range_c": {
                    "min": min(temps_min),
                    "max": max(temps_max)
                },
                "humidity_range": {
                    "min": min(all_humidity),
                    "max": max(all_humidity)
                },
                "conditions_summary": [day['hourly'][4]['weatherDesc'][0]['value'] for day in forecasts] # Sample mid-day conditions
            }

    except urllib.error.URLError as e:
        return {"error": f"Network error fetching weather: {str(e)}"}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    result = get_weather()
    print(json.dumps(result))
EOF