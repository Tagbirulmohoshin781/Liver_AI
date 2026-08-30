"""
tests/e2e/conftest.py
=====================
Global Pytest fixtures for all E2E Web and Cross-Platform test suites.
"""

import os
import io
import sys
import pytest
from PIL import Image

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from app import create_app
from src.db import register_user, authenticate_user


@pytest.fixture(scope="session")
def app():
    """Create a configured Flask application for E2E testing."""
    os.environ["APP_ENV"] = "testing"
    os.environ["ENABLE_EXPERIMENTAL_CLINICAL_SCORE"] = "true"
    os.environ["ENABLE_VISION_SIMULATION"] = "true"

    flask_app = create_app()
    flask_app.config.update({
        "TESTING": True,
        "SECRET_KEY": "e2e_test_secret_key_liverai_secure",
        "SERVER_NAME": "localhost.localdomain",
    })
    return flask_app


@pytest.fixture
def client(app):
    """Provides a fresh Flask test client."""
    return app.test_client()


@pytest.fixture
def registered_user():
    """Fixture providing a known test user."""
    test_username = "Dr. QA Specialist"
    test_email = "qa.sdet.lead@liverai.health"
    test_password = "SecurePassword123!"

    ok, msg, uid = register_user(test_username, test_email, test_password)
    user = authenticate_user(test_email, test_password)
    uid = user["id"] if user else (uid or 1)
    return {
        "id": uid,
        "username": test_username,
        "email": test_email,
        "password": test_password,
    }


@pytest.fixture
def authenticated_client(client, registered_user):
    """Provides a test client authenticated as the test user."""
    with client.session_transaction() as sess:
        sess["user_id"] = registered_user["id"]
        sess["username"] = registered_user["username"]
        sess["email"] = registered_user["email"]
        sess["is_admin"] = True
    return client


@pytest.fixture
def sample_biopsy_image_bytes():
    """Generates a synthetic 224x224 RGB histology slide patch image in memory."""
    img = Image.new("RGB", (224, 224), color=(180, 70, 120))
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)
    return buffer.getvalue()


@pytest.fixture
def sample_clinical_lpd_data():
    """Standard 10-biomarker LPD clinical test payload."""
    return {
        "age": 52,
        "gender": 1,  # Male
        "total_bilirubin": 2.4,
        "direct_bilirubin": 1.1,
        "alkaline_phosphotase": 240,
        "sgpt": 85,  # ALT
        "sgot": 78,  # AST
        "total_proteins": 6.2,
        "albumin": 3.0,
        "ag_ratio": 0.94,
    }
