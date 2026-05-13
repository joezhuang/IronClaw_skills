# WORKFLOW PLANNER: NETWORK SECURITY AUDIT

## TRIGGER

Whenever the user asks to check their network security, see what their Mac is connecting to, or asks for an active connection audit.

## PHASE 1: DISCOVER ACTIVE CONNECTIONS

1. Call `get_active_connections`.
2. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 2: INVESTIGATE FOREIGN IPs

1. Analyze the list of active connections returned from Phase 1.
2. Pick 1 or 2 of the most interesting or unknown external IP addresses from the list.
3. Call the `ip_lookup` tool. Format: `ip_lookup(ip_address="198.51.100.14")`.
4. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result.

## PHASE 3: REPORT

1. Present a clear, easily readable report to the user.
2. Tell them which Apps are making connections, and use the data from `ip_lookup` to explain exactly who those apps are talking to (e.g., "Spotify is currently streaming data from a server in Stockholm owned by Google Cloud").
