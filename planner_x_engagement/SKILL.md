# WORKFLOW EXECUTOR: X ENGAGEMENT CYCLE

## TRIGGER

Whenever the user asks to "run the Twitter bot," "engage on X," or "check my timeline," OR whenever the automated cron scheduler fires the background webhook.

## PHASE 1: GATHER DATA

1. You MUST call the `scrape_x_timeline` tool.
2. 🛑 STOP. Do not generate any conversational text. Do not summarize. Wait for the system to return the scraped `[OBSERVATION]`.

## PHASE 2: REASON & EXECUTE

1. ONLY AFTER receiving the `[OBSERVATION]` from Phase 1, review the scraped posts.
2. Filter the list for high-value topics (Tech, Finance, Business).
3. Randomly select ONE candidate from the filtered list to ensure variety.
4. Draft a creative, witty, and specific reply. Speak directly to the author using "you." Challenge their premise or offer a provocative counter-point. End with an insightful question.
5. You MUST call the `post_x_reply` tool using `target_url` and `reply_text`.
6. 🛑 STOP. Wait for the system to return the execution `[OBSERVATION]`.

## PHASE 3: REPORT

1. ONLY AFTER receiving the success confirmation from Phase 2, output a brief summary to the user detailing the URL you engaged with and the text you posted.

<!-- # planner_x_engagement Skill

This skill acts as the autonomous "brain" and orchestrator for the X (Twitter) engagement pipeline. It does not execute browser automation itself; instead, it coordinates two specialized, atomic sub-skills to ensure high-reliability execution.

## TRIGGER

Whenever the user asks to "run the Twitter bot," "engage on X," or "check my timeline," OR whenever the automated cron scheduler fires the background engagement webhook.

### Architectural Overview (The "Atomic" Pattern)

This planner solves the "LLM Cognitive Load" problem by separating data gathering from data execution.

Instead of struggling with a single, complex monolithic tool, the planner executes a strict, two-step pipeline:

1. **Step 1: Gather (No-Input)**
   - The planner triggers `scrape_x_timeline`.
   - It waits for the pure text/JSON array of recent posts, complete with paywall detection and external link context.

2. **Step 2: Reason & Draft (LLM Native)**
   - The planner analyzes the scraped data in its own context window.
   - It filters for high-value topics (Tech, Finance, Business).
   - It randomly selects a candidate to ensure variety (preventing "First-Post Bias").
   - It drafts a witty, creative, direct reply ("you/your") ending with an insightful question.

3. **Step 3: Execute (Strict-Input)**
   - The planner triggers `post_x_reply`.
   - It maps exactly two strict parameters: `target_url` (from Step 1) and `reply_text` (from Step 2).

### Prerequisites:

- The `scrape_x_timeline` skill must be installed and active in IronClaw.
- The `post_x_reply` skill must be installed and active in IronClaw.
- The cron job or trigger prompt must explicitly command the LLM to execute both tool calls in sequence. -->
