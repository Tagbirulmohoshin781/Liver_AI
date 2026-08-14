"""
routes/main_routes.py
======================
Main view routes, PWA manifest, and service worker endpoints.
"""

import os
from flask import Blueprint, render_template, send_from_directory, jsonify

main_bp = Blueprint("main", __name__)


@main_bp.route("/")
def index():
    firebase_config = {
        "apiKey":            os.environ.get("FIREBASE_API_KEY", ""),
        "authDomain":        os.environ.get("FIREBASE_AUTH_DOMAIN", ""),
        "projectId":         os.environ.get("FIREBASE_PROJECT_ID", ""),
        "storageBucket":     os.environ.get("FIREBASE_STORAGE_BUCKET", ""),
        "messagingSenderId": os.environ.get("FIREBASE_MESSAGING_SENDER_ID", ""),
        "appId":             os.environ.get("FIREBASE_APP_ID", ""),
    }
    has_firebase = bool(os.environ.get("FIREBASE_PROJECT_ID"))
    return render_template(
        "chat.html",
        firebase_config=firebase_config,
        has_firebase=has_firebase,
    )


@main_bp.route("/manifest.json")
def manifest():
    return send_from_directory("static", "manifest.json", mimetype="application/json")


@main_bp.route("/sw.js")
def service_worker():
    response = send_from_directory("static", "sw.js", mimetype="application/javascript")
    response.headers["Cache-Control"] = "no-cache"
    return response
