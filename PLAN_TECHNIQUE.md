# Technical Plan — FC 26 Manager Career Analytics Suite

> Master technical document for the new project direction.
> Supersedes `PLAN_TECHNIQUE_REGEN_DETECTOR.md` (the clone-detection project is retired — retiring players are removed from the DB before comparisons are possible, which makes the approach unreliable for end users).
> Last updated: 2026-04-16
> Status: **Planning only — no implementation yet.**

---

## 1. Project Vision

Build a **Python desktop analytics and scouting utility for EA Sports FC 26 Manager Career Mode**, delivering a polished seasonal intelligence dashboard to the user.

### Core principles

- **Offline-first**: the desktop app never touches the game. It reads only CSV files exported by a dedicated Lua script.
- **Ergonomic UI/UX**: modern, polished, readable, intuitive. UI quality is a first-class requirement, not a finishing touch.
- **Visual analytics**: prioritize charts, trends, and at-a-glance summaries over raw tables.
- **Deterministic**: same CSV input → same dashboards. No hidden state, no network calls.
- **Seasonal focus**: the app understands the structure of a career-mode season (league position, form, transfers, youth intake) and organizes data around it.

### Non-goals

- Real-time integration with the live game.
- Direct Live Editor execution from Python.
- Any form of retired-player / regen clone detection (abandoned direction).
- Cloud sync, multi-user features, or online services.

---

## 2. End-to-End Workflow

```
[1] User launches FC 26
[2] User opens Live Editor
[3] User runs our dedicated Lua export script(s)
[4] Script writes CSV file(s) to the Desktop
[5] User launches the Python desktop app (PySide)
[6] User imports the CSV(s) via the UI
[7] App parses, indexes, and builds dashboards
[8] User explores Overview / Analytics / Squad / Wonderkids / Tactics / Transfers
```

The Python app is a **pure CSV consumer**. It never executes Lua, never reads game memory, never modifies the save.

---

## 3. Software Architecture

### 3.1 High-level layering

```
┌──────────────────────────────────────────────────────┐
│  UI Layer (PySide6)                                  │
│  - Pages, widgets, charts, theming                   │
├──────────────────────────────────────────────────────┤
│  Presentation / ViewModel Layer                      │
│  - Page controllers, signals, formatting helpers     │
├──────────────────────────────────────────────────────┤
│  Analytics Engine                                    │
│  - Aggregations, trends, rankings, scouting logic    │
├──────────────────────────────────────────────────────┤
│  Domain Model                                        │
│  - Player, Team, League, Season, Fixture, Transfer   │
├──────────────────────────────────────────────────────┤
│  Import / Parsing Pipeline                           │
│  - CSV discovery, schema detection, type coercion    │
├──────────────────────────────────────────────────────┤
│  Persistence / Cache                                 │
│  - Per-session parquet or sqlite cache of parsed CSVs│
└──────────────────────────────────────────────────────┘
          ▲                                    ▲
          │                                    │
    CSVs on disk                       Lua export scripts
                                        (separate layer)
```

### 3.2 Technology stack

| Layer | Choice |
|-------|--------|
| UI framework | **PySide6** (Qt 6) |
| Charts | **PyQtGraph** primary, **QtCharts** fallback (no Matplotlib in the event loop) |
| Data handling | **pandas** for tabular ops, **polars** optional later if data grows |
| CSV parsing | `pandas.read_csv` with explicit dtypes |
| Persistence / cache | **SQLite** (via `sqlite3` or `SQLModel`) for session cache |
| Packaging | **PyInstaller** or **Briefcase** (decided before Sprint 1) |
| Config | TOML via `tomllib` (stdlib, Python 3.11+) |
| Logging | `logging` stdlib, rotating file handler |
| Testing | `pytest`, `pytest-qt` for UI smoke tests |

### 3.3 Threading model

- UI on the main thread only.
- CSV import, parsing, and heavy aggregations run on a `QThreadPool` worker.
- Use Qt signals to publish progress and results back to the UI.
- Never block the event loop — all long ops must show a progress indicator.

---

## 4. Folder / Module Structure

