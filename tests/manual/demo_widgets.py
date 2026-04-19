"""Manual demo: open a window showing each Sprint 8 widget primitive."""
from __future__ import annotations

import sys

import pandas as pd
from PySide6.QtWidgets import QApplication, QGridLayout, QWidget

from app.ui.theme import Palette, load_qss
from app.ui.widgets.chart_panel import ChartPanel, Series
from app.ui.widgets.data_table import DataTable
from app.ui.widgets.filter_bar import FilterBar
from app.ui.widgets.kpi_tile import KpiTile
from app.ui.widgets.sparkline import Sparkline
from app.ui.widgets.stat_card import StatCard


def main() -> int:
    app = QApplication(sys.argv)
    app.setStyleSheet(load_qss(Palette()))

    win = QWidget()
    win.setWindowTitle("Sprint 8 — widget demo")
    win.resize(1000, 600)
    grid = QGridLayout(win)

    grid.addWidget(StatCard("Points", "42", "GW 14", Sparkline([1, 2, 3, 4])), 0, 0)
    grid.addWidget(KpiTile("Wins", "10", 2), 0, 1)
    grid.addWidget(KpiTile("Goal diff", "+12", 5), 0, 2)

    fb = FilterBar()
    fb.add_search("Search players…")
    fb.add_combo("position", "Position", ["All", "GK", "DEF", "MID", "ATT"])
    grid.addWidget(fb, 1, 0, 1, 3)

    df = pd.DataFrame({"name": ["A", "B", "C"], "ovr": [90, 88, 85]})
    grid.addWidget(DataTable(df), 2, 0, 1, 2)

    grid.addWidget(
        ChartPanel(
            "Points progression", subtitle="last 8 matchdays",
            x_axis="MD", y_axis="pts",
            series=[Series("pts", x=list(range(8)), y=[0, 3, 6, 7, 10, 13, 14, 17])],
        ),
        2, 2,
    )

    win.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
