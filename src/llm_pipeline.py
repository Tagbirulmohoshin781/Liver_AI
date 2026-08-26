"""
src/llm_pipeline.py
====================
Isolated RAG + LLM pipeline for LiverAI.

Responsibilities:
  - Load local documents (PDF, TXT, CSV) from the Data/ directory.
  - Connect to Pinecone vector store (initialized in a background thread so
    the Flask server starts instantly and the first chat message triggers
    a warm fallback if the index is not yet ready).
  - Build the Gemini + LangChain RAG chain.
  - Expose generate_rag_answer() as the single entry point called by app.py.
"""

import os
import re
import time
import threading
import warnings

warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings("ignore", category=DeprecationWarning)

# ── Optional heavy imports (graceful fallback if missing) ─────────────────────
try:
    from langchain_pinecone import PineconeVectorStore
    HAS_PINECONE_LC = True
except ImportError:
    PineconeVectorStore = None
    HAS_PINECONE_LC = False

try:
    from langchain_google_genai import ChatGoogleGenerativeAI
    HAS_GENAI_LC = True
except ImportError:
    ChatGoogleGenerativeAI = None
    HAS_GENAI_LC = False

try:
    from langchain.chains import create_retrieval_chain
    from langchain.chains.combine_documents import create_stuff_documents_chain
    HAS_CHAINS = True
except ImportError:
    try:
        from langchain_classic.chains.retrieval import create_retrieval_chain         # type: ignore
        from langchain_classic.chains.combine_documents import create_stuff_documents_chain  # type: ignore
        HAS_CHAINS = True
    except ImportError:
        create_retrieval_chain = None
        create_stuff_documents_chain = None
        HAS_CHAINS = False

try:
    from langchain_core.prompts import ChatPromptTemplate
    HAS_PROMPTS = True
except ImportError:
    ChatPromptTemplate = None
    HAS_PROMPTS = False

try:
    from pinecone import Pinecone, ServerlessSpec
    HAS_PINECONE = True
except ImportError:
    Pinecone = None
    ServerlessSpec = None
    HAS_PINECONE = False

from .helper import (
    load_all_files, load_txt_files, filter_to_minimal_docs, text_split, download_embeddings
)
from .prompt import system_prompt

try:
    from .lora_inference import generate_lora_answer, is_lora_available
    HAS_LORA = True
except ImportError:
    try:
        from lora_inference import generate_lora_answer, is_lora_available
        HAS_LORA = True
    except ImportError:
        generate_lora_answer = None
        is_lora_available = lambda: False
        HAS_LORA = False

# ── Config from environment ───────────────────────────────────────────────────
PINECONE_API_KEY = (
    os.getenv("PINECONE_API_KEY", "") or os.getenv("PINECONE_API_KEY_ALT", "")
).strip()
GOOGLE_API_KEY = (
    os.getenv("GOOGLE_API", "") or os.getenv("GOOGLE_API_KEY", "") or
    os.getenv("GOOGLE_AI_API_KEY", "")
).strip()
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "").strip()
DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-chat").strip()
OPENAI_API_KEY = (
    os.getenv("OPENAI_API_KEY", "") or os.getenv("LLM_API_KEY", "") or os.getenv("OPENAI_API", "")
).strip()
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini").strip()

INDEX_NAME     = "chatbot-store"
PRIMARY_MODEL  = "gemini-1.5-flash"
FALLBACK_MODELS = ["gemini-2.0-flash", "gemini-1.5-pro", "gemini-2.5-flash"]

# ── Vision system prompt (no {context} placeholder) ───────────────────────────
_VISION_SYSTEM_PROMPT = (
    "You are LiverAI — a highly accurate, evidence-based, and empathetic medical health assistant "
    "specializing in liver health and histology analysis.\n\n"
    "SYSTEM DIRECTIVES:\n"
    "1. ACCURACY: Provide conservative, factual medical information grounded in AASLD/CDC guidelines.\n"
    "2. LANGUAGE: Use clear, empathetic, easy-to-understand language.\n"
    "3. MARKDOWN FORMATTING (REQUIRED): Use **bold** for medical terms, bullet lists (- item) for "
    "symptoms/features, and > blockquotes for important warnings.\n"
    "4. EMERGENCY TRIAGE: For acute signs (vomiting blood, black stools, severe jaundice with "
    "confusion), instruct the user to immediately call emergency services (911/112/ER).\n"
    "5. DISCLAIMER: Always end with: '*Please consult your healthcare provider for clinical "
    "diagnosis and personalized treatment.*'\n"
)

