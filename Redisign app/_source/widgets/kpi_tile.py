"""Compact KPI tile: label, value, optional delta indicator."""
from __future__ import annotations

from PySide6.QtWidgets import QFrame, QHBoxLayout, QLabel, QVBoxLayout, QWidget


class KpiTile(QFrame):
    def __init__(
        self,
        label: str,
        value: str,
        delta: float | None = None,
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(parent)
        self.setObjectName("card")

        outer = QVBoxLayout(self)
        outer.setContentsMargins(12, 10, 12, 10)
        outer.setSpacing(2)

        label_lbl = QLabel(label)
        label_lbl.setObjectName("card-title")
        outer.addWidget(label_lbl)

        row = QHBoxLayout()
        row.setSpacing(6)
        value_lbl = QLabel(value)
        value_lbl.setObjectName("card-value")
        row.addWidget(value_lbl)
        if delta is not None:
            sign = "+" if delta >= 0 else ""
            d = QLabel(f"{sign}{delta:g}")
            d.setObjectName("card-subtitle")
            color = "#5ad19a" if delta >= 0 else "#ef6f6f"
            d.setStyleSheet(f"color: {color};")
            row.addWidget(d)
        row.addStretch(1)
        outer.addLayout(row)

        self._value_lbl = value_lbl

    def set_value(self, value: str) -> None:
        self._value_lbl.setText(value)


__all__ = ["KpiTile"]
