# FC 26 Manager Career Analytics Suite — User Guide

A two-step workflow: **(1)** export CSVs from FC 26 via Live Editor Lua scripts,
**(2)** import the folder into the desktop app to drive the analytics views.

---

## 1. Run the Lua exports

Open **FC 26 Career Mode → Live Editor → Scripts**, then run the production
exports from `lua_exports/`:

| Script | Output (Desktop) | Purpose |
|---|---|---|
| `export_season_overview.lua` | `SEASON_OVERVIEW_DD_MM_YYYY.csv` | one row for the user's team / league |
| `export_standings.lua` | `STANDINGS_<league>_DD_MM_YYYY.csv` | full league table |
| `export_players_snapshot.lua` | `PLAYERS_SNAPSHOT_DD_MM_YYYY.csv` | every player + attributes |
| `export_wonderkids.lua` | `WONDERKIDS_DD_MM_YYYY.csv` | filtered to age ≤ 21, potential ≥ 85 |
| `export_season_stats.lua` | `SEASON_STATS_<comp>_DD_MM_YYYY.csv` | competition leaderboards |
| `export_fixtures.lua` | `FIXTURES_<comp>_DD_MM_YYYY.csv` | match list |
| `export_transfer_history.lua` | `TRANSFER_HISTORY_DD_MM_YYYY.csv` | transfers & contracts |

CSVs always land on the user's **Desktop**. Run multiple snapshots over the
season — the app keeps them and uses them for trend / progression charts.

> The scripts only call confirmed Live Editor APIs. Anything ambiguous is
> wrapped in `pcall` and surfaced as an empty cell rather than crashing.

## 2. Import into the app

1. Launch `FC26Analytics.exe` (or `python -m app.main` from a checkout).
2. Click **Import** in the sidebar.
3. Either **drop** the Desktop folder onto the drop zone, or click **Pick
   folder…** (defaults to `%USERPROFILE%\Desktop`).
4. Each detected file is parsed in a worker thread; rows are stored in the
   per-career SQLite session cache under `%LOCALAPPDATA%\FC26Analytics\cache`.
5. The pages refresh automatically.

Use **Clear cache** to start over (a confirmation dialog protects against
mis-clicks).

## 3. Page walkthrough

`TODO_SCREENSHOT` — capture each page once a real career is loaded.

- **Overview** — hero header + KPI grid (Points / W / D / L / GF / GA / GD /
  Recent Form / Objective). Sparklines per KPI appear once you have ≥2
  SEASON_OVERVIEW snapshots.
- **Analytics** — points progression, ranking evolution (inverted Y), home vs
  away GF/GA, form curve, current streak + unbeaten run.
- **Squad** — leaderboards (top scorers, top rated, form leaders), filter bar
  (search / position / team), per-player drawer with face aggregates and
  attribute list.
- **Wonderkids** — quadrant scatter (age × potential, colored by position
  group), table sorted by potential desc, real/generated origin badge,
  shared player drawer.
- **Tactics** — team ratings tiles, buildup / defensive depth dials, home vs
  away efficiency. Formation pitch is a placeholder until §15.4 is resolved.
- **Transfers** — incoming-transfers KPI (from TRANSFER_HISTORY), aging
  quadrant, expiring contracts table (click a row to see replacement
  candidates), positional depth bar chart.
- **Import** — drag/drop, file picker, parse log, cache management.

## 4. Files & locations

- App data root: `%LOCALAPPDATA%\FC26Analytics\`
  - `cache\<career>.sqlite` — session cache (one per career slug)
  - `logs\app.log` — rotating logs (5 MB × 3)
  - `config\` — reserved for user overrides
- Default scan dir: `%USERPROFILE%\Desktop`

## 5. Troubleshooting

- **No data shown** — verify the CSVs match the filename patterns above. The
  parser logs each rejected file in `app.log`.
- **Duplicate snapshots** — two imports of the same kind on the same date are
  kept as separate rows; the latest one wins on each page.
- **Theme** — toggle dark/light via the top toolbar.
