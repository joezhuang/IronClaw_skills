<!-- # WORKFLOW PLANNER: AUTO-LOCAL WEATHER

## TRIGGER

Activate this workflow whenever the user asks for the "weather" or "forecast" but DOES NOT explicitly name a city.

## PHASE 1: DISCOVER LOCATION (Delegation)

1. 🚨 STRICT RULE: You are missing the location variable. DO NOT ask the user for it. You must find it autonomously.
2. Look up at your system instructions and find the section labeled exactly: `--- REFERENCE SKILL: system_locator ---`
3. Execute the tool call required by that section to find the host machine's location.
4. Wait for the terminal output. Do NOT reply to the user yet.

## PHASE 2: FETCH WEATHER (Delegation)

1. Now that you have the city from Phase 1, look for the section labeled exactly: `--- REFERENCE SKILL: weather ---`
2. Pass the city you just found into the tool call required by that section.
3. Present the final result to the user. -->

<!-- # WORKFLOW PLANNER: AUTO-LOCAL WEATHER

## TRIGGER

Activate this workflow whenever the user asks for the "weather" or "forecast" but DOES NOT explicitly name a city.

## PHASE 1: DISCOVER LOCATION (CRITICAL)

1. 🚨 STRICT RULE: You are missing the location variable. You are FORBIDDEN from asking the user for it.
2. You MUST use your function-calling capability to execute the `system_locator` tool immediately.
3. 🛑 DO NOT generate any conversational text, apologies, or explanations. ONLY output the tool call for `system_locator`.

## PHASE 2: FETCH WEATHER (CRITICAL)

1. Once `system_locator` returns the city, you MUST execute the `weather` tool using that exact city name.
2. 🛑 DO NOT generate any conversational text. ONLY output the tool call for `weather`.
3. Only after the `weather` tool returns the data may you generate a final conversational text response for the user. -->

# WORKFLOW PLANNER: AUTO-LOCAL WEATHER

## TRIGGER

Whenever the user asks for weather without a city.

## PHASE 1: DISCOVER LOCATION

1. Call `system_locator`.
2. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 2: FETCH WEATHER

1. Once you receive the location result (e.g., "Australia/Sydney"), you MUST call the `weather` tool.
2. Format: `weather(location="The result from system_locator")`.
3. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 3: REPORT

1. Once you have the weather data, present it to the user.
