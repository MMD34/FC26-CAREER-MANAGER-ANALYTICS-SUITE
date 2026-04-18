-- export_standings.lua
-- PT §7.2 / CSV_CONTRACTS §7.2 — one row per team in the given league.
-- Source: leagueteamlinks WHERE leagueid = LEAGUE_ID, JOIN teams.
-- Output: %USERPROFILE%\Desktop\STANDINGS_<leaguename>_DD_MM_YYYY.csv
require 'imports/other/helpers'

assert(IsInCM(), "Script must be executed in career mode")

-- Optional override. Leave as nil to default to the user's current league.
local LEAGUE_ID = nil

local columns = {
    "export_date",
    "leagueid",
    "leaguename",
    "teamid",
    "teamname",
    "currenttableposition",
    "previousyeartableposition",
    "points",
    "nummatchesplayed",
    "homewins",
    "homedraws",
    "homelosses",
    "awaywins",
    "awaydraws",
    "awaylosses",
    "homegf",
    "homega",
    "awaygf",
    "awayga",
    "teamform",
    "teamlongform",
    "lastgameresult",
    "unbeatenleague",
    "champion",
    "team_overallrating",
}

local function csv_escape(v)
    if v == nil then return "" end
    local s = tostring(v)
    if s:find('[,"\n]') then
        s = '"' .. s:gsub('"', '""') .. '"'
    end
    return s
end

local function safe_read(tbl, record, field)
    local ok, val = pcall(function() return tbl:GetRecordFieldValue(record, field) end)
    if ok then return val end
    return nil
end

local function bool01(v)
    if v == nil then return "" end
    if v == true then return 1 end
    if v == false then return 0 end
    local n = tonumber(v)
    if n == nil then return "" end
    if n ~= 0 then return 1 end
    return 0
end

local function sanitize(name)
    local s = tostring(name or "league")
    s = s:gsub("[^A-Za-z0-9_%-]", "_")
    return s
end

local current_date = GetCurrentDate()
local export_date = string.format("%02d_%02d_%04d", current_date.day, current_date.month, current_date.year)
local desktop_path = string.format("%s\\Desktop", os.getenv('USERPROFILE'))

-- Resolve default LEAGUE_ID via the user's leagueteamlinks row.
local ltl = LE.db:GetTable("leagueteamlinks")
if LEAGUE_ID == nil then
    local user_teamid = GetUserTeamID()
    local rec = ltl:GetFirstRecord()
    while rec > 0 do
        if ltl:GetRecordFieldValue(rec, "teamid") == user_teamid then
            LEAGUE_ID = ltl:GetRecordFieldValue(rec, "leagueid")
            break
        end
        rec = ltl:GetNextValidRecord()
    end
end
assert(LEAGUE_ID ~= nil, "Could not resolve LEAGUE_ID")

-- Cache teams by teamid.
local teams = LE.db:GetTable("teams")
local TEAM_NAME = {}
local TEAM_OVR = {}
do
    local rec = teams:GetFirstRecord()
    while rec > 0 do
        local tid = teams:GetRecordFieldValue(rec, "teamid")
        TEAM_NAME[tid] = teams:GetRecordFieldValue(rec, "teamname")
        TEAM_OVR[tid] = teams:GetRecordFieldValue(rec, "overallrating")
        rec = teams:GetNextValidRecord()
    end
end

-- Resolve league name.
local leagues = LE.db:GetTable("leagues")
local league_name = ""
do
    local rec = leagues:GetFirstRecord()
    while rec > 0 do
        if leagues:GetRecordFieldValue(rec, "leagueid") == LEAGUE_ID then
            league_name = leagues:GetRecordFieldValue(rec, "leaguename") or ""
            break
        end
        rec = leagues:GetNextValidRecord()
    end
end

local file_path = string.format("%s\\STANDINGS_%s_%s.csv", desktop_path, sanitize(league_name), export_date)
local file = io.open(file_path, "w+")
io.output(file)
io.write(table.concat(columns, ","))
io.write("\n")

local rec = ltl:GetFirstRecord()
while rec > 0 do
    if ltl:GetRecordFieldValue(rec, "leagueid") == LEAGUE_ID then
        local tid = ltl:GetRecordFieldValue(rec, "teamid")
        local row = {
            export_date = export_date,
            leagueid = LEAGUE_ID,
            leaguename = league_name,
            teamid = tid,
            teamname = TEAM_NAME[tid] or "",
            currenttableposition = ltl:GetRecordFieldValue(rec, "currenttableposition"),
            previousyeartableposition = safe_read(ltl, rec, "previousyeartableposition"),
            points = ltl:GetRecordFieldValue(rec, "points"),
            nummatchesplayed = ltl:GetRecordFieldValue(rec, "nummatchesplayed"),
            homewins = ltl:GetRecordFieldValue(rec, "homewins"),
            homedraws = ltl:GetRecordFieldValue(rec, "homedraws"),
            homelosses = ltl:GetRecordFieldValue(rec, "homelosses"),
            awaywins = ltl:GetRecordFieldValue(rec, "awaywins"),
            awaydraws = ltl:GetRecordFieldValue(rec, "awaydraws"),
            awaylosses = ltl:GetRecordFieldValue(rec, "awaylosses"),
            homegf = ltl:GetRecordFieldValue(rec, "homegf"),
            homega = ltl:GetRecordFieldValue(rec, "homega"),
            awaygf = ltl:GetRecordFieldValue(rec, "awaygf"),
            awayga = ltl:GetRecordFieldValue(rec, "awayga"),
            teamform = safe_read(ltl, rec, "teamform"),
            teamlongform = safe_read(ltl, rec, "teamlongform"),
            lastgameresult = safe_read(ltl, rec, "lastgameresult"),
            unbeatenleague = safe_read(ltl, rec, "unbeatenleague"),
            champion = bool01(safe_read(ltl, rec, "champion")),
            team_overallrating = TEAM_OVR[tid],
        }
        local out = {}
        for i = 1, #columns do
            out[i] = csv_escape(row[columns[i]])
        end
        io.write(table.concat(out, ","))
        io.write("\n")
    end
    rec = ltl:GetNextValidRecord()
end

io.close(file)
LOGGER:LogInfo("Done: " .. file_path)
