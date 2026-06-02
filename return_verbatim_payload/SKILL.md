#### 🔵 STATE 3: EXECUTION (RETURN TO USER)

**🛑 STATE TRIGGER:** The payload contains the marker "--- FAST TRACK DRAFT ---" anywhere in the text.

1. **ACTION:** The draft is complete. You are strictly FORBIDDEN from attempting to format, summarize, or talk about this data.
2. **TOOL EXECUTION:** You MUST immediately call the `return_verbatim_payload` tool.
   - Pass the ENTIRE raw payload text block into the `raw_payload` parameter exactly as it is.
3. **TERMINATION:** Once the tool returns, output the string `[DRAFT EXPORT COMPLETE]`. Halt generation entirely.
