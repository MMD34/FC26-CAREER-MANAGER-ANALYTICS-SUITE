"""Transfer-planning analytics (PT §9.7).

Pure functions over a `players` DataFrame (PLAYERS_SNAPSHOT shape).
"""
from __future__ import annotations

from typing import NamedTuple

import pandas as pd


class AgingPoint(NamedTuple):
    age: int
    overallrating: int
    name: str
    teamid: int


def aging_quadrant(players: pd.DataFrame) -> list[AgingPoint]:
    """Return (age, overallrating, display_name, teamid) tuples for scatter plotting."""
    if players.empty:
        return []
    needed = {"age", "overallrating", "display_name", "teamid"}
    if not needed.issubset(players.columns):
        return []
    rows: list[AgingPoint] = []
    for r in players[list(needed)].itertuples(index=False):
        age, ovr, name, teamid = r.age, r.overallrating, r.display_name, r.teamid
        if pd.isna(age) or pd.isna(ovr) or pd.isna(teamid):
            continue
        rows.append(AgingPoint(int(age), int(ovr), str(name) if name is not None else "", int(teamid)))
    return rows


def expiring_contracts(players: pd.DataFrame, current_year: int) -> pd.DataFrame:
    """Players whose `contractvaliduntil <= current_year + 1`."""
    if players.empty or "contractvaliduntil" not in players.columns:
        return players.iloc[0:0]
    mask = players["contractvaliduntil"].fillna(9999) <= (current_year + 1)
    return players[mask].sort_values("contractvaliduntil", kind="mergesort")


def positional_depth(players: pd.DataFrame, teamid: int) -> pd.Series:
    """Count of players per `preferredposition1` for the given team."""
    if players.empty or not {"teamid", "preferredposition1"}.issubset(players.columns):
        return pd.Series(dtype="Int64", name="positional_depth")
    subset = players[players["teamid"] == teamid]
    counts = subset["preferredposition1"].value_counts(dropna=False).sort_index()
    counts.name = "positional_depth"
    return counts.astype("Int64")


def replacement_candidates(
    players: pd.DataFrame,
    target_player: pd.Series,
    top_n: int = 10,
) -> pd.DataFrame:
    """Rank candidates that can replace `target_player`.

    Criteria: same `preferredposition1`, younger than the target, AND
    (overallrating >= target.overallrating - 3 OR potential >= target.potential - 2).
    Result excludes the target itself, sorted by (potential desc, overallrating desc).
    """
    if players.empty:
        return players.iloc[0:0]
    needed = {"playerid", "preferredposition1", "age", "overallrating", "potential"}
    if not needed.issubset(players.columns):
        return players.iloc[0:0]

    target_pos = target_player.get("preferredposition1")
    target_age = target_player.get("age")
    target_ovr = target_player.get("overallrating")
    target_pot = target_player.get("potential")
    target_id = target_player.get("playerid")
    if pd.isna(target_pos) or pd.isna(target_age):
        return players.iloc[0:0]

    df = players
    mask = (
        (df["preferredposition1"] == target_pos)
        & (df["age"].fillna(999) < target_age)
        & (df["playerid"] != target_id)
    )
    if not pd.isna(target_ovr) and not pd.isna(target_pot):
        mask &= (
            (df["overallrating"].fillna(0) >= int(target_ovr) - 3)
            | (df["potential"].fillna(0) >= int(target_pot) - 2)
        )
    elif not pd.isna(target_ovr):
        mask &= df["overallrating"].fillna(0) >= int(target_ovr) - 3
    elif not pd.isna(target_pot):
        mask &= df["potential"].fillna(0) >= int(target_pot) - 2

    return df[mask].sort_values(
        ["potential", "overallrating"], ascending=False, kind="mergesort"
    ).head(top_n)


__all__ = [
    "AgingPoint",
    "aging_quadrant",
    "expiring_contracts",
    "positional_depth",
    "replacement_candidates",
]
