"""
Liver Patient Dataset (LPD) Preprocessing Pipeline
=====================================================
Handles:
  - Column name cleaning (encoding issues, leading whitespace)
  - Missing value imputation
  - Categorical encoding (Gender -> binary)
  - Outlier capping (IQR method)
  - Feature scaling (StandardScaler)
  - Class label normalization (1/2 -> 0/1)
  - Train/val/test split
  - Save preprocessed outputs + scaler + encoder
"""

import os
import sys
import warnings
import json
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
import joblib

warnings.filterwarnings("ignore")

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────
BASE_DIR   = Path(__file__).parent
DATA_DIR   = BASE_DIR / "Data"
MODELS_DIR = BASE_DIR / "models"
OUT_DIR    = BASE_DIR / "Data" / "preprocessed"

RAW_CSV    = DATA_DIR / "Liver Patient Dataset (LPD)_train.csv"

MODELS_DIR.mkdir(parents=True, exist_ok=True)
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Clean column name mapping (corrects encoding artifacts & leading whitespace)
# NOTE: actual CSV columns are:
#   'Age of the patient', 'Gender of the patient', 'Total Bilirubin',
#   'Direct Bilirubin', '?Alkphos Alkaline Phosphotase',
#   '?Sgpt Alamine Aminotransferase', 'Sgot Aspartate Aminotransferase',
#   'Total Protiens', '?ALB Albumin',
#   'A/G Ratio Albumin and Globulin Ratio', 'Result'
COLUMN_RENAME = {
    "Age of the patient"                              : "age",
    "Gender of the patient"                           : "gender",
    "Total Bilirubin"                                 : "total_bilirubin",
    "Direct Bilirubin"                                : "direct_bilirubin",
    # With BOM/replacement prefix (various forms)
    "Alkphos Alkaline Phosphotase"                    : "alkaline_phosphotase",
    "Sgpt Alamine Aminotransferase"                   : "sgpt",
    "Sgot Aspartate Aminotransferase"                 : "sgot",
    "Total Protiens"                                  : "total_proteins",
    "Total Proteins"                                  : "total_proteins",
    "ALB Albumin"                                     : "albumin",
    "A/G Ratio Albumin and Globulin Ratio"            : "ag_ratio",
    "Result"                                          : "result",
}

NUMERIC_FEATURES = [
    "age", "total_bilirubin", "direct_bilirubin",
    "alkaline_phosphotase", "sgpt", "sgot",
    "total_proteins", "albumin", "ag_ratio",
]

TARGET = "result"

# ──────────────────────────────────────────────────────────────────────────────
# STEP 1 — Load raw data
# ──────────────────────────────────────────────────────────────────────────────
print("=" * 60)
print("  LPD PREPROCESSING PIPELINE")
print("=" * 60)

print(f"\n[1] Loading raw CSV: {RAW_CSV.name}")
df = pd.read_csv(RAW_CSV, encoding="utf-8", encoding_errors="replace")
print(f"    Shape: {df.shape[0]:,} rows x {df.shape[1]} columns")
safe_cols = [c.encode("ascii", errors="replace").decode("ascii") for c in df.columns]
print(f"    Raw columns: {safe_cols}")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 2 — Clean column names
# ──────────────────────────────────────────────────────────────────────────────
print("\n[2] Cleaning column names ...")

# Step A: strip ALL leading non-ASCII, BOM, replacement chars, whitespace
import re as _re
def _clean_col(c):
    # Remove any leading non-printable / non-ASCII characters
    c = _re.sub(r'^[^\x21-\x7e]+', '', c)  # strip anything before first printable ASCII
    return c.strip()

df.columns = [_clean_col(c) for c in df.columns]

# Step B: Apply explicit rename map
df.rename(columns=COLUMN_RENAME, inplace=True)

# Step C: Lowercase all remaining column names
df.columns = [c.lower().replace(" ", "_") for c in df.columns]

print(f"    Clean columns: {list(df.columns)}")

# Step D: Remove duplicate columns
if df.columns.duplicated().any():
    df = df.loc[:, ~df.columns.duplicated()]
    print("    [WARN] Duplicate columns removed.")

