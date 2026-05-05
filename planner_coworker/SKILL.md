# WORKFLOW PLANNER: FILE COWORKER

## COMPLETION MANDATE (STRICT)

Do not report success until the final Excel or PowerPoint file is generated and saved to the disk.

## TRIGGER

Whenever the user asks to summarize, analyze, or convert files into a report, spreadsheet, or presentation.

## PHASE 1: DATA INGESTION

1. Determine the target files.
2. Call `execute_mac_command(command="cat [filename]")` to read the contents into your memory.
3. 🛑 STOP and wait for the `[OBSERVATION]` (the file contents).

## PHASE 2: SYNTHESIS & SUMMARIZATION

1. Analyze the raw data from Phase 1.
2. Extract the key themes, metrics, or requested summaries.
3. Format your synthesized findings into a clean JSON structure (e.g., arrays for Excel rows, or title/bullet-point pairs for PowerPoint slides).

## PHASE 3: GENERATION

1. Pass your synthesized JSON data to the file generator.
2. Call `file_coworker(action="generate_excel" or "generate_ppt", data_json="[Your JSON from Phase 2]", path="[Output Path]")`.
3. 🛑 STOP and wait for `[OBSERVATION]`.

## PHASE 4: FINAL REPORT

1. Confirm the file was generated.
2. Provide the user with a brief overview of the summary you created and the path to the new file.
