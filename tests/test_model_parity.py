"""
tests/test_model_parity.py
===========================
Cross-platform inference numerical parity test suite.
Verifies that clinical LPD risk predictions and feature transformations match expected tolerances (Delta < 1e-4).
"""

import unittest
import numpy as np
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.prediction import predict_liver_disease


class ModelNumericalParityTestCase(unittest.TestCase):
    def setUp(self):
        self.patient_a = {
            "age": 45,
            "gender": "Male",
            "total_bilirubin": 0.9,
            "direct_bilirubin": 0.2,
            "alkaline_phosphotase": 95.0,
            "sgpt": 28.0,
            "sgot": 25.0,
            "total_proteins": 7.2,
            "albumin": 4.2,
            "ag_ratio": 1.4
        }
        self.patient_b = {
            "age": 62,
            "gender": "Female",
            "total_bilirubin": 3.8,
            "direct_bilirubin": 1.9,
            "alkaline_phosphotase": 290.0,
            "sgpt": 140.0,
            "sgot": 165.0,
            "total_proteins": 5.4,
            "albumin": 2.9,
            "ag_ratio": 0.8
        }

    def test_numerical_determinism(self):
        """Repeated evaluations of identical patient profiles must return identical probabilities (Delta == 0.0)."""
        res1 = predict_liver_disease(self.patient_a)
        res2 = predict_liver_disease(self.patient_a)
        
        self.assertEqual(res1["status"], "ok")
        self.assertEqual(res2["status"], "ok")
        
        diff = abs(res1["probability"] - res2["probability"])
        self.assertLess(diff, 1e-6, f"Determinism failure: Delta {diff} exceeds threshold")

    def test_cross_gender_encoding_parity(self):
        """String 'Male' and numeric 1.0 gender representations must yield identical predictions (Delta < 1e-4)."""
        patient_str = dict(self.patient_a, gender="Male")
        patient_num = dict(self.patient_a, gender=1.0)
        
        res_str = predict_liver_disease(patient_str)
        res_num = predict_liver_disease(patient_num)
        
        diff = abs(res_str["probability"] - res_num["probability"])
        self.assertLess(diff, 1e-4, f"Gender parity failure: Delta {diff} exceeds 1e-4")

    def test_risk_level_separation(self):
        """Normal vs severe profiles must maintain distinct risk probabilities."""
        res_low = predict_liver_disease(self.patient_a)
        res_high = predict_liver_disease(self.patient_b)
        
        self.assertEqual(res_low["risk_level"], "Low")
        self.assertEqual(res_high["risk_level"], "High")
        self.assertGreater(res_high["probability"], res_low["probability"])


if __name__ == "__main__":
    unittest.main()
