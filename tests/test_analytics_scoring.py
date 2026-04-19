"""Tests for app.analytics.scoring (Sprint 7)."""
from __future__ import annotations

import pandas as pd

from app.analytics.scoring import monthly_gf_ga


def test_monthly_gf_ga_basic() -> None:
    df = pd.DataFrame(
        {
            "competition": ["L"] * 4,
            "compobjid": [1] * 4,
            "hometeamid": [10, 20, 10, 30],
            "awayteamid": [20, 10, 30, 10],
            "hometeam": ["A", "B", "A", "C"],
            "awayteam": ["B", "A", "C", "A"],
            "homescore": [2, 1, 3, 0],
            "awayscore": [1, 2, 0, 4],
            "date": ["2026-01-05", "2026-01-20", "2026-02-10", "2026-02-25"],
            "time": ["20:00"] * 4,
        }
    )
    res = monthly_gf_ga(df, teamid=10)
    # team 10: J H 2-1 (gf2 ga1), J A 1-2 (gf2 ga1), F H 3-0 (gf3 ga0), F A 0-4 (gf4 ga0)
    assert len(res) == 2
    jan = res.iloc[0]
    feb = res.iloc[1]
    assert int(jan["gf"]) == 4 and int(jan["ga"]) == 2 and int(jan["matches"]) == 2
    assert int(feb["gf"]) == 7 and int(feb["ga"]) == 0 and int(feb["matches"]) == 2


def test_monthly_gf_ga_missing_columns_returns_empty() -> None:
    df = pd.DataFrame({"competition": ["L"]})
    assert monthly_gf_ga(df, teamid=10).empty


def test_monthly_gf_ga_unparseable_dates() -> None:
    df = pd.DataFrame(
        {
            "hometeamid": [10],
            "awayteamid": [20],
            "homescore": [1],
            "awayscore": [0],
            "date": ["not-a-date"],
        }
    )
    assert monthly_gf_ga(df, teamid=10).empty
