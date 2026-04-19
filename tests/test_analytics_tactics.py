"""Tests for app.analytics.tactics (Sprint 7, PT §9.6)."""
from __future__ import annotations

from app.analytics.tactics import home_away_efficiency, team_ratings_profile
from app.domain.season import SeasonOverview
from app.domain.standings import StandingsRow


def _overview() -> SeasonOverview:
    return SeasonOverview(
        export_date="01_01_2026", season_year=2026,
        user_teamid=243, user_teamname="Real Madrid",
        leagueid=53, leaguename="Spain Primera División (1)",
        league_level=1, leaguetype=0,
        currenttableposition=1, previousyeartableposition=2,
        points=20, nummatchesplayed=8,
        homewins=3, homedraws=1, homelosses=0,
        awaywins=2, awaydraws=1, awaylosses=1,
        homegf=10, homega=2, awaygf=6, awayga=4,
        teamform="WWDLW", teamshortform="WWDLW", teamlongform="WWDLWWWLDW",
        lastgameresult=1,
        unbeatenhome=4, unbeatenaway=0, unbeatenleague=1, unbeatenallcomps=1,
        objective=0, hasachievedobjective=False,
        highestpossible=1, highestprobable=1,
        yettowin=0, actualvsexpectations=0, champion=False,
        team_overallrating=85, team_attackrating=88,
        team_midfieldrating=84, team_defenserating=82,
        buildupplay=70, defensivedepth=55,
    )


def _standings_row() -> StandingsRow:
    return StandingsRow(
        export_date="01_01_2026",
        leagueid=53, leaguename="L",
        teamid=243, teamname="T",
        currenttableposition=1, previousyeartableposition=2,
        points=20, nummatchesplayed=8,
        homewins=3, homedraws=1, homelosses=0,
        awaywins=2, awaydraws=1, awaylosses=1,
        homegf=10, homega=2, awaygf=6, awayga=4,
        teamform="W", teamlongform="WWDL",
        lastgameresult=1, unbeatenleague=1,
        champion=False, team_overallrating=85,
    )


def test_team_ratings_profile() -> None:
    p = team_ratings_profile(_overview())
    assert p["overall"] == 85
    assert p["attack"] == 88
    assert p["midfield"] == 84
    assert p["defense"] == 82
    assert p["buildupplay"] == 70
    assert p["defensivedepth"] == 55
    assert p["matchday_overall"] is None


def test_home_away_efficiency() -> None:
    eff = home_away_efficiency(_standings_row())
    assert eff["home_matches"] == 4.0
    assert eff["away_matches"] == 4.0
    assert eff["home_gf_per_match"] == 2.5
    assert eff["home_ga_per_match"] == 0.5
    assert eff["away_gf_per_match"] == 1.5
    assert eff["away_ga_per_match"] == 1.0


def test_home_away_efficiency_zero_matches() -> None:
    row = StandingsRow(
        export_date="x", leagueid=1, leaguename=None,
        teamid=1, teamname=None,
        currenttableposition=None, previousyeartableposition=None,
        points=0, nummatchesplayed=0,
        homewins=0, homedraws=0, homelosses=0,
        awaywins=0, awaydraws=0, awaylosses=0,
        homegf=0, homega=0, awaygf=0, awayga=0,
        teamform=None, teamlongform=None,
        lastgameresult=None, unbeatenleague=None,
        champion=None, team_overallrating=None,
    )
    eff = home_away_efficiency(row)
    assert eff["home_gf_per_match"] == 0.0
    assert eff["away_gf_per_match"] == 0.0
