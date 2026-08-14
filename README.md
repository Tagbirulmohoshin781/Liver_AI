# LiverAI Medical Chatbot

An AI-powered liver disease detection and medical assistant chatbot built with Flask, LangChain, Google Gemini, and Pinecone. Supports multimodal medical image analysis (vision), chat history, and Firebase authentication.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [API Keys Setup](#api-keys-setup)
- [Windows Setup](#windows-setup)
- [macOS Setup](#macos-setup)
- [iOS / iPadOS Access](#ios--ipados-access)
- [Environment Configuration](#environment-configuration)
- [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)

---

## Features

- RAG-powered medical Q&A (Pinecone + Google Gemini)
- Medical image analysis (liver scans, lab reports)
- Chat history & multi-session support
- Firebase authentication (Google, GitHub, Facebook, Email)
- PWA-ready (installable on iOS/macOS/Windows)
- Supports PDF, CSV, Excel, TXT, and web knowledge sources

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Python | 3.10 to 3.11 | 3.12+ may have torch compatibility issues |
| pip | Latest | Bundled with Python |
| Git | Any | For cloning the repo |

WARNING: Python 3.12 may cause issues with torch and torchvision on all platforms. Use Python 3.10 or 3.11 for best compatibility.

---

## API Keys Setup

You need accounts and API keys for:

| Service | Where to get it | Required |
|---|---|---|
| Google AI (Gemini) | https://aistudio.google.com/app/apikey | Yes |
| Pinecone | https://app.pinecone.io | Yes |
| HuggingFace | https://huggingface.co/settings/tokens | Yes |
| Firebase | https://console.firebase.google.com | Optional (social login) |

---

## Windows Setup

### Option A - Automated (Recommended)

Open PowerShell as Administrator and run:

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    .\setup_windows.ps1

### Option B - Manual Steps

**1. Install Python 3.11**

Download from https://www.python.org/downloads/release/python-3110/ and check "Add Python to PATH" during installation.

Verify:

    python --version
    # Expected: Python 3.11.x

**2. Clone the repository (if not already done)**

    git clone <your-repo-url>
    cd "Liver Disease Detectioon system 2"

**3. Create a virtual environment**

    python -m venv venv
    venv\Scripts\activate

**4. Install PyTorch (CPU version for most users)**

    pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

If you have an NVIDIA GPU, visit https://pytorch.org/get-started/locally/ to generate the correct CUDA command.

**5. Install all dependencies**

    pip install -r requirements.txt

**6. Configure environment variables**

    copy .env.example .env
    notepad .env

Fill in your API keys (see Environment Configuration section).

**7. Run the app**

    python app.py

Open your browser at: http://localhost:5000

---

## macOS Setup

### Option A - Automated (Recommended)

    chmod +x setup_mac.sh
    ./setup_mac.sh

### Option B - Manual Steps

**1. Install Homebrew (if not already installed)**

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

**2. Install Python 3.11**

    brew install python@3.11

Verify:

    python3.11 --version
    # Expected: Python 3.11.x

**3. Clone the repository**

    git clone <your-repo-url>
    cd "Liver Disease Detectioon system 2"

**4. Create a virtual environment**

    python3.11 -m venv venv
    source venv/bin/activate

**5. Install PyTorch**

Apple Silicon (M1/M2/M3/M4 chips):

    pip install torch torchvision

Apple Silicon uses MPS (Metal Performance Shaders) acceleration automatically.

Intel Mac:

    pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

**6. Install all dependencies**

    pip install -r requirements.txt

**7. Configure environment variables**

    cp .env.example .env
    nano .env

Fill in your API keys.

**8. Run the app**

    python app.py

Open your browser at: http://localhost:5000

NOTE: If prompted by the macOS Firewall, click Allow to permit Flask to accept network connections.

---

## iOS / iPadOS Access

Python Flask cannot run natively on iOS. There are two ways to use LiverAI on an iPhone or iPad:

### Method 1 - Access via Local Network (Recommended)

Run the server on your Mac or Windows PC on the same Wi-Fi network, then access it from your iPhone/iPad browser.

Step 1: Start the app with network access enabled on your Mac or Windows machine:

    python app.py --host 0.0.0.0

Or set HOST=0.0.0.0 in your .env file.

Step 2: Find your computer's local IP address:
- macOS: Run `ifconfig | grep "inet "` or go to System Settings > Wi-Fi > Details
- Windows: Run `ipconfig` and look for the IPv4 Address

Step 3: On your iPhone or iPad, open Safari and go to:

    http://<YOUR_COMPUTER_IP>:5000

Example: http://192.168.1.42:5000

Step 4 - Install as PWA (optional):
1. Tap the Share button (box with arrow icon) in Safari
2. Tap "Add to Home Screen"
3. Tap Add - LiverAI will appear as an app icon on your home screen

The app works fully in Safari on iOS 15 and later. All features including image upload are supported.

### Method 2 - Deploy to Cloud

Deploy LiverAI to a cloud platform so it is accessible from any device:

| Platform | Free Tier | Notes |
|---|---|---|
| Render | Yes | Easiest, connect GitHub repo |
| Railway | Yes | Good for Python apps |
| Heroku | Limited | Requires credit card |
| Google Cloud Run | Yes | Docker-based |

After deploying, access the URL from any iOS browser or install as a PWA.

---

## Environment Configuration

Copy .env.example to .env and fill in your values:

    # Required API Keys
    GOOGLE_API=your_google_gemini_api_key_here
    PINECONE_API_KEY=your_pinecone_api_key_here
    HUGGINGFACE_API_KEY=your_huggingface_token_here

    # Flask
    FLASK_SECRET_KEY=change-this-to-a-random-secret-string
    USER_AGENT=LiverAI-Chatbot/1.0

    # Server (optional)
    HOST=127.0.0.1     # Change to 0.0.0.0 to allow LAN access (for iOS)
    PORT=5000

    # Database
    DB_TYPE=sqlite     # Use mysql for production

    # Firebase (optional - enables Google/GitHub/Facebook login)
    FIREBASE_API_KEY=
    FIREBASE_AUTH_DOMAIN=
    FIREBASE_PROJECT_ID=
    FIREBASE_APP_ID=
    FIREBASE_SERVICE_ACCOUNT_PATH=firebase-service-account.json

---

## Running the App

Activate virtual environment first:

    # Windows:
    venv\Scripts\activate

    # macOS:
    source venv/bin/activate

Then run:

    python app.py

The app will be available at http://localhost:5000

On first run, the app will:
1. Download the embedding model (~90 MB) from HuggingFace
2. Create the Pinecone index and embed the knowledge base documents
3. Start the Flask server

Subsequent runs skip steps 1 and 2 and start in a few seconds.

---

## Project Structure

    Liver Disease Detectioon system 2/
    +-- app.py                   Main Flask application
    +-- requirements.txt         Python dependencies
    +-- setup.py                 Package setup
    +-- setup_windows.ps1        Windows automated setup script
    +-- setup_mac.sh             macOS automated setup script
    +-- .env.example             Environment variable template
    +-- .env                     Your local config (never commit!)
    +-- intents.json             Rule-based intent responses
    +-- store_index.py           Pinecone index builder
    +-- Data/                    Knowledge base documents (PDF/CSV/Excel/TXT)
    +-- src/
    |   +-- helper.py            Document loaders and embedding utils
    |   +-- prompt.py            System prompts for the LLM
    |   +-- db.py                SQLite/MySQL database helpers
    |   +-- vision_inference.py  Medical image analysis pipeline
    +-- templates/
    |   +-- chat.html            Main chat UI (single-page app)
    +-- static/                  CSS, JS, icons
    +-- models/                  Local model cache (auto-created)

---

## Troubleshooting

### Windows

| Problem | Solution |
|---|---|
| 'python' is not recognized | Re-install Python and check "Add to PATH", then restart terminal |
| torch install fails | Use the CPU-only PyTorch command in step 4 |
| venv\Scripts\activate not working | Run Set-ExecutionPolicy RemoteSigned in Admin PowerShell |
| Port 5000 blocked | Change PORT=5001 in .env or allow the port in Windows Firewall |
| PINECONE_API_KEY not set error | Make sure .env file exists and has no spaces around the = sign |

### macOS

| Problem | Solution |
|---|---|
| python3.11: command not found | Run brew install python@3.11 and follow Homebrew PATH instructions |
| SSL: CERTIFICATE_VERIFY_FAILED | Run the Install Certificates.command in your Python 3.11 folder |
| Apple Silicon torch errors | Upgrade pip: pip install --upgrade pip then retry |
| Permission denied on setup_mac.sh | Run chmod +x setup_mac.sh first |
| Port 5000 in use (AirPlay conflict) | Set PORT=5001 in .env OR disable AirPlay Receiver in System Settings |

IMPORTANT - macOS AirPlay Conflict: macOS 12 Monterey and later reserves port 5000 for AirPlay Receiver.
Fix option 1: Set PORT=5001 in your .env file.
Fix option 2: Go to System Settings > General > AirDrop & Handoff and disable AirPlay Receiver.

### iOS

| Problem | Solution |
|---|---|
| Cannot connect to computer IP | Make sure both devices are on the same Wi-Fi network |
| Connection refused | Start the app with --host 0.0.0.0 flag |
| Images not uploading | Use Safari (not third-party browsers) for best iOS compatibility |
| PWA shows no content offline | LiverAI requires an internet connection for AI responses |

---

## Quick Reference Commands

    # Windows - activate environment
    venv\Scripts\activate

    # macOS - activate environment
    source venv/bin/activate

    # Install dependencies
    pip install -r requirements.txt

    # Run the app (local only)
    python app.py

    # Run with LAN access (for iOS access)
    python app.py --host 0.0.0.0

    # Rebuild Pinecone knowledge base
    python store_index.py

    # Deactivate virtual environment
    deactivate

---

## Security Notes

- Never commit .env - it contains your API keys. It is already in .gitignore.
- Never commit firebase-service-account.json - treat it like a password.
- For production deployment, rotate all API keys and use your cloud provider environment variables instead of .env.

---

Built by Koushik Islam Shakil and Tagbirul Mohoshin
