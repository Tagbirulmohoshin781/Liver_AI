"""
train_vision_model.py
=====================
Trains a multi-label image classification model for liver biopsy histology grading.

Task:
    Given a liver biopsy patch image, predict the presence (0/1) of 4 pathological features:
      - Ballooning   (hepatocyte ballooning degeneration)
      - Fibrosis     (liver tissue scarring)
      - Inflammation (lobular inflammation)
      - Steatosis    (fat accumulation)

Dataset:
    Data/train/  Data/valid/  Data/test/
    Each folder has a _classes.csv with columns:
      filename, ballooning, fibrosis, inflammation, steatosis

Model:
    EfficientNet-B0 pretrained on ImageNet.
    Phase 1  -- train head only (backbone frozen).
    Phase 2  -- unfreeze all, fine-tune with differential LR.

Output:
    models/liver_vision/best_model.pth
    models/liver_vision/training_history.json
    models/liver_vision/model_config.json

Usage:
    python train_vision_model.py
    python train_vision_model.py --epochs 20 --batch_size 16
    python train_vision_model.py --model resnet50 --epochs 15
    python train_vision_model.py --dry_run
"""

import os
import sys
import json
import time
import argparse
import warnings
from datetime import datetime

warnings.filterwarnings("ignore")

# ── Constants ─────────────────────────────────────────────────────────────────
LABELS = ["ballooning", "fibrosis", "inflammation", "steatosis"]
NUM_CLASSES = len(LABELS)


# ── CLI ───────────────────────────────────────────────────────────────────────
def parse_args():
    p = argparse.ArgumentParser(description="Train liver histology multi-label classifier")
    p.add_argument("--train_dir",        default="Data/train",          help="Training images dir")
    p.add_argument("--valid_dir",        default="Data/valid",          help="Validation images dir")
    p.add_argument("--test_dir",         default="Data/test",           help="Test images dir")
    p.add_argument("--output_dir",       default="models/liver_vision", help="Output directory")
    p.add_argument("--model",            default="efficientnet_b0",     help="efficientnet_b0 | resnet50 | resnet34 | mobilenet_v3_small")
    p.add_argument("--img_size",         type=int,   default=224,       help="Input image size")
    p.add_argument("--epochs",           type=int,   default=15,        help="Phase-1 epochs (head)")
    p.add_argument("--fine_tune_epochs", type=int,   default=10,        help="Phase-2 epochs (all layers)")
    p.add_argument("--batch_size",       type=int,   default=16,        help="Batch size")
    p.add_argument("--lr",               type=float, default=1e-3,      help="Learning rate")
    p.add_argument("--threshold",        type=float, default=0.5,       help="Sigmoid threshold for binary pred")
    p.add_argument("--dry_run",          action="store_true",           help="Check data/model only, no training")
    return p.parse_args()


# ── Dependency check ──────────────────────────────────────────────────────────
def check_imports():
    errors = []
    for pkg, imp in [("torch", "torch"), ("torchvision", "torchvision"),
                     ("Pillow", "PIL"), ("scikit-learn", "sklearn")]:
        try:
            __import__(imp)
        except ImportError:
            errors.append(pkg)
    if errors:
        print("[ERROR] Missing packages. Install with:")
        print(f"  pip install {' '.join(errors)}")
        sys.exit(1)


# ── Device ────────────────────────────────────────────────────────────────────
def get_device():
    import torch
    if torch.cuda.is_available():
        name = torch.cuda.get_device_name(0)
        mem  = torch.cuda.get_device_properties(0).total_memory / 1e9
        print(f"[GPU] {name} ({mem:.1f} GB VRAM)")
        return torch.device("cuda")
    print("[CPU] No GPU detected -- training on CPU (will be slow).")
    return torch.device("cpu")


