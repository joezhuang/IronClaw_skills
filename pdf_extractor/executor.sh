#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/../.venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then EXEC_CMD="$VENV_PYTHON"; else EXEC_CMD="python3"; fi

$EXEC_CMD - <<'EOF' "$1"
import sys
import json
import os

try:
    # Parse the input JSON arguments
    args = json.loads(sys.argv[1])
    file_path = args.get('file_path', '')
    
    # Resolve path (handle tildes)
    expanded_path = os.path.expanduser(file_path)
    
    # Check for file existence before attempting to open
    if not os.path.exists(expanded_path):
        raise FileNotFoundError(f"The file at {file_path} was not found.")

    # Import PyMuPDF
    import fitz

    # Open the document
    doc = fitz.open(expanded_path)
    
    # Extract text from the first page if it exists
    extracted_text = ""
    if len(doc) > 0:
        page = doc.load_page(0)
        extracted_text = page.get_text()
    
    doc.close()

    # Output the result JSON
    print(json.dumps({
        "filename": os.path.basename(expanded_path),
        "extracted_text": extracted_text
    }))

except FileNotFoundError as e:
    print(json.dumps({"error": str(e)}))
except ImportError:
    print(json.dumps({"error": "The 'pymupdf' library is not installed. Please install it with pip."}))
except Exception as e:
    print(json.dumps({"error": f"An unexpected error occurred: {str(e)}"}))

EOF