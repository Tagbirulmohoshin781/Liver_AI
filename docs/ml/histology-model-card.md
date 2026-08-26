# Liver Biopsy Histology Classifier Model Card

## Model Details
- **Architecture**: EfficientNet-B0 (Multi-label classification head)
- **Targets**: Ballooning degeneration, Fibrosis, Lobular Inflammation, Steatosis
- **Input Resolution**: 224 x 224 RGB biopsy tile
- **Status**: \EXPERIMENTAL_RESEARCH_ONLY\

## Production Gating
- Production environments (\APP_ENV=production\) strictly forbid simulation fallback.
- If weights (\models/liver_vision/best_model.pth\) are missing or PyTorch is not available, the service returns HTTP 503 \MODEL_UNAVAILABLE\ rather than fabricating diagnostic probabilities.
