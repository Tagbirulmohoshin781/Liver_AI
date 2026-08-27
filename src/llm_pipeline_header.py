"""
LLM and RAG Pipeline Module for Liver Disease Clinical Reasoning.

Architecture:
- Intent-Aware Multi-Stage Dynamic Retrieval (NVIDIA RAG Blueprint Pattern)
- Multi-Hop Clinical Query Decomposition (NVIDIA AIQ-Research Pattern)
- Hierarchical Evidence Sourcing (AASLD Guidelines > EASL Guidelines > NCBI StatPearls)
- Strict 5-Section Markdown Clinical Output Structuring
- Automatic Fallback Cascade (Groq -> OpenRouter -> Direct OpenAI -> AASLD/EASL Knowledge Base)
"""

import os
import json
import base64
import urllib.request
import urllib.error
import re
from typing import List, Dict, Any, Optional

from dotenv import load_dotenv

load_dotenv()

# =============================================================================
# API Keys & Configurations
# =============================================================================
GOOGLE_API_KEY = os.getenv("GOOGLE_API") or os.getenv("GEMINI_API_KEY") or ""
GROQ_API_KEY = os.getenv("GROQ_API_KEY") or ""
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY") or ""
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY") or ""
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY") or os.getenv("LLM_API_KEY") or ""
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY") or ""
PINECONE_ENV = os.getenv("PINECONE_ENV") or "us-east-1"
PINECONE_INDEX_NAME = os.getenv("PINECONE_INDEX_NAME") or "liverai-index"

from src.prompt import (
    system_prompt,
    CLINICAL_GUIDES,
    FALLBACK_EN,
    classify_clinical_intent,
    extract_clinical_entities,
    build_local_fallback_answer,
    STRUCTURED_OUTPUT_SECTIONS
)
