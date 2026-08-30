"""
tests/e2e/web/specs/test_web_auth_flow.py
=========================================
E2E Test Spec for Authentication & Onboarding Journeys.
Tests:
  - AUTH-01: Valid Registration, Login, Session Persistence, /api/me
  - AUTH-02: Invalid Credentials, Missing Email/Password, Error Response Structure
  - AUTH-03: Guest Mode / Demo Access Isolation (no shared database identity)
  - AUTH-04: Logout & Session Teardown
"""

import uuid
import pytest
from tests.e2e.web.pages.login_page import LoginPage


class TestWebAuthFlow:

    def test_auth_page_dom_and_social_buttons_rendered(self, client):
        """Verify login view DOM renders all form fields and social SSO buttons."""
        page = LoginPage(client)
        res = page.navigate()
        assert res.status_code == 200
        assert page.is_loaded()
        assert page.find_element_by_id(page.EMAIL_INPUT_ID) is not None
        assert page.find_element_by_id(page.PASSWORD_INPUT_ID) is not None
        assert page.verify_social_buttons_present()

    def test_auth_valid_registration_and_login(self, client):
        """AUTH-01: Verify new user registration and subsequent login."""
        page = LoginPage(client)
        uid_str = uuid.uuid4().hex[:6]
        email = f"test.patient.{uid_str}@liverai.health"
        username = f"Alex Rivera {uid_str}"
        password = "Password@123"

        # Register
        reg_res = page.submit_register(username, email, password)
        assert reg_res.status_code in (200, 201)
        data = reg_res.get_json()
        assert data.get("success") is True

        # Verify /api/me session
        me_res = client.get("/api/me")
        assert me_res.status_code == 200
        me_data = me_res.get_json()
        assert me_data.get("authenticated") is True
        assert me_data["user"]["email"] == email.lower()

        # Logout
        logout_res = client.post("/api/logout")
        assert logout_res.status_code == 200

        # Login again
        login_res = page.submit_login(email, password)
        assert login_res.status_code == 200
        login_data = login_res.get_json()
        assert login_data.get("success") is True
        assert login_data["user"]["email"] == email.lower()

    def test_auth_invalid_credentials_handling(self, client):
        """AUTH-02: Verify invalid credentials return appropriate status and message."""
        page = LoginPage(client)
        res = page.submit_login("nonexistent.user@liverai.health", "WrongPassword!")
        assert res.status_code == 401
        data = res.get_json()
        assert data.get("success") is False
        assert "Invalid" in data.get("message", "")

    def test_auth_guest_isolation_security(self, client):
        """AUTH-03: Guest / Demo visitors must not receive a persistent database user ID."""
        from src.db import get_guest_user_id
        guest_id = get_guest_user_id()
        assert guest_id is None, "Guest isolation requires get_guest_user_id to be None."
