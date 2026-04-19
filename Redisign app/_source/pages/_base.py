"""Base class for all sidebar pages."""
from __future__ import annotations

from PySide6.QtWidgets import QWidget

from app.services.app_context import AppContext


class PageBase(QWidget):
    title: str = "Page"

    def __init__(self, context: AppContext) -> None:
        super().__init__()
        self.context = context

    def refresh(self) -> None:
        """Override to react to AppContext.dataChanged."""


__all__ = ["PageBase"]
