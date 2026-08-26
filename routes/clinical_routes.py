"""
routes/clinical_routes.py
===========================
Clinical LPD risk prediction model and vision histology model status.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import json
from flask import Blueprint, request, jsonify
from src.prediction import predict_liver_disease, models_available

clinical_bp = Blueprint("clinical", __name__)


@clinical_bp.route("/api/predict", methods=["POST"])
def api_predict():
    enabled = os.getenv("ENABLE_EXPERIMENTAL_CLINICAL_SCORE", "true").lower() == "true"
    if not enabled:
        return jsonify({
            "success": False,
            "code": "FEATURE_DISABLED",
            "message": "Experimental clinical score calculator is disabled in this environment."
        }), 403

    data = request.get_json(silent=True) or {}
    required = [
        "age", "gender", "total_bilirubin", "direct_bilirubin",
        "alkaline_phosphotase", "sgpt", "sgot",
        "total_proteins", "albumin", "ag_ratio",
    ]
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({
            "success": False,
            "message": f"Missing required fields: {', '.join(missing)}",
        }), 400

    try:
        result = predict_liver_disease(data)
        return jsonify({"success": True, "result": result})
    except Exception as e:
        print(f"[Prediction Error] {e}")
        return jsonify({"success": False, "message": f"Prediction failed: {e}"}), 500


@clinical_bp.route("/api/predict/status", methods=["GET"])
def api_predict_status():
    enabled = os.getenv("ENABLE_EXPERIMENTAL_CLINICAL_SCORE", "true").lower() == "true"
    return jsonify({
        "available": models_available() and enabled,
        "enabled": enabled,
        "mode": "experimental_heuristic"
    })


@clinical_bp.route("/vision_status", methods=["GET"])
def vision_status():
    weights_path = os.path.join("models", "liver_vision", "best_model.pth")
    config_path  = os.path.join("models", "liver_vision", "model_config.json")
    ready   = os.path.exists(weights_path)
    sim_allowed = os.getenv("ENABLE_VISION_SIMULATION", "false").lower() == "true"
    
    if ready:
        mode = "production"
    elif sim_allowed:
        mode = "simulation"
    else:
        mode = "disabled"

    metrics = None
    if ready and os.path.exists(config_path):
        try:
            with open(config_path) as f:
                cfg     = json.load(f)
                metrics = cfg.get("test_metrics", {}).get("overall")
        except Exception:
            pass
    return jsonify({"ready": ready, "mode": mode, "metrics": metrics})

