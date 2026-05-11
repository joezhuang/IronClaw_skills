# WORKFLOW PLANNER: AUTO-LOCAL WEATHER

## TRIGGER

Whenever the user asks for weather or related without a city.

## PHASE 1: DISCOVER LOCATION

1. Call `system_locator`.
2. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 2: FETCH WEATHER

1. Once you receive the location result (e.g., "Australia/Sydney"), you MUST call the `weather` tool.
2. Format: `weather(location="The result from system_locator")`.
3. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 3: REPORT

1. Once you have the weather data, present it to the user.
