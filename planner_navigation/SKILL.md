# WORKFLOW PLANNER: SYSTEM NAVIGATION

## TRIGGER

Activate this workflow whenever the user requests to "Open", "Launch", or "Click" a system application or Dock icon (e.g., "Open Finder", "Launch Chrome").

## PHASE 1: RESOLVE (CRITICAL)

1. 🚨 STRICT RULE: You are forbidden from guessing coordinates for system applications.
2. You MUST use the `system_navigator` tool.
3. Tool Call: `system_navigator(element_name="[Name of App]")`.
4. 🛑 STOP. Do not generate conversational text, apologies, or explanations. ONLY output the tool call. Wait for the `[OBSERVATION]` (the X,Y coordinates) from the Go Relay.

## PHASE 2: EXECUTE (CRITICAL)

1. Once the `system_navigator` returns the coordinates (e.g., "COORDS: 36, 2200"), you MUST immediately use the `gui_automator` tool.
2. Tool Call: `gui_automator(action="click", x=[X_FROM_PHASE_1], y=[Y_FROM_PHASE_1])`.
3. 🛑 STOP. Do not generate conversational text. ONLY output the tool call. Wait for the `[OBSERVATION]` (the confirmation from the Go Relay).

## PHASE 3: REPORT

1. Only after the `gui_automator` returns success may you generate a final conversational text response for the user (e.g., "I have successfully opened [App Name] for you.").
