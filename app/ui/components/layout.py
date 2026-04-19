from __future__ import annotations
from typing import Literal

from PySide6.QtWidgets import QFrame, QHBoxLayout, QVBoxLayout, QWidget, QLabel
from PySide6.QtCore import Qt

class Card(QFrame):
    """A styled card container."""
    def __init__(self, title: str | None = None, padding: Literal["default", "none"] = "default", parent=None):
        super().__init__(parent)
        self.setObjectName("card")
        self.main_layout = QVBoxLayout(self)
        
        if padding == "none":
            self.main_layout.setContentsMargins(0, 0, 0, 0)
        else:
            self.main_layout.setContentsMargins(16, 16, 16, 16)
            
        self.main_layout.setSpacing(12)
        
        if title:
            self.header = QLabel(title)
            self.header.setObjectName("card-title")
            self.main_layout.addWidget(self.header)
            
    def add_widget(self, widget: QWidget, stretch: int = 0) -> None:
        self.main_layout.addWidget(widget, stretch)
        
    def add_layout(self, layout, stretch: int = 0) -> None:
        self.main_layout.addLayout(layout, stretch)


class BaseColLayout(QFrame):
    """Base class for multi-column layouts."""
    def __init__(self, cols: int, parent=None):
        super().__init__(parent)
        self.setObjectName("col-layout")
        self._layout = QHBoxLayout(self)
        self._layout.setContentsMargins(0, 0, 0, 0)
        self._layout.setSpacing(16)
        self._cols = cols
        
    def add_widget(self, widget: QWidget, col: int = -1) -> None:
        if 0 <= col < self._cols:
            self._layout.insertWidget(col, widget)
        else:
            self._layout.addWidget(widget)

class TwoCol(BaseColLayout):
    def __init__(self, parent=None): super().__init__(2, parent)

class ThreeCol(BaseColLayout):
    def __init__(self, parent=None): super().__init__(3, parent)

class FourCol(BaseColLayout):
    def __init__(self, parent=None): super().__init__(4, parent)

class Legend(QFrame):
    """A layout helper for showing color legends."""
    def __init__(self, items: dict[str, str], parent=None):
        super().__init__(parent)
        self.setObjectName("legend")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)
        
        for label_text, color in items.items():
            item_layout = QHBoxLayout()
            item_layout.setSpacing(6)
            
            dot = QLabel()
            dot.setFixedSize(8, 8)
            # Since QSS parsing per-instance is expensive, inline style is fine for small dots
            # Note: We expect the color to be a valid CSS color string (e.g. from Palette tokens)
            dot.setStyleSheet(f"background-color: {color}; border-radius: 4px;")
            
            lbl = QLabel(label_text)
            lbl.setObjectName("legend-label")
            
            item_layout.addWidget(dot)
            item_layout.addWidget(lbl)
            layout.addLayout(item_layout)
            
        layout.addStretch()
