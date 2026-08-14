"""
app.py
======
LiverAI Medical Assistant — Modular Application Entry Point

Architecture:
  - routes/main_routes.py     → UI Shell, PWA Manifest, Service Worker
  - routes/auth_routes.py     → Authentication, Registration, Session & Firebase OAuth
  - routes/chat_routes.py     → Chat Streaming, File/Image Upload, History CRUD
  - routes/profile_routes.py  → Patient Medical Background, Settings & User Stats
  - routes/admin_routes.py    → System Admin Dashboard, User Management, Audit Logs
  - routes/clinical_routes.py → LPD Clinical Disease Risk Model & Vision Classifier Status

  - src/db.py                 → Database Connection Pool, Migrations & Data Access Layer
  - src/llm_pipeline.py       → Gemini 2.5 Flash RAG Pipeline + Pinecone Vector Index
  - src/prediction.py         → LPD Clinical Risk Machine Learning Model
  - src/vision_inference.py   → EfficientNet-B0 Biopsy Histology Classifier
"""

import os
import warnings
from dotenv import load_dotenv
from flask import Flask

warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings("ignore", category=DeprecationWarning)

# Load environment variables
load_dotenv()

if not os.environ.get("USER_AGENT"):
    os.environ["USER_AGENT"] = "LiverAI-Chatbot/1.0"

# Firebase Admin SDK Initialization
FIREBASE_SERVICE_ACCOUNT = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "firebase-service-account.json")
try:
    import firebase_admin
    from firebase_admin import credentials as fb_credentials
    if os.path.exists(FIREBASE_SERVICE_ACCOUNT) and not firebase_admin._apps:
        cred = fb_credentials.Certificate(FIREBASE_SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred)
        print("[Firebase] Admin SDK initialized successfully.")
except Exception as _fb_err:
    print(f"[Firebase] Setup notice: {_fb_err}")

# Database & RAG Pipeline Initialization
from src.db import init_db
from src.llm_pipeline import init_rag_pipeline

init_db()
init_rag_pipeline()

# Flask Application Setup & Blueprint Registration
def create_app():
    app = Flask(__name__)
    app.config["TEMPLATES_AUTO_RELOAD"] = True
    app.secret_key = os.getenv("FLASK_SECRET_KEY", "liverai-secret-key-2026")

    # Import and register Blueprints
    from routes import (
        main_bp, auth_bp, chat_bp,
        profile_bp, admin_bp, clinical_bp
    )

    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(profile_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(clinical_bp)

    return app

app = create_app()

if __name__ == "__main__":
    host = os.getenv("FLASK_RUN_HOST", "127.0.0.1")
    port = int(os.getenv("PORT", os.getenv("FLASK_RUN_PORT", 5000)))
    print(f"\n[LiverAI] Application running at http://{host}:{port}")
    app.run(host=host, port=port, debug=False)