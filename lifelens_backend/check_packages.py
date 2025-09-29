import importlib

required_packages = [
    "fastapi",
    "fitz",           # PyMuPDF imported as fitz
    "PIL",            # Pillow
    "pytesseract",
    "spacy",
    "re",             # built-in, should always be present
    "logging"         # built-in, should always be present
]

missing_packages = []

for pkg in required_packages:
    try:
        importlib.import_module(pkg)
    except ImportError:
        missing_packages.append(pkg)

if missing_packages:
    print("Missing packages:", missing_packages)
else:
    print("All packages are installed.")
