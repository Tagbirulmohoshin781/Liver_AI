"""
tests/e2e/web/specs/test_web_clinical_risk.py
=============================================
E2E Test Spec for LPD 10-Biomarker Clinical Disease Risk Predictor.
Tests:
  - CLIN-01: Full 10-Biomarker Payload Risk Prediction (/api/predict)
  - CLIN-02: Missing required parameters validation & error messaging
  - CLIN-03: AASLD clinical guideline heuristic truthfulness & non-diagnostic disclaimer
"""

import pytest
from tests.e2e.web.pages.clinical_predictor_page import ClinicalPredictorPage


class TestWebClinicalRisk:

    def test_predict_status_check(self, client):
        """Verify clinical risk prediction engine status."""
        page = ClinicalPredictorPage(client)
        res = page.check_predict_status()
        assert res.status_code == 200
        data = res.get_json()
        assert data.get("available") is True or "mode" in data

    def test_predict_valid_10_biomarker_payload(self, client, sample_clinical_lpd_data):
        """CLIN-01: Verify successful risk calculation with 10 biomarkers."""
        page = ClinicalPredictorPage(client)
        res = page.submit_prediction(sample_clinical_lpd_data)
        assert res.status_code == 200
        data = res.get_json()
        assert data.get("success") is True
        result = data.get("result", {})
        assert "risk_score" in result or "prediction" in result
        assert result.get("method") == "experimental_heuristic_aasld"
        assert result.get("is_diagnostic") is False
        assert "AASLD" in result.get("disclaimer", "")

    def test_predict_missing_parameters_validation(self, client):
        """CLIN-02: Verify missing parameters return 400 with missing field list."""
        page = ClinicalPredictorPage(client)
        incomplete_payload = {
            "age": 45,
            "gender": 1,
            # missing remaining 8 parameters
        }
        res = page.submit_prediction(incomplete_payload)
        assert res.status_code == 400
        data = res.get_json()
        assert data.get("success") is False
        assert "Missing required fields" in data.get("message", "")