# Step E: Ensure expected columns exist
EXPECTED = NUMERIC_FEATURES + ["gender", TARGET]
missing_cols = [c for c in EXPECTED if c not in df.columns]
if missing_cols:
    print(f"    [ERROR] Missing columns: {missing_cols}")
    print(f"    Available columns: {list(df.columns)}")
    sys.exit(1)

print("    All expected columns found OK")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 3 — Basic data quality report
# ──────────────────────────────────────────────────────────────────────────────
print("\n[3] Data Quality Report")
print(f"    Total rows    : {len(df):,}")
print(f"    Duplicates    : {df.duplicated().sum():,}")
print(f"    Missing values:")
has_missing = False
for col in EXPECTED:
    n_missing = df[col].isna().sum()
    pct = 100 * n_missing / len(df)
    if n_missing:
        print(f"      {col:<32} {n_missing:>6,} ({pct:.2f}%)")
        has_missing = True
if not has_missing:
    print("      None found!")

print(f"\n    Target distribution (raw):")
print(df[TARGET].value_counts().to_string())

# ──────────────────────────────────────────────────────────────────────────────
# STEP 4 — Drop exact duplicates
# ──────────────────────────────────────────────────────────────────────────────
print("\n[4] Removing duplicates ...")
n_before = len(df)
df.drop_duplicates(inplace=True)
df.reset_index(drop=True, inplace=True)
print(f"    Removed {n_before - len(df):,} duplicate rows. Remaining: {len(df):,}")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 5 — Encode Gender  (Female=0, Male=1)
# ──────────────────────────────────────────────────────────────────────────────
print("\n[5] Encoding 'gender' ...")
df["gender"] = df["gender"].astype(str).str.strip().str.title()
gender_map = {"Female": 0, "Male": 1}
df["gender"] = df["gender"].map(gender_map)

if df["gender"].isna().any():
    n = df["gender"].isna().sum()
    mode_val = df["gender"].dropna().mode()
    fill_val = int(mode_val.iloc[0]) if len(mode_val) > 0 else 1  # default Male=1
    print(f"    [WARN] {n} unrecognised gender values -- imputing with mode ({fill_val}).")
    df["gender"] = df["gender"].fillna(fill_val)

df["gender"] = df["gender"].astype(int)
print("    Gender encoded: Female=0, Male=1  OK")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 6 — Coerce numeric columns to float
# ──────────────────────────────────────────────────────────────────────────────
print("\n[6] Coercing numeric columns to float ...")
for col in NUMERIC_FEATURES:
    df[col] = pd.to_numeric(df[col], errors="coerce")
print("    Done OK")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 7 — Impute missing values (median strategy)
# ──────────────────────────────────────────────────────────────────────────────
print("\n[7] Imputing missing values with column median ...")
imputer = SimpleImputer(strategy="median")
df[NUMERIC_FEATURES] = imputer.fit_transform(df[NUMERIC_FEATURES])

imputer_path = MODELS_DIR / "lpd_imputer.pkl"
joblib.dump(imputer, imputer_path)
print(f"    Imputer saved --> {imputer_path.name}")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 8 — Outlier capping  (IQR x1.5 on each numeric feature)
# ──────────────────────────────────────────────────────────────────────────────
print("\n[8] Capping outliers (IQR x 1.5) ...")
outlier_bounds = {}
for col in NUMERIC_FEATURES:
    Q1  = df[col].quantile(0.25)
    Q3  = df[col].quantile(0.75)
    IQR = Q3 - Q1
    lo  = Q1 - 1.5 * IQR
    hi  = Q3 + 1.5 * IQR
    n_out = ((df[col] < lo) | (df[col] > hi)).sum()
    df[col] = df[col].clip(lo, hi)
    outlier_bounds[col] = {"lower": round(float(lo), 4), "upper": round(float(hi), 4)}
    print(f"    {col:<32}  [{lo:>8.2f}, {hi:>8.2f}]  capped {n_out:,}")

with open(MODELS_DIR / "lpd_outlier_bounds.json", "w") as f:
    json.dump(outlier_bounds, f, indent=2)
