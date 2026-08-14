"""
routes/chat_routes.py
======================
Chat streaming, document/image upload, and chat history CRUD routes.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from flask import Blueprint, request, jsonify, session
from werkzeug.utils import secure_filename
from src.db import (
    save_chat_message, get_user_chats, clear_user_history,
    delete_single_chat_message, get_guest_user_id
)
from src.llm_pipeline import generate_rag_answer, get_docsearch
from src.helper import load_pdf_files, text_split, load_txt_files, load_csv_files
from src.vision_inference import predict_image

chat_bp = Blueprint("chat", __name__)

ALLOWED_DOC_EXTENSIONS   = {"pdf", "txt", "csv", "docx", "doc", "json", "xlsx", "xls", "md"}
ALLOWED_IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "bmp", "tif", "tiff", "webp"}


def allowed_file(filename):
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    return ext in ALLOWED_DOC_EXTENSIONS or ext in ALLOWED_IMAGE_EXTENSIONS


def extract_single_document_text(file_path, filename):
    """Extracts text from a single uploaded document file safely."""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    doc_text = ""

    if ext == "pdf":
        try:
            import pypdf
            reader = pypdf.PdfReader(file_path)
            pages_text = []
            for page in reader.pages:
                t = page.extract_text()
                if t:
                    pages_text.append(t.strip())
            doc_text = "\n\n".join(pages_text)
        except Exception as e:
            print(f"[PDF Extraction fallback] {e}")
            try:
                from langchain_community.document_loaders import PyPDFLoader
                loader = PyPDFLoader(file_path)
                docs = loader.load()
                doc_text = "\n\n".join([d.page_content for d in docs if d.page_content])
            except Exception:
                pass

    elif ext in {"txt", "md", "json"}:
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                doc_text = f.read()
        except Exception as e:
            print(f"[Text Read Error] {e}")

    elif ext in {"csv", "xlsx", "xls"}:
        try:
            import pandas as pd
            if ext == "csv":
                df = pd.read_csv(file_path, encoding="utf-8", on_bad_lines="skip")
            else:
                df = pd.read_excel(file_path)
            doc_text = df.to_string(index=False)
        except Exception as e:
            print(f"[Table Read Fallback] {e}")
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    doc_text = f.read()
            except Exception:
                pass

    elif ext in {"docx", "doc"}:
        try:
            import docx
            doc = docx.Document(file_path)
            doc_text = "\n".join([p.text for p in doc.paragraphs if p.text])
        except Exception as e:
            print(f"[Docx Read Error] {e}")

    return doc_text.strip()



@chat_bp.route("/chat", methods=["POST"])
def chat_json():
    """JSON endpoint – called by the new JS sendMessage() function."""
    data = request.get_json(silent=True) or {}
    user_message = data.get("message", "").strip()
    history_json = data.get("history", [])
    image_path   = data.get("image_path", "")
    doc_content  = data.get("doc_content", "")

    if not user_message:
        return jsonify({"error": "Please enter a question about liver health."}), 400

    user_id = session.get("user_id") or get_guest_user_id()

    # Append active document content if uploaded
    if doc_content:
        user_message += f"\n\n[Active Uploaded Document Content]:\n{doc_content[:3000]}"

    # Append patient medical profile context into LLM prompt
    from src.db import get_user_profile
    profile = get_user_profile(user_id) if user_id else None
    if profile and (profile.get("age") or profile.get("gender") or profile.get("medical_notes")):
        med_info = []
        if profile.get("age"): med_info.append(f"Age: {profile['age']}")
        if profile.get("gender"): med_info.append(f"Gender: {profile['gender']}")
        if profile.get("medical_notes"): med_info.append(f"Medical Notes: {profile['medical_notes']}")
        user_message = user_message + "\n\n[Patient Context]: " + ", ".join(med_info)

    import json
    history_str = json.dumps(history_json) if isinstance(history_json, list) else str(history_json)

    # Attach active biopsy image prediction results if an image is attached/active
    if image_path and os.path.exists(image_path):
        try:
            from src.vision_inference import predict_image
            vision_res = predict_image(image_path)
            if vision_res.get("success") and vision_res.get("predictions"):
                preds = vision_res["predictions"]
                findings = []
                for k, v in preds.items():
                    status = "DETECTED" if v.get("positive") else "NOT DETECTED"
                    prob = v.get("probability", 0)
                    findings.append(f"{k.capitalize()}: {status} ({prob}%)")
                user_message += f"\n\n[Active Medical/Biopsy Image Findings]: {', '.join(findings)}"
        except Exception as _v_err:
            print(f"[Vision Context Warning]: {_v_err}")

    bot_response = generate_rag_answer(
        user_message,
        image_path=image_path if image_path else None,
        chat_history=history_json if isinstance(history_json, list) else []
    )

    # Persist in DB
    session_id = session.get("session_id", "default")
    save_chat_message(user_id, session_id, "user", user_message)
    save_chat_message(user_id, session_id, "assistant", bot_response)

    return jsonify({"response": bot_response})


@chat_bp.route("/get", methods=["POST"])
def chat_get():
    user_message = request.form.get("msg", "").strip()
    history_json = request.form.get("history", "")
    image_path   = request.form.get("image_path", "").strip()

    if not user_message:
        return jsonify({"response": "Please enter a question about liver health."})

    user_id = session.get("user_id") or get_guest_user_id()

    # Pass patient medical profile info into LLM prompt if available
    from src.db import get_user_profile
    profile = get_user_profile(user_id) if user_id else None
    if profile and (profile.get("age") or profile.get("gender") or profile.get("medical_notes")):
        med_info = []
        if profile.get("age"): med_info.append(f"Age: {profile['age']}")
        if profile.get("gender"): med_info.append(f"Gender: {profile['gender']}")
        if profile.get("medical_notes"): med_info.append(f"Medical Notes: {profile['medical_notes']}")
        user_message = user_message + "\n\n[Patient Context]: " + ", ".join(med_info)

    bot_response = generate_rag_answer(
        user_message,
        image_path=image_path if image_path else None,
        chat_history=[]
    )

    # Persist in DB
    session_id = session.get("session_id", "default")
    save_chat_message(user_id, session_id, "user", user_message)
    save_chat_message(user_id, session_id, "assistant", bot_response)

    return jsonify({"response": bot_response})




@chat_bp.route("/upload", methods=["POST"])
def upload_file():
    if "file" not in request.files:
        return jsonify({"success": False, "message": "No file provided in request."}), 400

    file = request.files["file"]
    if not file or file.filename == "":
        return jsonify({"success": False, "message": "No file selected."}), 400

    if not allowed_file(file.filename):
        return jsonify({
            "success": False,
            "message": "Unsupported file format. Supported types: PDF, TXT, CSV, DOCX, MD, JPG, PNG, TIFF.",
        }), 400

    try:
        filename  = secure_filename(file.filename) or f"upload_{os.urandom(4).hex()}"
        os.makedirs("Data", exist_ok=True)
        save_path = os.path.join("Data", filename)
        file.save(save_path)

        ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""

        # ── 1. Image processing (Histology Vision AI) ────────────────────────
        if ext in ALLOWED_IMAGE_EXTENSIONS:
            result = predict_image(save_path)
            predictions = result.get("predictions", {})
            raw_probs = result.get("raw_probabilities", {})
            mode = result.get("mode", "production")
            warning = result.get("warning")
            return jsonify({
                "success": True,
                "is_image": True,
                "filename": filename,
                "message": f"Biopsy slide image '{filename}' analyzed successfully.",
                "image_path": save_path,
                "predictions": predictions,
                "raw_probabilities": raw_probs,
                "mode": mode,
                "warning": warning
            })

        # ── 2. Document processing & text extraction ─────────────────────────
        doc_text = extract_single_document_text(save_path, filename)
        chunks_count = 0

        # Vector RAG indexing scoped ONLY to this uploaded file
        if doc_text:
            try:
                from src.helper import Document
                single_doc = Document(page_content=doc_text, metadata={"source": filename, "type": ext})
                chunks = text_split([single_doc])
                chunks_count = len(chunks)
                docsearch = get_docsearch()
                if docsearch and chunks:
                    docsearch.add_documents(chunks)
            except Exception as _rag_err:
                print(f"[RAG Indexing Notice] {_rag_err}")

        summary_note = f" ({len(doc_text)} characters extracted)" if doc_text else " (empty or unreadable text)"
        return jsonify({
            "success": True,
            "is_image": False,
            "filename": filename,
            "message": f"Document '{filename}' uploaded and indexed successfully!{summary_note}",
            "doc_content": doc_text[:5000],
            "chunk_count": chunks_count,
            "image_path": save_path
        })

    except Exception as e:
        print(f"[Upload Error] {e}")
        return jsonify({"success": False, "message": f"Upload failed: {str(e)}"}), 500


@chat_bp.route("/api/history", methods=["GET"])
def api_history():
    user_id = session.get("user_id") or get_guest_user_id()
    chats = get_user_chats(user_id)
    return jsonify({"success": True, "history": chats})


@chat_bp.route("/api/clear_history", methods=["POST"])
def api_clear_history():
    user_id = session.get("user_id") or get_guest_user_id()
    clear_user_history(user_id)
    return jsonify({"success": True, "message": "History cleared successfully."})


@chat_bp.route("/api/history/<int:msg_id>", methods=["DELETE"])
def api_delete_single_message(msg_id):
    user_id = session.get("user_id") or get_guest_user_id()
    delete_single_chat_message(user_id, msg_id)
    return jsonify({"success": True, "message": "Message deleted."})
