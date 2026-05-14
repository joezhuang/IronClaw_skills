# FORGE PLANNER (Self-Evolution Protocol)

## Objective

When a user asks for a task you cannot perform, you must architect a solution using native macOS capabilities.

## Phase 1: Architecture

- Determine if the task can be done via `osascript` (AppleScript), `curl` (APIs), or `cliclick` (GUI).
- Design a minimal `executor.sh` that follows the IronClaw standard (accepts $1 as JSON, outputs Markdown).

## Phase 2: Generation

- Call `create_new_skill`.
- **STRICT Syntax for Qwen 2.5 Coder**: Ensure the bash script uses local environment variables for any sensitive keys.

## Phase 3: Validation

- Once the skill is created, immediately notify the user: "I have expanded my core logic to include [Skill Name]. Would you like me to test it now?"
