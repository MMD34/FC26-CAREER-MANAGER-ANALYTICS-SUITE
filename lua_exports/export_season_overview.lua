-- export_season_overview.lua
-- PT §7.1 / CSV_CONTRACTS §7.1 — one row per (user team × current league).
-- Source: leagueteamlinks (filtered to user team) + leagues + teams.
-- Output: %USERPROFILE%\Desktop\SEASON_OVERVIEW_DD_MM_YYYY.csv
require 'imports/other/helpers'

assert(IsInCM(), "Script must be executed in career mode")

local columns = {
    "export_date",
    "season_year",
    "user_teamid",
    "user_teamname",
    "leagueid",
    "leaguename",
    "league_level",
    "leaguetype",
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
    "teamshortform",
    "teamlongform",
    "lastgameresult",
    "unbeatenhome",
    "unbeatenaway",
    "unbeatenleague",
    "unbeatenallcomps",
    "objective",
    "hasachievedobjective",
    "highestpossible",
    "highestprobable",
    "yettowin",
    "actualvsexpectations",
    "champion",
    "team_overallrating",
    "team_attackrating",
    "team_midfieldrating",
    "team_defenserating",
    "buildupplay",
    "defensivedepth",
    "captainid",
    "penaltytakerid",
    "freekicktakerid",
    "leftcornerkicktakerid",
    "rightcornerkicktakerid",
    "longkicktakerid",
    "leftfreekicktakerid",
    "rightfreekicktakerid",
    "favoriteteamsheetid",
    "teamstadiumcapacity",
    "clubworth",
    "domesticprestige",
    "internationalprestige",
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
    if v == true or v == 1 or v == "1" then return 1 end
    if v == false or v == 0 or v == "0" then return 0 end
    local n = tonumber(v)
    if n == nil then return "" end
    if n ~= 0 then return 1 end
    return 0
end

local current_date = GetCurrentDate()
local export_date = string.format("%02d_%02d_%04d", current_date.day, current_date.month, current_date.year)
local desktop_path = string.format("%s\\Desktop", os.getenv('USERPROFILE'))
local file_path = string.format("%s\\SEASON_OVERVIEW_%s.csv", desktop_path, export_date)

local user_teamid = GetUserTeamID()

-- Locate the user's row in leagueteamlinks (first match on teamid).
local ltl = LE.db:GetTable("leagueteamlinks")
local user_ltl_record = -1
local user_leagueid = nil
do
    local rec = ltl:GetFirstRecord()
    while rec > 0 do
        local tid = ltl:GetRecordFieldValue(rec, "teamid")
        if tid == user_teamid then
            user_ltl_record = rec
            user_leagueid = ltl:GetRecordFieldValue(rec, "leagueid")
            break
        end
        rec = ltl:GetNextValidRecord()
    end
end
assert(user_ltl_record > 0, "User team not found in leagueteamlinks")

-- Look up the leagues row.
local leagues = LE.db:GetTable("leagues")
local league_record = -1
do
    local rec = leagues:GetFirstRecord()
    while rec > 0 do
        local lid = leagues:GetRecordFieldValue(rec, "leagueid")
        if lid == user_leagueid then
            league_record = rec
            break
        end
        rec = leagues:GetNextValidRecord()
    end
end

-- Look up the teams row.
local teams = LE.db:GetTable("teams")
local team_record = -1
do
    local rec = teams:GetFirstRecord()
    while rec > 0 do
        local tid = teams:GetRecordFieldValue(rec, "teamid")
        if tid == user_teamid then
            team_record = rec
            break
        end
        rec = teams:GetNextValidRecord()
    end
end
assert(team_record > 0, "User team not found in teams table")

local row = {}
row.export_date = export_date
row.season_year = current_date.year
row.user_teamid = user_teamid
row.user_teamname = teams:GetRecordFieldValue(team_record, "teamname")
row.leagueid = user_leagueid
if league_record > 0 then
    row.leaguename = leagues:GetRecordFieldValue(league_record, "leaguename")
    row.league_level = safe_read(leagues, league_record, "level")
    row.leaguetype = safe_read(leagues, league_record, "leaguetype")
else
    row.leaguename = ""
    row.league_level = nil
    row.leaguetype = nil
end

row.currenttableposition = ltl:GetRecordFieldValue(user_ltl_record, "currenttableposition")
row.previousyeartableposition = safe_read(ltl, user_ltl_record, "previousyeartableposition")
row.points = ltl:GetRecordFieldValue(user_ltl_record, "points")
row.nummatchesplayed = ltl:GetRecordFieldValue(user_ltl_record, "nummatchesplayed")
row.homewins = ltl:GetRecordFieldValue(user_ltl_record, "homewins")
row.homedraws = ltl:GetRecordFieldValue(user_ltl_record, "homedraws")
row.homelosses = ltl:GetRecordFieldValue(user_ltl_record, "homelosses")
row.awaywins = ltl:GetRecordFieldValue(user_ltl_record, "awaywins")
row.awaydraws = ltl:GetRecordFieldValue(user_ltl_record, "awaydraws")
row.awaylosses = ltl:GetRecordFieldValue(user_ltl_record, "awaylosses")
row.homegf = ltl:GetRecordFieldValue(user_ltl_record, "homegf")
row.homega = ltl:GetRecordFieldValue(user_ltl_record, "homega")
row.awaygf = ltl:GetRecordFieldValue(user_ltl_record, "awaygf")
row.awayga = ltl:GetRecordFieldValue(user_ltl_record, "awayga")
row.teamform = safe_read(ltl, user_ltl_record, "teamform")
row.teamshortform = safe_read(ltl, user_ltl_record, "teamshortform")
row.teamlongform = safe_read(ltl, user_ltl_record, "teamlongform")
row.lastgameresult = safe_read(ltl, user_ltl_record, "lastgameresult")
row.unbeatenhome = safe_read(ltl, user_ltl_record, "unbeatenhome")
row.unbeatenaway = safe_read(ltl, user_ltl_record, "unbeatenaway")
row.unbeatenleague = safe_read(ltl, user_ltl_record, "unbeatenleague")
row.unbeatenallcomps = safe_read(ltl, user_ltl_record, "unbeatenallcomps")

-- §15.5 objectives: pcall every read; semantics still unknown but fields are present.
row.objective = safe_read(ltl, user_ltl_record, "objective")
row.hasachievedobjective = bool01(safe_read(ltl, user_ltl_record, "hasachievedobjective"))
row.highestpossible = safe_read(ltl, user_ltl_record, "highestpossible")
row.highestprobable = safe_read(ltl, user_ltl_record, "highestprobable")
row.yettowin = safe_read(ltl, user_ltl_record, "yettowin")
row.actualvsexpectations = safe_read(ltl, user_ltl_record, "actualvsexpectations")
row.champion = bool01(safe_read(ltl, user_ltl_record, "champion"))

row.team_overallrating = teams:GetRecordFieldValue(team_record, "overallrating")
row.team_attackrating = teams:GetRecordFieldValue(team_record, "attackrating")
row.team_midfieldrating = teams:GetRecordFieldValue(team_record, "midfieldrating")
row.team_defenserating = teams:GetRecordFieldValue(team_record, "defenserating")
row.buildupplay = safe_read(teams, team_record, "buildupplay")
row.defensivedepth = safe_read(teams, team_record, "defensivedepth")
row.captainid = safe_read(teams, team_record, "captainid")
row.penaltytakerid = safe_read(teams, team_record, "penaltytakerid")
row.freekicktakerid = safe_read(teams, team_record, "freekicktakerid")
row.leftcornerkicktakerid = safe_read(teams, team_record, "leftcornerkicktakerid")
row.rightcornerkicktakerid = safe_read(teams, team_record, "rightcornerkicktakerid")
row.longkicktakerid = safe_read(teams, team_record, "longkicktakerid")
row.leftfreekicktakerid = safe_read(teams, team_record, "leftfreekicktakerid")
row.rightfreekicktakerid = safe_read(teams, team_record, "rightfreekicktakerid")
row.favoriteteamsheetid = safe_read(teams, team_record, "favoriteteamsheetid")
row.teamstadiumcapacity = safe_read(teams, team_record, "teamstadiumcapacity")
row.clubworth = safe_read(teams, team_record, "clubworth")
row.domesticprestige = safe_read(teams, team_record, "domesticprestige")
row.internationalprestige = safe_read(teams, team_record, "internationalprestige")

local file = io.open(file_path, "w+")
io.output(file)
io.write(table.concat(columns, ","))
io.write("\n")
local out = {}
for i = 1, #columns do
    out[i] = csv_escape(row[columns[i]])
end
io.write(table.concat(out, ","))
io.write("\n")
io.close(file)
LOGGER:LogInfo("Done: " .. file_path)