# ── Dataset ───────────────────────────────────────────────────────────────────
def load_csv(data_dir: str):
    """Load and clean a _classes.csv from a split folder."""
    import pandas as pd

    csv_path = os.path.join(data_dir, "_classes.csv")
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV not found: {csv_path}")

    df = pd.read_csv(csv_path)
    df.columns = [c.strip() for c in df.columns]
    df["filename"] = df["filename"].str.strip()

    # Fast vectorized existence check
    img_paths = df["filename"].apply(lambda f: os.path.join(data_dir, f))
    mask      = img_paths.apply(os.path.exists)
    dropped   = int((~mask).sum())
    if dropped > 0:
        print(f"  [WARN] Dropped {dropped} missing images in {data_dir}")
    return df[mask].reset_index(drop=True)


class LiverDataset:
    """Minimal PyTorch-compatible dataset for liver histology images."""

    def __init__(self, data_dir: str, transform=None):
        from torch.utils.data import Dataset  # used only for type-check elsewhere
        self.data_dir  = data_dir
        self.transform = transform
        self.df        = load_csv(data_dir)
        print(f"  Loaded {len(self.df)} images from {data_dir}")

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        import torch
        from PIL import Image

        row      = self.df.iloc[idx]
        img_path = os.path.join(self.data_dir, row["filename"])

        # Load image -- use grey fallback on corrupt file
        try:
            img = Image.open(img_path).convert("RGB")
        except Exception:
            img = Image.new("RGB", (224, 224), (128, 128, 128))

        if self.transform:
            img = self.transform(img)

        labels = torch.tensor(
            [float(row[l]) for l in LABELS],
            dtype=torch.float32
        )
        return img, labels


# ── Transforms ────────────────────────────────────────────────────────────────
def get_transforms(img_size: int):
    """Return (train_transform, val_transform)."""
    from torchvision import transforms

    mean = [0.485, 0.456, 0.406]
    std  = [0.229, 0.224, 0.225]

    train_tf = transforms.Compose([
        transforms.Resize((img_size + 32, img_size + 32)),
        transforms.RandomCrop(img_size),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomVerticalFlip(p=0.5),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.1, hue=0.05),
        transforms.ToTensor(),
        transforms.Normalize(mean, std),
    ])

    val_tf = transforms.Compose([
        transforms.Resize((img_size, img_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean, std),
    ])

    return train_tf, val_tf


# ── Model ─────────────────────────────────────────────────────────────────────
def build_model(model_name: str, num_classes: int):
    """Build pretrained backbone with custom multi-label output head."""
    import torch.nn as nn
    import torchvision.models as models

    name = model_name.lower()

    if name == "efficientnet_b0":
        m = models.efficientnet_b0(weights="IMAGENET1K_V1")
        in_f = m.classifier[1].in_features
        m.classifier = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(in_f, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes),
        )
        # Freeze backbone
        for p in m.features.parameters():
            p.requires_grad = False

    elif name in ("resnet50", "resnet34", "resnet18"):
        m = getattr(models, name)(weights="IMAGENET1K_V1")
        in_f = m.fc.in_features
        m.fc = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(in_f, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes),
        )
        for pname, p in m.named_parameters():
            if "fc" not in pname:
                p.requires_grad = False

    elif name == "mobilenet_v3_small":
        m = models.mobilenet_v3_small(weights="IMAGENET1K_V1")
        in_f = m.classifier[3].in_features
        m.classifier[3] = nn.Linear(in_f, num_classes)
        for pname, p in m.named_parameters():
            if "classifier" not in pname:
                p.requires_grad = False

    else:
        raise ValueError(f"Unknown model '{model_name}'. "
                         f"Choose: efficientnet_b0, resnet50, resnet34, resnet18, mobilenet_v3_small")

    trainable = sum(p.numel() for p in m.parameters() if p.requires_grad)
    total     = sum(p.numel() for p in m.parameters())
    print(f"[Model] {model_name} | trainable: {trainable:,} / {total:,} ({100*trainable/total:.1f}%)")
    return m


