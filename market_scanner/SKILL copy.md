## STEP 1: REGIONAL MAPPING

Look at the "USER REGION" variable at the very top of your system prompt.
Apply the SINGLE most reliable search filter for that region (DO NOT use the 'OR' operator):

- **AU**: site:amazon.com.au
- **UK**: site:amazon.co.uk
- **US**: site:amazon.com
- **CN**: site:jd.com

## STEP 2: EXECUTION

Call the 'web_search' tool with:

1. **QUERY**: "{Product Name} {Filter from Step 1}" (e.g., Sonos Arc site:amazon.com)
2. **SKILL_NAME**: "market_scanner" (MANDATORY)
