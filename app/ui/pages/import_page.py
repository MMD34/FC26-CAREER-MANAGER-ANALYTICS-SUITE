"""Import page (PT §12.2): drag-drop, file picker, parse log, clear-cache."""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QObject, QRunnable, Qt, QThreadPool, Signal
from PySide6.QtGui import QDragEnterEvent, QDropEvent
from PySide6.QtWidgets import (
    QFileDialog,
    QFrame,
    QHBoxLayout,
    QLabel,
    QListWidget,
    QListWidgetItem,
    QMessageBox,
    QPlainTextEdit,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

from app.core.logging_setup import get_logger
from app.core.paths import desktop_dir
from app.import_.pipeline import ImportReport, import_folder
from app.services.app_context import AppContext
from app.ui.pages._base import PageBase

_log = get_logger(__name__)

_STATUS_ICON = {"ok": "✓", "error": "✗", "warning": "!"}


class _DropZone(QFrame):
    folderDropped = Signal(Path)

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("card")
        self.setAcceptDrops(True)
        self.setMinimumHeight(100)
        layout = QVBoxLayout(self)
        lbl = QLabel("Drop a folder here, or click ‘Pick folder’ below")
        lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(lbl)

    def dragEnterEvent(self, event: QDragEnterEvent) -> None:
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
        else:
            event.ignore()

    def dropEvent(self, event: QDropEvent) -> None:
        for url in event.mimeData().urls():
            path = Path(url.toLocalFile())
            if path.is_dir():
                self.folderDropped.emit(path)
                event.acceptProposedAction()
                return
        event.ignore()


class _WorkerSignals(QObject):
    finished = Signal(object)  # ImportReport
    failed = Signal(str)


class _ImportWorker(QRunnable):
    def __init__(self, folder: Path) -> None:
        super().__init__()
        self.folder = folder
        self.signals = _WorkerSignals()

    def run(self) -> None:  # type: ignore[override]
        try:
            report = import_folder(self.folder)
        except Exception as exc:  # pragma: no cover - defensive
            _log.exception("import worker crashed")
            self.signals.failed.emit(repr(exc))
            return
        self.signals.finished.emit(report)


class ImportPage(PageBase):
    title = "Import"

    def __init__(self, context: AppContext) -> None:
        super().__init__(context)

        outer = QVBoxLayout(self)
        outer.setContentsMargins(20, 20, 20, 20)
        outer.setSpacing(10)

        title = QLabel("Import")
        title.setStyleSheet("font-size: 20px; font-weight: 600;")
        outer.addWidget(title)

        self._dropzone = _DropZone()
        self._dropzone.folderDropped.connect(self._start_import)
        outer.addWidget(self._dropzone)

        controls = QHBoxLayout()
        self._pick_btn = QPushButton("Pick folder…")
        self._pick_btn.clicked.connect(self._pick_folder)
        controls.addWidget(self._pick_btn)
        self._clear_btn = QPushButton("Clear cache")
        self._clear_btn.clicked.connect(self._clear_cache)
        controls.addWidget(self._clear_btn)
        controls.addStretch(1)
        outer.addLayout(controls)

        self._files = QListWidget()
        outer.addWidget(self._files, 1)

        self._log = QPlainTextEdit()
        self._log.setReadOnly(True)
        self._log.setStyleSheet("font-family: 'Consolas', 'Cascadia Mono', monospace;")
        outer.addWidget(self._log, 1)

        self._pool = QThreadPool.globalInstance()

    # --- actions ------------------------------------------------------------

    def _pick_folder(self) -> None:
        start = str(desktop_dir())
        folder = QFileDialog.getExistingDirectory(self, "Select folder", start)
        if folder:
            self._start_import(Path(folder))

    def _start_import(self, folder: Path) -> None:
        self._append_log(f"→ scanning {folder}")
        self._files.clear()
        self._pick_btn.setEnabled(False)
        worker = _ImportWorker(folder)
        worker.signals.finished.connect(self._on_finished)
        worker.signals.failed.connect(self._on_failed)
        self._pool.start(worker)

    def _on_finished(self, report: ImportReport) -> None:
        self._pick_btn.setEnabled(True)
        for fr in report.files:
            icon = _STATUS_ICON.get(fr.status, "?")
            text = f"{icon} {fr.path.name} [{fr.kind}] rows={fr.rows_read}"
            if fr.error:
                text += f"  — {fr.error}"
            self._files.addItem(QListWidgetItem(text))
            if fr.status == "ok" and fr.parsed is not None:
                self.context.cache.save(fr.parsed)
        ok = report.ok_count
        err = report.error_count
        self._append_log(f"done: {ok} parsed, {err} errors")
        if ok > 0:
            self.context.notify_changed()

    def _on_failed(self, message: str) -> None:
        self._pick_btn.setEnabled(True)
        self._append_log(f"FAILED: {message}")

    def _clear_cache(self) -> None:
        confirm = QMessageBox.question(
            self,
            "Clear cache?",
            "This will remove all imported snapshots from the session cache. Continue?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if confirm == QMessageBox.StandardButton.Yes:
            self.context.cache.clear()
            self._append_log("cache cleared")
            self.context.notify_changed()

    def _append_log(self, line: str) -> None:
        self._log.appendPlainText(line)
