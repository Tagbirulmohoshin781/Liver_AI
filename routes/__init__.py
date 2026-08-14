"""
routes package initializer
===========================
Exports all Flask Blueprints for modular registration in app.py.
"""

from .main_routes import main_bp
from .auth_routes import auth_bp
from .chat_routes import chat_bp
from .profile_routes import profile_bp
from .admin_routes import admin_bp
from .clinical_routes import clinical_bp

__all__ = [
    "main_bp",
    "auth_bp",
    "chat_bp",
    "profile_bp",
    "admin_bp",
    "clinical_bp",
]
