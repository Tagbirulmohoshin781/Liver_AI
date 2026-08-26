# MEMORY.md — LiverAI Persistent Architectural Context

## Identity & Roles
- **Authoritative Identity**: Firebase Auth (Google, Facebook, Email/Password).
- **Authorization**: Supabase PostgreSQL with Row Level Security (RLS) enabled on all tables (\users\, \chat_history\, \iopsy_reports\, \system_metrics\, \clinical_records\).
- **Admin Accounts**: Explicit administrator role assignment via database or Firebase custom claims; no auto-seeded default admin accounts.

## Data Isolation & Storage
- **Chat History**: Scoped by \user_id\ and \session_id\.
- **Uploads**: Stored with randomized UUIDs in secure temporary storage during inference; no direct filesystem paths exposed to client.
- **RAG Knowledge Base**: Global curated medical KB (\Data/\) remains immutable during user sessions. User documents are passed in-session as untrusted data contexts only.
