"""Tests for app.analytics.form (Sprint 6, PT §9.2)."""
from __future__ import annotations

from app.analytics.form import (
    Streak,
    current_streak,
    decode_team_form,
    longest_unbeaten,
)


def test_decode_basic() -> None:
    assert decode_team_form("WWDLW") == ["W", "W", "D", "L", "W"]


def test_decode_case_and_unknown_chars() -> None:
    assert decode_team_form("w-w?d.l/w") == ["W", "W", "D", "L", "W"]


def test_decode_empty_and_none() -> None:
    assert decode_team_form("") == []
    assert decode_team_form(None) == []
    assert decode_team_form(42) == []


def test_current_streak_win_run() -> None:
    assert current_streak(["L", "W", "W", "W"]) == Streak("W", 3)


def test_current_streak_single() -> None:
    assert current_streak(["D"]) == Streak("D", 1)


def test_current_streak_empty() -> None:
    assert current_streak([]) == Streak(None, 0)


def test_longest_unbeaten() -> None:
    # W W D L W W W D L W W -> longest run without L is 4 (WWWD)
    assert longest_unbeaten(["W", "W", "D", "L", "W", "W", "W", "D", "L", "W", "W"]) == 4


def test_longest_unbeaten_all_losses() -> None:
    assert longest_unbeaten(["L", "L", "L"]) == 0


def test_longest_unbeaten_empty() -> None:
    assert longest_unbeaten([]) == 0
