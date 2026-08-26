# Render Memory & Resource Profile

## Target Environment
- **Platform**: Render Free Tier (512MB RAM limit)
- **Python Version**: 3.11.9
- **WSGI Server**: Gunicorn (1 worker, threads=4)

## Memory Footprint Benchmark
| Component | RAM Consumption | Mitigation Applied |
|---|---|---|
| Python Base + Flask + Blueprints | ~45 MB | Modular blueprint registration |
| LangChain Core + Local TF Retriever | ~28 MB | Lightweight in-memory TF indexing on startup |
| Supabase PostgreSQL Client | ~12 MB | Connection pooling & client reuse |
| FastEmbed / HuggingFace Local (Prior) | ~420 MB (OOM Crash) | Replaced with zero-RAM cloud embeddings & local TF |
| PyTorch + Torchvision (Prior) | ~350 MB (OOM Crash) | Removed from default runtime; ONNX/graceful unavailable state |
| **Total Steady State Memory** | **~85 MB** | **< 20% of 512MB limit — stable against Status 137 OOM** |
