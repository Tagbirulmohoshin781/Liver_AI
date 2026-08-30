"""
tests/e2e/web/pages/profile_page.py
===================================
Page Object for Patient Medical Profile (tab-profile), Activity Stats,
Age/Gender inputs, and Clinical History Notes.
"""

from .base_page import BasePage


class ProfilePage(BasePage):
    """Page Object representing the Patient Profile View."""

    # Locators
    TAB_PROFILE_ID = "tab-profile"
    PROFILE_AVATAR_LARGE_ID = "profile-avatar-large"
    PROFILE_DISPLAY_NAME_ID = "profile-display-name"
    PROFILE_DISPLAY_EMAIL_ID = "profile-display-email"
    STAT_MESSAGES_ID = "stat-messages"
    STAT_SESSIONS_ID = "stat-sessions"
    STAT_DAYS_ID = "stat-days"
    PROFILE_AGE_INPUT_ID = "profile-age"
    PROFILE_GENDER_SELECT_ID = "profile-gender"
    PROFILE_NOTES_TEXTAREA_ID = "profile-medical-notes"
    SAVE_MEDICAL_BTN_ID = "btn-save-medical"

    def is_loaded(self):
        """Verifies profile tab and medical input form exist."""
        return self.has_element(self.TAB_PROFILE_ID) and self.has_element(self.SAVE_MEDICAL_BTN_ID)

    def fetch_stats(self):
        """Queries /api/user/stats."""
        return self.client.get("/api/user/stats")

    def save_medical_profile(self, age, gender, medical_notes):
        """Updates medical background via /api/user/medical-profile."""
        return self.client.post(
            "/api/user/medical-profile",
            json={"age": age, "gender": gender, "medical_notes": medical_notes},
            content_type="application/json",
        )
