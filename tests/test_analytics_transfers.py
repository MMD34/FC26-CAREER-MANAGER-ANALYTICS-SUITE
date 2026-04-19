"""Tests for app.analytics.transfers (Sprint 7, PT §9.7)."""
from __future__ import annotations

import pandas as pd

from app.analytics.transfers import (
    aging_quadrant,
    expiring_contracts,
    positional_depth,
    replacement_candidates,
)


def _df() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "playerid": [1, 2, 3, 4, 5],
            "display_name": ["A", "B", "C", "D", "E"],
            "age": [30, 22, 19, 28, 24],
            "overallrating": [85, 78, 75, 84, 80],
            "potential": [85, 88, 90, 84, 86],
            "preferredposition1": [14, 14, 14, 5, 14],
            "teamid": [10, 10, 11, 10, 10],
            "contractvaliduntil": [2026, 2028, 2027, 2025, 2030],
        }
    )


def test_aging_quadrant() -> None:
    pts = aging_quadrant(_df())
    assert len(pts) == 5
    assert pts[0].age == 30 and pts[0].overallrating == 85 and pts[0].name == "A"


def test_expiring_contracts() -> None:
    res = expiring_contracts(_df(), current_year=2026)
    # threshold = 2027 → pid 1 (2026), 4 (2025), 3 (2027)
    assert set(res["playerid"]) == {1, 3, 4}


def test_positional_depth() -> None:
    s = positional_depth(_df(), teamid=10)
    # team 10: positions [14,14,5,14] → 5:1, 14:3
    assert int(s.loc[5]) == 1
    assert int(s.loc[14]) == 3


def test_replacement_candidates() -> None:
    df = _df()
    target = df[df["playerid"] == 1].iloc[0]  # MID, 30yo, OVR 85, POT 85
    res = replacement_candidates(df, target, top_n=10)
    # Eligible MIDs younger than 30: 2 (OVR 78, POT 88) -> POT≥83 ✓
    #                                3 (OVR 75, POT 90) -> POT≥83 ✓
    #                                5 (OVR 80, POT 86) -> POT≥83 ✓
    # All three pass; sorted by potential desc.
    assert list(res["playerid"]) == [3, 2, 5]


def test_replacement_candidates_missing_target_pos() -> None:
    df = _df()
    target = pd.Series({"playerid": 999, "preferredposition1": pd.NA, "age": 25})
    assert replacement_candidates(df, target).empty
