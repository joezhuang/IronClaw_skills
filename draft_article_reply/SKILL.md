# draft_article_reply Skill

This skill acts as a dedicated text-generation router, bypassing local LLM parameter constraints by delegating creative writing to a Cloud API to draft highly intelligent, analytical replies and internal intelligence briefs.

### Functionality:

1. **Input Reception:** Takes the clean, processed article text extracted from the previous reading step (e.g., `read_direct_article`), or can take raw text directly as input.
2. **Environment Agnostic:** Automatically reads `.env` variables to route payloads to Google Gemini or OpenAI-compatible endpoints (including OpenRouter or local vLLM instances).
3. **Persona Enforcement:** Injects a strict system prompt to categorize the news and ensure the output matches one of the 9 specific analytical personas (e.g., Macro Strategist, The Value Observer) designed to provide deep strategic insights and economic realities rather than social media hype.
4. **Visual Debugging:** Prints the generated analytical draft directly to `stderr` in the terminal for real-time review before passing the payload back to the IronClaw orchestrator.
