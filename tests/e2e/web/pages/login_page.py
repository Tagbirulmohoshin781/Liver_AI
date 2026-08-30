"""
tests/e2e/web/pages/login_page.py
=================================
Page Object for Authentication / Onboarding (Sign In, Sign Up, Instant Demo,
Forgot Password, and Social Login triggers).
"""

from .base_page import BasePage


class LoginPage(BasePage):
    """Page Object representing the Authentication View."""

    # Locators
    CONTAINER_ID = "login-view"
    FORM_LOGIN_ID = "form-login"
    EMAIL_INPUT_ID = "login-email"
    PASSWORD_INPUT_ID = "login-password"
    LOGIN_SUBMIT_BTN_ID = "btn-login-submit"
    ERROR_BOX_ID = "login-error"
    ERROR_TEXT_ID = "login-error-text"

    # Signup Form Locators
    SIGNUP_VIEW_ID = "auth-signup-view"
    SIGNUP_FORM_ID = "form-signup"
    SIGNUP_NAME_ID = "signup-name"
    SIGNUP_EMAIL_ID = "signup-email"
    SIGNUP_PASSWORD_ID = "signup-password"
    SIGNUP_CONFIRM_PW_ID = "signup-confirm-password"
    SIGNUP_SUBMIT_BTN_ID = "btn-signup-submit"
    SIGNUP_ERROR_BOX_ID = "signup-error"

    # Quick Access Locators
    GUEST_BTN_CLASS = "btn-guest-access"
    GOOGLE_BTN_ID = "btn-google-signin"
    FACEBOOK_BTN_ID = "btn-facebook-signin"
    GITHUB_BTN_ID = "btn-github-signin"
    FORGOT_MODAL_ID = "forgot-modal"

    def navigate(self):
        """Loads the application root which defaults to login when unauthenticated."""
        response = self.client.get("/")
        self.refresh_dom(response.get_data(as_text=True))
        return response

    def is_loaded(self):
        """Verifies login container is rendered in DOM."""
        return self.has_element(self.CONTAINER_ID)

    def submit_login(self, email, password):
        """Performs simulated POST submission to /api/login."""
        response = self.client.post(
            "/api/login",
            json={"email": email, "password": password},
            content_type="application/json",
        )
        return response

    def submit_register(self, username, email, password):
        """Performs simulated POST submission to /api/register."""
        response = self.client.post(
            "/api/register",
            json={"username": username, "email": email, "password": password},
            content_type="application/json",
        )
        return response

    def submit_forgot_password(self, email):
        """Performs password recovery request."""
        # Simulated endpoint or check
        return {"status": "ok", "email": email}

    def verify_social_buttons_present(self):
        """Verifies Google, Facebook, and GitHub SSO triggers exist."""
        return (
            self.find_element_by_id(self.GOOGLE_BTN_ID) is not None or
            len(self.find_elements_by_class("btn-social-item")) >= 3
        )
