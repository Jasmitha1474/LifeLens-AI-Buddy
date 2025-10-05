# 🌿 LifeLens – AI Buddy (Flutter + FastAPI)

> 🧠 A local AI-powered personal assistant that listens, understands, and organizes your life — all without the cloud.

---

### 🧩 Built With
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![spaCy](https://img.shields.io/badge/spaCy-NLP-green)
![Tesseract OCR](https://img.shields.io/badge/OCR-Tesseract-orange)

---

## 🎥 Demo Video

Experience LifeLens in action:  
[![Watch Demo](https://img.shields.io/badge/Watch%20Demo%20on-Google%20Drive-blue?logo=google-drive)](https://drive.google.com/file/d/1WTwU8S4fsSiiMc66VQfg7dvBmqAOt0aN/view?usp=drivesdk)

---

## 🌟 Highlights

- 🎙️ Voice-based interaction powered by **speech recognition**
- 🧾 Automatic **reminder extraction** from speech
- 📄 **AI-powered document processing** (PDFs & Images)
- 🧠 Intelligent **text summarization & keyword extraction**
- 🗂️ Smart **document classification** (resume, research, receipt, etc.)
- 💾 Local storage using **Hive** for offline reminders
- 💬 **Modern, glassmorphic Flutter UI** with Bricksans font
- 🔒 Fully **offline processing** for privacy and speed

---

## 🚀 Project Overview

**LifeLens** (AI Buddy) is a hybrid system combining a **Flutter mobile app** with a **FastAPI backend**.  

It allows users to:
- Record voice notes and automatically generate reminders.
- Upload PDFs or images and receive:
  - Extracted text
  - Summaries
  - Keywords
  - Detected document type  
- Store reminders locally with Hive for quick access.

Everything runs **entirely offline** — no third-party APIs, no cloud, no internet dependency.

---

## 🎨 Frontend – `ai_buddy_app` (Flutter)

### 🧩 Features
| Functionality | Description |
|---------------|-------------|
| 🎙️ Voice Recording | Real-time transcription using `speech_to_text` |
| ⏰ Smart Reminders | Extracts tasks, due dates, and deadlines from transcribed text |
| 💾 Persistent Storage | Stores reminders locally with Hive |
| 📄 Document Upload | Sends PDF or image files to backend for summarization |
| 💬 Stunning UI | Custom dark theme, animated mic, Bricksans typography |

---

