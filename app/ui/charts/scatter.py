"""ScatterChart component."""
from __future__ import annotations
from typing import Sequence
import pyqtgraph as pg
from PySide6.QtWidgets import QWidget, QVBoxLayout
from app.ui.design.theme_manager import ThemeManager

class ScatterChart(QWidget):
    def __init__(self, x_axis: str = "", y_axis: str = "", parent: QWidget | None = None) -> None:
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        
        self.plot = pg.PlotWidget(background=None)
        layout.addWidget(self.plot)
        self.plot.setLabel("bottom", x_axis)
        self.plot.setLabel("left", y_axis)
        
        self._series = []
        ThemeManager.instance().theme_changed.connect(self._on_theme_changed)
        self._apply_theme()
        
    def add_series(self, name: str, x: Sequence[float], y: Sequence[float], color_token: str = "accent", size: float = 8.0) -> None:
        self._series.append({
            "name": name, "x": list(x), "y": list(y), "color_token": color_token, "size": size
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
            scatter = pg.ScatterPlotItem(
                x=s["x"], y=s["y"],
                brush=pg.mkBrush(color_hex),
                pen=pg.mkPen(None),
                size=s["size"],
                name=s["name"]
            )
            self.plot.addItem(scatter)
            
        if self._series:
            all_x = [v for s in self._series for v in s["x"]]
            all_y = [v for s in self._series for v in s["y"]]
            if all_x and all_y:
                mid_x = (max(all_x) + min(all_x)) / 2
                mid_y = (max(all_y) + min(all_y)) / 2
                v_line = pg.InfiniteLine(pos=mid_x, angle=90, pen=pg.mkPen(palette.line_2, width=2))
                h_line = pg.InfiniteLine(pos=mid_y, angle=0, pen=pg.mkPen(palette.line_2, width=2))
                self.plot.addItem(v_line)
                self.plot.addItem(h_line)
                
    def _on_theme_changed(self, _) -> None:
        self._apply_theme()
        self._redraw()
        
    def _apply_theme(self) -> None:
        palette = ThemeManager.instance().current()
        for axis_name in ['bottom', 'left', 'top', 'right']:
            axis = self.plot.getAxis(axis_name)
            axis.setPen(palette.line)
            axis.setTextPen(palette.muted)

__all__ = ["ScatterChart"]
