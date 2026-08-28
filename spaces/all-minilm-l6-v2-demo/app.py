import time
from typing import List, Tuple, Dict, Any
import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import gradio as gr

# Try importing spaces for ZeroGPU environments; fallback gracefully on CPU
try:
    import spaces
    has_spaces = True
except ImportError:
    has_spaces = False

import torch
from sentence_transformers import SentenceTransformer, util
from sklearn.decomposition import PCA

MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"

# Initialize model
device = "cuda" if torch.cuda.is_available() else "cpu"
model = SentenceTransformer(MODEL_ID, device=device)

def get_gpu_decorator():
    if has_spaces and torch.cuda.is_available():
        return spaces.GPU(duration=30)
    def identity(fn):
        return fn
    return identity

gpu_decorator = get_gpu_decorator()


# --- Core Inference Logic ---

@gpu_decorator
def semantic_search(query: str, corpus_text: str, top_k: int = 5) -> Tuple[pd.DataFrame, str]:
    """
    Perform semantic search over a corpus of documents using cosine similarity with all-MiniLM-L6-v2.
    
    Args:
        query: The search query string.
        corpus_text: Multi-line string where each non-empty line is a candidate document.
        top_k: Maximum number of top relevant results to return.
    
    Returns:
        A DataFrame with ranked documents and similarity scores, plus timing metadata.
    """
    if not query.strip():
        return pd.DataFrame(columns=["Rank", "Similarity Score", "Match Quality", "Document"]), "⚠️ Please provide a query."
    
    docs = [line.strip() for line in corpus_text.strip().split("\n") if line.strip()]
    if not docs:
        return pd.DataFrame(columns=["Rank", "Similarity Score", "Match Quality", "Document"]), "⚠️ Please provide at least one document."
    
    start_time = time.time()
    
    query_emb = model.encode(query, convert_to_tensor=True)
    doc_embs = model.encode(docs, convert_to_tensor=True)
    
    cos_scores = util.cos_sim(query_emb, doc_embs)[0].cpu().numpy()
    elapsed_ms = (time.time() - start_time) * 1000
    
    ranked_indices = np.argsort(-cos_scores)
    top_indices = ranked_indices[:min(top_k, len(docs))]
    
    results = []
    for rank, idx in enumerate(top_indices, 1):
        score = float(cos_scores[idx])
        pct = round(score * 100, 2)
        
        if score >= 0.75:
            quality = "🟢 Excellent Match"
        elif score >= 0.50:
            quality = "🟡 Moderate Match"
        elif score >= 0.25:
            quality = "🟠 Low Relevance"
        else:
            quality = "⚪ Unrelated"
            
        results.append({
            "Rank": f"#{rank}",
            "Similarity Score": f"{score:.4f} ({pct}%)",
            "Match Quality": quality,
            "Document": docs[idx]
        })
        
    df = pd.DataFrame(results)
    stats = f"⚡ Search completed in **{elapsed_ms:.2f} ms** across **{len(docs)}** passages on device: `{device.upper()}`."
    return df, stats


@gpu_decorator
def compute_similarity_matrix(sentences_text: str) -> Tuple[go.Figure, pd.DataFrame]:
    """
    Computes an N x N pairwise cosine similarity matrix and generates an interactive heatmap.
    
    Args:
        sentences_text: Multi-line string where each line represents a sentence.
        
    Returns:
        Plotly heatmap figure and pairwise comparison DataFrame.
    """
    sentences = [s.strip() for s in sentences_text.strip().split("\n") if s.strip()]
    if len(sentences) < 2:
        empty_fig = go.Figure()
        empty_fig.update_layout(title="⚠️ Please provide at least 2 sentences.")
        return empty_fig, pd.DataFrame()
    
    # Truncate labels for heatmap axis display
    labels = [f"[{i+1}] {s[:35]}..." if len(s) > 35 else f"[{i+1}] {s}" for i, s in enumerate(sentences)]
    
    embeddings = model.encode(sentences, convert_to_tensor=True)
    sim_matrix = util.cos_sim(embeddings, embeddings).cpu().numpy()
    
    # Generate Heatmap
    fig = px.imshow(
        sim_matrix,
        x=labels,
        y=labels,
        color_continuous_scale="Viridis",
        labels=dict(x="Sentence A", y="Sentence B", color="Cosine Similarity"),
        text_auto=".2f",
        title="<b>Pairwise Sentence Similarity Heatmap (all-MiniLM-L6-v2)</b>",
    )
    fig.update_layout(
        xaxis_tickangle=-30,
        height=520,
        margin=dict(l=40, r=40, t=50, b=100),
        template="plotly_white"
    )
    
    # Generate Top Pairwise Table
    pairs = []
    n = len(sentences)
    for i in range(n):
        for j in range(i + 1, n):
            score = float(sim_matrix[i][j])
            pairs.append({
                "Sentence 1": sentences[i],
                "Sentence 2": sentences[j],
                "Cosine Similarity": round(score, 4),
                "Similarity (%)": f"{round(score * 100, 1)}%"
            })
    
    pairs_df = pd.DataFrame(pairs).sort_values(by="Cosine Similarity", ascending=False)
    return fig, pairs_df


