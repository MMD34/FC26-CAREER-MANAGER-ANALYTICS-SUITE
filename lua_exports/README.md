# Lua Exports

Production export scripts executed inside Live Editor while Career Mode is active. Each script writes a CSV to the user's Desktop using the filename convention described in `PLAN_TECHNIQUE.md` §13.3:

```
<KIND>_DD_MM_YYYY.csv
```

Outputs land in `%USERPROFILE%\Desktop`. The Python app imports them from there.

## Scripts

| Script | Output file | Purpose | Contract |
|---|---|---|---|
| `export_season_overview.lua` | `SEASON_OVERVIEW_DD_MM_YYYY.csv` | One row describing the user's team × current league (standings row + team ratings + objective fields). | PT §7.1 |
| `export_standings.lua` | `STANDINGS_<leaguename>_DD_MM_YYYY.csv` | Full league table for the user's current league (override `LEAGUE_ID` at top of the file to target another league). | PT §7.2 |
| `export_players_snapshot.lua` | `PLAYERS_SNAPSHOT_DD_MM_YYYY.csv` | One row per player in the `players` table joined with `teamplayerlinks` / `teams` / `leagueteamlinks` / `leagues`. Display name via `GetPlayerName` (per SCHEMA_NOTES §15.1). | PT §7.3 |
| `export_wonderkids.lua` | `WONDERKIDS_DD_MM_YYYY.csv` | `PLAYERS_SNAPSHOT` columns filtered by `age <= MAX_AGE` and `potential >= POTENTIAL_MIN` (defaults 21 / 85; change at top of the file). | PT §7.4 |
| `export_season_stats.lua` | `SEASON_STATS_DD_MM_YYYY.csv` | Per-player season statistics from `GetPlayersStats()`. Legacy script, contract §7.5. | PT §7.5 |
| `export_fixtures.lua` | `FIXTURES_<competition>_DD_MM_YYYY.csv` | Memory-sourced fixture list (legacy). | PT §7.6 |
| `export_transfer_history.lua` | `TRANSFER_HISTORY_DD_MM_YYYY.csv` | Memory-sourced transfer history (legacy). | PT §7.7 |

## Conventions

All production scripts:
- Start with `assert(IsInCM(), ...)`.
- Read tables via `LE.db:GetTable(...)` and iterate with `GetFirstRecord()` / `GetNextValidRecord()`.
- Wrap any PT §15-flagged field read in `pcall` (helper `safe_read`).
- Escape CSV values: if a string contains `,`, `"`, or newline, wrap in `"` and double internal `"`.
- Emit booleans as `0` / `1`; missing values as empty strings (never the literal `nil`).
