from __future__ import annotations

from PySide6.QtWidgets import QFrame, QVBoxLayout, QHBoxLayout, QLabel, QWidget, QPushButton
from PySide6.QtCore import Qt

class DrawerPanel(QFrame):
    """A right-side collapsible drawer panel."""
    def __init__(self, title: str, parent=None):
        super().__init__(parent)
        self.setObjectName("drawer-panel")
        self.setFixedWidth(320)
        
        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.main_layout.setSpacing(0)
        
        # Header
        self.header = QFrame()
        self.header.setObjectName("drawer-header")
        header_layout = QHBoxLayout(self.header)
        header_layout.setContentsMargins(20, 16, 20, 16)
        
        self.title_lbl = QLabel(title)
        self.title_lbl.setObjectName("drawer-title")
        header_layout.addWidget(self.title_lbl)
        
        self.close_btn = QPushButton("×")
        self.close_btn.setObjectName("btn--ghost")
        self.close_btn.setFixedSize(24, 24)
        self.close_btn.clicked.connect(self.hide)
        header_layout.addWidget(self.close_btn, 0, Qt.AlignmentFlag.AlignRight)
        
        self.main_layout.addWidget(self.header)
        
        # Body
        self.body = QFrame()
        self.body.setObjectName("drawer-body")
        self.body_layout = QVBoxLayout(self.body)
        self.body_layout.setContentsMargins(20, 20, 20, 20)
        self.body_layout.setSpacing(16)
        self.body_layout.setAlignment(Qt.AlignmentFlag.AlignTop)
        self.main_layout.addWidget(self.body, 1)

    def add_widget(self, widget: QWidget) -> None:
        self.body_layout.addWidget(widget)

class AttributeRow(QFrame):
    """An attribute row with a mini-bar."""
    def __init__(self, label: str, value: int, max_val: int = 99, parent=None):
        super().__init__(parent)
        self.setObjectName("attribute-row")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)
        
        lbl = QLabel(label)
        lbl.setObjectName("attr-label")
        lbl.setFixedWidth(100)
        
        val_lbl = QLabel(str(value))
        val_lbl.setObjectName("attr-value")
        val_lbl.setFixedWidth(24)
        val_lbl.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        
        bar_container = QFrame()
        bar_container.setObjectName("attr-bar-container")
        bar_container.setFixedHeight(6)
        
        bar_layout = QHBoxLayout(bar_container)
        bar_layout.setContentsMargins(0, 0, 0, 0)
        bar_layout.setSpacing(0)
        
        fill = QWidget()
        fill.setObjectName("attr-bar-fill")
        
        # Determine color based on value thresholds
        level = "bad"
        if value >= 80:
            level = "ok"
        elif value >= 65:
            level = "warn"
            
        fill.setProperty("level", level)
        
        empty = QWidget()
        empty.setObjectName("attr-bar-empty")
        
        # Use stretch factors to create a percentage width bar
        val = max(0, min(value, max_val))
        rem = max_val - val
        bar_layout.addWidget(fill, val)
        if rem > 0:
            bar_layout.addWidget(empty, rem)
        
        layout.addWidget(lbl)
        layout.addWidget(bar_container, 1)
        layout.addWidget(val_lbl)
