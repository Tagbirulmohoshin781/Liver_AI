# Liver Patient Dataset (LPD) Data Card

## 1. Dataset Summary
- **Source**: Indian Liver Patient Dataset (ILPD) / UCI Machine Learning Repository
- **Number of Records**: 583 original patient records (~19k records reported across augmented/expanded benchmarks)
- **Target Variable**: Liver disease indicator (Binary: 1=Liver Patient, 2=Non-Liver Patient)

## 2. Feature Specifications & Normal Reference Ranges (AASLD)
- \ge\: Patient Age (Years)
- \gender\: Biological Sex (0=Female, 1=Male)
- \	otal_bilirubin\: Total Bilirubin (0.1 - 1.2 mg/dL)
- \direct_bilirubin\: Direct / Conjugated Bilirubin (0.0 - 0.3 mg/dL)
- \lkaline_phosphotase\: Alkaline Phosphatase ALP (44 - 147 IU/L)
- \sgpt\: Alanine Aminotransferase ALT (7 - 56 IU/L)
- \sgot\: Aspartate Aminotransferase AST (10 - 40 IU/L)
- \	otal_proteins\: Serum Total Protein (6.0 - 8.3 g/dL)
- \lbumin\: Serum Albumin (3.5 - 5.0 g/dL)
- \g_ratio\: Albumin-to-Globulin Ratio (1.0 - 2.5)

## 3. Data Integrity & Leakage Mitigation
- Preprocessing pipelines (imputation, scaling) must be fitted strictly on training splits only.
- Test splits must remain isolated until final model evaluation.
