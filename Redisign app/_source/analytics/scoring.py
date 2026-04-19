"""Scoring-trend analytics (PT §9.1 monthly slice).

Monthly GF / GA aggregation from FIXTURES. Gated on FIXTURES presence.
"""
from __future__ import annotations

import pandas as pd

_FIXTURES_REQUIRED = {"hometeamid", "awayteamid", "homescore", "awayscore", "date"}


def monthly_gf_ga(fixtures: pd.DataFrame, teamid: int) -> pd.DataFrame:
    """Monthly goals-for / goals-against for the given team.

    Returns an empty DataFrame if FIXTURES is missing required columns or
    if no parseable dates are present.

    Output columns: `month` (period[M]), `gf`, `ga`, `matches`.
    """
    empty = pd.DataFrame(columns=["month", "gf", "ga", "matches"])
    if fixtures.empty or not _FIXTURES_REQUIRED.issubset(fixtures.columns):
        return empty

    parsed_dates = pd.to_datetime(fixtures["date"], errors="coerce")
    if parsed_dates.isna().all():
        return empty

    df = fixtures.assign(_dt=parsed_dates).dropna(subset=["_dt"])
    home_mask = df["hometeamid"] == teamid
    away_mask = df["awayteamid"] == teamid
    df = df[home_mask | away_mask].copy()
    if df.empty:
        return empty

    df["gf"] = df["homescore"].where(home_mask.loc[df.index], df["awayscore"]).astype("Int64")
    df["ga"] = df["awayscore"].where(home_mask.loc[df.index], df["homescore"]).astype("Int64")
    df["month"] = df["_dt"].dt.to_period("M")

    grouped = df.groupby("month", as_index=False).agg(
        gf=("gf", "sum"),
        ga=("ga", "sum"),
        matches=("gf", "count"),
    )
    return grouped.sort_values("month").reset_index(drop=True)


__all__ = ["monthly_gf_ga"]
