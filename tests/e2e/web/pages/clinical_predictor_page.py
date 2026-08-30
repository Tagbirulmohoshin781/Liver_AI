"""
tests/e2e/web/pages/clinical_predictor_page.py
==============================================
Page Object for the LPD Clinical Disease Risk Model & Biomarker Predictor.
"""

from .base_page import BasePage


class ClinicalPredictorPage(BasePage):
    """Page Object for Clinical Disease Risk Prediction."""

    REQUIRED_FIELDS = [
        "age",
        "gender",
        "total_bilirubin",
        "direct_bilirubin",
        "alkaline_phosphotase",
        "sgpt",
        "sgot",
        "total_proteins",
        "albumin",
        "ag_ratio",
    ]

    def check_predict_status(self):
        """Queries /api/predict/status endpoint."""
        return self.client.get("/api/predict/status")

    def submit_prediction(self, payload):
        """Posts 10-parameter biomarker payload to /api/predict."""
        return self.client.post(
            "/api/predict",
            json=payload,
            content_type="application/json",
        )
