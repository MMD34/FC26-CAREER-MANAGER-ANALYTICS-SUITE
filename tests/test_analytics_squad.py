"""Tests for app.analytics.squad (Sprint 7, PT §9.3)."""
from __future__ import annotations

import pandas as pd

from app.analytics.squad import form_leaders, injury_list, top_by_rating, top_scorers


def _df() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "playerid": [1, 2, 3, 4, 5],
            "display_name": ["A", "B", "C", "D", "E"],
            "leaguegoals": [12, 12, 5, 0, 8],
            "overallrating": [80, 88, 70, 75, 90],
            "form": [7, 5, 8, 1, 6],
            "injury": [0, 0, 5, 0, 12],
            "preferredposition1": [0, 5, 14, 24, 25],
        }
    )


def test_top_scorers_tiebreak_by_rating() -> None:
    res = top_scorers(_df(), n=3)
    assert list(res["playerid"]) == [2, 1, 5]


def test_top_by_rating_no_filter() -> None:
    res = top_by_rating(_df(), n=2)
    assert list(res["playerid"]) == [5, 2]


def test_top_by_rating_position_group() -> None:
    res = top_by_rating(_df(), n=10, position_group="ATT")
    assert list(res["playerid"]) == [5, 4]


def test_injury_list() -> None:
    res = injury_list(_df())
    assert set(res["playerid"]) == {3, 5}


def test_form_leaders() -> None:
    res = form_leaders(_df(), n=2)
    assert list(res["playerid"]) == [3, 1]


def test_empty_df_returns_empty() -> None:
    empty = pd.DataFrame()
    assert top_scorers(empty).empty
    assert injury_list(empty).empty
    assert form_leaders(empty).empty
    assert top_by_rating(empty).empty
