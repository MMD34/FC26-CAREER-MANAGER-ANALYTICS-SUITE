"""Sprint 13 page-level smoke tests.

Each page is instantiated against an empty AppContext and against one with
synthetic snapshots written via the parser layer. We capture Qt warnings:
the test fails if any are emitted.
"""
from __future__ import annotations

from pathlib import Path

import pytest

pytest.importorskip("PySide6")
pytest.importorskip("pyqtgraph")
pytest.importorskip("pytestqt")

from PySide6.QtCore import QtMsgType, qInstallMessageHandler  # noqa: E402

from app.import_.parsers import parser_for  # noqa: E402
from app.services.app_context import AppContext  # noqa: E402
from app.services.cache import SessionCache  # noqa: E402
from app.ui.pages.analytics_page import AnalyticsPage  # noqa: E402
from app.ui.pages.import_page import ImportPage  # noqa: E402
from app.ui.pages.overview_page import OverviewPage  # noqa: E402
from app.ui.pages.squad_page import SquadPage  # noqa: E402
from app.ui.pages.tactics_page import TacticsPage  # noqa: E402
from app.ui.pages.transfers_page import TransfersPage  # noqa: E402
from app.ui.pages.wonderkids_page import WonderkidsPage  # noqa: E402

from tests.test_parsers import _write_csv, ALL_KINDS  # noqa: E402

PAGE_CLASSES = (
    OverviewPage,
    AnalyticsPage,
    SquadPage,
    WonderkidsPage,
    TacticsPage,
    TransfersPage,
    ImportPage,
)


@pytest.fixture
def context(tmp_path: Path, monkeypatch) -> AppContext:
    # Redirect cache to tmp_path so the test never touches %LOCALAPPDATA%.
    monkeypatch.setattr(
        "app.services.app_context.cache_dir",
        lambda: tmp_path,
    )
    return AppContext("test_runtime")


@pytest.fixture
def populated_context(context: AppContext, tmp_path: Path) -> AppContext:
    # Save one of each kind to the cache.
    for kind in ALL_KINDS:
        path = _write_csv(tmp_path, kind)
        parsed = parser_for(kind).parse(path)
        context.cache.save(parsed)
    return context


@pytest.fixture
def qt_warning_capture():
    captured: list[str] = []

    def handler(msg_type, _ctx, message):
        if msg_type in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg):
            captured.append(message)

    qInstallMessageHandler(handler)
    yield captured
    qInstallMessageHandler(None)


@pytest.mark.parametrize("page_cls", PAGE_CLASSES)
def test_page_empty_cache(qtbot, qt_warning_capture, context, page_cls) -> None:
    page = page_cls(context)
    qtbot.addWidget(page)
    assert qt_warning_capture == [], qt_warning_capture


@pytest.mark.parametrize("page_cls", PAGE_CLASSES)
def test_page_with_data(qtbot, qt_warning_capture, populated_context, page_cls) -> None:
    page = page_cls(populated_context)
    qtbot.addWidget(page)
    page.refresh()
    assert qt_warning_capture == [], qt_warning_capture
