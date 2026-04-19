"""LineChart component."""
from __future__ import annotations
from typing import Sequence
import pyqtgraph as pg
from PySide6.QtWidgets import QWidget, QVBoxLayout
from app.ui.design.theme_manager import ThemeManager

class LineChart(QWidget):
    def __init__(self, x_axis: str = "", y_axis: str = "", invert_y: bool = False, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        
        self.plot = pg.PlotWidget(background=None)
        layout.addWidget(self.plot)
        
        self.plot.setLabel("bottom", x_axis)
        self.plot.setLabel("left", y_axis)
        if invert_y:
            self.plot.invertY(True)
            
        self.plot.showGrid(x=True, y=True, alpha=0.15)
        self._series = []
        
        ThemeManager.instance().theme_changed.connect(self._on_theme_changed)
        self._apply_theme()
        
    def add_series(self, name: str, x: Sequence[float], y: Sequence[float], color_token: str = "accent", width: float = 2.0) -> None:
        self._series.append({
            "name": name, "x": list(x), "y": list(y), "color_token": color_token, "width": width
        })
        self._redraw()
        
    def clear(self) -> None:
        self._series.clear()
        self.plot.clear()
        
    def _redraw(self) -> None:
        self.plot.clear()
        palette = ThemeManager.instance().current()
        for s in self._series:
            color_hex = getattr(palette, s["color_token"], palette.accent)
            pen = pg.mkPen(color_hex, width=s["width"])
            self.plot.plot(s["x"], s["y"], pen=pen, name=s["name"])
            
    def _on_theme_changed(self, _) -> None:
        self._apply_theme()
        self._redraw()
        
    def _apply_theme(self) -> None:
        palette = ThemeManager.instance().current()
        for axis_name in ['bottom', 'left', 'top', 'right']:
            axis = self.plot.getAxis(axis_name)
            axis.setPen(palette.line)
            axis.setTextPen(palette.muted)

__all__ = ["LineChart"]
