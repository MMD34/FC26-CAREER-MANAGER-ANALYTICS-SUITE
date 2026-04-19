"""Card with title, large value, optional subtitle and trend sparkline."""
from __future__ import annotations

from typing import Optional

from PySide6.QtWidgets import QFrame, QLabel, QVBoxLayout, QWidget

from app.ui.widgets.sparkline import Sparkline


class StatCard(QFrame):
    def __init__(
        self,
        title: str,
        value: str,
        subtitle: str | None = None,
        trend: Optional[Sparkline] = None,
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(parent)
        self.setObjectName("card")
        self.setFrameShape(QFrame.Shape.NoFrame)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 12, 14, 12)
        layout.setSpacing(4)

        title_lbl = QLabel(title)
        title_lbl.setObjectName("card-title")
        layout.addWidget(title_lbl)

        value_lbl = QLabel(value)
        value_lbl.setObjectName("card-value")
        layout.addWidget(value_lbl)
        self._value_lbl = value_lbl

        if subtitle:
            sub = QLabel(subtitle)
            sub.setObjectName("card-subtitle")
            layout.addWidget(sub)

        if trend is not None:
            layout.addWidget(trend)

    def set_value(self, value: str) -> None:
        self._value_lbl.setText(value)


__all__ = ["StatCard"]
