"""
tests/e2e/web/specs/test_web_responsive.py
==========================================
E2E Test Spec for Responsive Design Viewport Compatibility & Security Headers.
Tests:
  - RESP-01: Viewport meta-tags, viewport-fit=cover, CSS media queries, responsive CSS files
  - SEC-01: Defensive HTTP headers (X-Content-Type-Options, X-Frame-Options, Referrer-Policy)
"""

import pytest
from tests.e2e.web.pages.base_page import BasePage


class TestWebResponsiveAndSecurity:

    VIEWPORTS = [
        {"name": "Desktop (1920x1080)", "width": 1920, "height": 1080},
        {"name": "Tablet (768x1024)", "width": 768, "height": 1024},
        {"name": "Mobile (375x667)", "width": 375, "height": 667},
    ]

    def test_responsive_meta_tags_and_stylesheets_present(self, client):
        """RESP-01: Verify viewport-fit=cover and mobile.css stylesheets are linked."""
        res = client.get("/")
        assert res.status_code == 200
        page = BasePage(client, res.get_data(as_text=True))

        meta_vp = page.soup.find("meta", attrs={"name": "viewport"})
        assert meta_vp is not None
        assert "width=device-width" in meta_vp.get("content", "")
        assert "viewport-fit=cover" in meta_vp.get("content", "")

        # Verify responsive stylesheet links
        links = [l.get("href", "") for l in page.soup.find_all("link", rel="stylesheet")]
        assert any("mobile.css" in href for href in links)
        assert any("main.css" in href for href in links)

    def test_security_headers_enforcement(self, client):
        """SEC-01: Verify defensive security headers across all endpoints."""
        res = client.get("/healthz")
        assert res.headers.get("X-Content-Type-Options") == "nosniff"
        assert res.headers.get("X-Frame-Options") == "SAMEORIGIN"
        assert res.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