```
FC26-OTHER-SCRIPTS/
├── app/                              # Python desktop application
│   ├── __init__.py
│   ├── main.py                       # Entry point
│   ├── config/
│   │   ├── settings.toml             # User settings
│   │   └── theme.qss                 # Qt stylesheet
│   ├── core/
│   │   ├── logging_setup.py
│   │   ├── paths.py                  # Desktop, cache, config paths
│   │   └── constants.py              # Column names, enums
│   ├── import_/
│   │   ├── discovery.py              # Find CSVs on Desktop
│   │   ├── schema.py                 # Expected columns per CSV type
│   │   ├── parsers.py                # One parser per CSV kind
│   │   └── pipeline.py               # Orchestrates the import
│   ├── domain/
│   │   ├── player.py
│   │   ├── team.py
│   │   ├── league.py
│   │   ├── season.py
│   │   ├── fixture.py
│   │   └── transfer.py
│   ├── analytics/
│   │   ├── standings.py              # Points progression, ranking
│   │   ├── form.py                   # Streaks, form curve
│   │   ├── scoring.py                # Scoring / defensive trends
│   │   ├── squad.py                  # Top scorers, ratings, minutes
│   │   ├── wonderkids.py             # Young high-potential scouting
│   │   ├── tactics.py                # Formation / efficiency stats
│   │   └── transfers.py              # Aging, expiring, depth
│   ├── ui/
│   │   ├── app_window.py             # QMainWindow, sidebar nav
│   │   ├── theme.py                  # Palette, fonts, spacing tokens
│   │   ├── widgets/
│   │   │   ├── stat_card.py
│   │   │   ├── kpi_tile.py
│   │   │   ├── sparkline.py
│   │   │   ├── data_table.py
│   │   │   ├── filter_bar.py
│   │   │   └── chart_panel.py
│   │   └── pages/
│   │       ├── overview_page.py
│   │       ├── analytics_page.py
│   │       ├── squad_page.py
│   │       ├── wonderkids_page.py
│   │       ├── tactics_page.py
│   │       └── transfers_page.py
│   └── services/
│       ├── cache.py                  # SQLite session cache
│       └── export.py                 # Re-export curated views
│
├── lua_exports/                      # Lua scripts run inside Live Editor
│   ├── README.md
│   ├── export_season_overview.lua    # Club, league, standings
│   ├── export_players_snapshot.lua   # Full player attributes
│   ├── export_season_stats.lua       # (existing — kept as reference)
│   ├── export_fixtures.lua           # (existing)
│   ├── export_transfer_history.lua   # (existing)
│   └── export_wonderkids.lua         # Young high-potential list
│
├── SCRIPTS/                          # Existing Lua helpers (reference)
├── docs/
│   ├── CSV_CONTRACTS.md              # Column specs for every CSV
│   └── USER_GUIDE.md
├── tests/
│   ├── test_parsers.py
│   ├── test_analytics_*.py
│   └── test_pages_smoke.py
├── PLAN_TECHNIQUE.md                 # (this file)
└── requirements.txt
```

---

## 5. Data Flow

```
Lua export scripts  ──►  CSV files on Desktop
                              │
                              ▼
                     [ Import pipeline ]
                              │
             schema validation + type coercion
                              │
                              ▼
                  [ Domain model objects ]
                              │
                              ▼
                    [ Analytics engine ]
                              │
                              ▼
            [ ViewModels (Qt-friendly shapes) ]
                              │
                              ▼
                       [ UI pages ]
```

Rules:
- **Parsers never know about the UI.** They return dataframes / domain objects only.
- **Analytics never know about CSV formats.** They operate on domain objects.
- **UI never reads CSVs directly.** It requests data from viewmodels.

---

## 6. CSV Import Pipeline

### 6.1 Discovery

