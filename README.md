# 🌿 LifeLens – AI Buddy (Flutter + FastAPI)

> 🧠 A privacy-first AI-powered personal assistant that listens, understands, and organizes your life — all offline.

---

### 🧩 Built With
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![spaCy](https://img.shields.io/badge/spaCy-NLP-green)
![Tesseract OCR](https://img.shields.io/badge/OCR-Tesseract-orange)
![Hive](https://img.shields.io/badge/Database-Hive-yellow)
![SpeechToText](https://img.shields.io/badge/Speech-Speech_to_Text-red)

---

## Submissions

🎬 **Watch the full project demonstration:**  
[![Watch Demo](https://img.shields.io/badge/Watch%20on-Google%20Drive-blue?logo=google-drive)](https://drive.google.com/file/d/1WTwU8S4fsSiiMc66VQfg7dvBmqAOt0aN/view?usp=drivesdk)

---

## 🌟 Project Overview

**LifeLens – AI Buddy** is a hybrid mobile and backend system that combines:  
- A **Flutter frontend app** that listens to voice commands, manages reminders, and uploads files  
- A **FastAPI backend server** that performs document analysis (OCR, summarization, keyword extraction, classification)  

Everything is designed to run **locally** — meaning **no cloud**, **no API keys**, and **full privacy**.

---

## 🧩 Key Features

| Feature | Description |
|----------|-------------|
| 🎙️ Voice Interaction | Converts your voice into structured text using `speech_to_text` |
| ⏰ Smart Reminders | Extracts tasks and due dates using NLP |
| 🧠 Text Summarization | Summarizes documents intelligently using FastAPI backend |
| 🗂️ Document Classification | Identifies if text is resume, report, receipt, research, etc. |
| 🧾 Keyword Extraction | Uses spaCy NLP for entity and noun-phrase extraction |
| 🖼️ OCR Support | Reads text from PDFs and images using PyMuPDF + Tesseract |
| 💾 Local Storage | Uses Hive to store reminders persistently |
| 💬 Modern UI | Neon-glow theme, Bricksans font, Flutter dark mode |
| 🔒 Offline Processing | Fully functional without the internet |

---

## 🧰 Technology Stack

| Component | Technology |
|------------|-------------|
| **Frontend** | Flutter (Dart) |
| **Backend** | FastAPI (Python) |
| **NLP Engine** | spaCy |
| **OCR Engine** | pytesseract + PyMuPDF |
| **Storage** | Hive (local NoSQL) |
| **Speech** | speech_to_text |
| **UI Design** | Custom theming with Bricksans |

---

## 📱 Frontend – `ai_buddy_app` (Flutter)

### ✨ Features
- 🎙️ Voice-to-text transcription  
- 🧩 Automatic reminder detection  
- 💾 Persistent storage with Hive  
- 📄 File upload (PDF/Image) to backend  
- 🧠 AI summaries and insights displayed instantly  

