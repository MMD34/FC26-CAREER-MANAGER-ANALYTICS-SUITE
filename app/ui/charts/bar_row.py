"""BarRow component."""
from __future__ import annotations
from PySide6.QtCore import Qt, QRectF
from PySide6.QtGui import QPainter, QColor, QLinearGradient
from PySide6.QtWidgets import QWidget, QLabel, QHBoxLayout
from app.ui.design.theme_manager import ThemeManager

class BarRowTrack(QWidget):
    def __init__(self, value: float = 0.0, max_value: float = 1.0, color_token: str = "accent") -> None:
        super().__init__()
        self.value = value
        self.max_value = max_value
        self.color_token = color_token
        self.setMinimumHeight(8)
        self.setMaximumHeight(8)
        ThemeManager.instance().theme_changed.connect(self.update)
        
    def paintEvent(self, event) -> None:
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        rect = self.rect()
        
        palette = ThemeManager.instance().current()
        bg_color = QColor(palette.panel_2)
        color_hex = getattr(palette, self.color_token, palette.accent)
        fg_color = QColor(color_hex)
        
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(bg_color)
        painter.drawRoundedRect(rect, 4, 4)
        
        if self.max_value > 0 and self.value > 0:
            ratio = min(1.0, self.value / self.max_value)
            w = rect.width() * ratio
            fill_rect = QRectF(0, 0, w, rect.height())
            
            grad = QLinearGradient(0, 0, w, 0)
            c1 = QColor(fg_color)
            c1.setAlphaF(0.6)
            grad.setColorAt(0.0, c1)
            grad.setColorAt(1.0, fg_color)
            
            painter.setBrush(grad)
            painter.drawRoundedRect(fill_rect, 4, 4)
            
class BarRow(QWidget):
    def __init__(self, label: str, value: float, max_value: float = 100.0, color_token: str = "accent", value_str: str = "", parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("bar-row")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 4, 0, 4)
        layout.setSpacing(12)
        
        self.lbl = QLabel(label)
        self.lbl.setFixedWidth(80)
        
        self.track = BarRowTrack(value, max_value, color_token)
        
        self.val_lbl = QLabel(value_str or str(value))
        self.val_lbl.setFixedWidth(40)
        self.val_lbl.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        
        layout.addWidget(self.lbl)
        layout.addWidget(self.track, 1)
        layout.addWidget(self.val_lbl)

__all__ = ["BarRow"]
