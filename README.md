# 🌿 LifeLens – AI Buddy (Flutter + FastAPI)

**LifeLens – Your AI Buddy** is a smart personal assistant application that combines a **Flutter mobile app** with a **FastAPI backend**.  
It allows users to **record voice notes, extract reminders, and upload documents (PDFs or images)** to receive **AI-generated summaries**, **keywords**, and **document classifications** — all processed locally without any cloud dependency.

---

## 🧠 Project Overview

LifeLens has two core components:

1. 🧩 **Frontend – ai_buddy_app**  
   A **Flutter** application that handles:
   - Voice transcription using `speech_to_text`
   - Automatic reminder extraction
   - Local task storage using `Hive`
   - File uploads (PDFs, images) to the backend
   - Beautiful, modern UI with Bricksans font and animated mic visualization

2. ⚙️ **Backend – lifelens_backend**  
   A **FastAPI** server that processes uploaded files:
   - Extracts text from PDFs and images
   - Performs OCR using Tesseract
   - Extracts keywords using spaCy NLP
   - Detects document type (resume, research, receipt, etc.)
   - Generates local summaries — no OpenAI or cloud models required

Together, they form a fully offline AI-powered assistant that can **listen, understand, and organize** your tasks and documents intelligently.

---

## 🎨 Frontend – `ai_buddy_app` (Flutter)

### 🧩 Features
- 🎙️ **Voice Transcription**: Converts voice to text using `speech_to_text`.  
- ⏰ **Smart Reminders**: Detects events, deadlines, and due dates from speech.  
- 💾 **Local Storage**: Uses `Hive` for persistent task management.  
- 📄 **File Upload**: Sends PDFs or images to the backend for summarization.  
- 💬 **Clean Modern UI**: Dark theme, Bricksans font, neon accents, and fluid animations.


