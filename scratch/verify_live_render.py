import sys
import time
import requests

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

print("--- Testing GET /healthz ---")
t0 = time.time()
r_health = requests.get('https://liver-ai-haka.onrender.com/healthz', timeout=120)
lat_health = (time.time() - t0) * 1000
print(f"Health Status Code: {r_health.status_code}, Latency: {lat_health:.2f}ms")
print(f"Health Response: {r_health.json()}")
assert r_health.status_code == 200, f"Expected 200, got {r_health.status_code}"
assert r_health.json().get("status") == "alive", f"Expected alive, got {r_health.json()}"

print("\n--- Testing POST /chat ---")
payload = {"message": "Deep analysis of MASLD progression in patients with elevated ALT and HbA1c"}
t1 = time.time()
r_chat = requests.post('https://liver-ai-haka.onrender.com/chat', json=payload, timeout=120)
lat_chat = (time.time() - t1) * 1000
print(f"Chat Status Code: {r_chat.status_code}, Latency: {lat_chat:.2f}ms")
data = r_chat.json()
resp_text = data.get("response", "")
print(f"Chat Response Length: {len(resp_text)} characters")
print(f"Sources count: {len(data.get('sources', []))}")

required_sections = [
    "### 🩺 Clinical Overview & Assessment",
    "### 🔬 Biomarker / Histological Analysis",
    "### ⚠️ Risk Stratification & Red Flags",
    "### 📋 Evidence-Based Management & Nutrition Protocol",
    "### ⚖️ Clinical Disclaimer"
]

for sec in required_sections:
    assert sec in resp_text, f"Missing section: {sec}"
    print(f"Verified Section: {sec.encode('ascii', 'replace').decode('ascii')}")

assert "fallback warning" not in resp_text.lower(), "Detected fallback warning disclaimer"
print("\nMODULE 2: Production Live Render API Verification: 100% Passed!")
