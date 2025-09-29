from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
from PIL import Image
import io
import fitz  # PyMuPDF

app = FastAPI()

# CORS middleware to allow frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust origins as needed for production
    allow_methods=["*"],
    allow_headers=["*"],
)

def extract_text_from_pdf(file_bytes: bytes) -> str:
    doc = fitz.open(stream=file_bytes, filetype="pdf")
    text = ""
    for page in doc:
        text += page.get_text()
    return text

def extract_text_from_image(file_bytes: bytes) -> str:
    image = Image.open(io.BytesIO(file_bytes))
    text = pytesseract.image_to_string(image)
    return text

def summarize_text(text: str) -> str:
    sentences = text.split('.')
    return '.'.join(sentences[:3]) + ('.' if len(sentences) > 3 else '')

@app.post("/upload_file/")
async def upload_file(file: UploadFile = File(...)):
    file_bytes = await file.read()
    content_type = file.content_type
    extracted_text = ""

    if "pdf" in content_type:
        extracted_text = extract_text_from_pdf(file_bytes)
    elif "image" in content_type:
        extracted_text = extract_text_from_image(file_bytes)
    else:
        return {"error": "Unsupported file type"}

    summary = summarize_text(extracted_text)

    return {"summary": summary, "full_text": extracted_text}
