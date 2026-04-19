"""Shared application context: cache + cross-page signal bus."""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QObject, Signal

from app.core.paths import cache_dir
from app.services.cache import SessionCache


class AppContext(QObject):
    dataChanged = Signal()  # fired after a successful import or cache clear

    def __init__(self, career_slug: str = "default", parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._career_slug = career_slug
        self._cache_path = cache_dir() / f"{career_slug}.sqlite"
        self.cache = SessionCache(self._cache_path)

    @property
    def cache_path(self) -> Path:
        return self._cache_path

    def notify_changed(self) -> None:
        self.dataChanged.emit()


__all__ = ["AppContext"]