def unfreeze_model(model, model_name: str, base_lr: float):
    """Unfreeze all params; return AdamW with differential LR."""
    import torch.optim as optim

    for p in model.parameters():
        p.requires_grad = True

    name = model_name.lower()
    if name == "efficientnet_b0":
        backbone_p = list(model.features.parameters())
        head_p     = list(model.classifier.parameters())
    elif "resnet" in name:
        head_p     = list(model.fc.parameters())
        head_set   = set(id(p) for p in head_p)
        backbone_p = [p for p in model.parameters() if id(p) not in head_set]
    else:
        backbone_p = []
        head_p     = list(model.parameters())

    optimizer = optim.AdamW([
        {"params": backbone_p, "lr": base_lr / 10},
        {"params": head_p,     "lr": base_lr},
    ], weight_decay=1e-4)

    total = sum(p.numel() for p in model.parameters())
    print(f"[Fine-tune] All {total:,} params unfrozen | backbone_lr={base_lr/10:.6f} | head_lr={base_lr:.6f}")
    return optimizer


# ── Metrics ───────────────────────────────────────────────────────────────────
def compute_metrics(preds_prob, targets, threshold: float = 0.5):
    """
    preds_prob : np.ndarray (N, 4)  sigmoid probabilities
    targets    : np.ndarray (N, 4)  binary ground truth
    """
    import numpy as np
    from sklearn.metrics import f1_score, accuracy_score, roc_auc_score

    preds_bin = (preds_prob >= threshold).astype(int)
    targets   = targets.astype(int)

    result = {}
    f1s, aucs = [], []

    for i, lbl in enumerate(LABELS):
        f1  = f1_score(targets[:, i], preds_bin[:, i], zero_division=0)
        acc = accuracy_score(targets[:, i], preds_bin[:, i])
        # AUC requires both classes present
        if targets[:, i].sum() > 0 and targets[:, i].sum() < len(targets):
            auc = roc_auc_score(targets[:, i], preds_prob[:, i])
        else:
            auc = 0.5
        result[lbl] = {"f1": round(f1, 4), "auc": round(auc, 4), "acc": round(acc, 4)}
        f1s.append(f1); aucs.append(auc)

    result["overall"] = {
        "mean_f1":  round(sum(f1s) / len(f1s), 4),
        "mean_auc": round(sum(aucs) / len(aucs), 4),
    }
    return result


# ── Training / eval loops ─────────────────────────────────────────────────────
def train_epoch(model, loader, criterion, optimizer, device, use_amp: bool):
    import torch

    model.train()
    total_loss, n = 0.0, 0

    # AMP scaler -- only for CUDA
    scaler = torch.amp.GradScaler("cuda") if use_amp else None

    for imgs, labels in loader:
        imgs   = imgs.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        optimizer.zero_grad(set_to_none=True)

        if use_amp:
            with torch.autocast(device_type="cuda"):
                out  = model(imgs)
                loss = criterion(out, labels)
            scaler.scale(loss).backward()
            scaler.unscale_(optimizer)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            scaler.step(optimizer)
            scaler.update()
        else:
            out  = model(imgs)
            loss = criterion(out, labels)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()

        total_loss += loss.item()
        n += 1

    return total_loss / max(n, 1)


def eval_epoch(model, loader, criterion, device, threshold: float):
    import torch
    import numpy as np

    model.eval()
    total_loss, n = 0.0, 0
    all_probs, all_targets = [], []

    with torch.no_grad():
        for imgs, labels in loader:
            imgs   = imgs.to(device, non_blocking=True)
            labels = labels.to(device, non_blocking=True)

            out  = model(imgs)
            loss = criterion(out, labels)

            total_loss += loss.item(); n += 1
            all_probs.append(torch.sigmoid(out).cpu().numpy())
            all_targets.append(labels.cpu().numpy())

    all_probs   = np.concatenate(all_probs,   axis=0)
    all_targets = np.concatenate(all_targets, axis=0)
    avg_loss    = total_loss / max(n, 1)
    metrics     = compute_metrics(all_probs, all_targets, threshold)
    return avg_loss, metrics


