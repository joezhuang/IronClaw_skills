# advanced_weather_forecast Skill

This skill provides advanced weather data via `wttr.in`.

### Usage
- **Current Weather**: Provide only the `location`. The tool returns single-point values for temperature, humidity, and wind.
- **Forecasted Range**: Provide a `location` and a `period` (e.g., "tomorrow", "this weekend"). The tool will aggregate data to return a range (min/max) for temperature and humidity.

### Logic
1. If `period` is null/empty: Fetches `current_condition` and returns exact metrics.
2. If `period` is provided: Parses the `weather` forecast array to calculate minimum and maximum values across the predicted timeframe.