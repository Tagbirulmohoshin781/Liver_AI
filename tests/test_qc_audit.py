"""
tests/test_qc_audit.py
======================
Comprehensive QC audit test suite for LiverAI:
- Clinical AI 5-section markdown structure verification.
- Zero legacy fallback warning disclaimers in responses.
- Test inquiries: Fatty Liver, Early Warning Signs, Scan Interpretation.
- Dual endpoint contracts (/api/v1/chat, /chat, /api/v1/predict).
- Health and readiness probes (/healthz, /readyz).
- Auth & Guest mode sessions (/api/guest-login, /api/v1/auth/session).
"""

import os
import sys
import json
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from src.prompt import system_prompt, CLINICAL_DISCLAIMER
from src.llm_pipeline import generate_rag_answer, build_local_fallback_answer

FORBIDDEN_LEGACY_STRINGS = [
    "I'm using the local knowledge base",
    "external AI services are not available",
    "bundled with this application"
]

REQUIRED_5_SECTIONS = [
    "### 🩺 Clinical Overview & Assessment",
    "### 🔬 Biomarker / Histological Analysis",
    "### ⚠️ Risk Stratification & Red Flags",
    "### 📋 Evidence-Based Management & Nutrition Protocol",
    "### ⚖️ Clinical Disclaimer"
]


class TestQCAuditSuite(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.app = create_app()
        cls.client = cls.app.test_client()

    def test_healthz_and_readyz(self):
        """Test system liveness and readiness endpoints."""
        res_h = self.client.get("/healthz")
        self.assertEqual(res_h.status_code, 200)
        data_h = json.loads(res_h.data)
        self.assertEqual(data_h.get("status"), "alive")

        res_r = self.client.get("/readyz")
        self.assertIn(res_r.status_code, [200, 503])
        data_r = json.loads(res_r.data)
        self.assertIn("status", data_r)
        self.assertIn("rag", data_r)

    def test_clinical_fallback_structure(self):
        """Verify that fallback answers return the mandatory 5 clinical sections."""
        resp = build_local_fallback_answer("What causes ALT and AST to spike?")
        for section in REQUIRED_5_SECTIONS:
            self.assertIn(section, resp)
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            self.assertNotIn(forbidden, resp)

    def test_rag_generation_fatty_liver(self):
        """Test RAG answer generation on MASLD/NAFLD query."""
        resp = generate_rag_answer("What is fatty liver and how do I treat it?")
        self.assertIsInstance(resp, str)
        for section in REQUIRED_5_SECTIONS:
            self.assertIn(section, resp)
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            self.assertNotIn(forbidden, resp)
        self.assertIn("consult your healthcare provider", resp.lower())

    def test_rag_generation_warning_signs(self):
        """Test RAG answer generation on early warning signs query."""
        resp = generate_rag_answer("What are early warning signs of liver disease?")
        self.assertIsInstance(resp, str)
        for section in REQUIRED_5_SECTIONS:
            self.assertIn(section, resp)
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            self.assertNotIn(forbidden, resp)
        self.assertIn("jaundice", resp.lower())

    def test_rag_generation_scan_interpretation(self):
        """Test RAG answer generation on biopsy scan interpretation."""
        resp = generate_rag_answer("Interpret scan_1787846492516")
        self.assertIsInstance(resp, str)
        for section in REQUIRED_5_SECTIONS:
            self.assertIn(section, resp)
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            self.assertNotIn(forbidden, resp)

    def test_api_chat_endpoints(self):
        """Test both /chat and /api/v1/chat JSON endpoints."""
        payload = {"message": "Explain liver cirrhosis stages."}
        
        # Test /chat
        res1 = self.client.post("/chat", json=payload)
        self.assertEqual(res1.status_code, 200)
        data1 = json.loads(res1.data)
        self.assertIn("response", data1)
        self.assertTrue(len(data1["response"]) > 50)
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            self.assertNotIn(forbidden, data1["response"])

        # Test /api/v1/chat
        res2 = self.client.post("/api/v1/chat", json=payload)
        self.assertEqual(res2.status_code, 200)
        data2 = json.loads(res2.data)
        self.assertIn("response", data2)
        self.assertTrue(len(data2["response"]) > 50)
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            self.assertNotIn(forbidden, data2["response"])

    def test_api_guest_login(self):
        """Test instant guest access endpoint."""
        res = self.client.post("/api/guest-login")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data.get("success"))
        self.assertIn("user", data)
        self.assertTrue(data["user"].get("is_guest"))

    def test_clinical_predict_endpoints(self):
        """Test LPD risk prediction calculation."""
        patient_data = {
            "age": 45, "gender": 1,
            "total_bilirubin": 1.2, "direct_bilirubin": 0.4,
            "alkaline_phosphotase": 180, "sgpt": 48, "sgot": 52,
            "total_proteins": 6.8, "albumin": 3.6, "ag_ratio": 1.1
        }
        res = self.client.post("/api/v1/predict", json=patient_data)
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data.get("success"))
        self.assertIn("result", data)
        self.assertIn("risk_level", data["result"])


if __name__ == "__main__":
    unittest.main()
