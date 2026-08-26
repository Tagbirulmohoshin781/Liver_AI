# TASKS.md — LiverAI Development & Hardening Roadmap

## Phase 1 — Baseline & Triage [COMPLETED]
- [x] Branch creation (\ntigravity/overnight-hardening-20260827\)
- [x] Neutralize default admin (\dmin@gmail.com\) and guest identity
- [x] Enable RLS on all 5 Supabase tables
- [x] Clean PAT from git remote configuration

## Phase 2 — Core Hardening [COMPLETED]
- [x] Remove default credential seeding from \src/db.py\
- [x] Remove shared guest identity anti-pattern
- [x] Gate vision simulation in production (\src/vision_inference.py\)
- [x] Fix Flask secret key generation in \pp.py\
- [x] Fix \save_chat_message\ parameter mismatch bug
- [x] Isolate RAG user uploads from global vector index
- [x] Add DOMPurify XSS sanitization to Markdown rendering
- [x] Add \/healthz\ and \/readyz\ endpoints with security headers

## Phase 3 — Verification & CI [IN PROGRESS]
- [ ] Automated security & contract test suite
- [ ] GitHub Actions CI workflow
- [ ] Final audit & OpenAPI spec