@gpu_decorator
def visualize_2d_embeddings(corpus_text: str) -> go.Figure:
    """
    Reduces 384-dimensional sentence embeddings down to 2D using PCA and creates an interactive semantic scatter plot.
    
    Args:
        corpus_text: Multi-line string containing sentences to embed and project.
        
    Returns:
        Plotly 2D scatter plot figure.
    """
    sentences = [s.strip() for s in corpus_text.strip().split("\n") if s.strip()]
    if len(sentences) < 3:
        empty_fig = go.Figure()
        empty_fig.update_layout(title="⚠️ Please provide at least 3 sentences for 2D visualization.")
        return empty_fig
        
    embeddings = model.encode(sentences, convert_to_numpy=True)
    
    pca = PCA(n_components=2, random_state=42)
    coords_2d = pca.fit_transform(embeddings)
    
    var_explained = pca.explained_variance_ratio_ * 100
    
    df = pd.DataFrame({
        "PCA Component 1": coords_2d[:, 0],
        "PCA Component 2": coords_2d[:, 1],
        "Sentence": sentences,
        "Length": [len(s) for s in sentences]
    })
    
    fig = px.scatter(
        df,
        x="PCA Component 1",
        y="PCA Component 2",
        text="Sentence",
        hover_name="Sentence",
        size="Length",
        size_max=18,
        color="PCA Component 1",
        color_continuous_scale="Turbo",
        title=f"<b>2D Semantic Space Visualization (PCA)</b><br><sup>Total Variance Explained: {var_explained.sum():.1f}% (PC1: {var_explained[0]:.1f}%, PC2: {var_explained[1]:.1f}%)</sup>"
    )
    
    fig.update_traces(textposition="top center", marker=dict(opacity=0.85, line=dict(width=1, color="DarkSlateGrey")))
    fig.update_layout(
        height=580,
        template="plotly_white",
        margin=dict(l=40, r=40, t=70, b=40)
    )
    return fig


def inspect_vector(text: str) -> Tuple[str, str, go.Figure]:
    """
    Inspects embedding vector properties (dimensions, L2 norm, min/max values) for input text.
    
    Args:
        text: Input string.
        
    Returns:
        Formatted summary markdown, sample vector array preview, and distribution plot.
    """
    if not text.strip():
        empty_fig = go.Figure()
        return "⚠️ Please enter some text to inspect its vector.", "", empty_fig
        
    start_time = time.time()
    vector = model.encode(text, convert_to_numpy=True)
    calc_time = (time.time() - start_time) * 1000
    
    l2_norm = np.linalg.norm(vector)
    dim = len(vector)
    
    summary = f"""
### 📊 Vector Summary
- **Dimensions**: `{dim}`
- **L2 Norm**: `{l2_norm:.6f}` (Normalized unit length)
- **Min Value**: `{vector.min():.5f}`
- **Max Value**: `{vector.max():.5f}`
- **Mean**: `{vector.mean():.5f}`
- **Std Dev**: `{vector.std():.5f}`
- **Encoding Latency**: `{calc_time:.2f} ms`
"""
    preview = f"[\n  " + ", ".join([f"{v:.4f}" for v in vector[:16]]) + ",\n  ... (384 dimensions total)\n]"
    
    # Distribution Histogram
    fig = px.histogram(
        x=vector,
        nbins=40,
        labels={"x": "Dimension Value"},
        title="<b>Embedding Dimension Value Distribution</b>",
        color_discrete_sequence=["#6366F1"]
    )
    fig.update_layout(height=320, template="plotly_white", margin=dict(l=30, r=30, t=40, b=30))
    
    return summary, preview, fig


