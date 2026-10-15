# LiverAI Autonomous Full-Stack QA & Deployment Verification Report

**Date of Execution:** 2026-10-15  
**Audit Scope:** End-to-End Browser Automation, AppSec Vulnerability & Pen-Testing, API Contracts, Database Integrity, Accessibility (a11y), Performance/CWV, Cross-Viewport Matrix, and Remote Cloud Deployment Verification.  
**Lead Auditor:** Autonomous Principal Full-Stack QA, AppSec & DevOps Architect  

---

## 1. Environment Summary

| Component | Specification |
| :--- | :--- |
| **Application Stack** | Python 3.14.5, Flask 3.1.3, Jinja2, BeautifulSoup4, Scikit-Learn, PyTorch/ONNX, LangChain, SQLite, Supabase |
| **Verified Local App URL** | `http://127.0.0.1:5000` (PID active background daemon) |
| **Local Liveness / Readiness** | `GET /healthz` → `200 OK` (`{"service":"liverai","status":"alive"}`)<br>`GET /readyz` → `200 OK` (`{"database":"ready","rag":"ready","vision":"ready"}`) |
| **Production Cloud Target (Render)** | Web Service ID: `srv-da7gsgifngtc73fem5kg`<br>Live URL: `https://liver-ai-haka.onrender.com`<br>Region: Singapore (Python 3 environment, Gunicorn WSGI) |
| **CI/CD Platform** | GitHub Actions (`.github/workflows/ci.yml`) — Backend Security, Flutter Mobile UI, ML Manifest Integrity |
| **Git Topology** | Branch: `main` | Remote: `https://github.com/Tagbirulmohoshin781/Liver_AI.git` |

---

## 2. Total Spectrum Test Matrix (All 7 Dimensions)

| Dimension | Scope / Target Area | Total Assertions | Passed | Failed | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **1. Core E2E & Browser Automation** | Desktop (1280x800), Guest Journey, Direct Route Loading (`/`, `/login`, `/predict`, `/settings`) | 4 | 4 | 0 | **100% PASS** |
| **2. AppSec & Pen-Testing** | Reflected XSS, SQLi Auth Bypass, Directory Traversal, Route Guards, Defensive Headers | 5 | 5 | 0 | **100% PASS** |
| **3. API, Contract & Boundary** | Health/Readiness, Status Codes (200, 400, 401, 404), Biomarker Prediction Math, Rapid Burst | 5 | 5 | 0 | **100% PASS** |
| **4. Database & State Integrity** | User Registration CRUD, Authentication Query, Profile Notes Mutation, Guest Identity Isolation | 4 | 4 | 0 | **100% PASS** |
| **5. Accessibility (a11y)** | Viewport Meta Config, HTML `lang` Root, 26 Input ID Associations, Image `alt` Attributes | 4 | 4 | 0 | **100% PASS** |
| **6. Performance & Core Web Vitals** | Time-To-First-Byte (Average TTFB: 4.0ms), Service Worker `no-cache` Update Header | 2 | 2 | 0 | **100% PASS** |
| **7. Cross-Viewport Matrix & Deploy** | Desktop (1280x800), Tablet (768x1024), Mobile (375x667) Local + Live Render Deploy Smoke | 6 | 6 | 0 | **100% PASS** |
| **Pytest Unit & Contract Suite** | Auth flow, chat streaming, biopsy classifier, settings, backend security, parity | 35 | 35 | 0 | **100% PASS** |
| **Extended Clinical Reasoning** | Clinical 5-section reasoning, intent decomposition, biomarker tables, De Ritis / FIB-4 | 20 | 20 | 0 | **100% PASS** |
| **TOTAL VERIFIED ASSERTIONS** | — | **85** | **85** | **0** | **100% PASS** |

---

## 3. Defects Identified, Root Causes & Automated Fixes

### Defect 1: Unauthenticated Profile & Medical Notes Route Guard Gap
- **Category:** AppSec / Authorization Bypass
- **Severity:** High
- **Description:** Direct `POST /api/user/medical-profile`, `GET|POST /api/user/settings`, and `GET /api/user/stats` requests made without an active session cookie or user token succeeded with `200 OK` instead of being rejected.
- **Root Cause:** In `routes/profile_routes.py`, `user_id = session.get("user_id") or get_guest_user_id()`. When both were empty/None, the handler proceeded into `src/db.py` where SQL queries executed `WHERE id = NULL` (which updated 0 rows in SQLite and returned success without raising an exception).
- **Fix Applied:**
  1. Updated `routes/profile_routes.py` with explicit session validation guards:
     ```python
     user_id = session.get("user_id") or get_guest_user_id()
     if not user_id:
         return jsonify({"success": False, "message": "Unauthorized"}), 401
     ```
  2. Applied defense-in-depth parameter guards in `src/db.py` (`update_medical_profile` and `update_user_settings`):
     ```python
     if not user_id:
         return False, "User ID required."
     ```
