"""ChartPanel — title + subtitle + PyQtGraph PlotWidget with one or more series."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable, Literal, Sequence

import pyqtgraph as pg
from PySide6.QtWidgets import QFrame, QLabel, QVBoxLayout, QWidget

SeriesKind = Literal["line", "bar", "scatter"]


@dataclass
class Series:
    name: str
    x: Sequence[float]
    y: Sequence[float]
    kind: SeriesKind = "line"
    color: str = "#7c9cff"
    width: float = 2.0
    extra: dict = field(default_factory=dict)


class ChartPanel(QFrame):
    def __init__(
        self,
        title: str,
        subtitle: str = "",
        x_axis: str = "",
        y_axis: str = "",
        series: Iterable[Series] | None = None,
        invert_y: bool = False,
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(parent)
        self.setObjectName("card")

        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 12, 14, 12)
        layout.setSpacing(4)

        title_lbl = QLabel(title)
        title_lbl.setObjectName("card-title")
        layout.addWidget(title_lbl)

        if subtitle:
            sub_lbl = QLabel(subtitle)
            sub_lbl.setObjectName("card-subtitle")
            layout.addWidget(sub_lbl)

        plot = pg.PlotWidget(background=None)
        plot.showGrid(x=True, y=True, alpha=0.15)
        plot.setLabel("bottom", x_axis)
        plot.setLabel("left", y_axis)
        if invert_y:
            plot.invertY(True)
        layout.addWidget(plot, 1)
        self._plot = plot

        if series:
            self.set_series(series)

    def set_series(self, series: Iterable[Series]) -> None:
        self._plot.clear()
        legend_added = False
        for s in series:
            if s.kind == "line":
                self._plot.plot(
                    list(s.x), list(s.y),
                    pen=pg.mkPen(s.color, width=s.width),
                    name=s.name,
                )
            elif s.kind == "scatter":
                scatter = pg.ScatterPlotItem(
                    x=list(s.x), y=list(s.y),
                    brush=pg.mkBrush(s.color),
                    pen=pg.mkPen(None),
                    size=s.extra.get("size", 8),
                    name=s.name,
                )
                self._plot.addItem(scatter)
            elif s.kind == "bar":
                width = s.extra.get("width", 0.6)
                bar = pg.BarGraphItem(
                    x=list(s.x), height=list(s.y),
                    width=width, brush=pg.mkBrush(s.color),
                )
                self._plot.addItem(bar)
            if not legend_added:
                # only one legend per panel
                pass
        legend_added = True


__all__ = ["ChartPanel", "Series", "SeriesKind"]
