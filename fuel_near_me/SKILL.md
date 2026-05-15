# fuel_near_me Skill

This skill utilizes the **v2 NSW FuelCheck API** to perform a proximity-based search. Unlike the city-search version, this skill uses geographic coordinates to find the absolute cheapest fuel within a specific radius.

### Features

- **Proximity Search**: Finds stations within a 2km to 20km radius.
- **Cheapest First**: Results are automatically sorted by the NSW Government server by price.
- **V2 POST Logic**: Uses the optimized POST endpoint for faster responses and lower data overhead.

### Prerequisites

1. **Python 3**: No external libraries required (uses built-in `urllib`).
2. **API Credentials**:
   - Ensure your `NSW_FUEL_API_KEY` is set in your environment.
   - The skill uses the `Basic` Authorization header for OAuth2 token generation.

### Parameters

- `fuel_type`: (Optional) Choose from E10, U91, P95, P98, Diesel (DL), etc.
- `radius`: (Optional) Search distance in km.

### Technical Note

The reference point is currently hardcoded to **Revesby (-33.951, 151.013)**. To use this in another city, update the `lat` and `lon` variables in `executor.sh`.
