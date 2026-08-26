import os
import json

try:
    import torch
    import torch.nn as nn
    from torchvision import transforms
    HAS_TORCH = True
except ImportError:
    torch = None
    nn = None
    transforms = None
    HAS_TORCH = False

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    Image = None
    HAS_PIL = False

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LABELS = ["ballooning", "fibrosis", "inflammation", "steatosis"]

def build_efficientnet_head(num_classes: int = 4):
    """Rebuilds the custom head matching train_vision_model.py."""
    if not HAS_TORCH:
        return None
    import torchvision.models as models
    # Initialize without weights first
    model = models.efficientnet_b0(weights=None)
    in_features = model.classifier[1].in_features
    model.classifier = nn.Sequential(
        nn.Dropout(p=0.3),
        nn.Linear(in_features, 256),
        nn.ReLU(inplace=True),
        nn.Dropout(p=0.2),
        nn.Linear(256, num_classes)
    )
    return model

def predict_image(image_path: str):
    """
    Run multi-label classification on a liver biopsy patch image.
    If trained weights exist in models/liver_vision/best_model.pth and PyTorch is available,
    it runs PyTorch inference. Otherwise, it gracefully falls back to deterministic simulation mode.
    """
    if not os.path.exists(image_path):
        return {
            "success": False,
            "error": f"Image file not found: {image_path}"
        }

    weights_path = os.path.join(BASE_DIR, "models", "liver_vision", "best_model.pth")
    config_path = os.path.join(BASE_DIR, "models", "liver_vision", "model_config.json")

    # ── Check if trained model weights exist and PyTorch is available ────────
    if HAS_TORCH and HAS_PIL and os.path.exists(weights_path):
        try:
            device = torch.device("cuda" if (torch and torch.cuda.is_available()) else "cpu")
            model = build_efficientnet_head(4)
            if model is not None:
                try:
                    state_dict = torch.load(weights_path, map_location=device, weights_only=True)
                except Exception:
                    state_dict = torch.load(weights_path, map_location=device, weights_only=False)
                model.load_state_dict(state_dict)
                model.to(device)
                model.eval()

                # Load config to get thresholds
                thresholds = {l: 0.5 for l in LABELS}
                if os.path.exists(config_path):
                    try:
                        with open(config_path, "r") as f:
                            cfg = json.load(f)
                            threshold = cfg.get("threshold", 0.5)
                            thresholds = {l: threshold for l in LABELS}
                    except Exception:
                        pass

                # Preprocess image
                img = Image.open(image_path).convert("RGB")
                transform = transforms.Compose([
                    transforms.Resize((224, 224)),
                    transforms.ToTensor(),
                    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
                ])
                tensor = transform(img).unsqueeze(0).to(device)

                # Predict
                with torch.no_grad():
                    logits = model(tensor)
                    probs = torch.sigmoid(logits).squeeze().cpu().tolist()

                predictions = {}
                for i, label in enumerate(LABELS):
                    prob = probs[i]
                    predictions[label] = {
                        "probability": round(prob * 100, 1),
                        "positive": prob >= thresholds[label]
                    }

                return {
                    "success": True,
                    "mode": "production",
                    "predictions": predictions
                }
        except Exception as e:
            print(f"[Vision Warning] PyTorch inference failed ({e}). Falling back to simulation mode.")

    # ── Production gate: refuse simulation ───────────────────────────────────
    _app_env = os.getenv("APP_ENV", "development").lower()
    _sim_allowed = os.getenv("ENABLE_VISION_SIMULATION", "false").lower() == "true"

    if _app_env == "production" and _sim_allowed:
        # Explicitly refuse simulation flag in production
        return {
            "success": False,
            "error": "ENABLE_VISION_SIMULATION is not permitted in APP_ENV=production.",
            "code": "CONFIG_ERROR"
        }

    if not _sim_allowed:
        return {
            "success": False,
            "error": "Vision inference model unavailable.",
            "code": "MODEL_UNAVAILABLE",
            "message": "Histology classification requires a trained model. Please contact support."
        }

    # ── Simulation mode (development/testing only, ENABLE_VISION_SIMULATION=true) ─
    try:
        import hashlib
        with open(image_path, "rb") as f:
            img_bytes = f.read()
        h = hashlib.md5(img_bytes).hexdigest()
        scores = [
            (int(h[0:4], 16) % 100) / 100.0,
            (int(h[4:8], 16) % 100) / 100.0,
            (int(h[8:12], 16) % 100) / 100.0,
            (int(h[12:16], 16) % 100) / 100.0
        ]
    except Exception:
        sz = os.path.getsize(image_path) if os.path.exists(image_path) else 1000
        scores = [
            ((sz * 3) % 100) / 100.0,
            ((sz * 7) % 100) / 100.0,
            ((sz * 11) % 100) / 100.0,
            ((sz * 17) % 100) / 100.0
        ]

    predictions = {}
    for i, label in enumerate(LABELS):
        prob = scores[i]
        predictions[label] = {
            "probability": round(prob * 100, 1),
            "positive": prob >= 0.5
        }

    return {
        "success": True,
        "mode": "simulation",
        "predictions": predictions,
        "warning": "SIMULATION MODE — results are deterministic test fixtures, not real inference."
    }
