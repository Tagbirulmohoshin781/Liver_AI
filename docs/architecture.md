# LiverAI System Architecture

## Overview
LiverAI is an AI-assisted medical education and research support system providing clinical guidelines-grounded dialogue, experimental liver risk estimation heuristics, and digital pathology analysis capabilities.

\\\mermaid
graph TD
    Client[Web Browser / Flutter Mobile App]
    Firebase[Firebase Auth]
    Flask[Flask 3.x Backend on Render]
    Supabase[Supabase PostgreSQL with RLS]
    Pinecone[Pinecone Vector Index]
    Gemini[Google Gemini 2.5 Flash / 2.0 Flash]
    ONNX[ONNX EfficientNet-B0 Histology Model]

    Client -->|Identity Auth| Firebase
    Client -->|API Requests + Bearer/Cookie| Flask
    Flask -->|Session / User Profile Storage (RLS Enabled)| Supabase
    Flask -->|Vector Retrieval (Curated KB)| Pinecone
    Flask -->|Contextual Grounded Generation| Gemini
    Flask -->|Image Inference (Safe Sandbox)| ONNX
\\\

## Data Boundaries
1. **Curated Global Knowledge Base**: Read-only clinical documents from AASLD/CDC stored in Pinecone/local index.
2. **User Uploads**: Handled in ephemeral temporary storage; never appended to global vector store.
3. **Identity & Storage**: Firebase provides authentication; Supabase PostgreSQL enforces row-level security.
