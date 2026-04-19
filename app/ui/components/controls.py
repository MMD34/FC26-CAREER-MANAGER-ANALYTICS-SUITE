from __future__ import annotations

from PySide6.QtWidgets import QPushButton, QFrame, QHBoxLayout, QLabel
from PySide6.QtCore import Signal
from PySide6.QtGui import QIcon

class PrimaryButton(QPushButton):
    """A primary call-to-action button."""
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self.setObjectName("btn--primary")

class GhostButton(QPushButton):
    """A ghost/subtle button with no background until hovered."""
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self.setObjectName("btn--ghost")

class IconButton(QPushButton):
    """A button containing only an icon."""
    def __init__(self, icon: QIcon, parent=None):
        super().__init__(parent)
        self.setIcon(icon)
        self.setObjectName("icon-btn")

class FilterChip(QPushButton):
    """A togglable filter chip."""
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self.setObjectName("filter")
        self.setCheckable(True)

class Tabs(QFrame):
    """A row of styled tabs."""
    tab_changed = Signal(int)

    def __init__(self, tabs: list[str], parent=None):
        super().__init__(parent)
        self.setObjectName("tab-row")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(8)

        self._buttons: list[QPushButton] = []
        for i, text in enumerate(tabs):
            btn = QPushButton(text)
            btn.setObjectName("tab")
            btn.setCheckable(True)
            # Late binding of i
            btn.clicked.connect(lambda checked=False, idx=i: self.set_current_tab(idx))
            layout.addWidget(btn)
            self._buttons.append(btn)
        
        layout.addStretch()
        
        if self._buttons:
            self._buttons[0].setChecked(True)
            self._current_index = 0

    def set_current_tab(self, index: int) -> None:
        for i, btn in enumerate(self._buttons):
            btn.setChecked(i == index)
        if getattr(self, "_current_index", -1) != index:
            self._current_index = index
            self.tab_changed.emit(index)

class SectionTitle(QLabel):
    """Typography helper for section headings."""
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self.setObjectName("section-title")
