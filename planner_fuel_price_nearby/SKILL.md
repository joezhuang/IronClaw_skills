# WORKFLOW PLANNER: AUTO-FUEL PROXIMITY

## TRIGGER

Whenever the user asks for fuel prices, "petrol near me," or "cheap fuel in [suburb]" using geographic coordinates.

## PHASE 1: GEOGRAPHIC RESOLUTION

1.  **Extract Suburb**: Identify the suburb name from the user's prompt. If no suburb is mentioned, default to "Revesby".
2.  **Call Tool**: Call `geographic_translator`.
3.  **Format**: `geographic_translator(suburb="[Extracted Suburb]")`.
4.  🛑 **STOP**. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 2: RADIUS-BASED FUEL FETCH

1.  **Parse Coordinates**: Once you receive the location result (Latitude, Longitude, and Radius) from the translator.
2.  **Call Tool**: Call the `fuel_near_me` tool using the resolved data.
3.  **Format**: `fuel_near_me(lat=[LAT], lon=[LON], radius=[RADIUS], fuel_type="all")`.
    - _Note: If the user specifically mentioned a fuel type (e.g., "Premium 98" or "Diesel"), override the default "E10" with the appropriate code (P98, DL, etc.)._
4.  🛑 **STOP**. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 3: INTELLIGENT REPORTING

1.  **Analyze & Present**: Once you have the live price data from the API:
    - Identify and list the **Top 3 cheapest stations** found.
    - Clearly state the **Brand**, **Price (in cents)**, and **Full Address**.
    - Confirm the area searched (e.g., "Found within a 5km radius of Bankstown").
