# WORKFLOW PLANNER: NETWORK SECURITY AUDIT

## TRIGGER

Whenever the user asks to check their network security, see what their Mac is connecting to, or asks for an active connection audit.

## PHASE 1: DISCOVER ACTIVE CONNECTIONS

1. Call `get_active_connections`.
2. 🛑 STOP. Do not generate text. Wait for the `[OBSERVATION]` result from the Go Relay.

## PHASE 2: REPORT

1. Analyze the text returned from Phase 1 (which will contain the App Name, IP, City, and Organization).
2. Present a clear, easily readable report to the user.
3. Highlight any suspicious or foreign connections, explaining exactly who the apps on their Mac are talking to.
