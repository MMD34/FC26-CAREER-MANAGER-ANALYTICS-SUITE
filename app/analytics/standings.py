"""Standings analytics (PT §9.1).

Pure functions over `StandingsRow` domain objects. No Qt / IO dependencies.
"""
from __future__ import annotations

from typing import Iterable

import pandas as pd

from app.domain.standings import StandingsRow


def points_progression(standings_history: Iterable[StandingsRow]) -> pd.Series:
    """Return a Series of points indexed by export_date, sorted chronologically.

    Requires multiple snapshots to be meaningful. Returns an empty Series if
    fewer than two snapshots are supplied.
    """
    rows = list(standings_history)
    if len(rows) < 2:
        return pd.Series(dtype="Int64", name="points")
    data = {row.export_date: row.points for row in rows}
    series = pd.Series(data, name="points", dtype="Int64")
    return series.sort_index()


def gf_ga_home_away_split(row: StandingsRow) -> dict[str, int]:
    """Return goals-for / goals-against split into home and away buckets."""
    return {
        "home_gf": int(row.homegf or 0),
        "home_ga": int(row.homega or 0),
        "away_gf": int(row.awaygf or 0),
        "away_ga": int(row.awayga or 0),
        "total_gf": int((row.homegf or 0) + (row.awaygf or 0)),
        "total_ga": int((row.homega or 0) + (row.awayga or 0)),
    }


def goal_difference(row: StandingsRow) -> int:
    """Return total goal difference (GF - GA across home + away)."""
    split = gf_ga_home_away_split(row)
    return split["total_gf"] - split["total_ga"]


__all__ = ["points_progression", "gf_ga_home_away_split", "goal_difference"]
