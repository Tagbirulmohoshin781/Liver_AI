import os
import hashlib
import json

MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models")
MANIFEST_PATH = os.path.join(MODELS_DIR, "manifest.json")

def get_file_info(rel_path):
    full_path = os.path.join(MODELS_DIR, rel_path)
    if not os.path.exists(full_path):
        return None
    
    sha256 = hashlib.sha256()
    with open(full_path, "rb") as f:
        while chunk := f.read(8192):
            sha256.update(chunk)
            
    return {
        "file": rel_path.replace("\\", "/"),
        "sha256": sha256.hexdigest(),
        "size_bytes": os.path.getsize(full_path)
    }

files_to_index = [
    ("lpd_scaler.pkl", "StandardScaler for 10-biomarker LPD risk normalization"),
    ("lpd_imputer.pkl", "SimpleImputer for missing numeric biomarker feature values"),
    ("lpd_outlier_bounds.json", "Clinical upper/lower outlier capping thresholds"),
    ("lpd_metadata.json", "LPD dataset metadata and training parameters"),
    ("liver_vision/best_model.pth", "PyTorch EfficientNet-B0 fine-tuned multi-label histology classifier"),
    ("liver_vision/model_config.json", "Histology vision classifier decision thresholds and metrics")
]

artifacts = []
for rel_path, desc in files_to_index:
    info = get_file_info(rel_path)
    if info:
        info["description"] = desc
        artifacts.append(info)

manifest = {
    "version": "1.0.0",
    "updated_at": "2026-08-27T23:20:00Z",
    "artifacts": artifacts
}

with open(MANIFEST_PATH, "w") as f:
    json.dump(manifest, f, indent=2)

print(f"Generated manifest with {len(artifacts)} model artifacts.")
