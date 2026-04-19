"""Wonderkid-scouting analytics (PT §9.5).

Pure functions over a `players` DataFrame.
"""
from __future__ import annotations

from typing import Literal

import pandas as pd

from app.core.constants import (
    DEFAULT_WONDERKID_MAX_AGE,
    DEFAULT_WONDERKID_POTENTIAL,
    GENERATED_PLAYER_THRESHOLD,
)

PositionGroup = Literal["GK", "DEF", "MID", "ATT"]
Origin = Literal["real", "generated"]

# FIFA / FC integer position codes (preferredposition1):
#   0       -> GK
#   1..8    -> defenders (SW/RB/RCB/CB/LCB/LB/RWB/LWB variants)
#   9..19   -> midfielders (DM/CM/AM lines, incl. wide mids)
#   20..27  -> forwards (RF/CF/LF/RW/ST/LW; 26/27 are bench/reserve markers
#               but still in the attacking band when used as a primary pos)
_GK = {0}
_DEF_RANGE = range(1, 9)
_MID_RANGE = range(9, 20)
_ATT_RANGE = range(20, 28)


def origin_label(playerid: int) -> Origin:
    """Return 'generated' if `playerid >= GENERATED_PLAYER_THRESHOLD`, else 'real'."""
    return "generated" if int(playerid) >= GENERATED_PLAYER_THRESHOLD else "real"


def position_group(pos: int | str | None) -> PositionGroup | None:
    """Map a `preferredposition1` value to its high-level group.

    Accepts the integer code (PLAYERS_SNAPSHOT dtype) or a pre-decoded string
    label (`"GK"`, `"DEF"`, `"MID"`, `"ATT"`). Returns None if unknown / null.
    """
    if pos is None:
        return None
    if isinstance(pos, str):
        s = pos.strip().upper()
        if s in {"GK", "DEF", "MID", "ATT"}:
            return s  # type: ignore[return-value]
        return None
    try:
        code = int(pos)
    except (TypeError, ValueError):
        return None
    if code in _GK:
        return "GK"
    if code in _DEF_RANGE:
        return "DEF"
    if code in _MID_RANGE:
        return "MID"
    if code in _ATT_RANGE:
        return "ATT"
    return None


def filter_wonderkids(
    players: pd.DataFrame,
    max_age: int = DEFAULT_WONDERKID_MAX_AGE,
    min_potential: int = DEFAULT_WONDERKID_POTENTIAL,
) -> pd.DataFrame:
    """Subset of `players` meeting wonderkid criteria, sorted by potential desc."""
    if players.empty:
        return players
    required = {"age", "potential"}
    if not required.issubset(players.columns):
        return players.iloc[0:0]
    mask = (players["age"].fillna(999) <= max_age) & (
        players["potential"].fillna(0) >= min_potential
    )
    out = players[mask]
    return out.sort_values("potential", ascending=False, kind="mergesort")


__all__ = [
    "PositionGroup",
    "Origin",
    "origin_label",
    "position_group",
    "filter_wonderkids",
]
