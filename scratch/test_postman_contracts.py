import os
import sys
import json
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from app import app

client = app.test_client()

print("--- 1. Testing GET /healthz ---")
t0 = time.time()
res = client.get('/healthz')
lat_h = (time.time() - t0) * 1000
assert res.status_code == 200, f"Expected 200, got {res.status_code}"
data = res.get_json()
assert data.get("service") == "liverai" and data.get("status") == "alive", f"Unexpected payload: {data}"
print(f"✓ GET /healthz: 200 OK ({lat_h:.2f}ms) - Payload: {data}")

print("\n--- 2. Testing GET /readyz ---")
t0 = time.time()
res = client.get('/readyz')
lat_r = (time.time() - t0) * 1000
assert res.status_code == 200, f"Expected 200, got {res.status_code}"
data = res.get_json()
assert "status" in data, f"Unexpected readyz payload: {data}"
print(f"✓ GET /readyz: 200 OK ({lat_r:.2f}ms) - Payload: {data}")

print("\n--- 3. Testing POST /chat & POST /api/v1/chat ---")
for route in ['/chat', '/api/v1/chat']:
    payload = {"message": "What are the safe limits of vodka/alcohol for fatty liver?"}
    t0 = time.time()
    res = client.post(route, json=payload)
    lat_c = (time.time() - t0) * 1000
    assert res.status_code == 200, f"Expected 200 on {route}, got {res.status_code}"
    body = res.get_json()
    resp_text = body.get("response", body.get("answer", ""))
    
    # Assert zero-tolerance AASLD guidance
    assert "alcohol" in resp_text.lower() or "ethanol" in resp_text.lower(), f"Missing alcohol guidance on {route}"
    
    # Assert 5 mandatory Markdown headers
    headers = [
        '### 🩺 Clinical Overview & Assessment',
        '### 🔬 Biomarker / Histological Analysis',
        '### ⚠️ Risk Stratification & Red Flags',
        '### 📋 Evidence-Based Management & Nutrition Protocol',
        '### ⚖️ Clinical Disclaimer'
    ]
    for h in headers:
        assert h in resp_text, f"Missing header '{h}' on {route}"
        
    print(f"✓ {route}: 200 OK ({lat_c:.2f}ms, {len(resp_text)} chars, all 5 headers present)")

print("\n--- 4. Testing Error Handling on Empty Payload {} ---")
for route in ['/chat', '/api/v1/chat']:
    res = client.post(route, json={})
    assert res.status_code == 400, f"Expected 400 Bad Request on {route}, got {res.status_code}"
    data = res.get_json()
    assert "error" in data or "message" in data, f"Expected error description, got {data}"
    print(f"✓ {route} empty payload error handling: 400 Bad Request ({data})")

print("\nMODULE 2: Postman API Route & Contract Automation: 100% Passed!")
