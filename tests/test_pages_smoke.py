"""Sprint 8 smoke: instantiate every widget primitive without exception."""
from __future__ import annotations

import pandas as pd
import pytest

pytest.importorskip("PySide6")
pytest.importorskip("pyqtgraph")
pytestqt = pytest.importorskip("pytestqt")

from app.ui.theme import Palette, load_qss  # noqa: E402
from app.ui.widgets.chart_panel import ChartPanel, Series  # noqa: E402
from app.ui.widgets.data_table import DataTable  # noqa: E402
from app.ui.widgets.filter_bar import FilterBar  # noqa: E402
from app.ui.widgets.kpi_tile import KpiTile  # noqa: E402
from app.ui.widgets.sparkline import Sparkline  # noqa: E402
from app.ui.widgets.stat_card import StatCard  # noqa: E402


def test_load_qss_renders() -> None:
    qss = load_qss(Palette())
    assert "background-color" in qss


def test_sparkline(qtbot) -> None:
    w = Sparkline([1, 2, 3, 2, 4])
    qtbot.addWidget(w)
    assert w is not None


def test_stat_card(qtbot) -> None:
    w = StatCard("Points", "42", subtitle="GW 14", trend=Sparkline([1, 2, 3]))
    qtbot.addWidget(w)


def test_kpi_tile(qtbot) -> None:
    w = KpiTile("Wins", "10", delta=2)
    qtbot.addWidget(w)


def test_data_table(qtbot) -> None:
    df = pd.DataFrame({"a": [1, 2], "b": ["x", "y"]})
    w = DataTable(df)
    qtbot.addWidget(w)
    assert w.model().rowCount() == 2


def test_filter_bar(qtbot) -> None:
    w = FilterBar()
    w.add_search()
    w.add_combo("pos", "Position", ["All", "GK", "DEF"])
    qtbot.addWidget(w)
    assert w.filter_value("pos") == "All"


def test_chart_panel(qtbot) -> None:
    w = ChartPanel(
        "Test", subtitle="sub", x_axis="x", y_axis="y",
        series=[Series("a", x=[0, 1, 2], y=[1, 2, 3], kind="line")],
    )
    qtbot.addWidget(w)
