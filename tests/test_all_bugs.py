import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.prediction import predict_liver_disease, _rule_based_risk
from src.db import init_db, get_db_connection, upsert_firebase_user
from src.llm_pipeline import generate_rag_answer


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
        self.assertIn(res["risk_level"], ["Low", "Moderate"])
        self.assertLess(res["probability"], 0.50)

    def test_lpd_prediction_high_risk(self):
        """Severe lab values should return At Risk / High."""
        severe_patient = {
            "age": 55, "gender": 1,
            "total_bilirubin": 4.5, "direct_bilirubin": 2.1,
            "alkaline_phosphotase": 350, "sgpt": 180, "sgot": 210,
            "total_proteins": 5.2, "albumin": 2.8, "ag_ratio": 0.7
        }
        res = predict_liver_disease(severe_patient)
        self.assertEqual(res["risk_level"], "High")

    def test_rag_generation_response(self):
        """RAG pipeline should return structured medical answer."""
        resp = generate_rag_answer("What are the warning signs of liver disease?")
        self.assertIsInstance(resp, str)
        self.assertTrue(len(resp) > 20)


if __name__ == "__main__":
    unittest.main()
