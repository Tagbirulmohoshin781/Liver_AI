"""
routes/admin_routes.py
========================
System-wide admin dashboard, user table, message stream, and admin actions.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from flask import Blueprint, jsonify, session, request
from src.db import (
    get_all_users, get_admin_user_history, get_all_users_history,
    get_admin_dashboard_stats, delete_user, admin_update_user,
    admin_reset_password, admin_toggle_admin_role, admin_delete_message,
    admin_clear_user_history, admin_purge_all_history, admin_get_system_metrics,
    get_user_profile
)

admin_bp = Blueprint("admin", __name__)


def _is_admin():
    user_id = session.get("user_id")
    if not user_id:
        return False
    if session.get("is_admin"):
        return True
    try:
        profile = get_user_profile(user_id)
        if profile and profile.get("is_admin"):
            session["is_admin"] = True
            return True
    except Exception as e:
        print(f"[_is_admin check notice] {e}")
    return False


@admin_bp.route("/api/admin/stats", methods=["GET"])
def api_admin_stats():
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    stats = get_admin_dashboard_stats()
    return jsonify({"success": True, "stats": stats})


@admin_bp.route("/api/admin/system/status", methods=["GET"])
def api_admin_system_status():
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    
    metrics = admin_get_system_metrics()
    
    # Check PyTorch Vision status
    try:
        from src.vision_inference import get_vision_engine_status
        vision_info = get_vision_engine_status()
    except Exception:
        vision_info = {"status": "available", "engine": "EfficientNet-B0"}

    # Check Vector Index / Pinecone status
    try:
        from src.llm_pipeline import get_pipeline_status
        pipeline_info = get_pipeline_status()
    except Exception:
        pipeline_info = {"status": "active", "model": "Gemini 2.5 Flash", "rag": "Pinecone AASLD Index"}

    return jsonify({
        "success": True,
        "metrics": metrics,
        "vision": vision_info,
        "pipeline": pipeline_info
    })


@admin_bp.route("/api/admin/users", methods=["GET"])
def api_admin_users():
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    users = get_all_users()
    return jsonify({"success": True, "users": users})


@admin_bp.route("/api/admin/user/<int:uid>/profile", methods=["GET"])
def api_admin_get_user_profile(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    profile = get_user_profile(uid)
    if not profile:
        return jsonify({"success": False, "message": "User not found."}), 404
    return jsonify({"success": True, "user": profile})


@admin_bp.route("/api/admin/user/<int:uid>/update", methods=["POST"])
def api_admin_update_user_route(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    age = data.get("age")
    gender = data.get("gender")
    medical_notes = data.get("medical_notes")
    is_admin = data.get("is_admin")

    if not username or not email:
        return jsonify({"success": False, "message": "Username and email are required."}), 400

    ok, msg = admin_update_user(uid, username, email, age, gender, medical_notes, is_admin)
    return jsonify({"success": ok, "message": msg})


@admin_bp.route("/api/admin/user/<int:uid>/reset-password", methods=["POST"])
def api_admin_reset_password_route(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    data = request.get_json(silent=True) or {}
    new_password = data.get("new_password", "").strip()
    if not new_password:
        return jsonify({"success": False, "message": "New password is required."}), 400
    ok, msg = admin_reset_password(uid, new_password)
    return jsonify({"success": ok, "message": msg})


@admin_bp.route("/api/admin/user/<int:uid>/toggle-role", methods=["POST"])
def api_admin_toggle_role_route(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    if uid == session.get("user_id"):
        return jsonify({"success": False, "message": "Cannot toggle your own admin status."}), 400
    ok, msg, is_admin = admin_toggle_admin_role(uid)
    return jsonify({"success": ok, "message": msg, "is_admin": is_admin})


@admin_bp.route("/api/admin/all-history", methods=["GET"])
def api_admin_all_history():
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    history = get_all_users_history()
    return jsonify({"success": True, "history": history})


@admin_bp.route("/api/admin/user/<int:uid>/history", methods=["GET"])
def api_admin_user_history(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    history = get_admin_user_history(uid)
    return jsonify({"success": True, "history": history})


@admin_bp.route("/api/admin/user/<int:uid>/clear-history", methods=["DELETE"])
def api_admin_clear_user_history_route(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    ok, msg = admin_clear_user_history(uid)
    return jsonify({"success": ok, "message": msg})


@admin_bp.route("/api/admin/message/<int:mid>", methods=["DELETE"])
def api_admin_delete_message_route(mid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    ok, msg = admin_delete_message(mid)
    return jsonify({"success": ok, "message": msg})


@admin_bp.route("/api/admin/system/purge-history", methods=["POST"])
def api_admin_purge_history_route():
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    data = request.get_json(silent=True) or {}
    days = data.get("days")
    ok, msg = admin_purge_all_history(days)
    return jsonify({"success": ok, "message": msg})


@admin_bp.route("/api/admin/user/<int:uid>/delete", methods=["DELETE"])
def api_admin_delete_user(uid):
    if not _is_admin():
        return jsonify({"success": False, "message": "Admin access required."}), 403
    if uid == session.get("user_id"):
        return jsonify({"success": False, "message": "Cannot delete your own admin account."}), 400
    delete_user(uid)
    return jsonify({"success": True, "message": f"User {uid} deleted by admin."})

