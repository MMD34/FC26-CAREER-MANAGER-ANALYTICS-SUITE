"""Tests for app.analytics.wonderkids (Sprint 7, PT §9.5)."""
from __future__ import annotations

import pandas as pd

from app.analytics.wonderkids import filter_wonderkids, origin_label, position_group
from app.core.constants import GENERATED_PLAYER_THRESHOLD


def test_origin_label_real() -> None:
    assert origin_label(GENERATED_PLAYER_THRESHOLD - 1) == "real"


def test_origin_label_generated() -> None:
    assert origin_label(GENERATED_PLAYER_THRESHOLD) == "generated"
    assert origin_label(GENERATED_PLAYER_THRESHOLD + 1234) == "generated"


def test_position_group_int_codes() -> None:
    assert position_group(0) == "GK"
    assert position_group(5) == "DEF"
    assert position_group(14) == "MID"
    assert position_group(24) == "ATT"


def test_position_group_string_passthrough() -> None:
    assert position_group("GK") == "GK"
    assert position_group("att") == "ATT"
    assert position_group("UNKNOWN") is None


def test_position_group_none() -> None:
    assert position_group(None) is None
    assert position_group(99) is None


def test_filter_wonderkids() -> None:
    df = pd.DataFrame(
        {
            "playerid": [1, 2, 3, 4],
            "age": [20, 22, 19, 21],
            "potential": [88, 90, 84, 87],
        }
    )
    res = filter_wonderkids(df, max_age=21, min_potential=85)
    # Excluded: pid 2 (age>21), pid 3 (pot<85). Remaining sorted by potential desc.
    assert list(res["playerid"]) == [1, 4]


def test_filter_wonderkids_missing_columns() -> None:
    df = pd.DataFrame({"playerid": [1]})
    assert filter_wonderkids(df).empty
