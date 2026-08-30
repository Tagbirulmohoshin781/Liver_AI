# tests/e2e/web/pages/__init__.py
from .base_page import BasePage
from .login_page import LoginPage
from .chat_page import ChatPage
from .biopsy_page import BiopsyPage
from .clinical_predictor_page import ClinicalPredictorPage
from .settings_page import SettingsPage
from .profile_page import ProfilePage

__all__ = [
    "BasePage",
    "LoginPage",
    "ChatPage",
    "BiopsyPage",
    "ClinicalPredictorPage",
    "SettingsPage",
    "ProfilePage",
]
