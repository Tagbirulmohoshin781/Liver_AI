"""
tests/test_backend_security.py
===============================
Automated backend security and API validation test suite.
"""

import unittest
import json
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app


class BackendSecurityTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.app.config["TESTING"] = True
        self.client = self.app.test_client()

    def test_healthz_liveness(self):
        res = self.client.get("/healthz")
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertEqual(data.get("status"), "alive")
        self.assertEqual(data.get("service"), "liverai")

    def test_readyz_readiness(self):
        res = self.client.get("/readyz")
        self.assertIn(res.status_code, [200, 530, 503])
        data = res.get_json()
        self.assertIn("database", data)
        self.assertIn("rag", data)
        self.assertIn("vision", data)
        # Ensure secrets are never leaked in readiness probes
        self.assertNotIn("FLASK_SECRET_KEY", json.dumps(data))
        self.assertNotIn("SUPABASE_KEY", json.dumps(data))

    def test_predict_api_missing_fields(self):
        res = self.client.post("/api/v1/predict", json={"age": 45, "gender": "Male"})
        self.assertEqual(res.status_code, 400)
        data = res.get_json()
        self.assertFalse(data.get("success"))
        self.assertIn("Missing required fields", data.get("message", ""))

    def test_predict_api_valid_payload(self):
        payload = {
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
        res = self.client.post("/api/v1/predict", json=payload)
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data.get("success"))
        self.assertIn("result", data)
        self.assertEqual(data["result"].get("risk_level"), "Low")

    def test_upload_invalid_extension(self):
        data = {
            "file": (open(__file__, "rb"), "malicious_script.exe")
        }
        res = self.client.post("/upload", data=data, content_type="multipart/form-data")
        self.assertEqual(res.status_code, 400)
        json_data = res.get_json()
        self.assertFalse(json_data.get("success"))
        self.assertIn("Unsupported file format", json_data.get("message", ""))


if __name__ == "__main__":
    unittest.main()
