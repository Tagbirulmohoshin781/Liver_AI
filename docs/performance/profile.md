# Render Cloud Memory Optimization Profile

Target Platform: Render Free Tier (512MB RAM Limit)

1. Memory Architecture:
Render free tier provides 512MB RAM limit.

2. Optimization Strategies:
- Zero-RAM Cloud Embeddings: Pinecone cloud retrieval without loading heavy local embedding models into RAM.
- Lazy Artifact Loading: lpd_scaler.pkl (<1MB) loaded on-demand.
- EfficientNet-B0 Weights: ~17.6MB model size keeps peak memory under 180MB.
- Gunicorn Worker Bounds: gunicorn app:app --workers 1 --threads 4.
