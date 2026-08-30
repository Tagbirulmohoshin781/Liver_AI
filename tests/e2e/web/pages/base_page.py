"""
tests/e2e/web/pages/base_page.py
================================
Base Page Object Model (POM) containing resilient locator resolution,
DOM hierarchy parsing, HTML attribute inspection, and simulated user actions.
Prioritizes:
  1. id / data-testid attributes
  2. Semantic ARIA roles & accessibility tags
  3. Form input names / labels
  4. Structured CSS selectors
"""

from bs4 import BeautifulSoup


class BasePage:
    """Base class for all Web Page Objects."""

    def __init__(self, client=None, html_content=""):
        self.client = client
        self.html = html_content
        self.soup = BeautifulSoup(html_content, "html.parser") if html_content else None

    def refresh_dom(self, html_content):
        """Updates the internal DOM representation with new HTML response."""
        self.html = html_content
        self.soup = BeautifulSoup(html_content, "html.parser")

    def find_element_by_id(self, elem_id):
        """Finds an element by strict ID attribute."""
        if not self.soup:
            return None
        return self.soup.find(id=elem_id)

    def find_element_by_testid_or_id(self, identifier):
        """Finds an element by data-testid or ID."""
        if not self.soup:
            return None
        el = self.soup.find(attrs={"data-testid": identifier})
        if not el:
            el = self.soup.find(id=identifier)
        return el

    def find_elements_by_class(self, class_name):
        """Finds elements matching a CSS class name."""
        if not self.soup:
            return []
        return self.soup.find_all(class_=class_name)

    def find_button_with_text(self, text_substring):
        """Finds button or anchor element containing given text."""
        if not self.soup:
            return None
        for tag in self.soup.find_all(["button", "a"]):
            if text_substring.lower() in tag.get_text().lower():
                return tag
        return None

    def get_title(self):
        """Returns the document title."""
        if self.soup and self.soup.title:
            return self.soup.title.string.strip()
        return ""

    def has_element(self, elem_id):
        """Returns True if element ID exists in the DOM."""
        return self.find_element_by_id(elem_id) is not None
