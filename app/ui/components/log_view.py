from __future__ import annotations
from typing import Literal

from PySide6.QtWidgets import QPlainTextEdit
from PySide6.QtGui import QTextCursor, QTextCharFormat, QColor
from PySide6.QtCore import Qt

from app.ui.design.theme_manager import ThemeManager

class LogView(QPlainTextEdit):
    """A read-only log viewer with monospace formatting and colored lines."""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("log-view")
        self.setReadOnly(True)
        # Avoid wrapping for raw log lines
        self.setLineWrapMode(QPlainTextEdit.LineWrapMode.NoWrap)
        
    def append_log(self, text: str, level: Literal["info", "ok", "warn", "err"] = "info", timestamp: str | None = None) -> None:
        cursor = self.textCursor()
        cursor.movePosition(QTextCursor.MoveOperation.End)
        
        fmt = QTextCharFormat()
        
        # Pull colors dynamically from ThemeManager
        # NOTE: This assumes ThemeManager is a singleton and initialized.
        theme = ThemeManager().current_palette
        
        color = theme.text
        if level == "ok":
            color = theme.ok
        elif level == "warn":
            color = theme.warn
        elif level == "err":
            color = theme.bad
        elif level == "info":
            color = theme.text
            
        # Write timestamp with dimmed color
        if timestamp:
            ts_fmt = QTextCharFormat()
            ts_fmt.setForeground(QColor(theme.dim))
            cursor.insertText(f"[{timestamp}] ", ts_fmt)
            
        fmt.setForeground(QColor(color))
        cursor.insertText(text + "\n", fmt)
        
        self.setTextCursor(cursor)
        self.ensureCursorVisible()
