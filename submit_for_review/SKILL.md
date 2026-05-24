# submit_for_review Skill

This skill acts as an automated, hardcoded gatekeeper for drafted X (Twitter) replies. It removes the burden of self-evaluation from the LLM.

### Functionality:

1. **Extraction**: Takes the `draft_text` from the LLM's JSON payload.
2. **Radioactive Ban**: Physically blocks any text containing words related to violence, death, or mass casualties.
3. **Hook Enforcement**: Verifies the last character of the draft is a valid hook (punctuation or specific emojis).
4. **Logging**: Saves all successfully approved drafts to a local text file for auditing.
