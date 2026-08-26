# RUNBOOK.md — LiverAI Operations & Runbook

## Local Development
\\\ash
# Install dependencies
pip install -r requirements.txt

# Run Flask backend
python app.py
\\\

## Health & Readiness Endpoints
- **Liveness**: \GET /healthz\ ? \{"status": "alive"}\ (200)
- **Readiness**: \GET /readyz\ ? \{"status": "ready", "database": "ready", "rag": "ready", ...}\ (200/503)

## Environment Variables
| Variable | Description | Default |
|---|---|---|
| \APP_ENV\ | Environment mode (\development\ / \production\) | \development\ |
| \FLASK_SECRET_KEY\ | Secret session encryption key | Ephemeral fallback |
| \SUPABASE_URL\ | Supabase project URL | Required in prod |
| \SUPABASE_KEY\ | Supabase anon/service API key | Required in prod |
| \GOOGLE_API_KEY\ | Gemini API key for LLM responses | Optional |
| \ENABLE_VISION_SIMULATION\ | Allow test fixtures for vision (dev only) | \alse\ |
| \ENABLE_EXPERIMENTAL_CLINICAL_SCORE\ | Allow heuristic risk calculator | \	rue\ |