# ── Main train function ────────────────────────────────────────────────────────
def train(args):
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import DataLoader

    device  = get_device()
    use_amp = device.type == "cuda"
    os.makedirs(args.output_dir, exist_ok=True)

    # ── Data ──────────────────────────────────────────────────────────────────
    train_tf, val_tf = get_transforms(args.img_size)

    print("\n[DATA] Loading datasets...")
    train_ds = LiverDataset(args.train_dir, transform=train_tf)
    val_ds   = LiverDataset(args.valid_dir, transform=val_tf)

    train_loader = DataLoader(train_ds, batch_size=args.batch_size,
                              shuffle=True,  num_workers=0, pin_memory=use_amp)
    val_loader   = DataLoader(val_ds,   batch_size=args.batch_size,
                              shuffle=False, num_workers=0, pin_memory=use_amp)

    # Positive-class weight to handle label imbalance
    label_counts = train_ds.df[LABELS].sum(axis=0).values.astype(float)
    N            = float(len(train_ds))
    pos_weight   = torch.tensor(
        [(N - c) / max(c, 1) for c in label_counts], dtype=torch.float32
    ).to(device)
    print(f"[DATA] pos_weight = {[round(x, 2) for x in pos_weight.tolist()]}")

    # ── Model ─────────────────────────────────────────────────────────────────
    print("\n[MODEL] Building model...")
    model     = build_model(args.model, NUM_CLASSES).to(device)
    criterion = nn.BCEWithLogitsLoss(pos_weight=pos_weight)

    # Phase-1 optimizer (head only)
    trainable_p = [p for p in model.parameters() if p.requires_grad]
    optimizer   = optim.AdamW(trainable_p, lr=args.lr, weight_decay=1e-4)
    scheduler   = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs, eta_min=1e-6)

    best_val_loss   = float("inf")
    best_model_path = os.path.join(args.output_dir, "best_model.pth")
    patience        = 0
    PATIENCE        = 6

    history = {
        "train_loss": [], "val_loss": [], "val_f1": [], "val_auc": [],
        "per_label":  {l: {"f1": [], "auc": []} for l in LABELS},
    }

    total_epochs = args.epochs + args.fine_tune_epochs
    print(f"\n[TRAIN] Phase-1: {args.epochs} ep (head) + Phase-2: {args.fine_tune_epochs} ep (all)")
    print(f"[TRAIN] batch={args.batch_size} | lr={args.lr} | img={args.img_size} | AMP={use_amp}")
    print("-" * 70)

    t0 = time.time()

    for ep in range(1, total_epochs + 1):

        # Switch to Phase 2
        if ep == args.epochs + 1:
            print(f"\n[PHASE-2] Unfreezing all layers for fine-tuning...")
            optimizer = unfreeze_model(model, args.model, args.lr / 5)
            scheduler = optim.lr_scheduler.CosineAnnealingLR(
                optimizer, T_max=args.fine_tune_epochs, eta_min=1e-7
            )

        t_loss = train_epoch(model, train_loader, criterion, optimizer, device, use_amp)
        v_loss, v_metrics = eval_epoch(model, val_loader, criterion, device, args.threshold)
        scheduler.step()

        # Checkpoint
        if v_loss < best_val_loss:
            best_val_loss = v_loss
            torch.save(model.state_dict(), best_model_path)
            patience = 0
            tag = " <-- BEST"
        else:
            patience += 1
            tag = ""

        # Logging
        elapsed = (time.time() - t0) / 60
        lr_now  = optimizer.param_groups[-1]["lr"]
        print(
            f"Ep {ep:3d}/{total_epochs} | "
            f"TrLoss {t_loss:.4f} | "
            f"VaLoss {v_loss:.4f} | "
            f"F1 {v_metrics['overall']['mean_f1']:.4f} | "
            f"AUC {v_metrics['overall']['mean_auc']:.4f} | "
            f"lr {lr_now:.2e} | {elapsed:.1f}m{tag}"
        )

        history["train_loss"].append(round(t_loss, 4))
        history["val_loss"].append(round(v_loss, 4))
        history["val_f1"].append(v_metrics["overall"]["mean_f1"])
        history["val_auc"].append(v_metrics["overall"]["mean_auc"])
        for lbl in LABELS:
            history["per_label"][lbl]["f1"].append(v_metrics[lbl]["f1"])
            history["per_label"][lbl]["auc"].append(v_metrics[lbl]["auc"])

        # Early stopping (Phase 2 only)
        if patience >= PATIENCE and ep > args.epochs:
            print(f"\n[EARLY STOP] No improvement for {PATIENCE} consecutive epochs.")
            break

    # ── Test evaluation ────────────────────────────────────────────────────────
    print("\n[TEST] Loading best model and evaluating on test set...")
    model.load_state_dict(
        torch.load(best_model_path, map_location=device, weights_only=True)
    )
    test_ds     = LiverDataset(args.test_dir, transform=val_tf)
    test_loader = DataLoader(test_ds, batch_size=args.batch_size,
                             shuffle=False, num_workers=0)
    _, test_m   = eval_epoch(model, test_loader, criterion, device, args.threshold)

    elapsed_total = (time.time() - t0) / 60
    print(f"\n[RESULTS] Done in {elapsed_total:.1f} min | best_val_loss={best_val_loss:.4f}")
    print("[TEST METRICS]")
    print(f"  mean_F1={test_m['overall']['mean_f1']:.4f}  mean_AUC={test_m['overall']['mean_auc']:.4f}")
    print("\n  Per-label:")
    for lbl in LABELS:
        m = test_m[lbl]
        print(f"    {lbl:15s}  F1={m['f1']:.4f}  AUC={m['auc']:.4f}  Acc={m['acc']:.4f}")

    # Save artefacts
    history_path = os.path.join(args.output_dir, "training_history.json")
    with open(history_path, "w") as f:
        json.dump(history, f, indent=2)

    config = {
        "model_name":       args.model,
        "num_classes":      NUM_CLASSES,
        "labels":           LABELS,
        "img_size":         args.img_size,
        "threshold":        args.threshold,
        "best_val_loss":    round(best_val_loss, 4),
        "test_metrics":     test_m,
        "timestamp":        datetime.now().isoformat(),
        "weights_path":     best_model_path,
        "training_minutes": round(elapsed_total, 2),
    }
    config_path = os.path.join(args.output_dir, "model_config.json")
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)

    print(f"\n[SAVED] weights -> {best_model_path}")
    print(f"[SAVED] history -> {history_path}")
    print(f"[SAVED] config  -> {config_path}")
    print("\n" + "=" * 70)
    print("  Training complete!")
    print("=" * 70)
    return config


# ── Dry run ───────────────────────────────────────────────────────────────────
def dry_run(args):
    import torch

    print("\n[DRY RUN] Checking data and model...")
    train_tf, _ = get_transforms(args.img_size)
    ds          = LiverDataset(args.train_dir, transform=train_tf)
    print(f"  Train images: {len(ds)}")

    img, lbl = ds[0]
    print(f"  Sample image shape : {tuple(img.shape)}")
    print(f"  Sample labels      : {lbl.tolist()}")

    model = build_model(args.model, NUM_CLASSES)
    with torch.no_grad():
        out = model(img.unsqueeze(0))
    print(f"  Model output shape : {tuple(out.shape)}")
    print("\n[DRY RUN] All checks passed -- ready to train.")


# ── Entry point ───────────────────────────────────────────────────────────────
def main():
    args = parse_args()
    print("\n" + "=" * 70)
    print("  Liver Histology Vision Model -- Multi-Label Image Classifier")
    print("=" * 70)
    print(f"  Labels : {LABELS}")
    print(f"  Model  : {args.model}")
    print(f"  Data   : {args.train_dir}")

    check_imports()

    if args.dry_run:
        dry_run(args)
    else:
        train(args)


if __name__ == "__main__":
    main()
