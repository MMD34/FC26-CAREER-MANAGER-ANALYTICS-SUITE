"""ChartPanel upgraded to use new primitives."""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Iterable, Literal, Sequence
from PySide6.QtWidgets import QFrame, QLabel, QVBoxLayout, QWidget
from app.ui.charts.line_chart import LineChart
from app.ui.charts.scatter import ScatterChart

SeriesKind = Literal["line", "bar", "scatter"]

@dataclass
class Series:
    name: str
    x: Sequence[float]
    y: Sequence[float]
    kind: SeriesKind = "line"
    color: str = "accent"
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

        is_scatter = any(s.kind == "scatter" for s in (series or []))
        if is_scatter:
            self._chart = ScatterChart(x_axis, y_axis)
        else:
            self._chart = LineChart(x_axis, y_axis, invert_y=invert_y)
            
        layout.addWidget(self._chart, 1)

        if series:
            self.set_series(series)

    def set_series(self, series: Iterable[Series]) -> None:
        self._chart.clear()
        for s in series:
            if s.kind == "line" and isinstance(self._chart, LineChart):
                self._chart.add_series(s.name, s.x, s.y, color_token=s.color, width=s.width)
            elif s.kind == "scatter" and isinstance(self._chart, ScatterChart):
                size = s.extra.get("size", 8.0)
                self._chart.add_series(s.name, s.x, s.y, color_token=s.color, size=size)
            elif s.kind == "bar" and isinstance(self._chart, LineChart):
                self._chart.add_series(s.name, s.x, s.y, color_token=s.color, width=s.width)

__all__ = ["ChartPanel", "Series", "SeriesKind"]
