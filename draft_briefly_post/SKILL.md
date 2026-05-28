# draft_briefly_post Skill

This skill acts as a dedicated text-generation router, bypassing local LLM parameter constraints by delegating creative writing to a Cloud API to draft standalone broadcast posts for Briefly News.

### Functionality:

1. **Input Reception:** Takes the clean, processed cluster facts extracted from the Briefly app scraping step.
2. **Environment Agnostic:** Automatically reads `.env` variables to route payloads to Google Gemini or OpenAI-compatible endpoints (including OpenRouter or local vLLM instances).
3. **Persona Enforcement:** Injects a strict system prompt to categorize the news and ensure the output matches one of the 9 specific thought-provoking personas (e.g., Macro Strategist, The Value Observer) designed to hook readers into clicking the cluster link.
4. **Visual Debugging:** Prints the generated draft directly to `stderr` in the terminal for real-time editorial review before passing the payload back to the IronClaw orchestrator.
