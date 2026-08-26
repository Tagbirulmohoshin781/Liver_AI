import os

# Gunicorn configuration file for LiverAI
# Optimized for cloud deployment (Render, Railway, Fly.io, Heroku)

port = os.getenv("PORT", "5000")
bind = f"0.0.0.0:{port}"
workers = int(os.getenv("WEB_CONCURRENCY", 1))
threads = int(os.getenv("GUNICORN_THREADS", 2))
timeout = 120
keepalive = 5
accesslog = "-"
errorlog = "-"
loglevel = "info"
preload_app = False
