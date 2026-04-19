"""Tests for app.analytics.standings (Sprint 6, PT §9.1)."""
from __future__ import annotations

import pandas as pd

from app.analytics.standings import (
    gf_ga_home_away_split,
    goal_difference,
    points_progression,
)
from app.domain.standings import StandingsRow


def _row(export_date: str = "01_01_2026", points: int = 10, **overrides) -> StandingsRow:
    base = dict(
        export_date=export_date,
        leagueid=53,
        leaguename="Spain Primera División (1)",
        teamid=243,
        teamname="Real Madrid",
        currenttableposition=1,
        previousyeartableposition=2,
        points=points,
        nummatchesplayed=5,
        homewins=2, homedraws=0, homelosses=0,
        awaywins=1, awaydraws=1, awaylosses=1,
        homegf=6, homega=1,
        awaygf=3, awayga=4,
        teamform="WWDLW",
        teamlongform="WWDLWWWLDW",
        lastgameresult=1,
        unbeatenleague=1,
        champion=False,
        team_overallrating=85,
    )
    base.update(overrides)
    return StandingsRow(**base)


def test_points_progression_requires_two_snapshots() -> None:
    series = points_progression([_row("01_01_2026", points=10)])
    assert series.empty


def test_points_progression_sorted() -> None:
    rows = [
        _row("03_01_2026", points=15),
        _row("01_01_2026", points=10),
        _row("02_01_2026", points=12),
    ]
    series = points_progression(rows)
    assert list(series.index) == ["01_01_2026", "02_01_2026", "03_01_2026"]
    assert list(series.astype(int)) == [10, 12, 15]


def test_gf_ga_split() -> None:
    split = gf_ga_home_away_split(_row())
    assert split == {
        "home_gf": 6, "home_ga": 1,
        "away_gf": 3, "away_ga": 4,
        "total_gf": 9, "total_ga": 5,
    }


def test_goal_difference() -> None:
    assert goal_difference(_row()) == 4


def test_split_handles_none() -> None:
    row = _row(homegf=None, homega=None, awaygf=None, awayga=None)
    assert gf_ga_home_away_split(row) == {
        "home_gf": 0, "home_ga": 0,
        "away_gf": 0, "away_ga": 0,
        "total_gf": 0, "total_ga": 0,
    }
    assert goal_difference(row) == 0
