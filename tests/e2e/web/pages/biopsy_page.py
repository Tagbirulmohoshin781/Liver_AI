"""
tests/e2e/web/pages/biopsy_page.py
==================================
Page Object for the Biopsy AI Histology Analyzer View (tab-biopsy),
dropzone, preview card, status pill, and automated diagnostic reports.
"""

from .base_page import BasePage


class BiopsyPage(BasePage):
    """Page Object representing the Biopsy Histology AI Analyzer tab."""

    # Locators
    TAB_BIOPSY_ID = "tab-biopsy"
    BIOPSY_DROP_ZONE_ID = "biopsy-drop-zone"
    BIOPSY_FILE_INPUT_ID = "biopsy-file-input"
    BIOPSY_PREVIEW_BOX_ID = "biopsy-preview-box"
    BIOPSY_PREVIEW_IMG_ID = "biopsy-preview-img"
    BIOPSY_STATUS_ID = "biopsy-status"
    BIOPSY_REPORT_VIEW_ID = "biopsy-report-view"
    BIOPSY_HERO_CARD_CLASS = "biopsy-hero-card"

    def is_loaded(self):
        """Verifies biopsy tab and upload dropzone exist."""
        return self.has_element(self.TAB_BIOPSY_ID) and self.has_element(self.BIOPSY_DROP_ZONE_ID)

    def check_vision_status(self):
        """Queries /vision_status endpoint."""
        return self.client.get("/vision_status")

    def upload_and_analyze_biopsy(self, filename, image_bytes):
        """Uploads a biopsy patch for deep histopathology classification."""
        import io
        data = {
            "file": (io.BytesIO(image_bytes), filename),
        }
        response = self.client.post(
            "/upload",
            data=data,
            content_type="multipart/form-data",
        )
        return response