print("    Outlier bounds saved OK")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 9 — Normalise target labels  (1->0 = liver disease, 2->1 = no disease)
# ──────────────────────────────────────────────────────────────────────────────
print("\n[9] Normalising target labels (1->0 Liver Disease, 2->1 No Disease) ...")
df[TARGET] = df[TARGET].map({1: 0, 2: 1})
print("    Target distribution after normalisation:")
vc = df[TARGET].value_counts().sort_index()
for lbl, cnt in vc.items():
    name = "Liver Disease" if lbl == 0 else "No Disease"
    print(f"      {lbl} ({name:<14}) : {cnt:,}  ({100*cnt/len(df):.1f}%)")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 10 — Train / Validation / Test split  (70/15/15)
# ──────────────────────────────────────────────────────────────────────────────
print("\n[10] Splitting dataset (70% train | 15% val | 15% test) ...")
ALL_FEATURES = NUMERIC_FEATURES + ["gender"]
X = df[ALL_FEATURES].values
y = df[TARGET].values

X_train, X_temp, y_train, y_temp = train_test_split(
    X, y, test_size=0.30, random_state=42, stratify=y
)
X_val, X_test, y_val, y_test = train_test_split(
    X_temp, y_temp, test_size=0.50, random_state=42, stratify=y_temp
)

print(f"    Train : {len(X_train):,} rows")
print(f"    Val   : {len(X_val):,} rows")
print(f"    Test  : {len(X_test):,} rows")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 11 — Feature scaling (StandardScaler — fit on train only)
# ──────────────────────────────────────────────────────────────────────────────
print("\n[11] Scaling features with StandardScaler (fit on train only) ...")
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_val_scaled   = scaler.transform(X_val)
X_test_scaled  = scaler.transform(X_test)

scaler_path = MODELS_DIR / "lpd_scaler.pkl"
joblib.dump(scaler, scaler_path)
print(f"    Scaler saved --> {scaler_path.name}")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 12 — Save preprocessed splits as CSV
# ──────────────────────────────────────────────────────────────────────────────
print("\n[12] Saving preprocessed datasets ...")
feature_cols = ALL_FEATURES

def save_split(X_arr, y_arr, name):
    df_out = pd.DataFrame(X_arr, columns=feature_cols)
    df_out[TARGET] = y_arr
    path = OUT_DIR / f"lpd_{name}.csv"
    df_out.to_csv(path, index=False)
    print(f"    Saved {name:5} --> {path.name}  ({len(df_out):,} rows)")

save_split(X_train_scaled, y_train, "train")
save_split(X_val_scaled,   y_val,   "val")
save_split(X_test_scaled,  y_test,  "test")

# Save full cleaned (scaled) dataset
df_full = pd.DataFrame(
    np.vstack([X_train_scaled, X_val_scaled, X_test_scaled]),
    columns=feature_cols
)
df_full[TARGET] = np.concatenate([y_train, y_val, y_test])
full_path = OUT_DIR / "lpd_clean_full.csv"
df_full.to_csv(full_path, index=False)
print(f"    Saved full  --> {full_path.name}  ({len(df_full):,} rows)")

# ──────────────────────────────────────────────────────────────────────────────
# STEP 13 — Save metadata
# ──────────────────────────────────────────────────────────────────────────────
metadata = {
    "features"    : feature_cols,
    "target"      : TARGET,
    "label_map"   : {"0": "Liver Disease", "1": "No Disease"},
    "gender_map"  : {"0": "Female", "1": "Male"},
    "n_features"  : len(feature_cols),
    "train_rows"  : int(len(X_train_scaled)),
    "val_rows"    : int(len(X_val_scaled)),
    "test_rows"   : int(len(X_test_scaled)),
    "scaler_path" : str(scaler_path),
    "imputer_path": str(imputer_path),
}
meta_path = MODELS_DIR / "lpd_metadata.json"
with open(meta_path, "w") as f:
    json.dump(metadata, f, indent=2)
print(f"\n    Metadata saved --> {meta_path.name}")

# ──────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("  PREPROCESSING COMPLETE!")
print("=" * 60)
print(f"\n  Output directory : {OUT_DIR}")
print(f"  Models directory : {MODELS_DIR}")
print("\n  Files created:")
print("    Data/preprocessed/lpd_train.csv")
print("    Data/preprocessed/lpd_val.csv")
print("    Data/preprocessed/lpd_test.csv")
print("    Data/preprocessed/lpd_clean_full.csv")
print("    models/lpd_scaler.pkl")
print("    models/lpd_imputer.pkl")
print("    models/lpd_outlier_bounds.json")
print("    models/lpd_metadata.json")
print()
