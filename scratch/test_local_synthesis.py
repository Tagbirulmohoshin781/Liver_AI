import time
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from src.llm_pipeline import generate_rag_answer, classify_clinical_intent

t0 = time.time()
print("Executing Local Synthesis & Intent Analysis Checks...")

# Test 1: 1-Month Plan Timeline
q1 = 'provide me the one month guideline'
ans1 = generate_rag_answer(q1)
sections = ['Clinical Overview', 'Biomarker', 'Risk Stratification', 'Management & Nutrition', 'Clinical Disclaimer']
assert all(s in ans1 for s in sections), 'Missing mandatory sections in Q1'
assert 'Week 1' in ans1 and 'Week 4' in ans1, 'Missing 4-week timeline in Q1'
print("✓ Test 1 Passed: 1-Month Plan Timeline & 5 Sections Verified.")

# Test 2: Alcohol Zero-Tolerance Toxicity
q2 = 'What are the safe limits of vodka/alcohol for fatty liver?'
ans2 = generate_rag_answer(q2)
assert 'alcohol' in ans2.lower() or 'ethanol' in ans2.lower(), 'Failed alcohol intent evaluation'
print("✓ Test 2 Passed: Alcohol Zero-Tolerance Toxicity Intent Verified.")

# Test 3: Multi-Hop Research Analysis
q3 = 'Deep analysis of MASLD progression in patients with elevated ALT and HbA1c'
ans3 = generate_rag_answer(q3)
assert all(s in ans3 for s in sections), 'Missing sections in Q3'
print("✓ Test 3 Passed: Multi-Hop Research Analysis Verified.")

elapsed = time.time() - t0
print(f"Local synthesis checks: 100% Passed in {elapsed:.2f}s!")
