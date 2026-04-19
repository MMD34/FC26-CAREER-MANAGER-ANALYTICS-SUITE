"""Reusable per-player detail drawer (used by Squad + Wonderkids pages).

Displays a 6-axis face-aggregate "radar" (rendered as a bar chart in
PyQtGraph; a true polar radar requires extra plumbing not budgeted here)
plus an attribute list and form/injury badges.
"""
from __future__ import annotations

import pandas as pd
from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QDockWidget,
    QFrame,
    QHBoxLayout,
    QLabel,
    QListWidget,
    QVBoxLayout,
    QWidget,
)

from app.analytics.wonderkids import origin_label, position_group
from app.ui.charts.chart_panel import ChartPanel, Series

_FACE_AXES = ("pacdiv", "shohan", "paskic", "driref", "defspe", "phypos")
_FACE_LABEL = ("PAC", "SHO", "PAS", "DRI", "DEF", "PHY")


def _badge(text: str, color: str) -> QLabel:
    lbl = QLabel(text)
    lbl.setStyleSheet(
        f"background-color: {color}; color: #0f1115; padding: 2px 8px;"
        " border-radius: 8px; font-weight: 600;"
    )
    return lbl


class PlayerDrawer(QDockWidget):
    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__("Player", parent)
        self.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        self.setFeatures(QDockWidget.DockWidgetFeature.DockWidgetClosable)

        body = QWidget()
        layout = QVBoxLayout(body)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(10)

        self._name = QLabel("—")
        self._name.setStyleSheet("font-size: 18px; font-weight: 600;")
        layout.addWidget(self._name)

        badges = QFrame()
        self._badges_layout = QHBoxLayout(badges)
        self._badges_layout.setContentsMargins(0, 0, 0, 0)
        self._badges_layout.setSpacing(6)
        layout.addWidget(badges)

        self._chart = ChartPanel("Face aggregates", x_axis="", y_axis="0–99")
        layout.addWidget(self._chart, 1)

        self._attrs = QListWidget()
        layout.addWidget(self._attrs, 2)

        self.setWidget(body)

    def show_player(self, player: pd.Series) -> None:
        name = str(player.get("display_name") or player.get("playerid") or "—")
        self._name.setText(name)

        # badges
        while self._badges_layout.count():
            item = self._badges_layout.takeAt(0)
            w = item.widget()
            if w is not None:
                w.deleteLater()
        pos = position_group(player.get("preferredposition1"))
        if pos:
            self._badges_layout.addWidget(_badge(pos, "#7c9cff"))
        try:
            origin = origin_label(int(player.get("playerid")))
            self._badges_layout.addWidget(_badge(origin.upper(), "#9aa0aa"))
        except Exception:
            pass
        form_v = player.get("form")
        if pd.notna(form_v):
            self._badges_layout.addWidget(_badge(f"Form {int(form_v)}", "#5ad19a"))
        injury_v = player.get("injury")
        if pd.notna(injury_v) and float(injury_v) > 0:
            self._badges_layout.addWidget(_badge(f"Injury {int(injury_v)}", "#ef6f6f"))
        self._badges_layout.addStretch(1)

        # face-aggregate "radar" (bar chart)
        ys: list[float] = []
        for axis in _FACE_AXES:
            v = player.get(axis)
            ys.append(float(v) if pd.notna(v) else 0.0)
        self._chart.set_series([
            Series("face", x=list(range(len(_FACE_AXES))), y=ys, kind="bar", color="#7c9cff"),
        ])

        # attribute list
        self._attrs.clear()
        for axis, label in zip(_FACE_AXES, _FACE_LABEL):
            v = player.get(axis)
            self._attrs.addItem(f"{label}: {int(v) if pd.notna(v) else '—'}")
        for col in ("overallrating", "potential", "age", "leagueappearances",
                    "leaguegoals", "yellows", "reds"):
            v = player.get(col)
            if pd.notna(v):
                self._attrs.addItem(f"{col}: {int(v) if isinstance(v, (int, float)) else v}")


__all__ = ["PlayerDrawer"]