# ── Module-level state (managed by background init thread) ────────────────────
_lock          = threading.Lock()
_rag_ready     = False        # True once Pinecone + chains are built
_retriever     = None         # Pinecone or LocalFallback retriever
_docsearch     = None         # PineconeVectorStore instance (may be None)
_rag_chain     = None         # (model_name, chain) cache — rebuilt per model
_local_docs    = []


# =============================================================================
# Local Fallback Retriever
# =============================================================================
class LocalFallbackRetriever:
    """Simple in-process TF-style retriever over the bundled project data."""

    def __init__(self, documents):
        self.documents = documents

    def invoke(self, query: str):
        query_terms = [t for t in re.findall(r"[a-z0-9]+", query.lower()) if len(t) > 2]
        if not query_terms:
            return self.documents[:5]

        scored = []
        for doc in self.documents:
            content = (doc.page_content or "").lower()
            score   = sum(content.count(term) for term in query_terms)
            if score > 0:
                scored.append((score, doc))

        scored.sort(key=lambda item: item[0], reverse=True)
        return [doc for _, doc in scored[:6]]


# =============================================================================
# Background Initialization Thread
# =============================================================================
def _background_init():
    """Load local docs, connect to Pinecone, build RAG prompt — all off the main thread."""
    global _rag_ready, _retriever, _docsearch, _local_docs
    import gc

    # 1. Load lightweight text documents for fast startup and low RAM consumption (< 1MB)
    print("[RAG] Loading local fallback clinical documents from Data/ ...")
    raw = load_txt_files("Data")
    minimal = filter_to_minimal_docs(raw)
    chunks = text_split(minimal)
    with _lock:
        _local_docs = chunks
        _retriever = LocalFallbackRetriever(chunks)   # instant local retriever
        _rag_ready = True                             # mark ready immediately so server is 100% responsive
    print(f"[RAG] {len(chunks)} local fallback chunks ready.")
    gc.collect()

    # 2. Connect to Pinecone (optional cloud vector enhancement)
    if not (PINECONE_API_KEY and HAS_PINECONE and HAS_PINECONE_LC):
        print("[RAG] Pinecone credentials unavailable — using local documents only.")
        return

    try:
        print("[RAG] Connecting to Pinecone with zero-RAM cloud embeddings ...")
        embedding = download_embeddings()

        os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
        pc = Pinecone(api_key=PINECONE_API_KEY)

        existing = pc.list_indexes().names()
        if INDEX_NAME in existing:
            print(f"[RAG] Index '{INDEX_NAME}' found — connecting vector store ...")
            ds = PineconeVectorStore.from_existing_index(
                index_name=INDEX_NAME, embedding=embedding
            )
            ret = ds.as_retriever(
                search_type="mmr",
                search_kwargs={"k": 8, "fetch_k": 20, "lambda_mult": 0.7},
            )
            with _lock:
                _docsearch = ds
                _retriever = ret
            print("[RAG] Pinecone retriever connected successfully ✓")
        else:
            print(f"[RAG] Index '{INDEX_NAME}' not found in Pinecone. Using local knowledge base.")
        gc.collect()

    except Exception as exc:
        print(f"[RAG] Pinecone connection notice: {exc} — continuing with local clinical retriever.")



def init_rag_pipeline():
    """Call once at app startup. Spawns background init thread and returns immediately."""
    t = threading.Thread(target=_background_init, daemon=True, name="rag-init")
    t.start()
    print("[RAG] Background initialization started — server is ready to accept requests.")


