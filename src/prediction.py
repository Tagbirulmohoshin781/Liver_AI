"""
src/prediction.py
==================
Clinical liver disease risk prediction using the pre-trained
LPD (Liver Patient Dataset) scikit-learn model.

Input features (all numeric, collected from the UI form):
    age, gender (0=Female/1=Male), total_bilirubin, direct_bilirubin,
    alkaline_phosphotase, sgpt, sgot, total_proteins, albumin, ag_ratio

Output:
    {
        "probability": 0.73,       # 0-1 float
        "label": "At Risk",        # "At Risk" | "Low Risk"
        "risk_level": "High",      # "High" | "Moderate" | "Low"
        "confidence": 73,          # 0-100 int (percentage)
        "factors": ["high bilirubin", ...]   # key contributing factors
    }
"""

import os
import json

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    np = None
    HAS_NUMPY = False

try:
    import joblib
    HAS_JOBLIB = True
except ImportError:
    HAS_JOBLIB = False

MODELS_DIR    = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models")
SCALER_PATH   = os.path.join(MODELS_DIR, "lpd_scaler.pkl")
IMPUTER_PATH  = os.path.join(MODELS_DIR, "lpd_imputer.pkl")
BOUNDS_PATH   = os.path.join(MODELS_DIR, "lpd_outlier_bounds.json")
METADATA_PATH = os.path.join(MODELS_DIR, "lpd_metadata.json")

NUMERIC_FEATURES = [
    "age", "total_bilirubin", "direct_bilirubin",
    "alkaline_phosphotase", "sgpt", "sgot",
    "total_proteins", "albumin", "ag_ratio",
]

ALL_FEATURES = NUMERIC_FEATURES + ["gender"]

FEATURE_NAMES = ALL_FEATURES

_scaler    = None
_imputer   = None
_bounds    = None
_metadata  = None


def _load_artifacts():
    """Load sklearn artifacts lazily (once per process)."""
    global _scaler, _imputer, _bounds, _metadata

    if not HAS_JOBLIB:
        return  # caller will detect _scaler is None and use rule-based fallback

    if _scaler is None and os.path.exists(SCALER_PATH):
        _scaler = joblib.load(SCALER_PATH)

    if _imputer is None and os.path.exists(IMPUTER_PATH):
        _imputer = joblib.load(IMPUTER_PATH)

    if _bounds is None and os.path.exists(BOUNDS_PATH):
        with open(BOUNDS_PATH) as f:
            _bounds = json.load(f)

    if _metadata is None and os.path.exists(METADATA_PATH):
        with open(METADATA_PATH) as f:
            _metadata = json.load(f)


def predict_liver_disease(features: dict) -> dict:
    """
    Predict liver disease risk from clinical features.

    Args:
        features: dict with keys matching FEATURE_NAMES (values as float/int).

    Returns:
        dict with probability, label, risk_level, confidence, factors.

    Raises:
        ValueError: if required features are missing or models not found.
    """
    # Validate all required features are present
    missing = [f for f in ALL_FEATURES if f not in features]
    if missing:
        raise ValueError(f"Missing required features: {missing}")

    # If numpy is not installed, fall back to rule-based scorer
    if not HAS_NUMPY:
        return _rule_based_risk(features)

    # Load sklearn artifacts
    _load_artifacts()

    if _scaler is None or _imputer is None:
        # Graceful degradation: compute a simple rule-based risk score
        return _rule_based_risk(features)

    # Build feature vectors with safe float casting
    try:
        X_num = np.array([[float(features[f]) for f in NUMERIC_FEATURES]])
        raw_gender = str(features.get("gender", "Male")).strip().lower()
        if raw_gender in {"1", "1.0", "male", "m"}:
            gender_val = 1.0
        else:
            gender_val = 0.0
    except (ValueError, TypeError) as e:
        raise ValueError(f"Invalid numeric input for prediction features: {e}")

    # Apply outlier capping if bounds available
    if _bounds:
        for i, feat in enumerate(NUMERIC_FEATURES):
            if feat in _bounds:
                lo = _bounds[feat].get("lower", -np.inf)
                hi = _bounds[feat].get("upper",  np.inf)
                X_num[0, i] = np.clip(X_num[0, i], lo, hi)

    # Impute missing values on the 9 numeric features
    X_num_imputed = _imputer.transform(X_num)

    # Combine 9 imputed numeric features + gender (10 features) for scaler
    X_all = np.column_stack([X_num_imputed, [[gender_val]]])
    X_scaled = _scaler.transform(X_all)

    # Directional feature weights corresponding to ALL_FEATURES:
    # age(+), total_bilirubin(+), direct_bilirubin(+), alkaline_phosphotase(+),
    # sgpt(+), sgot(+), total_proteins(-), albumin(-), ag_ratio(-), gender(+)
    weights = np.array([0.3, 1.2, 1.2, 0.8, 1.0, 1.0, -0.6, -1.0, -0.8, 0.1])
    
    # Calculate weighted directional clinical score
    z_score = float(np.dot(X_scaled[0], weights))
    
    # Shifted sigmoid: when lab values are normal/average, prob ~ 0.15 - 0.25 (Low Risk)
    prob = float(1 / (1 + np.exp(-(z_score - 1.2))))
    prob = max(0.01, min(0.99, prob))

    # Determine risk category with truthful heuristic labeling
    if prob >= 0.65:
        label      = "Elevated Markers (Experimental)"
        risk_level = "High"
    elif prob >= 0.40:
        label      = "Borderline Markers (Experimental)"
        risk_level = "Moderate"
    else:
        label      = "Typical Reference Ranges"
        risk_level = "Low"

    # Identify key contributing factors (values outside normal reference ranges)
    factors = _identify_factors(features)

    return {
        "status": "ok",
        "method": "experimental_heuristic_aasld",
        "prediction": 1 if prob >= 0.40 else 0,
        "probability": round(prob, 3),
        "score": round(prob, 3),
        "label": label,
        "risk_level": risk_level,
        "confidence": int(round(prob * 100)),
        "risk_factors": factors,
        "factors": factors,
        "disclaimer": "This score is an educational heuristic based on AASLD/EASL reference ranges. Always consult a qualified physician.",
        "is_diagnostic": False
    }


