"""Pitch widget."""
from __future__ import annotations
from PySide6.QtCore import Qt
from PySide6.QtGui import QPainter, QColor, QPen
from PySide6.QtWidgets import QWidget
from app.ui.design.theme_manager import ThemeManager

class Pitch(QWidget):
    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setMinimumSize(200, 300)
        ThemeManager.instance().theme_changed.connect(self.update)
        
    def paintEvent(self, event) -> None:
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        rect = self.rect()
        palette = ThemeManager.instance().current()
        bg_color = QColor(palette.panel_2)
        line_color = QColor(palette.line_2)
        
        painter.fillRect(rect, bg_color)
        
        pen = QPen(line_color, 2)
        painter.setPen(pen)
        
        w, h = rect.width(), rect.height()
        m = 10
        
        # Outlines
        painter.drawRect(m, m, w - 2*m, h - 2*m)
        
        # Center line
        painter.drawLine(m, h/2, w - m, h/2)
        
        # Center circle
        painter.drawEllipse(w/2 - 30, h/2 - 30, 60, 60)
        
        # Penalty areas
        painter.drawRect(w/2 - 50, m, 100, 40)
        painter.drawRect(w/2 - 50, h - m - 40, 100, 40)
        
__all__ = ["Pitch"]
