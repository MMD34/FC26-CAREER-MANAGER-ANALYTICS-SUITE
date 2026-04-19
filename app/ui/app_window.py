"""Main QMainWindow shell with sidebar routing into a QStackedWidget."""
from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtGui import QAction
from PySide6.QtWidgets import (
    QApplication,
    QHBoxLayout,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QSplitter,
    QStackedWidget,
    QStatusBar,
    QToolBar,
    QWidget,
)

from app.services.app_context import AppContext
from app.ui.theme import LightPalette, Palette, load_qss
from app.ui.pages.analytics_page import AnalyticsPage
from app.ui.pages.import_page import ImportPage
from app.ui.pages.overview_page import OverviewPage
from app.ui.pages.squad_page import SquadPage
from app.ui.pages.tactics_page import TacticsPage
from app.ui.pages.transfers_page import TransfersPage
from app.ui.pages.wonderkids_page import WonderkidsPage

SIDEBAR_PAGES: tuple[str, ...] = (
    "Overview",
    "Analytics",
    "Squad",
    "Wonderkids",
    "Tactics",
    "Transfers",
    "Import",
)


class AppWindow(QMainWindow):
    def __init__(self, context: AppContext | None = None) -> None:
        super().__init__()
        self.setWindowTitle("FC26 Analytics")
        self.resize(1280, 800)

        self.context = context or AppContext()

        sidebar = QListWidget()
        sidebar.setFixedWidth(200)
        for name in SIDEBAR_PAGES:
            sidebar.addItem(QListWidgetItem(name))
        sidebar.setCurrentRow(0)
        self._sidebar = sidebar

        stack = QStackedWidget()
        self._pages: list[QWidget] = [
            OverviewPage(self.context),
            AnalyticsPage(self.context),
            SquadPage(self.context),
            WonderkidsPage(self.context),
            TacticsPage(self.context),
            TransfersPage(self.context),
            ImportPage(self.context),
        ]
        for p in self._pages:
            stack.addWidget(p)
        self._stack = stack

        sidebar.currentRowChanged.connect(stack.setCurrentIndex)

        splitter = QSplitter(Qt.Orientation.Horizontal)
        splitter.addWidget(sidebar)
        splitter.addWidget(stack)
        splitter.setStretchFactor(0, 0)
        splitter.setStretchFactor(1, 1)

        container = QWidget()
        layout = QHBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(splitter)
        self.setCentralWidget(container)

        status = QStatusBar()
        status.showMessage("Ready")
        self.setStatusBar(status)
        self._status = status

        toolbar = QToolBar("Top")
        toolbar.setMovable(False)
        self.addToolBar(toolbar)
        self._theme_action = QAction("Light theme", self)
        self._theme_action.setCheckable(True)
        self._theme_action.toggled.connect(self._toggle_theme)
        toolbar.addAction(self._theme_action)
        self._light_mode = False

        self.context.dataChanged.connect(self._on_data_changed)

    def _toggle_theme(self, checked: bool) -> None:
        self._light_mode = checked
        palette = LightPalette() if checked else Palette()
        app = QApplication.instance()
        if app is not None:
            app.setStyleSheet(load_qss(palette))
        self._theme_action.setText("Dark theme" if checked else "Light theme")

    def _on_data_changed(self) -> None:
        for page in self._pages:
            refresh = getattr(page, "refresh", None)
            if callable(refresh):
                refresh()
        self._status.showMessage("Data refreshed")