# --- Presets & Examples ---

SEARCH_DEFAULT_QUERY = "How to keep a healthy liver and prevent disease?"
SEARCH_DEFAULT_CORPUS = """A balanced diet rich in antioxidants and low in saturated fats supports liver health.
Regular cardiovascular exercise helps reduce liver fat accumulation and improves insulin sensitivity.
Drinking adequate water and limiting excessive alcohol intake prevents hepatic toxicity.
Artificial intelligence models can detect early hepatic fibrosis and cirrhosis from ultrasound scans.
Spacecraft propulsion systems utilize liquid hydrogen and liquid oxygen for orbital insertion.
Convolutional neural networks achieve state-of-the-art accuracy in medical computer vision benchmarks.
Hydration and sleep quality have a direct correlation with cognitive productivity and stamina."""

SIMILARITY_DEFAULT_SENTENCES = """The quick brown fox jumps over the lazy dog.
A fast auburn canine leaps above a sleepy hound.
Artificial intelligence and deep neural networks are transforming healthcare.
Machine learning algorithms are revolutionizing modern medical diagnostics.
The solar eclipse cast a dark shadow across the continent yesterday.
Astronomers observed the celestial alignment through high-powered telescopes."""

SPACE_2D_DEFAULT_CORPUS = """Patient shows elevated ALT and AST liver enzymes.
Serum bilirubin levels indicate possible hepatic jaundice.
Clinical ultrasound reveals mild fatty liver steatosis.
The software application uses FastAPI and Docker for microservice deployment.
Kubernetes orchestrates containerized backend services across nodes.
The Python web server handles concurrent asynchronous HTTP requests.
Jupiter is the largest planet in our solar system with iconic swirling storms.
Mars rover discovers ancient riverbed sediments and mineral traces.
Astronomers detected distant exoplanets within the habitable circumstellar zone."""


# --- Gradio UI Assembly ---

