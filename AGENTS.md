# AGENTS.md — LiverAI AI Operating Governance

## System Directives
1. **Clinical Safety & Boundaries**: LiverAI is an educational and research support tool. Never claim clinical diagnostic validation without explicit regulatory approval.
2. **Tenant Isolation**: User medical data, uploads, and chat history must remain isolated. Never index user uploads into global vector stores.
3. **Fail-Closed Security**: Missing credentials in production must fail startup cleanly. Never default to insecure fallback credentials or unauthenticated data access.
4. **Verification Gates**: Every change must be verified with automated test suites before committing.

## Key Subsystems
- **Backend API**: Flask 3.x modular architecture with blueprints in \outes/\.
- **Database Layer**: Supabase PostgreSQL with RLS enabled; local SQLite for testing.
- **RAG Engine**: Pinecone vector store + local TF fallback; strict prompt boundary marking.
- **Vision Inference**: PyTorch / ONNX EfficientNet-B0; simulation strictly prohibited in production.
- **Mobile Client**: Flutter 3.x with clean architecture in \Liver Disease Detection App/lib/\.
