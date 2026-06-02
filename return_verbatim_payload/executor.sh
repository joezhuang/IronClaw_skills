#!/bin/bash

# Extract the raw_payload parameter passed by the LLM function call
RAW_INPUT="$1"

# Use python to safely parse out the 'raw_payload' text value and print it completely raw
python3 -c "
import sys, json
try:
    args = json.loads(sys.argv[1])
    print(args.get('raw_payload', sys.argv[1]))
except Exception as e:
    print(sys.argv[1])
" "$RAW_INPUT"