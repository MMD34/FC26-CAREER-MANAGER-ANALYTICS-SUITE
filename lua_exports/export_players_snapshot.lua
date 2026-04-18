-- export_players_snapshot.lua
-- PT §7.3 / CSV_CONTRACTS §7.3 — one row per player.
-- Per SCHEMA_NOTES §15.1 (Option A): display_name is resolved via GetPlayerName(playerid);
-- firstname/lastname/commonname/jerseyname are emitted empty.
-- Output: %USERPROFILE%\Desktop\PLAYERS_SNAPSHOT_DD_MM_YYYY.csv
require 'imports/other/helpers'

assert(IsInCM(), "Script must be executed in career mode")

local columns = {
    "export_date","playerid","is_generated",
    "firstname","lastname","commonname","display_name","jerseyname",
    "birthdate","age",
    "nationality","gender","preferredfoot",
    "preferredposition1","preferredposition2","preferredposition3","preferredposition4",
    "preferredposition5","preferredposition6","preferredposition7",
    "role1","role2","role3","role4","role5",
    "overallrating","potential","internationalrep",
    "pacdiv","shohan","paskic","driref","defspe","phypos",
    "gkdiving","gkhandling","gkkicking","gkpositioning","gkreflexes",
    "crossing","finishing","headingaccuracy","shortpassing","volleys",
    "defensiveawareness","standingtackle","slidingtackle","dribbling","curve",
    "freekickaccuracy","longpassing","ballcontrol","shotpower","jumping",
    "stamina","strength","longshots","acceleration","sprintspeed",
    "agility","reactions","balance","aggression","composure",
    "interceptions","positioning","vision","penalties",
    "trait1","trait2","icontrait1","icontrait2",
    "skillmoves","skillmoveslikelihood","weakfootabilitytypecode",
    "height","weight",
    "contractvaliduntil","playerjointeamdate","isretiring",
    "teamid","teamname","jerseynumber","squad_position",
    "leagueid","leaguename","league_level",
    "form","injury",
    "leagueappearances","leaguegoals","leaguegoalsprevmatch","leaguegoalsprevthreematches",
    "yellows","reds",
    "istopscorer","isamongtopscorers","isamongtopscorersinteam",
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

local current_date = GetCurrentDate()
local export_date = string.format("%02d_%02d_%04d", current_date.day, current_date.month, current_date.year)
local desktop_path = string.format("%s\\Desktop", os.getenv('USERPROFILE'))
local file_path = string.format("%s\\PLAYERS_SNAPSHOT_%s.csv", desktop_path, export_date)

local function compute_age(birthdate_days)
    if birthdate_days == nil then return nil end
    local ok, age = pcall(function()
        local bd = DATE:new()
        bd:FromGregorianDays(birthdate_days)
        local a = current_date.year - bd.year
        if (current_date.month < bd.month)
           or (current_date.month == bd.month and current_date.day < bd.day) then
            a = a - 1
        end
        return a
    end)
    if ok then return age end
    return nil
end

-- Step 2: full pass over teamplayerlinks, keyed by playerid.
LOGGER:LogInfo("Caching teamplayerlinks...")
local TPL = {}
do
    local tpl = LE.db:GetTable("teamplayerlinks")
    local rec = tpl:GetFirstRecord()
    while rec > 0 do
        local pid = tpl:GetRecordFieldValue(rec, "playerid")
        TPL[pid] = {
            teamid = tpl:GetRecordFieldValue(rec, "teamid"),
            jerseynumber = safe_read(tpl, rec, "jerseynumber"),
            position = safe_read(tpl, rec, "position"),
            form = safe_read(tpl, rec, "form"),
            injury = safe_read(tpl, rec, "injury"),
            leagueappearances = safe_read(tpl, rec, "leagueappearances"),
            leaguegoals = safe_read(tpl, rec, "leaguegoals"),
            leaguegoalsprevmatch = safe_read(tpl, rec, "leaguegoalsprevmatch"),
            leaguegoalsprevthreematches = safe_read(tpl, rec, "leaguegoalsprevthreematches"),
            yellows = safe_read(tpl, rec, "yellows"),
            reds = safe_read(tpl, rec, "reds"),
            istopscorer = safe_read(tpl, rec, "istopscorer"),
            isamongtopscorers = safe_read(tpl, rec, "isamongtopscorers"),
            isamongtopscorersinteam = safe_read(tpl, rec, "isamongtopscorersinteam"),
        }
        rec = tpl:GetNextValidRecord()
    end
end

-- Step 3: teamid → leagueid.
LOGGER:LogInfo("Caching leagueteamlinks...")
local TEAM_LEAGUE = {}
do
    local ltl = LE.db:GetTable("leagueteamlinks")
    local rec = ltl:GetFirstRecord()
    while rec > 0 do
        local tid = ltl:GetRecordFieldValue(rec, "teamid")
        TEAM_LEAGUE[tid] = ltl:GetRecordFieldValue(rec, "leagueid")
        rec = ltl:GetNextValidRecord()
    end
end

-- Step 4: leagueid → (leaguename, level).
LOGGER:LogInfo("Caching leagues...")
local LEAGUE = {}
do
    local leagues = LE.db:GetTable("leagues")
    local rec = leagues:GetFirstRecord()
    while rec > 0 do
        local lid = leagues:GetRecordFieldValue(rec, "leagueid")
        LEAGUE[lid] = {
            leaguename = leagues:GetRecordFieldValue(rec, "leaguename"),
            level = safe_read(leagues, rec, "level"),
        }
        rec = leagues:GetNextValidRecord()
    end
end

-- Step 5: teamid → teamname.
LOGGER:LogInfo("Caching teams...")
local TEAM_NAME = {}
do
    local teams = LE.db:GetTable("teams")
    local rec = teams:GetFirstRecord()
    while rec > 0 do
        local tid = teams:GetRecordFieldValue(rec, "teamid")
        TEAM_NAME[tid] = teams:GetRecordFieldValue(rec, "teamname")
        rec = teams:GetNextValidRecord()
    end
end

-- Step 6: full pass over players.
LOGGER:LogInfo("Exporting players...")
local file = io.open(file_path, "w+")
io.output(file)
io.write(table.concat(columns, ","))
io.write("\n")

local players_table = LE.db:GetTable("players")
local rec = players_table:GetFirstRecord()
local row_count = 0
while rec > 0 do
    local pid = players_table:GetRecordFieldValue(rec, "playerid")
    local birthdate = players_table:GetRecordFieldValue(rec, "birthdate")
    local tpl_row = TPL[pid]
    local teamid = tpl_row and tpl_row.teamid or nil
    local leagueid = teamid and TEAM_LEAGUE[teamid] or nil
    local league = leagueid and LEAGUE[leagueid] or nil

    local row = {
        export_date = export_date,
        playerid = pid,
        is_generated = (pid ~= nil and pid >= 460000) and 1 or 0,
        firstname = "",
        lastname = "",
        commonname = "",
        display_name = GetPlayerName(pid) or "",
        jerseyname = "",
        birthdate = birthdate,
        age = compute_age(birthdate),

        nationality = safe_read(players_table, rec, "nationality"),
        gender = safe_read(players_table, rec, "gender"),
        preferredfoot = safe_read(players_table, rec, "preferredfoot"),
        preferredposition1 = players_table:GetRecordFieldValue(rec, "preferredposition1"),
        preferredposition2 = safe_read(players_table, rec, "preferredposition2"),
        preferredposition3 = safe_read(players_table, rec, "preferredposition3"),
        preferredposition4 = safe_read(players_table, rec, "preferredposition4"),
        preferredposition5 = safe_read(players_table, rec, "preferredposition5"),
        preferredposition6 = safe_read(players_table, rec, "preferredposition6"),
        preferredposition7 = safe_read(players_table, rec, "preferredposition7"),
        role1 = safe_read(players_table, rec, "role1"),
        role2 = safe_read(players_table, rec, "role2"),
        role3 = safe_read(players_table, rec, "role3"),
        role4 = safe_read(players_table, rec, "role4"),
        role5 = safe_read(players_table, rec, "role5"),

        overallrating = players_table:GetRecordFieldValue(rec, "overallrating"),
        potential = players_table:GetRecordFieldValue(rec, "potential"),
        internationalrep = safe_read(players_table, rec, "internationalrep"),

        pacdiv = safe_read(players_table, rec, "pacdiv"),
        shohan = safe_read(players_table, rec, "shohan"),
        paskic = safe_read(players_table, rec, "paskic"),
        driref = safe_read(players_table, rec, "driref"),
        defspe = safe_read(players_table, rec, "defspe"),
        phypos = safe_read(players_table, rec, "phypos"),

        gkdiving = safe_read(players_table, rec, "gkdiving"),
        gkhandling = safe_read(players_table, rec, "gkhandling"),
        gkkicking = safe_read(players_table, rec, "gkkicking"),
        gkpositioning = safe_read(players_table, rec, "gkpositioning"),
        gkreflexes = safe_read(players_table, rec, "gkreflexes"),

        crossing = safe_read(players_table, rec, "crossing"),
        finishing = safe_read(players_table, rec, "finishing"),
        headingaccuracy = safe_read(players_table, rec, "headingaccuracy"),
        shortpassing = safe_read(players_table, rec, "shortpassing"),
        volleys = safe_read(players_table, rec, "volleys"),
        defensiveawareness = safe_read(players_table, rec, "defensiveawareness"),
        standingtackle = safe_read(players_table, rec, "standingtackle"),
        slidingtackle = safe_read(players_table, rec, "slidingtackle"),
        dribbling = safe_read(players_table, rec, "dribbling"),
        curve = safe_read(players_table, rec, "curve"),
        freekickaccuracy = safe_read(players_table, rec, "freekickaccuracy"),
        longpassing = safe_read(players_table, rec, "longpassing"),
        ballcontrol = safe_read(players_table, rec, "ballcontrol"),
        shotpower = safe_read(players_table, rec, "shotpower"),
        jumping = safe_read(players_table, rec, "jumping"),
        stamina = safe_read(players_table, rec, "stamina"),
        strength = safe_read(players_table, rec, "strength"),
        longshots = safe_read(players_table, rec, "longshots"),
        acceleration = safe_read(players_table, rec, "acceleration"),
        sprintspeed = safe_read(players_table, rec, "sprintspeed"),
        agility = safe_read(players_table, rec, "agility"),
        reactions = safe_read(players_table, rec, "reactions"),
        balance = safe_read(players_table, rec, "balance"),
        aggression = safe_read(players_table, rec, "aggression"),
        composure = safe_read(players_table, rec, "composure"),
        interceptions = safe_read(players_table, rec, "interceptions"),
        positioning = safe_read(players_table, rec, "positioning"),
        vision = safe_read(players_table, rec, "vision"),
        penalties = safe_read(players_table, rec, "penalties"),

        trait1 = safe_read(players_table, rec, "trait1"),
        trait2 = safe_read(players_table, rec, "trait2"),
        icontrait1 = safe_read(players_table, rec, "icontrait1"),
        icontrait2 = safe_read(players_table, rec, "icontrait2"),
        skillmoves = safe_read(players_table, rec, "skillmoves"),
        skillmoveslikelihood = safe_read(players_table, rec, "skillmoveslikelihood"),
        weakfootabilitytypecode = safe_read(players_table, rec, "weakfootabilitytypecode"),
        height = safe_read(players_table, rec, "height"),
        weight = safe_read(players_table, rec, "weight"),
        contractvaliduntil = safe_read(players_table, rec, "contractvaliduntil"),
        playerjointeamdate = safe_read(players_table, rec, "playerjointeamdate"),
        isretiring = bool01(safe_read(players_table, rec, "isretiring")),

        teamid = teamid,
        teamname = teamid and TEAM_NAME[teamid] or "",
        jerseynumber = tpl_row and tpl_row.jerseynumber or nil,
        squad_position = tpl_row and tpl_row.position or nil,
        leagueid = leagueid,
        leaguename = league and league.leaguename or "",
        league_level = league and league.level or nil,

        -- §15.3 form/injury: raw integers; encoding still TBD.
        form = tpl_row and tpl_row.form or nil,
        injury = tpl_row and tpl_row.injury or nil,
        leagueappearances = tpl_row and tpl_row.leagueappearances or nil,
        leaguegoals = tpl_row and tpl_row.leaguegoals or nil,
        leaguegoalsprevmatch = tpl_row and tpl_row.leaguegoalsprevmatch or nil,
        leaguegoalsprevthreematches = tpl_row and tpl_row.leaguegoalsprevthreematches or nil,
        yellows = tpl_row and tpl_row.yellows or nil,
        reds = tpl_row and tpl_row.reds or nil,
        istopscorer = tpl_row and bool01(tpl_row.istopscorer) or "",
        isamongtopscorers = tpl_row and bool01(tpl_row.isamongtopscorers) or "",
        isamongtopscorersinteam = tpl_row and bool01(tpl_row.isamongtopscorersinteam) or "",
    }

    local out = {}
    for i = 1, #columns do
        out[i] = csv_escape(row[columns[i]])
    end
    io.write(table.concat(out, ","))
    io.write("\n")
    row_count = row_count + 1
    rec = players_table:GetNextValidRecord()
end

io.close(file)
LOGGER:LogInfo(string.format("Done: %s (%d rows)", file_path, row_count))