# =============================================================================
# Helper: Local-docs fallback answer
# =============================================================================
def build_local_fallback_answer(user_msg: str, docs=None) -> str:
    """Generate a grounded fallback answer from local document chunks or fine-tuned LoRA model."""
    relevant_docs = docs or []
    query_terms = [t for t in re.findall(r"[a-z0-9]+", user_msg.lower()) if len(t) > 2]

    selected = []
    context_text = ""
    if relevant_docs:
        scored = []
        for doc in relevant_docs:
            content = (doc.page_content or "").lower()
            score   = sum(content.count(t) for t in query_terms) if query_terms else 1
            if score > 0:
                scored.append((score, doc))
        scored.sort(key=lambda item: item[0], reverse=True)
        selected = [d.page_content.strip() for _, d in scored[:3] if d.page_content.strip()]
        context_text = "\n\n".join(selected)

    # Try fine-tuned local LoRA model (Phi-3 + liver-lora) if available
    try:
        from .lora_inference import generate_lora_answer
        print("[RAG] Attempting inference using fine-tuned Liver LoRA model...")
        lora_ans = generate_lora_answer(prompt=user_msg, context=context_text, system_prompt=system_prompt)
        if lora_ans and len(lora_ans.strip()) > 10:
            print(f"[RAG] Liver LoRA response generated ({len(lora_ans)} chars) ✓")
            return lora_ans
    except Exception as lora_err:
        print(f"[RAG] Liver LoRA model unavailable or failed: {lora_err}")

    intro = (
        "I'm using the local knowledge base bundled with this application because the "
        "external AI services are not available right now."
    )
    if selected:
        selected_text = "\n\n".join(f"- {s.strip()}" for s in selected if s)
        return (
            f"{intro}\n\nRelevant information:\n{selected_text}\n\n"
            "*Please consult your healthcare provider for clinical diagnosis and personalised treatment.*"
        )
    return (
        f"{intro}\n\nPlease try again once the external AI services are configured, "
        "or use the local liver-health resources in the project data.\n\n"
        "*Please consult your healthcare provider for clinical diagnosis and personalised treatment.*"
    )


# =============================================================================
# Helper: OpenAI API Fallback Answer
# =============================================================================
def generate_openai_answer(system_prompt_str: str, user_input_str: str, temperature: float = 0.25) -> str:
    """Generate answer using OpenAI-compatible Chat Completion API (OpenAI, Groq, OpenRouter, Ollama, etc.)."""
    key = (os.getenv("OPENROUTER_API_KEY", "") or os.getenv("OPENAI_API_KEY", "") or os.getenv("LLM_API_KEY", "") or os.getenv("GROQ_API_KEY", "") or os.getenv("OPENAI_API", "")).strip()
    if not key:
        return ""
    try:
        import urllib.request
        import json
        
        base_url = (os.getenv("OPENAI_BASE_URL", "") or os.getenv("LLM_BASE_URL", "")).rstrip("/")
        if not base_url:
            if key.startswith("sk-or-v1-"):
                base_url = "https://openrouter.ai/api/v1"
            elif key.startswith("gsk_"):
                base_url = "https://api.groq.com/openai/v1"
            else:
                base_url = "https://api.openai.com/v1"
                
        url = f"{base_url}/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {key}",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            "HTTP-Referer": "http://127.0.0.1:5000",
            "X-Title": "LiverAI Medical Assistant"
        }

        # Model selection logic with fallbacks
        env_model = os.getenv("OPENAI_MODEL", "").strip()
        models_to_try = []
        if env_model:
            models_to_try.append(env_model)
        if key.startswith("sk-or-v1-") or "openrouter" in base_url:
            models_to_try.extend(["openrouter/auto", "meta-llama/llama-3.3-70b-instruct", "deepseek/deepseek-r1:free", "google/gemini-2.0-flash-001", "meta-llama/llama-3.1-8b-instruct:free"])
        elif key.startswith("gsk_") or "groq" in base_url:
            models_to_try.extend(["llama-3.3-70b-versatile", "llama-3.1-8b-instant", "mixtral-8x7b-32768"])
        else:
            models_to_try.extend(["gpt-4o-mini", "gpt-3.5-turbo", "gpt-4o"])

        # Deduplicate preserving order
        models_to_try = list(dict.fromkeys(models_to_try))

        for model in models_to_try:
            try:
                payload = {
                    "model": model,
                    "messages": [
                        {"role": "system", "content": system_prompt_str},
                        {"role": "user", "content": user_input_str}
                    ],
                    "temperature": temperature,
                    "max_tokens": 4096
                }
                data = json.dumps(payload).encode("utf-8")
                req = urllib.request.Request(url, data=data, headers=headers, method="POST")
                with urllib.request.urlopen(req, timeout=30) as resp:
                    res_data = json.loads(resp.read().decode("utf-8"))
                    choice = res_data.get("choices", [{}])[0]
                    answer = choice.get("message", {}).get("content", "").strip()
                    if answer:
                        print(f"[LLM] Answer via API ({model}) ({len(answer)} chars)")
                        return answer
            except Exception as me:
                print(f"[LLM Warning] Model '{model}' via {base_url} failed: {me}")
    except Exception as e:
        print(f"[LLM Error] API call failed: {e}")
    return ""