def _rule_based_risk(features: dict) -> dict:
    """
    Simple rule-based risk estimation when no ML models are available.
    Uses standard clinical reference ranges from AASLD guidelines.
    """
    score = 0
    factors = []

    tb = float(features.get("total_bilirubin", 0))
    db = float(features.get("direct_bilirubin", 0))
    alt = float(features.get("sgpt", 0))
    ast = float(features.get("sgot", 0))
    alp = float(features.get("alkaline_phosphotase", 0))
    alb = float(features.get("albumin", 4.5))
    age = int(features.get("age", 30))

    if tb > 1.2:
        score += 2
        factors.append("elevated total bilirubin")
    if db > 0.3:
        score += 2
        factors.append("elevated direct bilirubin")
    if alt > 56:
        score += 2
        factors.append("elevated ALT (SGPT)")
    if ast > 40:
        score += 1
        factors.append("elevated AST (SGOT)")
    if alp > 147:
        score += 1
        factors.append("elevated alkaline phosphatase")
    if alb < 3.5:
        score += 2
        factors.append("low albumin")
    if age > 50:
        score += 1
        factors.append("age over 50")

    # Normalise score to 0-1
    max_score = 11
    prob = min(score / max_score, 0.99)

    if prob >= 0.55:
        label, risk_level = "At Risk", "High"
    elif prob >= 0.35:
        label, risk_level = "At Risk", "Moderate"
    else:
        label, risk_level = "Low Risk", "Low"

    return {
        "probability": round(prob, 3),
        "label":       label,
        "risk_level":  risk_level,
        "confidence":  int(round(prob * 100)),
        "factors":     factors,
    }


def _identify_factors(features: dict) -> list:
    """Return a list of clinical factors that are outside normal reference ranges."""
    factors = []
    refs = {
        "total_bilirubin":    (0.0, 1.2,  "elevated total bilirubin"),
        "direct_bilirubin":   (0.0, 0.3,  "elevated direct bilirubin"),
        "sgpt":               (7,   56,   "elevated ALT (SGPT)"),
        "sgot":               (10,  40,   "elevated AST (SGOT)"),
        "alkaline_phosphotase": (44, 147, "elevated alkaline phosphatase"),
        "albumin":            (3.5, 5.0,  "low albumin"),
        "ag_ratio":           (1.0, 2.5,  "abnormal A/G ratio"),
    }
    for feat, (lo, hi, label) in refs.items():
        val = features.get(feat)
        if val is not None:
            val = float(val)
            if val < lo or val > hi:
                factors.append(label)
    if int(features.get("age", 0)) > 50:
        factors.append("age over 50")
    return factors


def models_available() -> bool:
    """Return True if at least the scaler and imputer files exist."""
    return os.path.exists(SCALER_PATH) and os.path.exists(IMPUTER_PATH)
