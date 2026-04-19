"""Inline sparkline using PyQtGraph."""
from __future__ import annotations

from typing import Sequence

import pyqtgraph as pg
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QWidget


class Sparkline(pg.PlotWidget):
    def __init__(
        self,
        values: Sequence[float] | None = None,
        color: str = "#7c9cff",
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(parent=parent, background=None)
        self.setMouseEnabled(x=False, y=False)
        self.setMenuEnabled(False)
        self.hideAxis("bottom")
        self.hideAxis("left")
        self.setMinimumHeight(28)
        self.setMaximumHeight(48)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self._color = color
        self.set_values(values or [])

    def set_values(self, values: Sequence[float]) -> None:
        self.clear()
        if not values:
            return
        xs = list(range(len(values)))
        self.plot(xs, list(values), pen=pg.mkPen(self._color, width=2))


__all__ = ["Sparkline"]
