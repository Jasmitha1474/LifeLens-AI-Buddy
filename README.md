# AI Buddy – FastAPI Backend (for LifeLens)

This repository contains the **FastAPI backend** for **LifeLens – Your AI Buddy**, a local-only AI service that processes documents (PDFs or images), extracts text, identifies document types, generates summaries, and extracts key information — all without relying on external APIs.

It is lightweight, private, and designed to integrate seamlessly with the **LifeLens Flutter app**.

---

## 🧠 Overview

The AI Buddy backend:
- Extracts text from uploaded **PDF** or **image** files.
- Analyzes text locally using **spaCy** for keyword extraction.
- Detects document type (resume, research paper, receipt, meeting notes, etc.).
- Generates short, meaningful summaries from extracted text.
- Returns a clean **JSON response** that the frontend can easily use.

All processing happens locally — **no cloud calls**, ensuring full privacy.

---

## ⚙️ Tech Stack

| Component | Technology |
|------------|-------------|
| **Framework** | FastAPI |
| **Language** | Python 3.9+ |
| **PDF Extraction** | PyMuPDF (`fitz`) |
| **Image OCR** | pytesseract + Pillow |
| **NLP / Keyword Extraction** | spaCy (`en_core_web_sm`) |
| **Response Format** | JSON |
| **CORS** | FastAPI middleware |

---

## 🧩 Features

| Feature | Description |
|----------|-------------|
| 🧾 **PDF Text Extraction** | Reads and extracts text from PDF files. |
| 🖼️ **Image OCR** | Recognizes and extracts text from PNG/JPEG images. |
| 🧠 **Keyword Extraction** | Identifies important keywords and named entities using spaCy. |
| 📑 **Document Type Detection** | Automatically categorizes the document type (resume, research, receipt, etc.). |
| 📝 **Summarization** | Creates a short, meaningful summary (first few sentences). |
| 🔒 **Local Only** | Everything runs offline — no external APIs or network requests. |

---

## 📁 Project Structure

