"""QTableView wrapper backed by a pandas DataFrame model."""
from __future__ import annotations

from typing import Sequence

import pandas as pd
from PySide6.QtCore import QAbstractTableModel, QModelIndex, Qt
from PySide6.QtWidgets import QHeaderView, QTableView, QWidget


class _PandasModel(QAbstractTableModel):
    def __init__(self, df: pd.DataFrame, columns: Sequence[str] | None = None):
        super().__init__()
        self._set_df(df, columns)

    def _set_df(self, df: pd.DataFrame, columns: Sequence[str] | None) -> None:
        cols = list(columns) if columns is not None else list(df.columns)
        self._cols = [c for c in cols if c in df.columns]
        self._df = df[self._cols].reset_index(drop=True) if self._cols else df.iloc[0:0]

    def replace(self, df: pd.DataFrame, columns: Sequence[str] | None = None) -> None:
        self.beginResetModel()
        self._set_df(df, columns)
        self.endResetModel()

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._df)

    def columnCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._cols)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or role != Qt.ItemDataRole.DisplayRole:
            return None
        value = self._df.iat[index.row(), index.column()]
        if pd.isna(value):
            return ""
        return str(value)

    def headerData(
        self,
        section: int,
        orientation: Qt.Orientation,
        role: int = Qt.ItemDataRole.DisplayRole,
    ):
        if role != Qt.ItemDataRole.DisplayRole:
            return None
        if orientation == Qt.Orientation.Horizontal:
            return self._cols[section] if section < len(self._cols) else None
        return section + 1


class DataTable(QTableView):
    def __init__(
        self,
        df: pd.DataFrame | None = None,
        columns: Sequence[str] | None = None,
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(parent)
        self._model = _PandasModel(df if df is not None else pd.DataFrame(), columns)
        self.setModel(self._model)
        self.setAlternatingRowColors(True)
        self.setSortingEnabled(False)
        self.verticalHeader().setVisible(False)
        self.horizontalHeader().setStretchLastSection(True)
        self.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.ResizeToContents)
        self.setSelectionBehavior(QTableView.SelectionBehavior.SelectRows)

    def set_dataframe(
        self, df: pd.DataFrame, columns: Sequence[str] | None = None
    ) -> None:
        self._model.replace(df, columns)


__all__ = ["DataTable"]
