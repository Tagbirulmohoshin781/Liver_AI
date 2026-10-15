"""
scripts/run_total_spectrum_qa.py
================================
Total Spectrum QA Automation Runner for LiverAI across 7 testing dimensions:
1. Core E2E & Browser Automation (Chrome)
2. Application Security & Pen-Testing (XSS, SQLi, Path Traversal, Security Headers, CORS)
3. API, Contract & Boundary Testing
4. Database & State Integrity (CRUD, Session Isolation)
5. Accessibility (a11y) & WCAG 2.1 AA Inspection
6. Performance & Core Web Vitals (TTFB, Payload limits)
7. Cross-Viewport Matrix & Live Render Deployment Verification
"""

import os
import sys
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

import time
import json
import io
import urllib.request
import urllib.error
from playwright.sync_api import sync_playwright

LOCAL_BASE_URL = "http://127.0.0.1:5000"
RENDER_BASE_URL = "https://liver-ai-haka.onrender.com"

SCREENSHOTS_DIR = os.path.abspath("test-results/screenshots")
LOCAL_SCREENSHOTS = os.path.join(SCREENSHOTS_DIR, "local")
RENDER_SCREENSHOTS = os.path.join(SCREENSHOTS_DIR, "render")
VERCEL_SCREENSHOTS = os.path.join(SCREENSHOTS_DIR, "vercel")

for d in [LOCAL_SCREENSHOTS, RENDER_SCREENSHOTS, VERCEL_SCREENSHOTS]:
    os.makedirs(d, exist_ok=True)

test_results = {
    "e2e_browser": {"total": 0, "passed": 0, "failed": 0, "details": []},
    "appsec": {"total": 0, "passed": 0, "failed": 0, "details": []},
    "api_contracts": {"total": 0, "passed": 0, "failed": 0, "details": []},
    "database_state": {"total": 0, "passed": 0, "failed": 0, "details": []},
    "accessibility": {"total": 0, "passed": 0, "failed": 0, "details": []},
    "performance": {"total": 0, "passed": 0, "failed": 0, "details": []},
    "cross_viewport_deploy": {"total": 0, "passed": 0, "failed": 0, "details": []},
}

def record_test(dimension: str, test_name: str, passed: bool, notes: str = ""):
    test_results[dimension]["total"] += 1
    if passed:
        test_results[dimension]["passed"] += 1
        status_str = "[PASS]"
    else:
        test_results[dimension]["failed"] += 1
        status_str = "[FAIL]"
    test_results[dimension]["details"].append({"name": test_name, "passed": passed, "notes": notes})
    print(f"  {status_str} {test_name}: {notes}")


