"""Tactical analytics (PT §9.6).

Pure functions over `SeasonOverview` / `StandingsRow` domain objects.
"""
from __future__ import annotations

from app.domain.season import SeasonOverview
from app.domain.standings import StandingsRow


def team_ratings_profile(overview: SeasonOverview) -> dict[str, int | None]:
    """Team ratings + matchday counterparts.

    Note: PT §9.6 mentions "matchday counterparts" but SEASON_OVERVIEW does
    not currently expose distinct matchday-rating columns (see
    docs/CSV_CONTRACTS.md and PT §7.1). We report the four base ratings
    plus `buildupplay` / `defensivedepth` as the tactical readout, and
    leave matchday-specific keys reserved (None) for forward compatibility
    when / if those fields are added.
    """
    return {
        "overall": overview.team_overallrating,
        "attack": overview.team_attackrating,
        "midfield": overview.team_midfieldrating,
        "defense": overview.team_defenserating,
        "buildupplay": overview.buildupplay,
        "defensivedepth": overview.defensivedepth,
        "matchday_overall": None,
        "matchday_attack": None,
        "matchday_midfield": None,
        "matchday_defense": None,
    }


def home_away_efficiency(row: StandingsRow) -> dict[str, float]:
    """GF/match, GA/match split into home and away.

    Clean-sheet ratio is left to the SEASON_STATS path (per PT §9.6); not
    derivable from STANDINGS columns alone.
    """
    home_matches = (row.homewins or 0) + (row.homedraws or 0) + (row.homelosses or 0)
    away_matches = (row.awaywins or 0) + (row.awaydraws or 0) + (row.awaylosses or 0)

    def _per(value: int | None, matches: int) -> float:
        if not matches:
            return 0.0
        return float(value or 0) / matches

    return {
        "home_gf_per_match": _per(row.homegf, home_matches),
        "home_ga_per_match": _per(row.homega, home_matches),
        "away_gf_per_match": _per(row.awaygf, away_matches),
        "away_ga_per_match": _per(row.awayga, away_matches),
        "home_matches": float(home_matches),
        "away_matches": float(away_matches),
    }


__all__ = ["team_ratings_profile", "home_away_efficiency"]
