"""Composable QToolBar with a search field and combo-box filters."""
from __future__ import annotations

from typing import Iterable

from PySide6.QtCore import Signal
from PySide6.QtWidgets import QComboBox, QLineEdit, QLabel, QToolBar, QWidget


class FilterBar(QToolBar):
    searchChanged = Signal(str)
    filterChanged = Signal(str, str)  # key, value

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setMovable(False)
        self._search: QLineEdit | None = None
        self._combos: dict[str, QComboBox] = {}

    def add_search(self, placeholder: str = "Search…") -> QLineEdit:
        edit = QLineEdit()
        edit.setPlaceholderText(placeholder)
        edit.setClearButtonEnabled(True)
        edit.textChanged.connect(self.searchChanged)
        edit.setMaximumWidth(220)
        self.addWidget(edit)
        self._search = edit
        return edit

    def add_combo(
        self, key: str, label: str, values: Iterable[str], default: str | None = None
    ) -> QComboBox:
        self.addWidget(QLabel(f"  {label}: "))
        combo = QComboBox()
        for v in values:
            combo.addItem(v)
        if default is not None:
            idx = combo.findText(default)
            if idx >= 0:
                combo.setCurrentIndex(idx)
        combo.currentTextChanged.connect(lambda txt, k=key: self.filterChanged.emit(k, txt))
        self.addWidget(combo)
        self._combos[key] = combo
        return combo

    def search_text(self) -> str:
        return self._search.text() if self._search else ""

    def filter_value(self, key: str) -> str:
        combo = self._combos.get(key)
        return combo.currentText() if combo else ""


__all__ = ["FilterBar"]
