"""Sparkline component."""
from __future__ import annotations
from typing import Sequence
from PySide6.QtCore import Qt, QPointF
from PySide6.QtGui import QPainter, QPainterPath, QPen, QColor, QLinearGradient
from PySide6.QtWidgets import QWidget
from app.ui.design.theme_manager import ThemeManager

class Sparkline(QWidget):
    def __init__(self, values: Sequence[float] | None = None, color: str = "accent", parent: QWidget | None = None) -> None:
        super().__init__(parent=parent)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self.setMinimumHeight(28)
        self.setMaximumHeight(48)
        self._color_token = color
        self._values = list(values) if values else []
        ThemeManager.instance().theme_changed.connect(self._on_theme_changed)
        
    def set_values(self, values: Sequence[float]) -> None:
        self._values = list(values)
        self.update()
        
    def _on_theme_changed(self, _) -> None:
        self.update()

    def paintEvent(self, event) -> None:
        if not self._values or len(self._values) < 2:
            return
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        rect = self.rect()
        margin = 2
        w, h = rect.width() - 2 * margin, rect.height() - 2 * margin
        min_val, max_val = min(self._values), max(self._values)
        range_val = max_val - min_val if max_val > min_val else 1.0
        
        palette = ThemeManager.instance().current()
        color_hex = getattr(palette, self._color_token, palette.accent)
        color = QColor(color_hex)
        
        points = []
        n = len(self._values)
        for i, val in enumerate(self._values):
            x = margin + (i / (n - 1)) * w
            y = margin + h - ((val - min_val) / range_val) * h
            points.append(QPointF(x, y))
            
        path = QPainterPath()
        path.moveTo(points[0])
        for i in range(len(points) - 1):
            p1, p2 = points[i], points[i + 1]
            ctrl1 = QPointF((p1.x() + p2.x()) / 2, p1.y())
            ctrl2 = QPointF((p1.x() + p2.x()) / 2, p2.y())
            path.cubicTo(ctrl1, ctrl2, p2)
            
        pen = QPen(color, 2.0)
        pen.setCapStyle(Qt.PenCapStyle.RoundCap)
        pen.setJoinStyle(Qt.PenJoinStyle.RoundJoin)
        painter.setPen(pen)
        painter.drawPath(path)
        
        fill_path = QPainterPath(path)
        fill_path.lineTo(points[-1].x(), rect.height())
        fill_path.lineTo(points[0].x(), rect.height())
        fill_path.closeSubpath()
        
        grad = QLinearGradient(0, margin, 0, rect.height())
        grad_color = QColor(color)
        grad_color.setAlpha(40)
        grad.setColorAt(0.0, grad_color)
        grad.setColorAt(1.0, QColor(0, 0, 0, 0))
        painter.fillPath(fill_path, grad)
        painter.end()

__all__ = ["Sparkline"]
