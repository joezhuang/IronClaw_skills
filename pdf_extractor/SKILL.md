# pdf_extractor Skill

This skill extracts the text content from the first page of a specified PDF file on macOS.

### Requirements
- **PyMuPDF**: The script requires the `pymupdf` library.
- **Venv**: If you are using a Python virtual environment as per IronClaw standards, ensure it is installed within the `.venv` directory adjacent to the skill.

### Installation
```bash
# If using a global python installation:
pip install pymupdf

# If using the IronClaw standard .venv:
./.venv/bin/pip install pymupdf
```

### Usage
The skill accepts a `file_path` argument. It handles tilde expansion (e.g., `~/Documents/file.pdf`) and returns a JSON object with the filename and the extracted text. If the file is missing or an error occurs, it returns an error message.