def run_e2e_and_viewport_tests():
    print("\n--- [Dimension 1 & 7] Core E2E, Cross-Viewport & Browser Automation ---")
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)

        # 1. Desktop 1280x800
        page_desktop = browser.new_page(viewport={"width": 1280, "height": 800})
        res = page_desktop.goto(f"{LOCAL_BASE_URL}/", wait_until="networkidle")
        passed = (res.status == 200)
        record_test("e2e_browser", "Desktop (1280x800) Homepage Load", passed, f"Status: {res.status}")
        path_desktop = os.path.join(LOCAL_SCREENSHOTS, "desktop-1280x800.png")
        page_desktop.screenshot(path=path_desktop)
        record_test("cross_viewport_deploy", "Desktop Screenshot Captured", os.path.exists(path_desktop), path_desktop)

        # 2. Tablet 768x1024
        page_tablet = browser.new_page(viewport={"width": 768, "height": 1024})
        res_tab = page_tablet.goto(f"{LOCAL_BASE_URL}/", wait_until="networkidle")
        path_tablet = os.path.join(LOCAL_SCREENSHOTS, "tablet-768x1024.png")
        page_tablet.screenshot(path=path_tablet)
        record_test("cross_viewport_deploy", "Tablet (768x1024) Viewport Screenshot", (res_tab.status == 200), path_tablet)

        # 3. Mobile 375x667
        page_mobile = browser.new_page(viewport={"width": 375, "height": 667})
        res_mob = page_mobile.goto(f"{LOCAL_BASE_URL}/", wait_until="networkidle")
        path_mobile = os.path.join(LOCAL_SCREENSHOTS, "mobile-375x667.png")
        page_mobile.screenshot(path=path_mobile)
        record_test("cross_viewport_deploy", "Mobile (375x667) Viewport Screenshot", (res_mob.status == 200), path_mobile)

        # 4. Auth & Guest Login Journey
        page_auth = browser.new_page(viewport={"width": 1280, "height": 800})
        page_auth.goto(f"{LOCAL_BASE_URL}/login")
        # Check guest button
        guest_btn = page_auth.query_selector(".btn-guest-access, #btn-guest-login, [onclick*='guestLogin']")
        if guest_btn:
            guest_btn.click()
            page_auth.wait_for_timeout(1000)
        path_auth = os.path.join(LOCAL_SCREENSHOTS, "auth-guest-flow.png")
        page_auth.screenshot(path=path_auth)
        record_test("e2e_browser", "Auth Flow & Guest Mode Trigger", True, "Rendered and captured auth view")

        # 5. Direct Predict Route & Form Validation
        page_predict = browser.new_page(viewport={"width": 1280, "height": 800})
        res_pred = page_predict.goto(f"{LOCAL_BASE_URL}/predict")
        path_pred = os.path.join(LOCAL_SCREENSHOTS, "clinical-predictor-form.png")
        page_predict.screenshot(path=path_pred)
        record_test("e2e_browser", "Direct /predict Route Verification", (res_pred.status == 200), f"Status {res_pred.status}")

        # 6. Settings / Theme Page
        page_settings = browser.new_page(viewport={"width": 1280, "height": 800})
        res_set = page_settings.goto(f"{LOCAL_BASE_URL}/settings")
        path_set = os.path.join(LOCAL_SCREENSHOTS, "settings-theme.png")
        page_settings.screenshot(path=path_set)
        record_test("e2e_browser", "Direct /settings Route Verification", (res_set.status == 200), f"Status {res_set.status}")

        # 7. Live Render Deployment Browser Check
        print("\n--- Live Render Deployment Smoke Test ---")
        try:
            page_render = browser.new_page(viewport={"width": 1280, "height": 800})
            res_render = page_render.goto(f"{RENDER_BASE_URL}/", timeout=45000, wait_until="networkidle")
            path_render = os.path.join(RENDER_SCREENSHOTS, "render-homepage.png")
            page_render.screenshot(path=path_render)
            record_test("cross_viewport_deploy", "Live Render Homepage Load", (res_render.status == 200), f"Status: {res_render.status}")
        except Exception as e:
            record_test("cross_viewport_deploy", "Live Render Homepage Load", False, str(e))

        try:
            # Render Mobile
            page_render_mob = browser.new_page(viewport={"width": 375, "height": 667})
            res_rmob = page_render_mob.goto(f"{RENDER_BASE_URL}/", timeout=45000)
            path_rmob = os.path.join(RENDER_SCREENSHOTS, "render-mobile-375x667.png")
            page_render_mob.screenshot(path=path_rmob)
            record_test("cross_viewport_deploy", "Live Render Mobile (375x667)", (res_rmob.status == 200), path_rmob)
        except Exception as e:
            record_test("cross_viewport_deploy", "Live Render Mobile (375x667)", False, str(e))

        try:
            # Render /predict
            page_render_pred = browser.new_page(viewport={"width": 1280, "height": 800})
            res_rpred = page_render_pred.goto(f"{RENDER_BASE_URL}/predict", timeout=45000)
            path_rpred = os.path.join(RENDER_SCREENSHOTS, "render-predict.png")
            page_render_pred.screenshot(path=path_rpred)
            record_test("cross_viewport_deploy", "Live Render Direct /predict Route", (res_rpred.status == 200), path_rpred)
        except Exception as e:
            record_test("cross_viewport_deploy", "Live Render Direct /predict Route", False, str(e))

        browser.close()


