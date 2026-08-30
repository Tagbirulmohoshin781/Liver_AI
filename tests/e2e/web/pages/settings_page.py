"""
tests/e2e/web/pages/settings_page.py
====================================
Page Object for Engine Settings (tab-settings), Theme Presets (Dark, OLED,
Midnight, Nordic, Cyberpunk, Emerald, Rose, Sepia, Light), Custom HEX Color Studio,
Model Temperature Slider, and Response Complexity Tone.
"""

from .base_page import BasePage


class SettingsPage(BasePage):
    """Page Object representing the Settings View."""

    # Locators
    TAB_SETTINGS_ID = "tab-settings"
    THEME_PRESET_CLASS = "theme-preset-btn"
    ACTIVE_THEME_INDICATOR_ID = "active-theme-indicator"
    FONT_SIZE_RANGE_ID = "font-size-range-mobile"
    COLOR_PALETTE_ID = "color-palette"
    CUSTOM_COLOR_CARD_ID = "custom-color-card"
    CUSTOM_HEX_INPUT_ID = "custom-color-hex-input"
    CUSTOM_COLOR_PICKER_ID = "custom-color-picker"
    SETTING_TEMP_RANGE_ID = "setting-temp-range"
    STYLE_PILL_CLASS = "style-pill"

    THEME_MODES = [
        "dark", "oled", "midnight", "nordic", "cyberpunk",
        "emerald", "rose", "sepia", "light"
    ]

    def is_loaded(self):
        """Verifies settings tab and custom color studio exist."""
        return self.has_element(self.TAB_SETTINGS_ID) and self.has_element(self.CUSTOM_COLOR_CARD_ID)

    def get_available_theme_buttons(self):
        """Returns list of theme button elements."""
        return self.find_elements_by_class(self.THEME_PRESET_CLASS)

    def save_settings(self, settings_dict):
        """Saves settings via /api/user/settings."""
        return self.client.post(
            "/api/user/settings",
            json=settings_dict,
            content_type="application/json",
        )

    def fetch_settings(self):
        """Retrieves stored settings via /api/user/settings."""
        return self.client.get("/api/user/settings")
