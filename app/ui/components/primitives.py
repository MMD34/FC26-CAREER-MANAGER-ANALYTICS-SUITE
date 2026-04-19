from __future__ import annotations
from typing import Literal

from PySide6.QtWidgets import QLabel
from PySide6.QtCore import Qt

class Chip(QLabel):
    """A badge/tag with a colored background."""
    def __init__(self, text: str, variant: Literal["default", "ok", "warn", "bad", "accent", "mono"] = "default", parent=None):
        super().__init__(text, parent)
        self.setObjectName(f"chip--{variant}")
        self.setAlignment(Qt.AlignCenter)

class Pill(QLabel):
    """A pill shape indicator with level styling."""
    def __init__(self, text: str, level: Literal["hi", "md", "lo"] = "md", parent=None):
        super().__init__(text, parent)
        self.setObjectName(f"pill--{level}")
        self.setAlignment(Qt.AlignCenter)

class PosBadge(QLabel):
    """A positional badge (GK, DEF, MID, ATT)."""
    def __init__(self, role: Literal["GK", "DEF", "MID", "ATT", "Unknown"], parent=None):
        super().__init__(role, parent)
        role_class = role.lower() if role in ("GK", "DEF", "MID", "ATT") else "unknown"
        self.setObjectName(f"pos-badge--{role_class}")
        self.setAlignment(Qt.AlignCenter)

class Avatar(QLabel):
    """A circular widget with initials."""
    def __init__(self, initials: str, parent=None):
        super().__init__(initials[:2].upper(), parent)
        self.setObjectName("avatar")
        self.setAlignment(Qt.AlignCenter)
