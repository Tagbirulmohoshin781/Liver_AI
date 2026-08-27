"""
tests/test_aiq_research.py
===========================
Verification test suite for NVIDIA AIQ-Research multi-hop query decomposition,
clinical reasoning, and 5-section response synthesis.
"""

import unittest
from src.llm_pipeline import (
    generate_rag_answer,
    classify_clinical_intent,
    decompose_clinical_query,
)


class TestAiqResearch(unittest.TestCase):
    def setUp(self):
        self.sections = [
            "### 🩺 Clinical Overview & Assessment",
            "### 🔬 Biomarker / Histological Analysis",
            "### ⚠️ Risk Stratification & Red Flags",
            "### 📋 Evidence-Based Management & Nutrition Protocol",
            "### ⚖️ Clinical Disclaimer",
        ]

    def test_query_decomposition_masld_diabetes(self):
        q = "Deep analysis of MASLD progression in patients with elevated ALT and HbA1c"
        subqs = decompose_clinical_query(q)
        self.assertGreaterEqual(len(subqs), 3)
        self.assertTrue(any("insulin resistance" in s.lower() or "srebp-1c" in s.lower() for s in subqs))

    def test_query_decomposition_differential(self):
        q = "Differential diagnosis between Alcoholic Hepatitis and MASLD using AST:ALT ratios"
        subqs = decompose_clinical_query(q)
        self.assertGreaterEqual(len(subqs), 3)
        self.assertTrue(any("de ritis" in s.lower() or "ast alt" in s.lower() for s in subqs))

    def test_query_decomposition_histology(self):
        q = "Interpret scan_1787846492516 with bridging fibrosis and elevated triglycerides"
        subqs = decompose_clinical_query(q)
        self.assertGreaterEqual(len(subqs), 3)
        self.assertTrue(any("bridging fibrosis" in s.lower() or "f3" in s.lower() for s in subqs))

    def test_benchmark_queries_synthesis(self):
        queries = [
            "Deep analysis of MASLD progression in patients with elevated ALT and HbA1c",
            "Differential diagnosis between Alcoholic Hepatitis and MASLD using AST:ALT ratios",
            "Interpret scan_1787846492516 with bridging fibrosis and elevated triglycerides",
        ]

        for q in queries:
            with self.subTest(query=q):
                ans = generate_rag_answer(q)
                self.assertIsNotNone(ans)
                self.assertGreater(len(ans), 500)
                for sec in self.sections:
                    self.assertIn(sec, ans, f"Missing section '{sec}' for query: {q}")
                # Ensure no legacy fallback warning notices
                self.assertNotIn("Local fallback knowledge base", ans)
                self.assertNotIn("operating on cached", ans)


if __name__ == "__main__":
    unittest.main()