with gr.Blocks(title="all-MiniLM-L6-v2 Semantic Embeddings Demo", theme=gr.themes.Soft(primary_hue="indigo", secondary_hue="blue")) as demo:
    gr.Markdown(
        """
        # 🧠 sentence-transformers/all-MiniLM-L6-v2 Interactive Studio
        ### High-Speed Semantic Search, Sentence Embeddings, and Similarity Diagnostics
        
        This space demonstrates the dense embedding capabilities of **[all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)** (384 dimensions, 256 tokens max sequence, mean pooled).
        """
    )
    
    with gr.Tabs():
        # --- TAB 1: Semantic Search ---
        with gr.TabItem("🔍 Semantic Search & Ranking"):
            gr.Markdown("#### Retrieve and rank candidate passages based on semantic cosine similarity to your query.")
            with gr.Row():
                with gr.Column(scale=1):
                    query_in = gr.Textbox(
                        value=SEARCH_DEFAULT_QUERY,
                        label="Search Query",
                        placeholder="Type a natural language question or query...",
                        lines=2
                    )
                    top_k_slider = gr.Slider(
                        minimum=1,
                        maximum=15,
                        value=5,
                        step=1,
                        label="Top K Results"
                    )
                    corpus_in = gr.Textbox(
                        value=SEARCH_DEFAULT_CORPUS,
                        label="Candidate Passages (one per line)",
                        lines=10,
                        placeholder="Paste paragraphs or candidate texts separated by newlines..."
                    )
                    search_btn = gr.Button("⚡ Execute Semantic Search", variant="primary")
                    
                with gr.Column(scale=1):
                    search_status = gr.Markdown("Click **Execute Semantic Search** to run.")
                    search_results = gr.DataFrame(
                        label="Ranked Search Results",
                        headers=["Rank", "Similarity Score", "Match Quality", "Document"],
                        wrap=True
                    )
            
            search_btn.click(
                fn=semantic_search,
                inputs=[query_in, corpus_in, top_k_slider],
                outputs=[search_results, search_status]
            )
            
            gr.Examples(
                examples=[
                    [
                        "How can AI assist doctors in diagnosis?",
                        SEARCH_DEFAULT_CORPUS,
                        4
                    ],
                    [
                        "Space exploration and rocket engines",
                        SEARCH_DEFAULT_CORPUS,
                        3
                    ]
                ],
                inputs=[query_in, corpus_in, top_k_slider],
                outputs=[search_results, search_status],
                fn=semantic_search,
                cache_examples=False
            )

        # --- TAB 2: Similarity Heatmap ---
        with gr.TabItem("📊 Similarity Matrix & Heatmap"):
            gr.Markdown("#### Compare multiple sentences at once with an interactive cosine similarity matrix.")
            with gr.Row():
                with gr.Column(scale=1):
                    matrix_sentences = gr.Textbox(
                        value=SIMILARITY_DEFAULT_SENTENCES,
                        label="Sentences to Compare (one per line)",
                        lines=10,
                        placeholder="Enter 2 to 10 sentences to compute pairwise similarities..."
                    )
                    matrix_btn = gr.Button("📊 Compute Similarity Matrix", variant="primary")
                    
                with gr.Column(scale=1):
                    heatmap_plot = gr.Plot(label="Cosine Similarity Heatmap")
                    
            with gr.Row():
                pairs_table = gr.DataFrame(
                    label="Sorted Pairwise Similarity Rankings",
                    headers=["Sentence 1", "Sentence 2", "Cosine Similarity", "Similarity (%)"],
                    wrap=True
                )
                
            matrix_btn.click(
                fn=compute_similarity_matrix,
                inputs=[matrix_sentences],
                outputs=[heatmap_plot, pairs_table]
            )

        # --- TAB 3: 2D Semantic Space Visualizer ---
        with gr.TabItem("🌌 2D Semantic Space (PCA)"):
            gr.Markdown("#### Project 384-dimensional sentence vectors onto a 2D space to observe semantic clustering.")
            with gr.Row():
                with gr.Column(scale=1):
                    pca_corpus = gr.Textbox(
                        value=SPACE_2D_DEFAULT_CORPUS,
                        label="Sentences to Cluster (one per line, minimum 3)",
                        lines=12,
                        placeholder="Enter sentences spanning multiple topic categories..."
                    )
                    pca_btn = gr.Button("🌌 Project & Visualize in 2D", variant="primary")
                    
                with gr.Column(scale=2):
                    pca_plot = gr.Plot(label="2D Interactive Embedding Scatter Plot")
                    
            pca_btn.click(
                fn=visualize_2d_embeddings,
                inputs=[pca_corpus],
                outputs=[pca_plot]
            )

        # --- TAB 4: Vector Inspector ---
        with gr.TabItem("🔬 Embedding Vector Diagnostics"):
            gr.Markdown("#### Inspect vector statistics, normalization, dimension distribution, and raw float values.")
            with gr.Row():
                with gr.Column(scale=1):
                    inspect_text = gr.Textbox(
                        value="Antigravity AI intelligent pair programming agent.",
                        label="Input Text",
                        lines=3
                    )
                    inspect_btn = gr.Button("🔬 Inspect Vector", variant="primary")
                    inspect_summary = gr.Markdown()
                    
                with gr.Column(scale=1):
                    inspect_preview = gr.Code(label="First 16 Dimension Values Preview", language="json")
                    inspect_dist_plot = gr.Plot(label="Dimension Value Histogram")
                    
            inspect_btn.click(
                fn=inspect_vector,
                inputs=[inspect_text],
                outputs=[inspect_summary, inspect_preview, inspect_dist_plot]
            )

    gr.Markdown(
        """
        ---
        💡 **Model Reference**: [sentence-transformers/all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) | Ready for deployment to **Hugging Face Spaces**.
        """
    )

if __name__ == "__main__":
    demo.launch(mcp_server=True)
