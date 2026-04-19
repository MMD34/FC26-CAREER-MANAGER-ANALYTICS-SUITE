from __future__ import annotations
from typing import Literal

from PySide6.QtWidgets import QFrame, QVBoxLayout, QHBoxLayout, QLabel
from PySide6.QtCore import Qt, Signal

from app.ui.components.primitives import Pill

class Dropzone(QFrame):
    """A drag-and-drop zone."""
    files_dropped = Signal(list)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("dropzone")
        self.setAcceptDrops(True)
        
        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(32, 48, 32, 48)
        self.main_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.main_layout.setSpacing(8)
        
        self.text_lbl = QLabel("Drag & drop CSV files here")
        self.text_lbl.setObjectName("dropzone-text")
        self.text_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.sub_lbl = QLabel("or click to browse")
        self.sub_lbl.setObjectName("dropzone-sub")
        self.sub_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.main_layout.addWidget(self.text_lbl)
        self.main_layout.addWidget(self.sub_lbl)

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
            self.setProperty("drag-hover", True)
            self.style().unpolish(self)
            self.style().polish(self)

    def dragLeaveEvent(self, event):
        self.setProperty("drag-hover", False)
        self.style().unpolish(self)
        self.style().polish(self)

    def dropEvent(self, event):
        self.setProperty("drag-hover", False)
        self.style().unpolish(self)
        self.style().polish(self)
        
        urls = event.mimeData().urls()
        files = [u.toLocalFile() for u in urls if u.isLocalFile()]
        if files:
            self.files_dropped.emit(files)

class FileRow(QFrame):
    """A row displaying an imported file and its status."""
    def __init__(self, filename: str, status: Literal["ok", "warn", "err"] = "ok", parent=None):
        super().__init__(parent)
        self.setObjectName("file-row")
        
        layout = QHBoxLayout(self)
        layout.setContentsMargins(12, 8, 12, 8)
        layout.setSpacing(12)
        
        self.name_lbl = QLabel(filename)
        self.name_lbl.setObjectName("file-name")
        layout.addWidget(self.name_lbl, 1)
        
        # Mapping status to Pill level/text
        pill_level: Literal["hi", "md", "lo"] = "md"
        pill_text = "OK"
        if status == "warn":
            pill_level = "lo"
            pill_text = "Partial"
        elif status == "err":
            pill_level = "hi"
            pill_text = "Error"
            
        self.status_pill = Pill(pill_text, level=pill_level)
        layout.addWidget(self.status_pill)
