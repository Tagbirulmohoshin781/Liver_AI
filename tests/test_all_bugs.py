import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.prediction import predict_liver_disease, _rule_based_risk
from src.db import init_db, get_db_connection, upsert_firebase_user
from src.llm_pipeline import analyze_histology_image
from app import get_intent_response, _build_intent_response, intents_data


class TestBugsFixes(unittest.TestCase):

    def test_lpd_prediction_low_risk(self):
        """Normal lab values should return Low Risk."""
        normal_patient = {
            "age": 30, "gender": 1,
            "total_bilirubin": 0.8, "direct_bilirubin": 0.2,
            "alkaline_phosphotase": 100, "sgpt": 25, "sgot": 22,
            "total_proteins": 7.0, "albumin": 4.5, "ag_ratio": 1.5
        }
        res = predict_liver_disease(normal_patient)
        self.assertEqual(res["label"], "Low Risk", f"Normal patient was misdiagnosed: {res}")
        self.assertLess(res["probability"], 0.40)

    def test_lpd_prediction_high_risk(self):
        """Severe lab values should return At Risk / High."""
        severe_patient = {
            "age": 55, "gender": 1,
            "total_bilirubin": 4.5, "direct_bilirubin": 2.1,
            "alkaline_phosphotase": 350, "sgpt": 180, "sgot": 210,
            "total_proteins": 5.2, "albumin": 2.8, "ag_ratio": 0.7
        }
        res = predict_liver_disease(severe_patient)
        self.assertEqual(res["label"], "At Risk")
        self.assertEqual(res["risk_level"], "High")

    def test_intent_resources_key(self):
        """Resource intent should include patient-friendly & academic links."""
        for intent in intents_data.get("intents", []):
            if intent.get("tag") == "resources_intent":
                resp = _build_intent_response(intent)
                self.assertIn("Patient-Friendly Guides:", resp, "Resource intent failed to load guides due to key mismatch.")
                self.assertIn("Medical/Academic Texts:", resp)

    def test_db_upsert_firebase_user(self):
        """Firebase user upsert should work without type errors."""
        uid, uname = upsert_firebase_user("test_fb_user@example.com", "Test FB User")
        self.assertIsInstance(uid, int)
        self.assertEqual(uname, "Test FB User")


if __name__ == "__main__":
    unittest.main()
