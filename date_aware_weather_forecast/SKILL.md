# date_aware_weather_forecast Skill

A robust weather skill that provides specific weather data for exact dates, moving beyond relative terms like 'today' or 'tomorrow'. It uses geocoding to resolve locations and intelligently switches between forecast and archive APIs to provide data for dates in the past or the near future.

### Usage
- **location**: Any city or place name (e.g., "Paris", "Tokyo", "New York").
- **date**: A specific date in `YYYY-MM-DD` format.

### Features
- **Date-Specific**: Unlike basic tools, this skill accepts any valid date.
- **Wide Range**: Supports forecasts up to 16 days in the future and historical data for dates in the past.
- **Detailed Output**: Returns Max/Min temperatures and a descriptive weather condition (e.g., "Partly cloudy").

### Limitations
- Forecasts for dates more than 16 days in the future are not supported by standard meteorological models.
- Historical data is subject to station availability.