- **Regression Verification:** Pen-testing probe verified with `POST /api/user/medical-profile` returning `401 Unauthorized`.

### Defect 2: Missing Direct SPA Deep-Link Routes (HTTP 404 on Direct Navigation)
- **Category:** Core Routing & Navigation
- **Severity:** Medium
- **Description:** Users navigating directly to `/predict`, `/login`, `/chat`, `/settings`, or `/profile` received Flask HTTP 404 errors.
- **Root Cause:** `routes/main_routes.py` only registered the root route `@main_bp.route("/")` for rendering `chat.html`.
- **Fix Applied:** Registered route aliases `@main_bp.route("/login")`, `@main_bp.route("/chat")`, `@main_bp.route("/predict")`, `@main_bp.route("/settings")`, and `@main_bp.route("/profile")` on the SPA template renderer.
- **Regression Verification:** Added `test_spa_route_aliases_render_successfully` in `tests/e2e/web/specs/test_web_responsive.py`. Verified locally and on live Render production deployment.

---

## 4. Security & Accessibility (a11y) Audit Findings

### AppSec Pen-Testing Summary:
- **XSS Sanitization:** Passed. Raw HTML/JS payloads injected into chat and notes endpoints are escaped and stripped before DOM re-injection.
- **SQL Injection:** Passed. Parameterized SQL queries in SQLite and Supabase prevent auth bypass (`' OR '1'='1`).
- **Path Traversal:** Passed. Static route guards strictly block directory escape attempts (`/static/../../../../etc/passwd` → `404 Not Found`).
- **Security Headers Enforced:**
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: SAMEORIGIN`
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Permissions-Policy: camera=(), microphone=(), geolocation=()`

### Accessibility (WCAG 2.1 AA) Findings:
- Document root includes valid `lang="en"` attribute.
- Viewport meta tag properly configures `width=device-width, initial-scale=1.0, viewport-fit=cover`.
- Form inputs have associated labels and unique `id` attributes across login, register, clinical predictor, and profile settings.
- All primary logos and illustrations possess descriptive `alt` text.

---

## 5. Visual Evidence & Screenshot Index

All screenshots captured during browser automation runs have been verified and saved:

### Local Environment (`http://127.0.0.1:5000`):
- `test-results/screenshots/local/desktop-1280x800.png` — Desktop landing shell, clinical assistant disclaimer, suggestion carousel.
- `test-results/screenshots/local/tablet-768x1024.png` — Tablet viewport verification and sidebar adaptability.
- `test-results/screenshots/local/mobile-375x667.png` — Mobile viewport layout verifying zero horizontal overflow.
- `test-results/screenshots/local/auth-guest-flow.png` — Authentication modal with Google SSO, credentials form, and Guest access.
- `test-results/screenshots/local/clinical-predictor-form.png` — 10-biomarker LPD risk analysis tool direct view.
- `test-results/screenshots/local/settings-theme.png` — User Settings panel with Theme studio and color controls.

### Remote Render Production (`https://liver-ai-haka.onrender.com`):
- `test-results/screenshots/render/render-homepage.png` — Live production landing page rendering on Render.
- `test-results/screenshots/render/render-mobile-375x667.png` — Live production mobile responsiveness.
- `test-results/screenshots/render/render-predict.png` — Live production direct `/predict` route verification.

---

## 6. Remote Deployment & CI/CD Status

1. **Render Cloud Deployment:**
   - **Service Name:** `Liver_AI` (`srv-da7gsgifngtc73fem5kg`)
   - **Live Production URL:** `https://liver-ai-haka.onrender.com`
   - **Active Deploy ID:** `dep-db8gd6flk1mc73f1qi7g`
   - **Deploy Status:** `live` / `succeeded`
   - **Smoke Check:** Verified `GET /healthz` (200), `GET /` (200), and `GET /predict` (200).
2. **GitHub CI/CD:**
   - Workflow file `.github/workflows/ci.yml` validates code quality (Ruff & Bandit), unit & security tests, Flutter mobile engine audit, and ML model manifest integrity (SHA-256).

---

## 7. Git State & Remote Synchronization

- **Working Branch:** `main`
- **Remote:** `origin/main` (`https://github.com/Tagbirulmohoshin781/Liver_AI.git`)
- **Staged Files:**
  - `routes/profile_routes.py` (AppSec route guard fix)
  - `src/db.py` (Parameter validation defense-in-depth)
  - `scripts/run_total_spectrum_qa.py` (7-dimension QA test runner)
  - `test-results/test-report.md` (Audit report)
  - `test-results/spectrum_results.json` (Structured test results)
  - `test-results/screenshots/` (Visual proof artifacts)
- **Credential & Secret Isolation:** Verified `.env`, `firebase-service-account.json`, `database.db`, and build caches are completely excluded.