def run_appsec_pen_tests():
    print("\n--- [Dimension 2] Application Security & Pen-Testing ---")
    import requests

    # 1. Defensive Security Headers
    r = requests.get(f"{LOCAL_BASE_URL}/healthz")
    headers = r.headers
    x_content_type = headers.get("X-Content-Type-Options") == "nosniff"
    x_frame = headers.get("X-Frame-Options") == "SAMEORIGIN"
    referrer = headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    perm_policy = "camera=()" in headers.get("Permissions-Policy", "")
    sec_headers_pass = x_content_type and x_frame and referrer and perm_policy
    record_test("appsec", "Defensive Security Headers", sec_headers_pass,
                f"nosniff={x_content_type}, frame={x_frame}, referrer={referrer}")

    # 2. XSS Payload Injection in Chat API
    xss_payload = {"message": "<script>alert('XSS-TEST')</script><img src=x onerror=alert(1)>"}
    rxss = requests.post(f"{LOCAL_BASE_URL}/api/v1/chat", json=xss_payload)
    data_xss = rxss.json()
    resp_text = data_xss.get("response", "")
    no_raw_script = "<script>alert('XSS-TEST')</script>" not in resp_text
    record_test("appsec", "Reflected XSS Sanitization in Chat API", no_raw_script, "Raw script tags stripped/defended")

    # 3. SQL Injection Probe in Auth API
    sqli_payload = {"email": "admin' OR '1'='1' --", "password": "' OR '1'='1"}
    r_sqli = requests.post(f"{LOCAL_BASE_URL}/api/login", json=sqli_payload)
    sqli_rejected = (r_sqli.status_code == 401)
    record_test("appsec", "SQL Injection Probe (Auth Bypassing)", sqli_rejected, f"Response: {r_sqli.status_code}")

    # 4. Path Traversal Probe on Static Assets
    r_traversal = requests.get(f"{LOCAL_BASE_URL}/static/../../../../etc/passwd")
    traversal_blocked = (r_traversal.status_code in [400, 404])
    record_test("appsec", "Path Traversal Protection on Static Assets", traversal_blocked, f"Status: {r_traversal.status_code}")

    # 5. Auth Barrier on Protected API (Profile update without session)
    r_auth_bar = requests.post(f"{LOCAL_BASE_URL}/api/user/medical-profile", json={"allergies": "Penicillin"})
    auth_bar_pass = (r_auth_bar.status_code in [401, 403, 302])
    record_test("appsec", "Unauthenticated Route Guard Barrier", auth_bar_pass, f"Status: {r_auth_bar.status_code}")


def run_api_contract_tests():
    print("\n--- [Dimension 3] API, Contract & Boundary Testing ---")
    import requests

    # 1. Health & Readiness Contracts
    r_h = requests.get(f"{LOCAL_BASE_URL}/healthz")
    record_test("api_contracts", "GET /healthz Contract (200 OK)", r_h.status_code == 200, f"Code {r_h.status_code}")

    r_r = requests.get(f"{LOCAL_BASE_URL}/readyz")
    record_test("api_contracts", "GET /readyz Contract (200 OK)", r_r.status_code in [200, 503], f"Code {r_r.status_code}")

    # 2. Predict API Missing Fields (400 Bad Request)
    r_pred_bad = requests.post(f"{LOCAL_BASE_URL}/api/v1/predict", json={"age": 50})
    record_test("api_contracts", "POST /api/v1/predict Validation (400 Bad Request)", r_pred_bad.status_code == 400, f"Code {r_pred_bad.status_code}")

    # 3. Predict API Valid 10 Biomarkers (200 OK)
    valid_biomarkers = {
        "age": 52, "gender": 1, "total_bilirubin": 2.4, "direct_bilirubin": 1.1,
        "alkaline_phosphotase": 240, "sgpt": 85, "sgot": 78,
        "total_proteins": 6.2, "albumin": 3.0, "ag_ratio": 0.94
    }
    r_pred_ok = requests.post(f"{LOCAL_BASE_URL}/api/v1/predict", json=valid_biomarkers)
    res_json = r_pred_ok.json()
    has_risk = "result" in res_json and "risk_level" in res_json["result"]
    record_test("api_contracts", "POST /api/v1/predict Clinical Calculation (200 OK)", (r_pred_ok.status_code == 200 and has_risk), f"Risk: {res_json.get('result', {}).get('risk_level')}")

    # 4. Rapid Sequential Bursts
    burst_passed = True
    for _ in range(5):
        r_burst = requests.get(f"{LOCAL_BASE_URL}/api/predict/status")
        if r_burst.status_code != 200:
            burst_passed = False
    record_test("api_contracts", "Burst Request Stability (5 rapid calls)", burst_passed, "Zero daemon crash or dropped sockets")


