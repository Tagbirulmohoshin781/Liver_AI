"""
tests/e2e/web/pages/chat_page.py
================================
Page Object for the Clinical AI Hepatology Chat View (tab-chat),
Welcome Hero, Suggestion Chips, Quick Prompt Carousel, Attachment Modals,
and Conversation Persistence.
"""

from .base_page import BasePage


class ChatPage(BasePage):
    """Page Object representing the Clinical AI Chat tab."""

    # Locators
    CHAT_VIEW_ID = "chat-view"
    TAB_CHAT_ID = "tab-chat"
    WELCOME_SCREEN_ID = "welcome-screen"
    CHAT_INPUT_ID = "chat-input"
    SEND_BTN_ID = "btn-send"
    ATTACH_BTN_ID = "btn-attach"
    MSG_GROUP_ID = "msg-group"
    UPLOAD_MODAL_ID = "upload-modal"
    DROP_ZONE_ID = "drop-zone"
    FILE_INPUT_ID = "file-input"

    # Suggestion & Carousel Locators
    SUGGESTION_CHIP_CLASS = "suggestion-chip"
    QUICK_CHIP_CLASS = "quick-chip"
    SIDEBAR_ID = "sidebar"
    NEW_CHAT_BTN_CLASS = "btn-new-chat"

    def navigate(self):
        """Fetches the main chat interface."""
        response = self.client.get("/")
        self.refresh_dom(response.get_data(as_text=True))
        return response

    def is_loaded(self):
        """Verifies chat tab and input box exist."""
        return self.has_element(self.TAB_CHAT_ID) and self.has_element(self.CHAT_INPUT_ID)

    def get_suggestion_chips(self):
        """Returns list of text inside suggestion chips."""
        chips = self.find_elements_by_class(self.SUGGESTION_CHIP_CLASS)
        return [c.get_text().strip() for c in chips]

    def get_quick_prompt_chips(self):
        """Returns list of text inside quick carousel chips."""
        chips = self.find_elements_by_class(self.QUICK_CHIP_CLASS)
        return [c.get_text().strip() for c in chips]

    def send_chat_message(self, message_text, session_id="test_session_e2e"):
        """Posts a message to the chat endpoint."""
        response = self.client.post(
            "/chat",
            json={"message": message_text, "session_id": session_id},
            content_type="application/json",
        )
        return response

    def upload_document(self, filename, file_bytes, content_type="application/pdf"):
        """Uploads a clinical document via /upload."""
        import io
        data = {
            "file": (io.BytesIO(file_bytes), filename),
        }
        response = self.client.post(
            "/upload",
            data=data,
            content_type="multipart/form-data",
        )
        return response

    def fetch_history(self):
        """Fetches user chat history."""
        return self.client.get("/api/history")

    def clear_history(self):
        """Clears all chat history."""
        return self.client.post("/api/clear_history")
