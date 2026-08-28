---
title: all-MiniLM-L6-v2 Semantic Embeddings & Search Demo
emoji: 🧠
colorFrom: blue
colorTo: indigo
sdk: gradio
sdk_version: 5.20.0
app_file: app.py
pinned: false
short_description: Semantic search, similarity heatmap & 2D embedding space demo
---

# 🧠 all-MiniLM-L6-v2 Semantic Search & Embeddings Demo

Welcome to the interactive demonstration for **[sentence-transformers/all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)**.

This model maps sentences and paragraphs to a **384-dimensional dense vector space** and is widely regarded as one of the most efficient, versatile embedding models for clustering, semantic search, and text similarity.

---

## 🌟 Interactive Capabilities

1. **🔍 Semantic Search & Passage Re-ranking**: Query a dynamic list of candidate documents, compute cosine similarity, and retrieve the most relevant passages sorted by score with visual confidence bars.
2. **📊 Similarity Matrix & Heatmap**: Compare multiple sentences simultaneously with an interactive Plotly heatmap and detailed pairwise breakdown.
3. **🌌 2D Semantic Space Visualizer**: Real-time dimensionality reduction (PCA) projecting 384-dimensional sentence vectors onto an interactive 2D coordinate space.
4. **🔬 Embedding Vector Diagnostics**: Inspect vector dimensions, L2 norm, token length, and raw embedding sample values.

---

## 🚀 Model Details
- **Model Name**: `sentence-transformers/all-MiniLM-L6-v2`
- **Base Architecture**: MiniLM-L6-H384-uncased
- **Embedding Dimensions**: 384
- **Max Sequence Length**: 256 tokens
- **Output Pooling**: Mean Pooling
- **Normalized**: Yes (Unit length / Cosine similarity equals dot product)
