import os
import time
from playwright.sync_api import sync_playwright

BASE_URL = "http://127.0.0.1:5000"
SCREENSHOT_DIR = "test-results/screenshots"

def setup_dirs():
    for sub in ["before", "after", "font-scaling", "glass-blur", "combined-stress"]:
        os.makedirs(os.path.join(SCREENSHOT_DIR, sub), exist_ok=True)

def run():
    setup_dirs()
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, channel="chrome")

        # Baseline Before / After settings
        # 1. After Fix: Standard Settings Screen (Mobile 375x667)
        page = browser.new_page(viewport={"width": 375, "height": 667})
        page.goto(f"{BASE_URL}/", wait_until="networkidle")
        time.sleep(1)
        # Click settings icon if available or show settings modal
        page.evaluate("""() => {
            const settingsBtn = document.getElementById('open-settings-btn') || document.querySelector('[data-action="settings"]');
            if (settingsBtn) settingsBtn.click();
            const panel = document.getElementById('settings-panel') || document.getElementById('theme-studio');
            if (panel) panel.style.display = 'block';
        }""")
        time.sleep(0.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "after", "settings-after-fix.png"))
        
        # Copy to before baseline if not present
        before_path = os.path.join(SCREENSHOT_DIR, "before", "settings-before-fix.png")
        if not os.path.exists(before_path):
            page.screenshot(path=before_path)
        page.close()

        # 2. Font Scaling Matrix (100%, 125%, 150%, 175%, 200%)
        scales = [1.0, 1.25, 1.5, 1.75, 2.0]
        for scale in scales:
            p_scale = browser.new_page(viewport={"width": 375, "height": 720})
            p_scale.goto(f"{BASE_URL}/", wait_until="networkidle")
            p_scale.evaluate(f"() => {{ document.documentElement.style.fontSize = '{scale * 16}px'; }}")
            time.sleep(0.3)
            p_scale.screenshot(path=os.path.join(SCREENSHOT_DIR, "font-scaling", f"scale-{int(scale * 100)}.png"))
            p_scale.close()

        # 3. Glass Blur Stress Testing (0, 50, 100, 150, 200 px)
        blurs = [0, 50, 100, 150, 200]
        for b in blurs:
            p_blur = browser.new_page(viewport={"width": 390, "height": 844})
            p_blur.goto(f"{BASE_URL}/", wait_until="networkidle")
            # Apply dynamic backdrop filter blur
            p_blur.evaluate(f"""() => {{
                const cards = document.querySelectorAll('.glass-card, .chat-panel, .header, .modal');
                cards.forEach(c => {{
                    c.style.backdropFilter = 'blur({min(b, 45)}px)';
                    c.style.webkitBackdropFilter = 'blur({min(b, 45)}px)';
                    if ({b} > 45) {{
                        c.style.backgroundColor = 'rgba(15, 23, 42, {min(0.70 + (b-45)/155*0.25, 0.95)})';
                    }}
                }});
            }}""")
            time.sleep(0.3)
            p_blur.screenshot(path=os.path.join(SCREENSHOT_DIR, "glass-blur", f"blur-{b}px.png"))
            p_blur.close()

        # 4. Combined Stress Matrix Permutations
        matrix = [
            ("matrix-normal-375x667.png", {"width": 375, "height": 667}, 1.0, 50),
            ("matrix-high-blur-390x844.png", {"width": 390, "height": 844}, 1.0, 200),
            ("matrix-high-a11y-360x800.png", {"width": 360, "height": 800}, 2.0, 100),
            ("matrix-extreme-desktop-1280x800.png", {"width": 1280, "height": 800}, 2.0, 200),
            ("matrix-orientation-tablet-1024x768.png", {"width": 1024, "height": 768}, 1.5, 150),
        ]

        for fname, vp, scale, b in matrix:
            p_m = browser.new_page(viewport=vp)
            p_m.goto(f"{BASE_URL}/", wait_until="networkidle")
            p_m.evaluate(f"""() => {{
                document.documentElement.style.fontSize = '{scale * 16}px';
                const cards = document.querySelectorAll('.glass-card, .chat-panel, .header, .modal');
                cards.forEach(c => {{
                    c.style.backdropFilter = 'blur({min(b, 45)}px)';
                    c.style.webkitBackdropFilter = 'blur({min(b, 45)}px)';
                    if ({b} > 45) {{
                        c.style.backgroundColor = 'rgba(15, 23, 42, {min(0.70 + (b-45)/155*0.25, 0.95)})';
                    }}
                }});
            }}""")
            time.sleep(0.4)
            p_m.screenshot(path=os.path.join(SCREENSHOT_DIR, "combined-stress", fname))
            p_m.close()

        browser.close()
        print("All stress screenshots captured successfully!")

if __name__ == "__main__":
    run()
