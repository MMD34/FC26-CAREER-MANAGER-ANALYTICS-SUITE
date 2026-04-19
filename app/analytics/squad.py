"""Squad-performance analytics (PT §9.3).

Pure functions over a `players` DataFrame (PLAYERS_SNAPSHOT shape; see
`app/import_/schema.py::PLAYERS_SNAPSHOT_COLUMNS`).
"""
from __future__ import annotations

import pandas as pd


def top_scorers(players: pd.DataFrame, n: int = 10) -> pd.DataFrame:
    """Top `n` scorers by `leaguegoals`, tiebreak by `overallrating` desc."""
    if players.empty or "leaguegoals" not in players.columns:
        return players.iloc[0:0]
    sort_cols = ["leaguegoals"]
    if "overallrating" in players.columns:
        sort_cols.append("overallrating")
    return players.sort_values(sort_cols, ascending=False, kind="mergesort").head(n)


def top_by_rating(
    players: pd.DataFrame,
    n: int = 10,
    position_group: str | None = None,
) -> pd.DataFrame:
    """Top `n` players by `overallrating`, optionally restricted to a position group."""
    if players.empty or "overallrating" not in players.columns:
        return players.iloc[0:0]
    df = players
    if position_group is not None and "preferredposition1" in df.columns:
        from app.analytics.wonderkids import position_group as group_of
        mask = df["preferredposition1"].map(lambda v: group_of(v) == position_group)
        df = df[mask.fillna(False)]
    return df.sort_values("overallrating", ascending=False, kind="mergesort").head(n)


def injury_list(players: pd.DataFrame) -> pd.DataFrame:
    """Players currently flagged as injured (`injury` > 0).

    The `injury` field's exact scale is partially probed (see
    docs/SCHEMA_NOTES.md §15.3); any non-zero value is treated as injured
    until the histogram lands.
    """
    if players.empty or "injury" not in players.columns:
        return players.iloc[0:0]
    return players[players["injury"].fillna(0) > 0]


def form_leaders(players: pd.DataFrame, n: int = 10) -> pd.DataFrame:
    """Top `n` players by `form` (descending)."""
    if players.empty or "form" not in players.columns:
        return players.iloc[0:0]
    return players.sort_values("form", ascending=False, kind="mergesort").head(n)


__all__ = ["top_scorers", "top_by_rating", "injury_list", "form_leaders"]
