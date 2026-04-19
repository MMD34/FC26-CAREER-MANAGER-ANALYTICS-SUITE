"""UI theme tokens and QSS loader.

Defines the design tokens (palette, spacing, radii, typography) used across
the app and produces the QSS string consumed by QApplication.setStyleSheet.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class Palette:
    background: str = "#0f1115"
    surface: str = "#14171d"
    surface_alt: str = "#1c2029"
    border: str = "#1c2029"
    text: str = "#e6e8ec"
    text_muted: str = "#9aa0aa"
    accent: str = "#7c9cff"
    success: str = "#5ad19a"
    warning: str = "#f3c969"
    danger: str = "#ef6f6f"


@dataclass(frozen=True)
class LightPalette(Palette):
    background: str = "#f5f6fa"
    surface: str = "#ffffff"
    surface_alt: str = "#eef0f6"
    border: str = "#dcdfe7"
    text: str = "#101218"
    text_muted: str = "#5b6271"
    accent: str = "#3858d4"


@dataclass(frozen=True)
class Spacing:
    xs: int = 4
    sm: int = 8
    md: int = 12
    lg: int = 16
    xl: int = 24
    xxl: int = 32


@dataclass(frozen=True)
class Radii:
    sm: int = 6
    md: int = 10
    lg: int = 14


@dataclass(frozen=True)
class FontTokens:
    family: str = '"Inter", "Segoe UI", system-ui, sans-serif'
    size_sm: int = 11
    size_base: int = 13
    size_md: int = 15
    size_lg: int = 20


@dataclass(frozen=True)
class Theme:
    palette: Palette = field(default_factory=Palette)
    spacing: Spacing = field(default_factory=Spacing)
    radii: Radii = field(default_factory=Radii)
    fonts: FontTokens = field(default_factory=FontTokens)


def load_qss(palette: Palette | None = None) -> str:
    """Render the global stylesheet using the supplied palette tokens."""
    p = palette or Palette()
    f = FontTokens()
    return f"""
QWidget {{
    background-color: {p.background};
    color: {p.text};
    font-family: {f.family};
    font-size: {f.size_base}px;
}}
QMainWindow {{ background-color: {p.background}; }}
QStatusBar {{
    background-color: {p.surface};
    color: {p.text_muted};
    border-top: 1px solid {p.border};
}}
QListWidget {{
    background-color: {p.surface};
    border: none;
    padding: 8px 0;
    outline: 0;
}}
QListWidget::item {{
    padding: 10px 16px;
    border-left: 3px solid transparent;
}}
QListWidget::item:hover {{ background-color: {p.surface_alt}; }}
QListWidget::item:selected {{
    background-color: {p.surface_alt};
    border-left: 3px solid {p.accent};
    color: {p.text};
}}
QFrame#card {{
    background-color: {p.surface};
    border: 1px solid {p.border};
    border-radius: 10px;
}}
QLabel#card-title {{ color: {p.text_muted}; font-size: {f.size_sm}px; }}
QLabel#card-value {{ color: {p.text}; font-size: {f.size_lg}px; font-weight: 600; }}
QLabel#card-subtitle {{ color: {p.text_muted}; font-size: {f.size_sm}px; }}
QPushButton {{
    background-color: {p.surface_alt};
    color: {p.text};
    border: 1px solid {p.border};
    border-radius: 6px;
    padding: 6px 14px;
}}
QPushButton:hover {{ background-color: {p.accent}; color: {p.background}; }}
QTableView {{
    background-color: {p.surface};
    alternate-background-color: {p.surface_alt};
    gridline-color: {p.border};
    selection-background-color: {p.accent};
    selection-color: {p.background};
}}
QHeaderView::section {{
    background-color: {p.surface_alt};
    color: {p.text_muted};
    border: none;
    padding: 6px 8px;
}}
QPlainTextEdit, QLineEdit, QComboBox {{
    background-color: {p.surface};
    border: 1px solid {p.border};
    border-radius: 6px;
    padding: 4px 8px;
    color: {p.text};
}}
QToolBar {{
    background-color: {p.surface};
    border: none;
    spacing: 8px;
}}
"""


def load_qss_from_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


__all__ = [
    "Palette",
    "LightPalette",
    "Spacing",
    "Radii",
    "FontTokens",
    "Theme",
    "load_qss",
    "load_qss_from_file",
]
