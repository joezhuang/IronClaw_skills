# WORKFLOW PLANNER: MASTER TRIP ORCHESTRATOR

## TRIGGER

Whenever the user asks to plan a trip, book a vacation, or find flights and hotels for a destination.

## PHASE 1: GATHER ORIGIN & DATES (CRITICAL)

1. **Origin Check:** If the user did not specify where they are flying FROM, call `system_locator` to find their current location.
   - Format: `system_locator()`
   - 🛑 STOP. Wait for the `[OBSERVATION]` from Go Relay.
2. **Date Check:** You MUST have valid, future check-in and check-out dates. Use the current system time to verify the dates are in the future.
   - _If dates are missing or in the past: DO NOT call the scanners. Ask the user for valid future dates and STOP._

## PHASE 2: FLIGHT SEARCH (DUFFEL)

1. Once you have the Origin, Destination, and Dates, you MUST call the `flight_scanner` tool.
2. Format: `flight_scanner(origin="...", destination="...", departure_date="...", return_date="...")`
3. 🛑 STOP. Do not generate conversational text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 3: HOTEL SEARCH (AMADEUS)

1. Once the flight data is received, you MUST call the `hotel_scanner` tool using the exact same destination and dates.
2. Format: `hotel_scanner(location="...", checkin_date="...", checkout_date="...")`
3. 🛑 STOP. Do not generate conversational text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 4: SYNTHESIS & REPORT

1. You now have both Flight and Hotel data. Present a unified, beautifully formatted markdown itinerary to the user.
2. Include the total estimated prices.
3. Ask if they would like to proceed with booking these specific options.
