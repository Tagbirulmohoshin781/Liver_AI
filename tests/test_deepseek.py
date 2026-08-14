import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import src.llm_pipeline as pipe


class TestDeepSeekIntegration(unittest.TestCase):

    def test_deepseek_vars_loaded(self):
        self.assertTrue(hasattr(pipe, "DEEPSEEK_API_KEY"))
        self.assertTrue(hasattr(pipe, "DEEPSEEK_MODEL"))
        self.assertTrue(hasattr(pipe, "generate_deepseek_answer"))

    def test_deepseek_empty_key_graceful_fallback(self):
        # With empty key, generate_deepseek_answer should return empty string without errors
        saved_key = pipe.DEEPSEEK_API_KEY
        try:
            pipe.DEEPSEEK_API_KEY = ""
            ans = pipe.generate_deepseek_answer("System prompt", "User prompt")
            self.assertEqual(ans, "")
        finally:
            pipe.DEEPSEEK_API_KEY = saved_key


if __name__ == "__main__":
    unittest.main()
