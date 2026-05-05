#!/bin/bash
ACTION=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('action', ''))" "$1")
DATA=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('data_json', '{}'))" "$1")
PATH_OUT=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('path', 'output.xlsx'))" "$1")

case "$ACTION" in
    "analyze_dir")
        # Simply return the file list and details
        ls -lh "$PATH_OUT"
        ;;

    "generate_excel")
        # Use a python one-liner to turn JSON into Excel
        python3 -c "import pandas as pd, json; data=json.loads('$DATA'); pd.DataFrame(data).to_excel('$PATH_OUT', index=False)"
        echo "SUCCESS: Excel file created at $PATH_OUT"
        ;;

    "generate_ppt")
        # Logic to trigger a python script that handles the slides
        # We'll point it to a small helper script
        python3 ~/ironclaw_skills/file_coworker/ppt_maker.py "$DATA" "$PATH_OUT"
        echo "SUCCESS: PowerPoint created at $PATH_OUT"
        ;;
esac