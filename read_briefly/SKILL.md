# read_briefly Skill

This skill navigates directly to a specific news cluster within the Briefly News application to extract its aggregated text, summaries, and core facts.

### Functionality:

1. **Automation**: Uses Playwright to open the persistent user profile and navigate directly to the targeted Briefly cluster URL.
2. **Main Layout Extraction**: Strips away generic layout clutter (navigation bars, footers, sidebars) and captures the primary dashboard content containing your news summaries, "Why it Matters," and "What's Next" sections.
3. **Structured Payload Delivery**: Outputs the extracted text with the exact delimiters needed to trigger the next phase of the IronClaw publishing state machine.
