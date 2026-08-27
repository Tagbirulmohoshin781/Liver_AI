"""
routes/auth_routes.py
======================
User authentication, registration, session, and Firebase OAuth routes.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from flask import Blueprint, request, jsonify, session
from src.db import (
    register_user, authenticate_user, get_user_profile, upsert_firebase_user
)

try:
    from firebase_admin import auth as fb_auth
    HAS_FIREBASE = True
except ImportError:
    HAS_FIREBASE = False

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/api/register", methods=["POST"])
def api_register():
    data     = request.get_json(silent=True) or request.form
    username = data.get("username", "").strip()
    email    = data.get("email",    "").strip()
    password = data.get("password", "").strip()

    success, message, user_id = register_user(username, email, password)
    if success:
        session["user_id"]  = user_id
        session["username"] = username
        session["email"]    = email.lower()
        full_profile = get_user_profile(user_id)
        return jsonify({
            "success": True,
            "message": message,
            "user": full_profile or {"id": user_id, "username": username, "email": email.lower()},
        })
    return jsonify({"success": False, "message": message}), 400


@auth_bp.route("/api/login", methods=["POST"])
def api_login():
    data     = request.get_json(silent=True) or request.form
    email    = data.get("email",    "").strip()
    password = data.get("password", "").strip()

    user = authenticate_user(email, password)
    if user:
        session["user_id"]  = user["id"]
        session["username"] = user["username"]
        session["email"]    = user["email"]
        session["is_admin"] = bool(user.get("is_admin"))
        full_profile = get_user_profile(user["id"])
        if full_profile:
            session["is_admin"] = bool(full_profile.get("is_admin"))
        return jsonify({"success": True, "message": "Login successful!", "user": full_profile or user})
    return jsonify({"success": False, "message": "Invalid email address or password."}), 401


@auth_bp.route("/api/logout", methods=["POST"])
def api_logout():
    session.clear()
    return jsonify({"success": True, "message": "Logged out successfully."})


@auth_bp.route("/api/me", methods=["GET"])
def api_me():
    if "user_id" not in session:
        return jsonify({"authenticated": False})

    profile = get_user_profile(session["user_id"])
    if not profile:
        session.clear()
        return jsonify({"authenticated": False})

    session["is_admin"] = bool(profile.get("is_admin"))

    return jsonify({
        "authenticated": True,
        "user": profile,
    })


@auth_bp.route("/api/firebase-login", methods=["POST"])
@auth_bp.route("/api/v1/auth/session", methods=["POST"])
def api_firebase_login():
    data     = request.get_json(silent=True) or {}
    id_token = data.get("idToken", "").strip()

    if not id_token:
        return jsonify({"success": False, "message": "No authentication token provided."}), 400

    decoded = None

    # 1. Try Firebase Admin SDK verification if initialized
    if HAS_FIREBASE:
        try:
            decoded = fb_auth.verify_id_token(id_token)
        except Exception as e:
            print(f"[Firebase Admin Verify Notice]: {e}")

    # 2. Fallback: Verify directly via Google OAuth TokenInfo public service
    if not decoded:
        try:
            import urllib.request
            import json
            url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
            req = urllib.request.Request(url, headers={"User-Agent": "LiverAI-Auth/1.0"})
            with urllib.request.urlopen(req, timeout=8) as resp:
                if resp.status == 200:
                    info = json.loads(resp.read().decode("utf-8"))
                    email = info.get("email")
                    if email:
                        decoded = {
                            "uid": info.get("sub") or info.get("user_id") or email,
                            "email": email,
                            "name": info.get("name") or info.get("email", "").split("@")[0],
                            "firebase": {"sign_in_provider": "google.com"}
                        }
        except Exception as _g_err:
            print(f"[Google TokenInfo Verify Error]: {_g_err}")

    if not decoded:
        return jsonify({"success": False, "message": "Authentication token verification failed."}), 401

    firebase_uid = decoded.get("uid", "")
    email        = (decoded.get("email") or f"{firebase_uid}@firebase.user").lower().strip()
    display_name = decoded.get("name") or decoded.get("display_name") or email.split("@")[0]
    provider     = decoded.get("firebase", {}).get("sign_in_provider", "google")

    user_id, username = upsert_firebase_user(email, display_name)

    session["user_id"]  = user_id
    session["username"] = username
    session["email"]    = email

    full_profile = get_user_profile(user_id)
    if full_profile:
        session["is_admin"] = bool(full_profile.get("is_admin"))

    return jsonify({
        "success": True,
        "message": f"Signed in with {provider}!",
        "user":    full_profile or {"id": user_id, "username": username, "email": email},
    })


@auth_bp.route("/api/guest-login", methods=["POST"])
def api_guest_login():
    import uuid
    guest_id = f"guest_{uuid.uuid4().hex[:8]}"
    guest_email = f"{guest_id}@guest.liverai.health"
    guest_name = "Guest Evaluator"

    user_id, username = upsert_firebase_user(guest_email, guest_name)

    session["user_id"]  = user_id
    session["username"] = username
    session["email"]    = guest_email
    session["is_guest"] = True

    return jsonify({
        "success": True,
        "message": "Welcome to LiverAI in Guest Mode!",
        "user": {
            "id": user_id,
            "username": username,
            "email": guest_email,
            "role": "Guest Evaluator",
            "is_guest": True
        }
    })


