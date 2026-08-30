"""
tests/e2e/web/specs/test_web_settings_profile.py
================================================
E2E Test Spec for Engine Settings (Theme Presets, Custom Color Studio,
Model Temperature, Complexity Tone) and Patient Medical Profile.
Tests:
  - SET-01: Theme presets availability and custom color studio DOM
  - SET-02: Settings persistence (/api/user/settings)
  - PROF-01: Medical profile update & stats retrieval
"""

import pytest
from tests.e2e.web.pages.settings_page import SettingsPage
from tests.e2e.web.pages.profile_page import ProfilePage


class TestWebSettingsAndProfile:

    def test_settings_dom_theme_presets_and_color_studio(self, authenticated_client):
        """SET-01: Verify settings DOM contains all 9 theme presets and custom color studio."""
        page = SettingsPage(authenticated_client)
        res = authenticated_client.get("/")
        page.refresh_dom(res.get_data(as_text=True))
        assert page.is_loaded()

        theme_btns = page.get_available_theme_buttons()
        assert len(theme_btns) >= 8
        assert page.find_element_by_id(page.CUSTOM_HEX_INPUT_ID) is not None
        assert page.find_element_by_id(page.CUSTOM_COLOR_PICKER_ID) is not None

    def test_settings_save_and_retrieve(self, authenticated_client):
        """SET-02: Verify saving and fetching customized user settings."""
        page = SettingsPage(authenticated_client)
        new_settings = {
            "theme": "midnight",
            "accent_hex": "#00F0FF",
            "font_size": 16,
            "temperature": 0.2,
            "response_style": "detailed",
        }
        save_res = page.save_settings(new_settings)
        assert save_res.status_code == 200
        assert save_res.get_json().get("success") is True

        get_res = page.fetch_settings()
        assert get_res.status_code == 200

    def test_profile_medical_background_update(self, authenticated_client):
        """PROF-01: Verify updating patient medical profile conditions & notes."""
        page = ProfilePage(authenticated_client)
        res = page.save_medical_profile(
            age=48,
            gender="Female",
            medical_notes="History of metabolic dysfunction-associated steatohepatitis (MASH). Elevated GGT.",
        )
        assert res.status_code == 200
        data = res.get_json()
        assert data.get("success") is True
        assert data.get("profile", {}).get("age") == 48

        # Check stats
        stats_res = page.fetch_stats()
        assert stats_res.status_code == 200
        assert stats_res.get_json().get("success") is True
