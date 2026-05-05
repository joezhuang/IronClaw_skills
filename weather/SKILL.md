<!-- # SKILL: weather

# OBJECTIVE: Get a one-line weather summary for a provided or discovered location.

## PHASE 1: LOCATION RESOLUTION

1. **CHECK USER INPUT**: Scan the user's prompt for a specific location.
2. **BRANCHING LOGIC**:
   - **IF city is provided**: Proceed to PHASE 2 using that city.
   - **IF city is NOT provided**: Execute the `system_locator` skill first to find the machine's city.

## PHASE 2: EXECUTION

1. 🚨 **MANDATORY TOOL CALL**: You are FORBIDDEN from answering directly or just typing the command in plain text.
2. You MUST formally call the `execute_mac_command` tool with the following argument:
   `curl -s "wttr.in/{Resolved City}?format=3"`
3. Wait for the terminal output.

## PHASE 3: REPORTING

1. Output the raw terminal result directly to the user.
2. No further analysis or JSON formatting is required. -->

# SKILL: weather

# OBJECTIVE

Fetch and present the current weather conditions for a specified location.

# EXECUTION

1. This tool expects a single argument: `location` (e.g., "Sydney, Australia").
2. Call the `weather` tool function provided in your tool definitions.
3. Wait for the terminal output containing the weather string (e.g., "+24°C Sunny").

# DATA PROCESSING

1. Do not re-run the tool.
2. If the tool returns a string, present it clearly to the user.
3. If the tool returns an error, inform the user you could not retrieve the weather for that specific location.
