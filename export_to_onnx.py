import os
import sys
import json

# Ensure UTF-8 output on Windows
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

import torch
import torch.nn as nn
import torchvision.models as models

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
WEIGHTS_PATH = os.path.join(BASE_DIR, "models", "liver_vision", "best_model.pth")
OUTPUT_DIR = os.path.join(BASE_DIR, "Liver Disease Detection App", "assets", "models")
OUTPUT_ONNX = os.path.join(OUTPUT_DIR, "liver_vision.onnx")
OUTPUT_META = os.path.join(OUTPUT_DIR, "model_meta.json")

os.makedirs(OUTPUT_DIR, exist_ok=True)

class LiverVisionModel(nn.Module):
    def __init__(self, num_classes=4):
        super().__init__()
        self.backbone = models.efficientnet_b0(weights=None)
        in_features = self.backbone.classifier[1].in_features
        self.backbone.classifier = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(in_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes)
        )
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        logits = self.backbone(x)
        probs = self.sigmoid(logits)
        return probs

def export():
    print(f"Loading weights from {WEIGHTS_PATH}...")
    model = LiverVisionModel(num_classes=4)
    state_dict = torch.load(WEIGHTS_PATH, map_location="cpu", weights_only=False)
    
    # Load weights
    model.backbone.load_state_dict(state_dict)
    model.eval()
    
    dummy_input = torch.randn(1, 3, 224, 224, dtype=torch.float32)
    
    print(f"Exporting to ONNX at {OUTPUT_ONNX}...")
    try:
        # Export with dynamo=False for robust direct export
        torch.onnx.export(
            model,
            dummy_input,
            OUTPUT_ONNX,
            export_params=True,
            opset_version=18,
            do_constant_folding=True,
            input_names=["input"],
            output_names=["probabilities"],
            dynamo=False
        )
    except TypeError:
        torch.onnx.export(
            model,
            dummy_input,
            OUTPUT_ONNX,
            export_params=True,
            opset_version=18,
            do_constant_folding=True,
            input_names=["input"],
            output_names=["probabilities"]
        )
    
    print("ONNX export completed successfully!")
    
    # Test with ONNX Runtime to verify
    import onnxruntime as ort
    import numpy as np
    
    session = ort.InferenceSession(OUTPUT_ONNX)
    test_arr = np.random.randn(1, 3, 224, 224).astype(np.float32)
    outputs = session.run(None, {"input": test_arr})
    print(f"Verified ONNX Runtime execution! Test output shape: {outputs[0].shape}, values: {outputs[0]}")
    
    meta = {
        "model_name": "LiverVision_EfficientNetB0",
        "format": "ONNX",
        "input_name": "input",
        "output_name": "probabilities",
        "input_shape": [1, 3, 224, 224],
        "input_mean": [0.485, 0.456, 0.406],
        "input_std": [0.229, 0.224, 0.225],
        "labels": [
            {
                "id": "ballooning",
                "name": "Hepatocyte Ballooning",
                "description": "Cellular swelling & degeneration",
                "threshold": 0.50
            },
            {
                "id": "fibrosis",
                "name": "Tissue Fibrosis",
                "description": "Connective tissue scarring & expansion",
                "threshold": 0.50
            },
            {
                "id": "inflammation",
                "name": "Lobular Inflammation",
                "description": "Inflammatory cellular aggregates",
                "threshold": 0.50
            },
            {
                "id": "steatosis",
                "name": "Hepatic Steatosis",
                "description": "Intracellular fat droplet accumulation",
                "threshold": 0.50
            }
        ]
    }
    
    with open(OUTPUT_META, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print(f"Metadata written to {OUTPUT_META}")

if __name__ == "__main__":
    export()