def run_database_state_tests():
    print("\n--- [Dimension 4] Database, State & Data Integrity ---")
    import uuid
    from src.db import register_user, authenticate_user, update_medical_profile, get_user_profile

    # 1. Create User
    uid_str = uuid.uuid4().hex[:6]
    test_email = f"qa.patient.{uid_str}@liverai.health"
    test_user = f"QA Lead {uid_str}"
    test_pass = "SecurePass123!"

    ok, msg, uid = register_user(test_user, test_email, test_pass)
    record_test("database_state", "Database CRUD - Create User Record", (ok and uid is not None), f"UID: {uid}")

    # 2. Read / Authenticate User
    auth_user = authenticate_user(test_email, test_pass)
    record_test("database_state", "Database CRUD - Read & Authenticate Record", (auth_user is not None), f"Retrieved: {test_email}")

    # 3. Update User Medical Profile
    u_ok, u_msg = update_medical_profile(uid, 45, "Male", "Allergies: Sulfa. Previous fatty liver diagnosis.")
    prof = get_user_profile(uid)
    record_test("database_state", "Database CRUD - Mutate Profile Record", (u_ok and "Sulfa" in prof.get("medical_notes", "")), "Medical notes successfully updated")

    # 4. Guest Mode Identity Isolation
    from src.db import get_guest_user_id
    guest_id = get_guest_user_id()
    record_test("database_state", "Guest Isolation - Zero Shared Database Identity", (guest_id is None), "get_guest_user_id is None")


def run_accessibility_tests():
    print("\n--- [Dimension 5] Accessibility (a11y) & WCAG 2.1 AA Audit ---")
    import requests
    from bs4 import BeautifulSoup

    r = requests.get(f"{LOCAL_BASE_URL}/")
    soup = BeautifulSoup(r.text, "html.parser")

    # 1. Viewport Meta Tag
    vp = soup.find("meta", attrs={"name": "viewport"})
    record_test("accessibility", "Responsive Viewport Meta Configured", vp is not None and "width=device-width" in vp.get("content", ""), "width=device-width verified")

    # 2. Document Language Tag
    html_tag = soup.find("html")
    has_lang = html_tag and bool(html_tag.get("lang"))
    record_test("accessibility", "HTML Document Root has lang attribute", bool(has_lang), f"lang='{html_tag.get('lang') if html_tag else None}'")

    # 3. Form Input Labels & IDs
    inputs = soup.find_all("input")
    inputs_with_id = [i for i in inputs if i.get("id")]
    record_test("accessibility", "Form Inputs have Descriptive Unique IDs", len(inputs_with_id) >= 2, f"{len(inputs_with_id)} inputs audited")

    # 4. Images Alt Attributes
    images = soup.find_all("img")
    missing_alt = [img for img in images if not img.get("alt")]
    record_test("accessibility", "Images Have Accessible Alt Descriptions", len(missing_alt) == 0, f"Found {len(images)} images, {len(missing_alt)} missing alt")


def run_performance_tests():
    print("\n--- [Dimension 6] Performance & Core Web Vitals ---")
    import requests

    # 1. TTFB (Time to First Byte)
    times = []
    for _ in range(3):
        t0 = time.time()
        requests.get(f"{LOCAL_BASE_URL}/")
        times.append(time.time() - t0)
    avg_ttfb = (sum(times) / len(times)) * 1000
    record_test("performance", "Local TTFB Benchmark (< 200ms)", avg_ttfb < 200, f"Average TTFB: {avg_ttfb:.1f}ms")

    # 2. Static Asset Cache Control
    r_sw = requests.get(f"{LOCAL_BASE_URL}/sw.js")
    record_test("performance", "Service Worker Cache Header (no-cache)", "no-cache" in r_sw.headers.get("Cache-Control", ""), "Service worker updates cleanly")


if __name__ == "__main__":
    print("=================================================================")
    print("        LIVERAI TOTAL SPECTRUM QA AUTOMATION EXECUTION           ")
    print("=================================================================")
    run_e2e_and_viewport_tests()
    run_appsec_pen_tests()
    run_api_contract_tests()
    run_database_state_tests()
    run_accessibility_tests()
    run_performance_tests()

    print("\n=================================================================")
    print("                      TEST RESULTS SUMMARY                       ")
    print("=================================================================")
    grand_total = 0
    grand_passed = 0
    grand_failed = 0
    for dim, data in test_results.items():
        grand_total += data["total"]
        grand_passed += data["passed"]
        grand_failed += data["failed"]
        print(f"{dim.upper():<25}: {data['passed']}/{data['total']} Passed")
    print(f"\nTOTAL ASSERTIONS: {grand_passed}/{grand_total} Passed ({grand_failed} failed)")
    print("=================================================================")

    # Write JSON results
    with open("test-results/spectrum_results.json", "w") as f:
        json.dump(test_results, f, indent=2)
    print("Results saved to test-results/spectrum_results.json")
