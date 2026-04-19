"""Dial component."""
from __future__ import annotations
from PySide6.QtCore import Qt, QRectF
from PySide6.QtGui import QPainter, QColor, QPen
from PySide6.QtWidgets import QWidget, QVBoxLayout, QLabel
from app.ui.design.theme_manager import ThemeManager

class Dial(QWidget):
    def __init__(self, value: float = 0.0, max_value: float = 100.0, label: str = "", color_token: str = "accent", parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.value = value
        self.max_value = max_value
        self.color_token = color_token
        self.label_text = label
        self.setMinimumSize(80, 80)
        ThemeManager.instance().theme_changed.connect(self.update)
        
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.center_lbl = QLabel(str(int(value)))
        self.center_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = self.center_lbl.font()
        font.setPointSize(16)
        font.setBold(True)
        self.center_lbl.setFont(font)
        layout.addWidget(self.center_lbl)
        
    def paintEvent(self, event) -> None:
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        rect = self.rect()
        size = min(rect.width(), rect.height()) - 16
        draw_rect = QRectF((rect.width() - size)/2, (rect.height() - size)/2, size, size)
        
        palette = ThemeManager.instance().current()
        bg_color = QColor(palette.line)
        fg_color = QColor(getattr(palette, self.color_token, palette.accent))
        
        pen_bg = QPen(bg_color, 8)
        pen_bg.setCapStyle(Qt.PenCapStyle.RoundCap)
        painter.setPen(pen_bg)
        painter.drawArc(draw_rect, 0, 360 * 16)
        
        if self.max_value > 0 and self.value > 0:
            ratio = min(1.0, self.value / self.max_value)
            span_angle = int(-ratio * 360 * 16)
            
            pen_fg = QPen(fg_color, 8)
            pen_fg.setCapStyle(Qt.PenCapStyle.RoundCap)
            painter.setPen(pen_fg)
            painter.drawArc(draw_rect, 90 * 16, span_angle)

__all__ = ["Dial"]
