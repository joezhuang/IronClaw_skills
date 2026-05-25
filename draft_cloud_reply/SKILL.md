# draft_cloud_reply Skill

This skill acts as a dedicated text-generation router, bypassing local LLM parameter constraints by delegating creative writing to a Cloud API.

### Functionality:

1. **Input Reception:** Takes the clean, processed article facts extracted from previous scraping/summarization steps.
2. **Environment Agnostic:** Automatically reads `.env` variables to route payloads to Google Gemini or OpenAI-compatible endpoints (including Groq or local vLLM instances).
3. **Persona Enforcement:** Injects a strict system prompt to ensure output matches the cynical, punchy "Briefly News" brand voice.
4. **Visual Debugging:** Prints the generated draft directly to `stderr` in the terminal for real-time editorial review before passing the payload back to the IronClaw orchestrator.
