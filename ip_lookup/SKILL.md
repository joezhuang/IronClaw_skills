# SKILL: ip_lookup

# OBJECTIVE

Fetch the geographic location and organization details for a specific public IP address.

# EXECUTION

1. This tool expects a single argument: `ip_address` (e.g., "8.8.8.8").
2. Call the `ip_lookup` tool function provided in your tool definitions.
3. Wait for the terminal output containing the JSON data about the IP.

# DATA PROCESSING

1. Do not re-run the tool if it fails.
2. Parse the returned JSON data and explain who owns the IP address to the user in plain English.