- Default scan location: `%USERPROFILE%\Desktop\` (matches the Lua scripts' output path).
- Filename patterns recognised:
  - `SEASON_OVERVIEW_DD_MM_YYYY.csv`
  - `PLAYERS_SNAPSHOT_DD_MM_YYYY.csv`
  - `SEASON_STATS_DD_MM_YYYY.csv`
  - `FIXTURES_<competition>_DD_MM_YYYY.csv`
  - `TRANSFER_HISTORY_DD_MM_YYYY.csv`
  - `WONDERKIDS_DD_MM_YYYY.csv`
- The user can also pick a folder manually.

### 6.2 Schema detection

Each CSV kind has an explicit expected-columns list in `app/import_/schema.py`. On import:

1. Read the header row.
2. Match against known schemas (permissive — extra columns allowed, missing required columns → error).
3. Route to the correct parser.

### 6.3 Parsing

- Use `pandas.read_csv(..., dtype=<explicit map>)` to avoid inference surprises.
- Coerce dates via helpers (Lua `birthdate` is in Gregorian days — convert using a known FC26 epoch once parsed; leave raw column preserved).
- Normalize IDs to `Int64` (nullable) rather than `float`.

### 6.4 Validation

- Report per-file status: rows read, rows dropped, missing columns.
- Non-fatal issues surface as a toast; fatal ones block the import and show a clear message.

### 6.5 Caching

- After a successful import, write the parsed tables to `%LOCALAPPDATA%\FC26Analytics\cache\session.sqlite`.
- On next launch, offer "reopen last session" without re-parsing.

---

## 7. Parsing Engine Details

Separate parser per CSV kind. Each returns a typed dataframe and a small metadata dict (season, export date, source filename).

| Parser | Source CSV | Produces |
|--------|-----------|----------|
| `parse_season_overview` | SEASON_OVERVIEW | Club + current standings row |
| `parse_players_snapshot` | PLAYERS_SNAPSHOT | Player attribute table |
| `parse_season_stats` | SEASON_STATS | Per-player per-competition match stats |
| `parse_fixtures` | FIXTURES_* | Fixture list per competition |
| `parse_transfer_history` | TRANSFER_HISTORY | Transfers + loans |
| `parse_wonderkids` | WONDERKIDS | Young high-potential candidates |

All parsers share a common base: `BaseParser.parse(path) -> ParsedCSV`.

---

## 8. Analytics Engine

### 8.1 Standings & season progression

Inputs: FIXTURES_* + SEASON_OVERVIEW.
Outputs: points-per-matchday series, league-position-per-matchday series, GF/GA running totals, goal difference curve.

### 8.2 Form & streaks

Inputs: FIXTURES_* filtered to user club.
Outputs: last-N results (W/D/L), current streak, longest unbeaten run, home/away split.

### 8.3 Squad performance

Inputs: SEASON_STATS + PLAYERS_SNAPSHOT.
Outputs: top scorers, assists, appearances, avg rating, clean sheets (GKs), minutes played, injury flags (if present).

### 8.4 Player development trend

Requires multiple PLAYERS_SNAPSHOT imports from different dates.
Outputs: OVR / potential delta per player between snapshots.

### 8.5 Wonderkids

Inputs: PLAYERS_SNAPSHOT.
Logic: filter by age ≤ 21 and `potential >= threshold` (default 85; user-tunable).
Outputs: ranked list with age, OVR, potential, club, league, origin flag (real vs generated via `playerid` threshold — already confirmed: `>= 460000` = generated).

### 8.6 Tactical stats

Inputs: SEASON_OVERVIEW + aggregated FIXTURES / SEASON_STATS.
Derived metrics: goals per match, goals conceded per match, clean-sheet ratio, simple "finishing efficiency" proxy = goals / shots if shots exported (see Points to Verify).

### 8.7 Transfer planning

Inputs: PLAYERS_SNAPSHOT + (optional) contract CSV.
Outputs: aging list (age × OVR quadrant), expiring contracts (by `contractvaliduntil` vs current season year), position depth chart, replacement suggestions (same position, younger, similar or better OVR/potential).

---

## 9. Chart & Visualization Modules

All charts wrap **PyQtGraph** and expose a uniform API:

```
ChartPanel(title, subtitle, x_axis, y_axis, series[])
```

Chart types provided:

| Module | Chart type | Used on |
|--------|-----------|---------|
| `line_chart.py` | Line + area | Points progression, ranking evolution, form curve |
| `bar_chart.py` | Vertical / horizontal bars | Top scorers, assists, appearances |
| `stacked_bar.py` | Stacked bars | W/D/L per month, home vs away GF/GA |
| `radar_chart.py` | Radar | Player attribute profile (PAC/SHO/PAS/DRI/DEF/PHY) |
| `sparkline.py` | Inline mini chart | KPI tiles, table cells |
| `heatmap.py` | Position / depth heatmap | Tactical + squad depth views |
| `scatter.py` | Scatter | Age × potential (wonderkids), age × OVR (aging) |

Theming: every chart reads colors from a single palette in `ui/theme.py` (primary, success, warn, danger, neutral, subtle grid).

---

## 10. Wonderkid Scouting Module

Dedicated page and dedicated export script.

### 10.1 Lua export (`export_wonderkids.lua`)

Single-pass over `players` table, writing rows where:
- `age <= 21` (computed from `birthdate` + `GetCurrentDate()` — pattern confirmed in `mass_edit_age.lua`)
- `potential >= POTENTIAL_MIN` (parameter, default 85)

Columns: `playerid, name, club, league, nationality, age, birthdate, preferredposition1, preferredposition2, overallrating, potential, is_generated, trait1, trait2, skillmoves, weakfootabilitytypecode` plus the full attribute set already confirmed in `99ovr_99pot.lua`.

### 10.2 Python page

- Sortable, filterable table (age, potential, position, league, nationality, real vs generated).
- Quadrant scatter: age (x) × potential (y), colored by position group.
- Per-player drawer: radar of 6 attribute groups + raw attribute list.
- "Origin type" badge: `real` vs `generated` — derived purely from `playerid >= 460000` threshold (confirmed in `delete_generated_players.lua` and `list_players.lua`).

---

## 11. UI / Page Architecture

### 11.1 Shell

`QMainWindow` with:
- **Left sidebar** — collapsible nav: Overview, Analytics, Squad, Wonderkids, Tactics, Transfers, Import.
- **Top bar** — current season, current club, global filter, import button, theme toggle.
- **Central stack** — one page per section.
- **Status bar** — last import timestamp, row counts, log indicator.

### 11.2 Pages

#### 11.2.1 Season Overview
Hero header with club crest (optional), season label, league + position.
KPI grid (3×3): Points · Wins · Draws · Losses · GF · GA · GD · Recent Form (5-game dots) · Objectives progress.
Each KPI tile uses a sparkline for its trend.

#### 11.2.2 Season Analytics
Full-page grid of charts:
- Points progression (line)
- Ranking evolution (line, inverted Y)
- Scoring trend (bar + line overlay)
- Defensive trend (bar + line overlay)
- Form curve (moving average)
- Streaks panel (textual + color coded)

#### 11.2.3 Squad Performance
Top-N leaderboards as horizontal bar charts:
- Top scorers, assists, appearances, ratings, clean sheets.
Filter bar: competition, position, minimum minutes.
Per-player drawer: development trend (if multi-snapshot), radar, match log.

#### 11.2.4 Wonderkid Scout Hub
See §10.2.

#### 11.2.5 Tactical Dashboard
- Formation visual (pitch diagram with 11 slots; input from user-selected starting XI).
- KPI tiles: possession, pass accuracy, finishing efficiency, defensive solidity.
*(All four metrics depend on fields we have not yet confirmed — see "Points to Verify".)*

#### 11.2.6 Transfer Planning
- Aging quadrant (scatter).
- Expiring contracts table with years-left.
- Replacement finder — select a player, get ranked candidates (same position, younger, similar OVR/potential).
- Positional depth bar chart.

#### 11.2.7 Import Page
- Drag-and-drop zone + file picker.
- Detected files list with status icons.
- Parse log.
- "Clear cache" control.

### 11.3 Design tokens

- **Typography**: single font family (Inter or system default), 4 sizes.
- **Spacing**: 4/8/12/16/24/32 px scale.
- **Radii**: 6 / 10 / 14 px.
- **Palette**: dark theme by default, light theme toggle. Semantic tokens only (never hex in pages).

---

## 12. Export-Script Workflow (Lua side)

### 12.1 Guiding rule — never invent API calls

**Every Lua export script must use ONLY methods already confirmed.** Anything else goes to "Points to Verify" and is tested with `pcall` in a throwaway script before being used in production.

### 12.2 Confirmed Live Editor API (inherited from the prior plan + script analysis)

#### Table access
- `LE.db:GetTable("players")`
- `LE.db:GetTable("teamplayerlinks")`
- `LE.db:GetTable("teams")`
- `LE.db:GetTable("career_playercontract")`
- `LE.db:GetTable("leagues")` *(confirmed 16/04/2026 via `discover_league_columns.lua`)*
- `LE.db:GetTable("leagueteamlinks")` *(confirmed same date)*

#### Record iteration
- `table:GetFirstRecord()`
- `table:GetNextValidRecord()`
- `table:GetRecordFieldValue(record, "field")`
- `table:SetRecordFieldValue(record, "field", value)`

#### Confirmed `players` fields
Identity/meta: `playerid`, `birthdate`, `nationality`, `isretiring`, `height`, `preferredposition1`, `preferredposition2`, `preferredfoot`, `modifier`, `contractvaliduntil`, `hashighqualityhead`, `headclasscode`, `headassetid`.
Attributes (full list confirmed via `99ovr_99pot.lua`):
- GK: `gkdiving`, `gkhandling`, `gkkicking`, `gkpositioning`, `gkreflexes`
- ATT: `crossing`, `finishing`, `headingaccuracy`, `shortpassing`, `volleys`
- DEF: `defensiveawareness`, `standingtackle`, `slidingtackle`
- SKL: `dribbling`, `curve`, `freekickaccuracy`, `longpassing`, `ballcontrol`
- PWR: `shotpower`, `jumping`, `stamina`, `strength`, `longshots`
- MOV: `acceleration`, `sprintspeed`, `agility`, `reactions`, `balance`
- MEN: `aggression`, `composure`, `interceptions`, `positioning`, `vision`, `penalties`
- Global: `overallrating`, `potential`
Playstyles: `trait1`, `trait2`, `icontrait1`, `icontrait2`, `skillmoves`, `weakfootabilitytypecode`.

#### Confirmed `teamplayerlinks` fields
`playerid`, `teamid`, `jerseynumber`.

#### Confirmed `career_playercontract` fields
`playerid`, `contract_status`, `contract_date`, `last_status_change_date`, `duration_months`, `playerrole`.

#### Confirmed `leagues` / `leagueteamlinks` fields
Per `discover_league_columns.lua` (2026-04-16):
- `leagues`: `leagueid`, `leaguename`, `countryid`, `level`, `leaguetype`, …
- `leagueteamlinks`: `leagueid`, `teamid`, `points`, `currenttableposition`, `nummatchesplayed`, `homewins/losses/draws`, `awaywins/losses/draws`, `homegf/ga`, `awaygf/ga`, `teamform`, `teamshortform`, `teamlongform`, `lastgameresult`, `unbeatenleague`, `unbeatenaway`, `unbeatenallcomps`, `champion`, `objective`.

#### Confirmed helper functions
- `GetPlayerName(playerid)` — slow; call only on needed subset.
- `GetTeamName(teamid)`
- `GetTeamIdFromPlayerId(playerid)`
- `GetPlayerIDSForTeam(teamid)`
- `GetUserSeniorTeamPlayerIDs()`
- `GetUserTeamID()`
- `GetCurrentDate()` → `{day, month, year}`, with `:ToInt()` (per `extend_user_team_players_contracts.lua`).
- `GetPlayerPrimaryPositionName(code)`
- `GetCompetitionNameByObjID(id)`
- `GetPlayersStats()` — returns per-player per-competition match-stat table.
- `GetCMEventNameByID(id)` (per `track_cm_events.lua`)
- `IsInCM()`
- `PlayerHasDevelopementPlan(playerid)` (per `99ovr_99pot.lua`)
- `PlayerSetValueInDevelopementPlan(playerid, field, value)`
- `MessageBox(title, msg)`
- `Log(msg)` / `LOGGER:LogInfo(msg)` / `LOGGER:LogError(msg)`
- `AddEventHandler("pre__CareerModeEvent", cb)` (per `track_cm_events.lua`)

#### Confirmed DATE class
`DATE:new()`, `:FromGregorianDays(days)`, `:ToGregorianDays()`, `:FromInt(int)`, `:ToInt()`, `:ToString()`, fields `.year / .month / .day`.

#### Confirmed memory helpers (advanced scripts only)
`MEMORY:ReadPointer`, `ReadInt`, `ReadShort`, `ReadChar`, `ReadBool`, `ReadMultilevelPointer`. Used in `export_fixtures.lua` and `export_transfer_history.lua` for in-memory structures (standings, fixtures, negotiations). These are **reference-only** — do not extend without verification.

#### Confirmed import modules
`imports/other/helpers`, `imports/career_mode/helpers`, `imports/career_mode/enums`, `imports/services/enums`, `imports/core/date`, `imports/core/common`, `imports/core/memory`, `imports/other/playstyles_enum`.

#### Confirmed constants
- `playerid >= 460000` → generated player.
- `playerid < 460000` → real (original DB) player.
- Contract statuses `1 / 3 / 5` → loaned-in (per `extend_user_team_players_contracts.lua`).

### 12.3 CSV writing pattern (confirmed, reused verbatim)
```lua
local desktop_path = string.format("%s\\Desktop", os.getenv('USERPROFILE'))
local d = GetCurrentDate()
local path = string.format("%s\\<KIND>_%02d_%02d_%04d.csv", desktop_path, d.day, d.month, d.year)
local f = io.open(path, "w+")
io.output(f)
io.write(table.concat(columns, ",")); io.write("\n")
-- ... rows
io.close(f)
```

### 12.4 New scripts to produce (planning only — not to implement yet)
- `export_season_overview.lua` — user club, league, standings row from `leagueteamlinks`.
- `export_players_snapshot.lua` — full attribute dump, one row per player.
- `export_wonderkids.lua` — filtered subset (age ≤ 21, potential ≥ threshold).

All three should:
1. `assert(IsInCM())` upfront.
2. Single pass over `players`.
3. Lazy `GetPlayerName` / `GetTeamName` calls only on retained rows.
4. `pcall` around any field listed in "Points to Verify".

---

## 13. Scalability Considerations

- **Player table size**: tens of thousands of rows. Single pass in Lua; pandas handles the rest trivially.
- **Multiple snapshots**: the app stores each imported CSV as a separate row in the session cache keyed by export date → supports multi-season / multi-snapshot comparisons without reloading.
- **Chart density**: PyQtGraph scales to tens of thousands of points; downsample in analytics layer if a chart exceeds 5k visible points.
- **Memory**: keep raw dataframes; derive lazily. Cache derived views in viewmodels with invalidation on new import.
- **Future data growth**: if any single CSV exceeds ~200 MB, move that parser to `polars` or chunked reads — the parser interface is already abstracted for this.

---

## 14. Error Handling

- **Parser layer**: raise typed exceptions (`MissingColumnError`, `SchemaMismatchError`, `EmptyFileError`). Pipeline catches and reports per-file.
- **Analytics layer**: pure functions; assume validated input; any missing optional field returns `None` and the UI renders "—".
- **UI layer**: global `QErrorMessage` for fatal errors; inline toasts for recoverable ones.
- **Logging**: rotating file log at `%LOCALAPPDATA%\FC26Analytics\logs\app.log`. Every import and every unhandled exception logged with stack trace.
- **User-visible rule**: the app never crashes silently; every failure produces either a toast or a modal.

---

## 15. Future Extensibility

- **Plugin-style analytics**: each analytics module registers via a small registry → new modules drop-in without UI changes.
- **Additional CSV kinds**: adding a new CSV means one new schema entry + one new parser + optional new page.
- **Multi-save comparison**: with the snapshot cache already keyed by date, comparing two seasons or two careers is mostly a UI exercise.
- **i18n**: wrap all user-facing strings through a `tr()` helper from the start (Qt provides this natively).
- **Theme packs**: palette already tokenized — new themes are pure QSS + color-token files.
- **Alternative data sources**: the domain layer is CSV-agnostic — if EA ever ships an official export, swap parsers only.

---

## 16. Points to Verify — Unconfirmed Methods / Data Access Requirements

> **Critical rule** — nothing below is to be used in production scripts until it has been validated with a throwaway `pcall`-guarded test script. The Live Editor engine is very sensitive; guessing fields crashes it.

### 16.1 `players` table — unverified fields
| Field | Needed for | Status |
|-------|-----------|--------|
| `firstname`, `lastname`, `commonname` | Splitting player name without `GetPlayerName()` | **Unverified** — no existing script reads them. Fallback: `GetPlayerName()` only. |
| `preferredposition3`, `preferredposition4` | Position flexibility analytics | **Unverified**. PS_V2 only reads position1/2. |
| `age` | Direct age read | **Unverified / likely absent**. Compute from `birthdate` instead (confirmed pattern). |
| `injury*` related fields | Squad "injuries" KPI | **Unverified** — no existing script accesses them. |
| `fitness`, `form`, `morale`, `sharpness` | Tactical + squad trends | **Needs verification.** `auto_max_user_team_*` scripts exist — names suggest these fields exist but confirmation from those scripts' content is pending. |
| `shots`, `shotsontarget`, `passes` per match | Finishing efficiency, pass accuracy | **Unverified.** May not exist in `players`; probably elsewhere if at all. |

### 16.2 `GetPlayersStats()` — field coverage
`export_season_stats.lua` confirms: `playerid`, `app`, `goals`, `assists`, `yellow`, `two_yellow`, `red`, `saves`, `goals_conceded`, `clean_sheets`, `motm`, `avg`, `compobjid`, `compname`.
**Unverified**: shots, key passes, pass accuracy, possession contribution, distance covered, xG — any richer per-match telemetry. Document-as-absent until proven otherwise.

### 16.3 Team-level tactical data
| Need | Status |
|------|--------|
| Formation / tactical preset per team | **Unverified.** No existing script reads a "formation" column. May require a different table (e.g., `team_tactics`, `formations`) that must be discovered via a `discover_*.lua` probe. |
| Possession / pass accuracy aggregates | **Unverified.** Likely not in `players` or `leagueteamlinks`. Source unknown. |

### 16.4 Objectives progress (for Season Overview)
**Unverified.** `leagueteamlinks.objective` exists — semantics unclear (integer? bitmask? reference into another table?). Needs a small probe script to dump a few sample values for the user's team.

### 16.5 Contract / transfer fee data at rest
`career_playercontract` has `duration_months` and dates but **no salary/wage field is confirmed**. Salary / release-clause / weekly-wage fields: **unverified** — probably in a different table.

### 16.6 Fixtures outside memory
`export_fixtures.lua` reads fixtures from in-memory structures via `MEMORY:*`. **No confirmed DB table for fixtures**. If a CSV of fixtures is wanted without memory reads, this is an open question.

### 16.7 Regen / generated-player origin tagging
Only the numeric threshold (`playerid >= 460000`) is confirmed. **No field** tells us whether a generated player is a youth-academy intake vs a regen vs a free-agent refill — do not invent one.

### 16.8 Competition / league metadata
- Mapping `compobjid` (from `GetPlayersStats`) → league is not obviously the same identifier as `leagueid` in `leagues`. **Needs verification** before cross-joining season-stats with league standings.

### 16.9 Python-side items to decide (non-Lua)
- Packaging tool: PyInstaller vs Briefcase.
- Charting fallback: whether QtCharts is actually needed or PyQtGraph covers every chart type.
- Whether the SQLite cache should be a single file per career save or rolling.

---

## 17. Review Checklist Before Starting Development

- [ ] User reviews §16 and runs probe scripts for any field they want used.
- [ ] User confirms CSV column contracts in `docs/CSV_CONTRACTS.md` (to be drafted).
- [ ] Decision on packaging tool.
- [ ] Decision on dark-only vs light+dark at v1.
- [ ] Sign-off on page list (§11.2) — add/remove before building.

---

*End of plan — no code is to be written until the user signs off on §16 and §17.*
