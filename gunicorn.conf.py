import os

# Gunicorn configuration file for LiverAI
# Automatically detected by Gunicorn in any deployment environment

port = os.getenv("PORT", "5000")
bind = f"0.0.0.0:{port}"
workers = int(os.getenv("WEB_CONCURRENCY", 1))
threads = 4
timeout = 120
accesslog = "-"
errorlog = "-"
loglevel = "info"