# =============================================================================
# Histology Vision Analysis (PyTorch)
# =============================================================================
def analyze_histology_image(image_path: str) -> dict:
    """Run fine-tuned EfficientNet-B0 histology model and return label scores."""
    weights_path = os.path.join("models", "liver_vision", "best_model.pth")
    if not os.path.exists(image_path):
        return {}
    try:
        from .vision_inference import predict_image
        res = predict_image(image_path)
        if res.get("success") and res.get("predictions"):
            return {k: v.get("probability", 0.0) for k, v in res.get("predictions").items()}
        return {}
    except Exception as e:
        print(f"[Histology Error] {e}")
        return {}


# =============================================================================
# DeepSeek API Integration (deepseek-chat / deepseek-reasoner)
# =============================================================================
def generate_deepseek_answer(
    system_prompt_str: str,
    user_input_str: str,
    temperature: float = 0.25,
) -> str:
    """
    Generate an answer using the DeepSeek API.
    Supports OpenAI Python SDK (OpenAI-compatible client) or HTTP requests fallback.
    """
    if not DEEPSEEK_API_KEY:
        return ""

    model_name = DEEPSEEK_MODEL or "deepseek-chat"
    messages = [
        {"role": "system", "content": system_prompt_str},
        {"role": "user", "content": user_input_str},
    ]

    # 1. Try OpenAI SDK (OpenAI-compatible client)
    try:
        from openai import OpenAI
        client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url="https://api.deepseek.com")
        response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            temperature=temperature,
            max_tokens=4096,
        )
        if response.choices and response.choices[0].message.content:
            answer = response.choices[0].message.content.strip()
            print(f"[DeepSeek] Answer via OpenAI SDK '{model_name}' ({len(answer)} chars) ✓")
            return answer
    except ImportError:
        pass
    except Exception as exc:
        print(f"[DeepSeek Warning] OpenAI SDK failed: {exc}")

    # 2. Direct HTTP API fallback (requests)
    try:
        import requests
        headers = {
            "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": model_name,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": 4096,
        }
        resp = requests.post(
            "https://api.deepseek.com/chat/completions",
            headers=headers,
            json=payload,
            timeout=30,
        )
        if resp.status_code == 200:
            data = resp.json()
            answer = data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
            if answer:
                print(f"[DeepSeek] Answer via HTTP API '{model_name}' ({len(answer)} chars) ✓")
                return answer
        else:
            print(f"[DeepSeek Warning] HTTP status {resp.status_code}: {resp.text[:200]}")
    except Exception as exc:
        print(f"[DeepSeek Error] HTTP request failed: {exc}")

    return ""


