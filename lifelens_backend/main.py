from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import fitz
from PIL import Image
import pytesseract
import io
import spacy
import re
import logging
from typing import List, Tuple
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AI Buddy - Local Only")
logger = logging.getLogger("uvicorn.error")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # You can restrict later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load spaCy NLP model
try:
    nlp = spacy.load("en_core_web_sm")
    SPACY = True
except Exception as e:
    logger.warning(f"spaCy not available: {e}")
    nlp = None
    SPACY = False

def extract_text_from_pdf(file_bytes: bytes) -> str:
    try:
        doc = fitz.open(stream=file_bytes, filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text()
        return text.strip()
    except Exception as e:
        logger.error(f"PDF extraction error: {e}")
        raise HTTPException(status_code=400, detail="Failed to extract text from PDF")

def extract_text_from_image(file_bytes: bytes) -> str:
    try:
        image = Image.open(io.BytesIO(file_bytes))
        return pytesseract.image_to_string(image).strip()
    except Exception as e:
        logger.error(f"Image extraction error: {e}")
        raise HTTPException(status_code=400, detail="Failed to extract text from image")

def spacy_extract_keywords(text: str) -> List[str]:
    if not SPACY or not text:
        return []
    doc = nlp(text)
    kws = set()
    for chunk in doc.noun_chunks:
        kws.add(chunk.text.lower())
    for ent in doc.ents:
        kws.add(ent.text.lower())
    return list(kws)

def detect_doc_type(text: str) -> str:
    t = text.lower()
    if any(k in t for k in ["resume", "skills", "experience"]):
        return "resume"
    if any(k in t for k in ["abstract", "journal", "doi", "references"]):
        return "research"
    if any(k in t for k in ["invoice", "receipt", "total", "payment"]):
        return "receipt"
    if any(k in t for k in ["meeting", "agenda", "minutes"]):
        return "meeting_notes"
    if any(k in t for k in ["report", "analysis", "findings"]):
        return "report"
    return "generic"

def split_sentences(text: str) -> List[str]:
    return re.split(r'(?<=[.!?])\s+', text.strip())

def local_summary(text: str, keywords: List[str], max_sentences: int = 3) -> Tuple[str, str]:
    if not text:
        return ("No text to summarize.", "generic")

    doc_type = detect_doc_type(text)
    sentences = split_sentences(text)

    if not sentences:
        return (text[:300] + "...", doc_type)

    chosen = " ".join(sentences[:max_sentences])
    preamble = {
        "resume": "This appears to be a resume highlighting experience and skills.",
        "research": "This looks like a research article summarizing study and findings.",
        "receipt": "This is a receipt or invoice showing purchases and totals.",
        "meeting_notes": "These are meeting notes summarizing discussions and decisions.",
        "report": "This appears to be a structured report with analysis and conclusions.",
        "generic": "This is a general document summarized below."
    }.get(doc_type, "This is a document.")

    return (f"{preamble}\n\n{chosen}", doc_type)

@app.post("/upload_file/")
async def upload_file(file: UploadFile = File(...), max_sentences: int = 3):
    try:
        file_bytes = await file.read()
        ctype = (file.content_type or "").lower()

        if ctype in ["application/pdf", "application/octet-stream"]:
            text = extract_text_from_pdf(file_bytes)
        elif ctype in ["image/png", "image/jpeg"]:
            text = extract_text_from_image(file_bytes)
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported file type: {ctype}")

        keywords = spacy_extract_keywords(text)
        summary, doc_type = local_summary(text, keywords, max_sentences)

        return JSONResponse(content={
            "summary": summary,
            "keywords": keywords,
            "doc_type": doc_type
        })

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return JSONResponse(content={
            "summary": "Unexpected error occurred but system is running.",
            "keywords": [],
            "doc_type": "generic"
        })
