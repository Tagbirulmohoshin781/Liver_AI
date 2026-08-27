# LiverAI – Medical Assistant & Precision Diagnostic Intelligence

An enterprise-grade, cross-platform AI medical diagnostic system built with **Flask**, **LangChain**, **Google Gemini 2.5 Flash**, **Pinecone RAG**, and a **Flutter Mobile App**. Provides 10-biomarker clinical LPD risk prediction, ONNX microscopic biopsy histology vision classification, and real-time medical AI chat.

---

## 🏗️ System Architecture & Workflow

```mermaid
flowchart TD
    subgraph Clients["📱 Client Applications"]
        WEB["🌐 Web Application (HTML5 / Vanilla CSS / JS)"]
        APK["📱 Mobile Application (Flutter APK / ONNX Runtime)"]
    end

    subgraph REST_API["⚙️ Backend REST API (Flask / Gunicorn)"]
        AUTH["`/api/login` & `/api/register` (Supabase / SQLite)"]
        PRED["`/api/v1/predict` (LPD Clinical 10-Biomarker Risk Engine)"]
        CHAT["`/chat` (Gemini 2.5 Flash RAG Pipeline)"]
        VISION["`/api/vision/analyze` (Histology Classifier)"]
    end

    subgraph Data_Layer["💾 Data & Knowledge Engine"]
        AASLD["AASLD / EASL Clinical Text Guidelines (131 Local Chunks)"]
        PINECONE["Pinecone Vector Index (Zero-RAM Embeddings)"]
        DB["Supabase PostgreSQL / SQLite Encrypted Storage"]
    end

    WEB --> AUTH
    WEB --> PRED
    WEB --> CHAT
    WEB --> VISION

    APK --> PRED
    APK --> CHAT
    APK -- "Offline Fallback" --> ONNX["Local ONNX Runtime / Clinical Engine"]

    CHAT --> AASLD
    CHAT --> PINECONE
    AUTH --> DB
```

---

## 🎨 Unified Design System & Tokens

Both the **Web App** and **Mobile App (APK)** implement a synchronized high-tech design system:

| Token Category | Value / Hex Code | Usage |
| :--- | :--- | :--- |
| **Primary Base** | `#07111E` / `#0B1120` | Medical Deep Navy Canvas |
| **Surface Card** | `#0F172A` (85% Opacity Glass) | Frosted glass cards (`24px` radius, `1px` subtle outline) |
| **Primary Accent** | `#2563EB` / `#1D4ED8` | Primary CTA buttons & active highlights |
| **Cyan Accent** | `#00E5FF` / `#38BDF8` | Glowing title gradients, emblem highlights & badges |
| **Safe / Low Risk** | `#10B981` (Emerald Green) | Normal lab biomarker status & low risk badges |
| **Warning / Moderate**| `#F59E0B` (Amber Yellow) | Borderline lab values & moderate risk warnings |
| **Danger / High Risk**| `#EF4444` (Coral Red) | Critical biomarker elevations & high risk alerts |

---

## 🔬 10 Clinical Biomarkers (LPD Dataset Engine)

1. **Age**: Patient age in years
2. **Gender**: Male (1) / Female (0)
3. **Total Bilirubin**: Total serum bilirubin (mg/dL)
4. **Direct Bilirubin**: Conjugated direct bilirubin (mg/dL)
5. **Alkaline Phosphatase (Alkphos)**: ALP enzyme level (IU/L)
6. **Alamine Aminotransferase (Sgpt / ALT)**: ALT liver enzyme level (IU/L)
7. **Aspartate Aminotransferase (Sgot / AST)**: AST liver enzyme level (IU/L)
8. **Total Proteins**: Total serum protein concentration (g/dL)
9. **Albumin**: Serum albumin level (g/dL)
10. **A/G Ratio**: Albumin-to-Globulin balance ratio

---

## 🔌 API Endpoints Specification

### Clinical Risk Prediction: `POST /api/v1/predict`
```json
// Request Body
{
  "age": 45,
  "gender": 1,
  "total_bilirubin": 1.4,
  "direct_bilirubin": 0.4,
  "alkaline_phosphotase": 160,
  "sgpt": 65,
  "sgot": 48,
  "total_proteins": 6.8,
  "albumin": 3.2,
  "ag_ratio": 0.9
}
```

```json
// Response Body (200 OK)
{
  "success": true,
  "result": {
    "status": "ok",
    "prediction": 1,
    "probability": 0.72,
    "risk_level": "High",
    "confidence": 72,
    "risk_factors": [
      "elevated total bilirubin",
      "elevated direct bilirubin",
      "elevated ALT (SGPT)",
      "elevated AST (SGOT)",
      "low albumin",
      "abnormal A/G ratio"
    ]
  }
}
```

---

## 📱 Building the Release APK

To build the standalone release APK for Android devices:

```powershell
# 1. Navigate to mobile project
cd "Liver Disease Detection App"

# 2. Verify static analysis (0 issues)
dart analyze

# 3. Compile production release APK
flutter build apk --release
```

The output APK will be saved at:
`Liver Disease Detection App/build/app/outputs/flutter-apk/app-release.apk`

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