# =============================================================================
# Main Entry Point: generate_rag_answer()
# =============================================================================
def generate_rag_answer(
    user_msg: str,
    image_path: str = None,
    temperature: float = 0.25,
    chat_history: list = None,
) -> str:
    """
    Single public interface for all LLM responses.
    - If image_path provided → multimodal Gemini Vision + local PyTorch histology model.
    - Otherwise → standard text RAG chain (Gemini, DeepSeek, or Pinecone MMR).
    - Falls back to local documents if external services are unavailable.
    """
    chat_history = chat_history or []

    with _lock:
        retriever = _retriever
        docsearch = _docsearch

    # ── PRE-FETCH docs (for fallback and context) ─────────────────────────────
    docs = []
    try:
        if retriever:
            docs = retriever.invoke(user_msg)
    except Exception as ret_err:
        print(f"[Retriever Warning] {type(ret_err).__name__}: {ret_err}")

    # ── MULTIMODAL VISION PATH ────────────────────────────────────────────────
    if image_path and os.path.exists(image_path):
        try:
            from google import genai as new_genai
            from PIL import Image as PILImage

            if not GOOGLE_API_KEY:
                raise RuntimeError("Google API key is not configured.")

            client = new_genai.Client(api_key=GOOGLE_API_KEY)
            img = PILImage.open(image_path).convert("RGB")

            histology_scores = analyze_histology_image(image_path)
            histology_ctx = ""
            if histology_scores:
                histology_ctx = (
                    "\n\n[Fine-Tuned PyTorch Histology Model Confidence Scores]:\n"
                    + "\n".join(f"- {k.capitalize()}: {v}%" for k, v in histology_scores.items())
                    + "\n(Integrate these scores into your histological analysis.)"
                )

            context_str = "\n\n".join(d.page_content for d in docs[:6]) if docs else ""
            history_ctx = ""
            if chat_history:
                history_ctx = "\n\nConversation History (most recent last):\n"
                for turn in chat_history[-6:]:
                    role = "User" if turn["role"] == "user" else "LiverAI"
                    history_ctx += f"{role}: {turn['content']}\n"

            vision_prompt = (
                f"{_VISION_SYSTEM_PROMPT}\n\n"
                f"Context from Knowledge Base:\n{context_str}"
                f"{histology_ctx}{history_ctx}\n\n"
                f"User Question: {user_msg}\n\n"
                "Please analyse the uploaded medical image carefully and provide a clear, "
                "supportive diagnostic interpretation."
            )

            for m_name in ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-2.5-flash"]:
                try:
                    response = client.models.generate_content(
                        model=m_name,
                        contents=[vision_prompt, img],
                    )
                    if response.text:
                        print(f"[Vision] Answer via '{m_name}' ({len(response.text)} chars)")
                        return response.text
                except Exception as ve:
                    print(f"[Vision Warning] '{m_name}' failed: {ve}")
        except Exception as e:
            print(f"[Vision Error] {e}. Falling back to text RAG ...")

    # ── TEXT RAG PIPELINE ─────────────────────────────────────────────────────
    # Build conversation-augmented query with history
    augmented_input = user_msg
    if chat_history:
        history_lines = []
        for turn in chat_history[-6:]:
            role = "User" if turn["role"] == "user" else "LiverAI"
            history_lines.append(f"{role}: {turn['content']}")
        augmented_input = (
            f"[Conversation History]\n{chr(10).join(history_lines)}\n\n"
            f"[Current Question]\n{user_msg}"
        )

    # Build context from retrieved docs & histology findings
    context_str = ""
    if docs:
        context_str = "\n\n".join(d.page_content for d in docs[:8])

    if image_path and os.path.exists(image_path):
        histology_scores = analyze_histology_image(image_path)
        if histology_scores:
            hist_lines = [f"- {k.replace('_', ' ').title()}: {v}% ({'DETECTED' if v>=50 else 'NOT DETECTED'})" for k, v in histology_scores.items()]
            context_str += "\n\n[Uploaded Biopsy Histology Patch Findings]:\n" + "\n".join(hist_lines)

    full_system_prompt = system_prompt.replace("{context}", context_str)
    full_prompt = full_system_prompt + "\n\nUser: " + augmented_input

    # ── Check if Fine-Tuned Liver LoRA Model should be used ─────────────────
    use_lora = os.getenv("USE_LORA_MODEL", "false").lower() in ("1", "true", "yes")
    if use_lora and HAS_LORA and is_lora_available():
        lora_ans = generate_lora_answer(prompt=augmented_input, context=context_str, system_prompt=full_system_prompt)
        if lora_ans:
            print(f"[LLM] Answer via fine-tuned Liver LoRA model ({len(lora_ans)} chars) ✓")
            return lora_ans

    # 0. Try OpenAI-compatible API if configured (Groq, OpenRouter, OpenAI, etc.)
    if OPENAI_API_KEY or os.getenv("LLM_API_KEY") or os.getenv("GROQ_API_KEY") or os.getenv("OPENROUTER_API_KEY"):
        oa_ans = generate_openai_answer(
            system_prompt_str=full_system_prompt,
            user_input_str=augmented_input,
            temperature=temperature,
        )
        if oa_ans:
            return oa_ans

    # 1. Try DeepSeek API if configured
    if DEEPSEEK_API_KEY:
        ds_ans = generate_deepseek_answer(
            system_prompt_str=full_system_prompt,
            user_input_str=augmented_input,
            temperature=temperature,
        )
        if ds_ans:
            return ds_ans

    # 2. Try Google Gemini (google.generativeai or google.genai SDK)
    if GOOGLE_API_KEY:
        # A. Try standard google.generativeai SDK
        try:
            import google.generativeai as legacy_genai
            legacy_genai.configure(api_key=GOOGLE_API_KEY)
            for model_name in ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-2.0-flash"]:
                try:
                    gm = legacy_genai.GenerativeModel(model_name)
                    res = gm.generate_content(full_prompt)
                    if res and res.text:
                        answer = res.text.strip()
                        print(f"[LLM] Answer via google.generativeai '{model_name}' ({len(answer)} chars)")
                        return answer
                except Exception as me:
                    print(f"[LLM] google.generativeai '{model_name}' failed: {me}")
        except Exception as e:
            print(f"[LLM] google.generativeai error: {e}")

        # B. Try new google.genai SDK
        try:
            from google import genai as new_genai
            client = new_genai.Client(api_key=GOOGLE_API_KEY)
            for model_name in ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-2.5-flash"]:
                try:
                    response = client.models.generate_content(
                        model=model_name,
                        contents=full_prompt,
                    )
                    answer = (response.text or "").strip()
                    if answer:
                        print(f"[LLM] Answer via google.genai '{model_name}' ({len(answer)} chars)")
                        return answer
                except Exception as e:
                    print(f"[LLM] google.genai '{model_name}' failed: {e}")
        except Exception as e:
            print(f"[LLM] google.genai error: {e}")

    # 3. Try LangChain RAG chain if available
    if GOOGLE_API_KEY and HAS_GENAI_LC and HAS_CHAINS and retriever is not None:
        rag_prompt = None
        if HAS_PROMPTS and ChatPromptTemplate is not None:
            rag_prompt = ChatPromptTemplate.from_messages([
                ("system", system_prompt),
                ("human", "{input}"),
            ])

        for model_name in ["gemini-2.0-flash", "gemini-1.5-flash"]:
            try:
                chat_model = ChatGoogleGenerativeAI(
                    model=model_name,
                    google_api_key=GOOGLE_API_KEY,
                    temperature=temperature,
                    max_output_tokens=4096,
                )
                qa_chain  = create_stuff_documents_chain(chat_model, rag_prompt)
                rag_chain = create_retrieval_chain(retriever, qa_chain)
                response  = rag_chain.invoke({"input": augmented_input})
                answer    = str(response.get("answer", "")).strip()
                if answer:
                    print(f"[LLM] LangChain answer via '{model_name}' ({len(answer)} chars)")
                    return answer
            except Exception as e:
                print(f"[LLM Warning] LangChain '{model_name}' failed: {e}")

    print("[LLM] All AI paths failed. Using local knowledge base fallback.")
    return build_local_fallback_answer(user_msg, docs=docs)


def get_docsearch():
    """Returns the current PineconeVectorStore instance (may be None if not ready)."""
    with _lock:
        return _docsearch


def is_rag_ready() -> bool:
    """Returns True if the RAG pipeline has finished loading documents."""
    with _lock:
        return bool(_rag_ready)

