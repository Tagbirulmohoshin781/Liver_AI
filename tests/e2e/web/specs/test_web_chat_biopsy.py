"""
tests/e2e/web/specs/test_web_chat_biopsy.py
===========================================
E2E Test Spec for Clinical AI Hepatology Chat, Document Uploads,
Biopsy AI Histopathology Classifier, and History Management.
Tests:
  - CHAT-01: Chat message endpoint, suggestions, prompt carousel
  - CHAT-02: Document attachment upload (PDF/TXT/CSV)
  - BIO-01: Biopsy slide patch classification & status
  - HIST-01: Diagnostic history retrieval and clear
"""

import pytest
from tests.e2e.web.pages.chat_page import ChatPage
from tests.e2e.web.pages.biopsy_page import BiopsyPage


class TestWebChatAndBiopsy:

    def test_chat_page_welcome_hero_and_suggestions_rendered(self, client):
        """Verify chat view DOM contains welcome hero and suggestion chips."""
        page = ChatPage(client)
        page.navigate()
        assert page.is_loaded()

        suggestions = page.get_suggestion_chips()
        assert len(suggestions) >= 4
        assert any("warning signs" in s.lower() for s in suggestions)
        assert any("fatty liver" in s.lower() for s in suggestions)

        quick_chips = page.get_quick_prompt_chips()
        assert len(quick_chips) >= 4

    def test_chat_message_submission_and_response(self, authenticated_client):
        """CHAT-01: Verify sending a clinical question produces response."""
        page = ChatPage(authenticated_client)
        res = page.send_chat_message("What are early warning signs of liver disease?")
        assert res.status_code == 200
        data = res.get_json()
        assert data.get("success") is True or "response" in data or "answer" in data or "status" in data

    def test_chat_document_attachment_upload(self, authenticated_client):
        """CHAT-02: Verify document attachment upload and text extraction."""
        page = ChatPage(authenticated_client)
        sample_doc_content = b"Patient lab report: AST 45 U/L, ALT 55 U/L. Mild hepatic steatosis observed."
        res = page.upload_document("lab_report.txt", sample_doc_content, content_type="text/plain")
        assert res.status_code == 200
        data = res.get_json()
        assert data.get("success") is True
        assert "upload_id" in data or "extracted_text" in data or "filename" in data

    def test_biopsy_vision_status_and_analysis(self, authenticated_client, sample_biopsy_image_bytes):
        """BIO-01: Verify biopsy vision status and histology patch classification."""
        page = BiopsyPage(authenticated_client)
        status_res = page.check_vision_status()
        assert status_res.status_code == 200
        status_data = status_res.get_json()
        assert "mode" in status_data

        # Submit biopsy patch
        analyze_res = page.upload_and_analyze_biopsy("slide_patch_01.png", sample_biopsy_image_bytes)
        assert analyze_res.status_code == 200
        analyze_data = analyze_res.get_json()
        assert analyze_data.get("success") is True or "results" in analyze_data

    def test_chat_history_fetch_and_clear(self, authenticated_client):
        """HIST-01: Verify history retrieval and clean teardown."""
        page = ChatPage(authenticated_client)
        hist_res = page.fetch_history()
        assert hist_res.status_code == 200

        clear_res = page.clear_history()
        assert clear_res.status_code == 200
        assert clear_res.get_json().get("success") is True
