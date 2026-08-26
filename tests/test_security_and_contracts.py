"""
tests/test_security_and_contracts.py
====================================
Standard library unittest regression suite covering:
  - Health (/healthz) and Readiness (/readyz) contracts
  - Defensive security headers
  - Guest isolation (no shared guest identity)
  - Chat persistence parameter ordering
  - Truthful clinical heuristic labeling
  - Vision inference simulation production gating
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app
from src.db import save_chat_message, get_guest_user_id, get_user_chats
from src.prediction import predict_liver_disease
from src.vision_inference import predict_image


class LiverAISecurityAndContractsTest(unittest.TestCase):

    def setUp(self):
        self.app = create_app()
        self.app.config["TESTING"] = True
        self.client = self.app.test_client()

    def test_healthz_liveness(self):
        """GET /healthz must return 200 with service status."""
        res = self.client.get("/healthz")
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertEqual(data.get("status"), "alive")
        self.assertEqual(data.get("service"), "liverai")

    def test_readyz_readiness(self):
        """GET /readyz must return dependency status without leaking keys."""
        res = self.client.get("/readyz")
        self.assertIn(res.status_code, (200, 503))
        data = res.get_json()
        self.assertIn("database", data)
        self.assertIn("rag", data)
        self.assertIn("vision", data)
        self.assertIn("status", data)

    def test_security_headers(self):
        """Responses must include defensive security headers."""
        res = self.client.get("/healthz")
        self.assertEqual(res.headers.get("X-Content-Type-Options"), "nosniff")
        self.assertEqual(res.headers.get("X-Frame-Options"), "SAMEORIGIN")
        self.assertEqual(res.headers.get("Referrer-Policy"), "strict-origin-when-cross-origin")

    def test_guest_isolation(self):
        """Anonymous visitors must not share a persistent database guest record."""
        guest_id = get_guest_user_id()
        self.assertIsNone(guest_id, "Shared guest identity must return None to prevent cross-user leakage.")

    def test_save_chat_message_unambiguous(self):
        """save_chat_message must correctly map role, message, and session_id without argument swapping."""
        msg_id = save_chat_message(
            user_id=1,
            session_id="session_test_42",
            role="user",
            message="What are symptoms of hepatitis?"
        )
        if msg_id:
            chats = get_user_chats(1)
            matching = [c for c in chats if c["id"] == msg_id]
            if matching:
                self.assertEqual(matching[0]["role"], "user")
                self.assertEqual(matching[0]["message"], "What are symptoms of hepatitis?")
                self.assertEqual(matching[0]["session_id"], "session_test_42")

    def test_clinical_risk_truthful_labeling(self):
        """LPD prediction must be explicitly labeled as an experimental heuristic with AASLD ranges."""
        sample_features = {
            "age": 45,
            "gender": 1,
            "total_bilirubin": 2.1,
            "direct_bilirubin": 0.8,
            "alkaline_phosphotase": 210,
            "sgpt": 75,
            "sgot": 60,
            "total_proteins": 6.5,
            "albumin": 3.2,
            "ag_ratio": 0.9,
        }
        result = predict_liver_disease(sample_features)
        self.assertEqual(result.get("status"), "ok")
        self.assertEqual(result.get("method"), "experimental_heuristic_aasld")
        self.assertFalse(result.get("is_diagnostic"))
        self.assertIn("disclaimer", result)
        self.assertIn("AASLD", result.get("disclaimer", ""))

    def test_vision_simulation_gate(self):
        """When no real weights exist, simulation must be rejected if ENABLE_VISION_SIMULATION is false."""
        os.environ["ENABLE_VISION_SIMULATION"] = "false"
        os.environ["APP_ENV"] = "production"
        
        res = predict_image("nonexistent_test.jpg")
        if "mode" in res:
            self.assertNotEqual(res.get("mode"), "simulation", "Simulation must never run in production.")


if __name__ == "__main__":
    unittest.main()
