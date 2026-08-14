"""
routes/profile_routes.py
=========================
User profile stats, medical profile updates, and settings routes.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import json
from flask import Blueprint, request, jsonify, session
from src.db import (
    get_user_stats, update_username, update_password, delete_user,
    get_user_profile, update_medical_profile, update_user_settings, get_guest_user_id
)

profile_bp = Blueprint("profile", __name__)


@profile_bp.route("/api/user/stats", methods=["GET"])
def api_user_stats():
    user_id = session.get("user_id") or get_guest_user_id()
    stats = get_user_stats(user_id)
    return jsonify({"success": True, "stats": stats})


@profile_bp.route("/api/user/medical-profile", methods=["POST"])
def api_update_medical_profile():
    user_id = session.get("user_id") or get_guest_user_id()

    data = request.get_json(silent=True) or request.form or {}
    age = data.get("age")
    gender = data.get("gender")
    medical_notes = data.get("medical_notes")

    ok, message = update_medical_profile(user_id, age, gender, medical_notes)
    if ok:
        profile = get_user_profile(user_id)
        return jsonify({"success": True, "message": message, "profile": profile})
    return jsonify({"success": False, "message": message}), 400


@profile_bp.route("/api/user/settings", methods=["GET", "POST"])
def api_user_settings_route():
    user_id = session.get("user_id") or get_guest_user_id()

    if request.method == "POST":
        data = request.get_json(silent=True) or {}
        settings_str = json.dumps(data)
        ok, message = update_user_settings(user_id, settings_str)
        return jsonify({"success": ok, "message": message})

    # GET
    profile = get_user_profile(user_id)
    settings = {}
    if profile and profile.get("settings_json"):
        try:
            settings = json.loads(profile["settings_json"])
        except Exception:
            settings = {}
    return jsonify({"success": True, "settings": settings})


@profile_bp.route("/api/user/update-name", methods=["POST"])
def api_update_name():
    user_id = session.get("user_id")
    if not user_id:
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    data         = request.get_json(silent=True) or {}
    new_username = data.get("username", "").strip()
    ok, message  = update_username(user_id, new_username)
    if ok:
        session["username"] = new_username
        return jsonify({"success": True, "message": message, "username": new_username})
    return jsonify({"success": False, "message": message}), 400


@profile_bp.route("/api/user/update-password", methods=["POST"])
def api_update_password():
    user_id = session.get("user_id")
    if not user_id:
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    data        = request.get_json(silent=True) or {}
    old_pw      = data.get("old_password", "")
    new_pw      = data.get("new_password", "")
    ok, message = update_password(user_id, old_pw, new_pw)
    if ok:
        return jsonify({"success": True, "message": message})
    return jsonify({"success": False, "message": message}), 400


@profile_bp.route("/api/user/delete-account", methods=["DELETE"])
def api_delete_account():
    user_id = session.get("user_id")
    if not user_id:
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    delete_user(user_id)
    session.clear()
    return jsonify({"success": True, "message": "Account permanently deleted."})
