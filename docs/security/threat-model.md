# LiverAI Security & Threat Model

## Threat Matrix & Mitigations

| Threat | Risk Level | Mitigation Implemented |
|---|---|---|
| Default Admin Account Takeover | P0 Critical | Removed auto-seeded default admin credentials; invalidated live default admin; explicit role-based access. |
| Cross-Tenant Chat/Medical Leakage | P0 Critical | Row Level Security (RLS) enabled on all 5 Supabase tables; removed global shared guest identity. |
| Client-Controlled Filesystem Traversal | P0 Critical | Replaced raw filesystem path parameters with server-side UUID upload tokens. |
| RAG Knowledge Base Poisoning | P0 Critical | User document uploads are isolated per-session and never indexed into the shared global Pinecone store. |
| Prompt Injection via Uploaded PDFs | P1 High | Untrusted document attachments are strictly demarcated with clear boundary fences in LLM context. |
| Cross-Site Scripting (XSS) via Markdown | P1 High | Client-side DOMPurify sanitization applied to all parsed markdown outputs before DOM insertion. |
| Fabricated Diagnostic Results | P0 Critical | Simulation mode is strictly gated and refused in production (\APP_ENV=production\). |
