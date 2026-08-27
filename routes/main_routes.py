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
        "apiKey":            os.environ.get("FIREBASE_API_KEY", "AIzaSyCdbYO2g75yW8JS9FLffJmdhSHjIJM8BYI"),
        "authDomain":        os.environ.get("FIREBASE_AUTH_DOMAIN", "liver-ai-medical-assistant.firebaseapp.com"),
        "projectId":         os.environ.get("FIREBASE_PROJECT_ID", "liver-ai-medical-assistant"),
        "storageBucket":     os.environ.get("FIREBASE_STORAGE_BUCKET", "liver-ai-medical-assistant.appspot.com"),
        "messagingSenderId": os.environ.get("FIREBASE_MESSAGING_SENDER_ID", "528254457830"),
        "appId":             os.environ.get("FIREBASE_APP_ID", "1:528254457830:web:c2966559abb2c443f4a827"),
    }
    has_firebase = bool(firebase_config.get("apiKey"))
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


@main_bp.route("/favicon.ico")
@main_bp.route("/favicon.svg")
def favicon():
    return send_from_directory("static", "favicon.svg", mimetype="image/svg+xml")

