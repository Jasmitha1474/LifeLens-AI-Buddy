# 🌿 LifeLens – AI Buddy (Flutter + FastAPI)

> 🧠 A privacy-first offline AI assistant that listens, understands, and organizes your life — without relying on cloud services or API keys.

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

## 🎬 Demo Video

🎬 **Watch the full project demonstration:**  
[![Watch Demo](https://img.shields.io/badge/Watch%20on-Google%20Drive-blue?logo=google-drive)](https://drive.google.com/file/d/1WTwU8S4fsSiiMc66VQfg7dvBmqAOt0aN/view?usp=drivesdk)

---

## 🌟 Project Overview

**LifeLens – AI Buddy** is a hybrid mobile and backend system that helps users manage reminders, understand documents, and extract insights — all processed offline.

It brings together:  
- A **Flutter mobile application** for voice interaction, storage, and file uploads  
- A **FastAPI backend server** that performs OCR, NLP, summarization, and classification  

The system is designed for **full privacy**, with every operation running locally.

---

## 🧩 Key Features

| Feature | Description |
|----------|-------------|
| 🎙️ Voice Interaction | Converts speech into structured text using `speech_to_text` |
| ⏰ Smart Reminder Extraction | Detects tasks, dates, and important phrases using spaCy |
| 🧠 Text Summarization | Creates concise summaries of long text or uploaded documents |
| 🗂️ Document Classification | Identifies document type (resume, receipt, research, etc.) |
| 🧾 Keyword / Entity Extraction | Extracts key terms, entities, and noun phrases |
| 🖼️ OCR Support | Reads text from images and PDFs using PyMuPDF + Tesseract |
| 💾 Local Storage | Saves data securely using Hive local database |
| 💬 Modern UI | Dark mode UI with neon accents and smooth interactions |
| 🔒 Offline Processing | Works without internet, cloud APIs, or external services |

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
| **UI Design** | Custom dark theme with Bricksans |

---

## 📱 Frontend – `ai_buddy_app` (Flutter)

### ✨ Features
- 🎙️ Voice-to-text transcription  
- 🧩 Automatic reminder detection using NLP  
- 💾 Persistent local storage with Hive  
- 📄 Upload PDFs/images for analysis  
- 🧠 Displays summaries, keywords, and document insights  

---

## ⚙️ Backend – FastAPI AI Server

### Processing Pipeline:

#### **1. OCR / Text Extraction**
- Tesseract for image OCR  
- PyMuPDF for PDF parsing  

#### **2. NLP Processing**
- spaCy model for keyword detection, entity extraction, and structure analysis  

#### **3. Summarization & Insights**
- Lightweight summarization logic  
- Rule-based and statistical text extraction  

#### **4. API Endpoints**
- Accepts text, images, and PDFs  
- Returns structured JSON responses to the Flutter app  

---

## 🚀 Running the Backend (Local FastAPI)

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

uvicorn main:app --reload

## 📲 Running the Flutter App

cd ai_buddy_app

flutter pub get

flutter run

## 🔒 Privacy Philosophy

LifeLens is built around **local-first AI**:

- No third-party API calls  
- No cloud storage  
- No login required  
- No data leaves the device  

This makes it suitable for users who prefer privacy without compromising functionality.

---

## 🔭 Future Enhancements

- Offline document Q&A  
- Improved document classification  
- Lightweight local LLM support  
- Richer reminder extraction  
- Multi-document dashboard  
- Embedding-based storage (vector search)  
- Desktop client version  

---

