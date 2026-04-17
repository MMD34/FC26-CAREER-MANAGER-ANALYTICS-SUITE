-- ============================================================
-- [[ FC26 ULTRA DNA SYSTEM — V2 ]]
-- ============================================================
--
-- FLUJO (embudo de 10 pasos):
--   0  Lectura + stat_cache
--   1  Normalizaciones + semilla
--   2  Arquetipos como piso (base * factor)
--   3  Scanner técnico suma sobre el piso
--   4  Bonuses físicos, skill stars, pierna débil, pos2
--   4b Especialistas (pool_add_specialist, sin cap)
--   5  Filtro prereqs hard/soft
--   5b Filtro de altura para PS aéreos
--   6  Cultura (liga → nación → club)
--   7  Sinergias
--   8  SHOOTING_BOOST + ROLE_BOOST + ordenación + garantía tiro
--   9  Anomalía post-proceso
--  10  Hidden PS (slot adicional, trait2)
-- ============================================================
-- Posiciones FC26:
--   0=GK  1=SW  2=RWB  3=RB   4=RCB  5=CB   6=LCB
--   7=LB  8=LWB 9=RDM 10=CDM 11=LDM 12=RM  13=RCM
--  14=CM 15=LCM 16=LM 17=RAM 18=CAM 19=LAM 20=RF
--  21=CF 22=LF  23=RW 24=RS  25=ST  26=LS  27=LW
-- ============================================================

require 'imports/other/helpers'
require 'imports/other/playstyles_enum'

-- ============================================================
-- SECCIÓN 1: CONFIGURACIÓN GLOBAL
-- ============================================================
-- Todo valor marcado [CONFIGURABLE] puede modificarse.
-- Los valores por defecto están calibrados para FC26 estándar.
-- ============================================================
local CFG = {
    -- ── SCANNER ──────────────────────────────────────────────
    MIN_STAT_QUALIFY      = 60,    -- [CONFIGURABLE] Umbral mínimo de stat para campo
    MIN_STAT_GK           = 60,    -- [CONFIGURABLE] Umbral mínimo de stat para portero

    -- ── PS+ ──────────────────────────────────────────────────
    PLUS_STAT_NORMAL      = 85,    -- [CONFIGURABLE] Stat mínimo para icono PS+ normal
    PLUS_STAT_ELITE       = 88,    -- [CONFIGURABLE] Stat mínimo para icono PS+ élite

    -- ── LÍMITES Y PESOS ───────────────────────────────────────
    OFFROLE_MAX           = 2,     -- [CONFIGURABLE] Máximo PS fuera-de-rol por jugador
    ROLE_BOOST            = 300,   -- [CONFIGURABLE] Bonus en ordenación para PS de posición propia
    SHOOTING_BOOST        = 250,   -- [CONFIGURABLE] Bonus ADICIONAL para PS de tiro en posiciones
                                   --   atacantes/extremos/CAM/LM/RM (se suma al ROLE_BOOST si aplica)
    WONDERKID_DIFF        = 13,    -- [CONFIGURABLE] Gap OVR→POT mínimo para +1 PS bonus

    -- ── ARQUETIPOS ───────────────────────────────────────────
    ARCHETYPE_MIN_OVR     = 65,    -- [CONFIGURABLE] OVR mínimo para activar arquetipos
    ARCH_BASE_SCALE       = 100,   -- [CONFIGURABLE] Divisor del stat_factor del arquetipo
                                   --   factor = stat / ARCH_BASE_SCALE. Mínimo interno: 0.5

    -- ── ESPECIALISTAS ────────────────────────────────────────
    SPECIALIST_T1         = 85,    -- [CONFIGURABLE] Tier 1 → score 120 (sin cap)
    SPECIALIST_T2         = 90,    -- [CONFIGURABLE] Tier 2 → score 350 (sin cap)
    SPECIALIST_T3         = 95,    -- [CONFIGURABLE] Tier 3 → score 800 (sin cap)

    -- ── TECHO DE POOL ─────────────────────────────────────────
    MAX_POOL_SCORE        = 400,   -- [CONFIGURABLE] Máximo acumulado por PS en fuentes NORMALES
                                   --   Impide que Technical/Rapid/First Touch dominen siempre.
                                   --   Los especialistas tienen su propia función sin este cap.
    SOURCE_CAP            = 400,   -- [CONFIGURABLE] Máximo que UNA fuente puede aportar en una sola
                                   --   llamada normal. Igual a MAX_POOL_SCORE es coherente.

    -- ── FILTROS DE ALTURA ─────────────────────────────────────
    HEIGHT_MIN_AERIAL     = 180,   -- [CONFIGURABLE] Altura mínima absoluta para Aerial Fortress
                                   --   Por debajo → score = 0 sin excepciones
    HEIGHT_MIN_HEADER     = 175,   -- [CONFIGURABLE] Altura mínima absoluta para Precision Header
                                   --   Por debajo → score = 0 sin excepciones

    -- ── CULTURA ──────────────────────────────────────────────
    CULTURAL_CAP          = 100,   -- [CONFIGURABLE] Techo cultural por PS (acumulado)
    CULTURAL_DELTA_LEAGUE = 20,    -- [CONFIGURABLE] Bonus de liga
    CULTURAL_DELTA_NATION = 28,    -- [CONFIGURABLE] Bonus de nación
    CULTURAL_DELTA_CLUB   = 35,    -- [CONFIGURABLE] Bonus de club

    -- ── SINERGIAS ────────────────────────────────────────────
    SYNERGY_SCORE         = 22,    -- [CONFIGURABLE] Puntos añadidos por sinergia activa
    SYNERGY_THRESHOLD     = 80,    -- [CONFIGURABLE] Score mínimo en origen para disparar sinergia

    -- ── NORMALIZACIÓN ────────────────────────────────────────
    NORM_TOP_BONUS        = 3,     -- [CONFIGURABLE] Bonus ligero en ligas Tier 1 (muy suave)
    NORM_AGE_YOUNG        = 21,    -- [CONFIGURABLE] Edad máxima para bonus de velocidad joven
    NORM_AGE_VETERAN      = 30,    -- [CONFIGURABLE] Edad mínima para bonus de lectura veterano
    NORM_AGE_BONUS        = 2,     -- [CONFIGURABLE] Puntos de bonus de normalización edad

    -- ── ANOMALÍA ─────────────────────────────────────────────
    ANOMALY_CHANCE        = 20,   -- [CONFIGURABLE] 1 en N probabilidad de rasgo único
    ANOMALY_MIN_OVR       = 65,    -- [CONFIGURABLE] OVR mínimo para anomalía

    -- ── HIDDEN PS ────────────────────────────────────────────
    HIDDEN_PS_CHANCE      = 15,    -- [CONFIGURABLE] % de jugadores con hidden PS (career)

    -- ── LOGGING ──────────────────────────────────────────────
    LOG_ENABLED           = true,  -- [CONFIGURABLE] true = genera DNA_log.csv
    LOG_PATH              = "DNA_log.csv",
    LOG_TOP_SCORES        = 3,     -- [CONFIGURABLE] PS top a incluir en el log

    -- ── INTERNA ──────────────────────────────────────────────
    CURRENT_DAY_FC26      = 162200,-- Día FC26 base (no modificar salvo cambio de DB)
}

-- ============================================================
-- SECCIÓN 2: GRUPO DE TIRO Y POSICIONES PRIORITARIAS
-- ============================================================
-- SHOOTING_PS: conjunto de PS que representan capacidad de tiro.
-- Estos reciben SHOOTING_BOOST en atacantes/extremos/CAM/LM/RM.
--
-- SHOOTING_PRIORITY_POS: posiciones donde el tiro debe dominar
-- sobre cualquier otro PS cuando hay empate de score.
-- Incluye LM/RM porque muchos extremos están catalogados así.
--
-- [CONFIGURABLE] Añade/quita PS o posiciones.
-- ============================================================
local SHOOTING_PS = {
    [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,
    [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true,
    [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
    [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
    [ENUM_PLAYSTYLE1_GAMECHANGER]=true,
}
-- Orden de prioridad si hay que FORZAR PS de tiro fuera del pool
local SHOOTING_FORCE_ORDER = {
    ENUM_PLAYSTYLE1_FINESSE_SHOT,
    ENUM_PLAYSTYLE1_POWER_SHOT,
    ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
    ENUM_PLAYSTYLE1_CHIP_SHOT,
    ENUM_PLAYSTYLE1_GAMECHANGER,
}

local SHOOTING_PRIORITY_POS = {
    [12]=true,  -- RM
    [16]=true,  -- LM
    [17]=true,  -- RAM
    [18]=true,  -- CAM
    [19]=true,  -- LAM
    [20]=true,  -- RF
    [21]=true,  -- CF
    [22]=true,  -- LF
    [23]=true,  -- RW
    [24]=true,  -- RS
    [25]=true,  -- ST
    [26]=true,  -- LS
    [27]=true,  -- LW
}

-- ============================================================
-- SECCIÓN 3: TIERS DE LIGA (normalización suave)
-- ============================================================
-- Tier 1: ligas élite → NORM_TOP_BONUS en scanner (muy pequeño)
-- Tier 2/3: sin bonus. La diferencia es mínima para no castigar
-- outliers de ligas menores (un 85 de spd es 85 en cualquier liga).
-- [CONFIGURABLE] Añade league_id → tier.
-- ============================================================
local LEAGUE_TIER = {
    [13]  = 1,   -- Premier League
    [53]  = 1,   -- La Liga
    [19]  = 1,   -- Bundesliga
    [31]  = 1,   -- Serie A
    [16]  = 1,   -- Ligue 1
    [10]  = 1,   -- Eredivisie
    [308] = 1,   -- Liga Portugal
    [50]  = 2,   -- Scottish Premiership
    [4]   = 2,   -- Belgian Pro League
    [1]   = 2,   -- Danish Superliga
    [56]  = 2,   -- Swedish Allsvenskan
    [66]  = 2,   -- Polish Ekstraklasa
    [80]  = 2,   -- Austria Bundesliga
    [68]  = 2,   -- Turkish Süper Lig
    [189] = 2,   -- Swiss Super League
    [41]  = 2,   -- Norwegian Eliteserien
    [83]  = 2,   -- Korea K League 1
    [39]  = 2,   -- MLS
    [353] = 2,   -- Argentina Primera División 
    [350] = 2,   -- Saudi Pro League
    [14]  = 2,   -- Championship (Inglaterra)
    [60]  = 2,   -- England League One 
    [61]  = 2,   -- England League Two
    [65]  = 2,   -- Rep. Ireland Premier Division
    [76] = 2,   -- Rest of World
}
-- Cualquier liga no listada aquí = Tier 3 (sin bonus)

-- ============================================================
-- SECCIÓN 4: UMBRALES ELEVADOS EN EL SCANNER
-- ============================================================
-- Un PS aquí solo entra al pool si el stat supera ESTE umbral
-- (más alto que MIN_STAT_QUALIFY). Score calculado desde el mínimo.
-- [CONFIGURABLE] Sube para hacer PS más raros.
-- ============================================================
local PS_SCANNER_THRESH = {
    [ENUM_PLAYSTYLE1_TECHNICAL]  = 80,   -- Requiere dribbling alto para aparecer
    [ENUM_PLAYSTYLE1_QUICK_STEP] = 85,   -- Aceleración muy alta
    [ENUM_PLAYSTYLE1_TRICKSTER]  = 75,   -- Dribbling medio-alto
}

-- ============================================================
-- SECCIÓN 5: MAPEO stat → PS candidatos
-- ============================================================
-- [CONFIGURABLE] Añade o quita asociaciones.
-- ============================================================
local ATTR_MAP = {
    -- === REMATE ===
    finishing        = {ENUM_PLAYSTYLE1_FINESSE_SHOT,    ENUM_PLAYSTYLE1_CHIP_SHOT,
                        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT},
    shotpower        = {ENUM_PLAYSTYLE1_POWER_SHOT},
    longshots        = {ENUM_PLAYSTYLE1_POWER_SHOT,       ENUM_PLAYSTYLE1_CHIP_SHOT,       ENUM_PLAYSTYLE1_FINESSE_SHOT,       ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT},
    volleys          = {ENUM_PLAYSTYLE1_ACROBATIC},
    curve            = {ENUM_PLAYSTYLE1_FINESSE_SHOT,     ENUM_PLAYSTYLE1_GAMECHANGER},
    penalties        = {ENUM_PLAYSTYLE1_DEAD_BALL},
    freekickaccuracy = {ENUM_PLAYSTYLE1_DEAD_BALL},

    -- === PASE ===
    shortpassing     = {ENUM_PLAYSTYLE1_TIKI_TAKA,        ENUM_PLAYSTYLE1_INCISIVE_PASS,
                        ENUM_PLAYSTYLE1_PINGED_PASS},
    longpassing      = {ENUM_PLAYSTYLE1_LONG_BALL_PASS,   ENUM_PLAYSTYLE1_PINGED_PASS,
                        ENUM_PLAYSTYLE1_INVENTIVE},
    crossing         = {ENUM_PLAYSTYLE1_WHIPPED_PASS,     ENUM_PLAYSTYLE1_LONG_BALL_PASS},
    vision           = {ENUM_PLAYSTYLE1_INCISIVE_PASS,    ENUM_PLAYSTYLE1_TIKI_TAKA,
                        ENUM_PLAYSTYLE1_INVENTIVE},

    -- === REGATE / CONTROL ===
    dribbling        = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_TRICKSTER,
                        ENUM_PLAYSTYLE1_FIRST_TOUCH,      ENUM_PLAYSTYLE1_PRESS_PROVEN},
    ballcontrol      = {ENUM_PLAYSTYLE1_FIRST_TOUCH,      ENUM_PLAYSTYLE1_TECHNICAL},
    agility          = {ENUM_PLAYSTYLE1_QUICK_STEP,       ENUM_PLAYSTYLE1_TECHNICAL,       ENUM_PLAYSTYLE1_ACROBATIC},
    reactions        = {ENUM_PLAYSTYLE1_FIRST_TOUCH,      ENUM_PLAYSTYLE1_PRESS_PROVEN},
    positioning      = {ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT},

    -- === VELOCIDAD ===
    sprintspeed      = {ENUM_PLAYSTYLE1_RAPID},
    acceleration     = {ENUM_PLAYSTYLE1_QUICK_STEP},

    -- === DEFENSA ===
    interceptions     = {ENUM_PLAYSTYLE1_INTERCEPT,       ENUM_PLAYSTYLE1_ANTICIPATE},
    standingtackle    = {ENUM_PLAYSTYLE1_BLOCK,           ENUM_PLAYSTYLE1_BRUISER,
                         ENUM_PLAYSTYLE1_ENFORCER},
    slidingtackle     = {ENUM_PLAYSTYLE1_SLIDE_TACKLE,       ENUM_PLAYSTYLE1_BLOCK},
    defensiveawareness= {ENUM_PLAYSTYLE1_ANTICIPATE,      ENUM_PLAYSTYLE1_JOCKEY,       ENUM_PLAYSTYLE1_INTERCEPT,       ENUM_PLAYSTYLE1_ANTICIPATE},
    aggression        = {ENUM_PLAYSTYLE1_BRUISER,         ENUM_PLAYSTYLE1_JOCKEY,
                         ENUM_PLAYSTYLE1_ENFORCER,       ENUM_PLAYSTYLE1_SLIDE_TACKLE},

    -- === FÍSICO ===
    headingaccuracy  = {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_PRECISION_HEADER},
    jumping          = {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_PRECISION_HEADER},
    stamina          = {ENUM_PLAYSTYLE1_RELENTLESS},
    strength         = {ENUM_PLAYSTYLE1_BRUISER},

    -- === PORTERO (solo activos en is_gk) ===
    gkdiving         = {ENUM_PLAYSTYLE2_GK_FAR_REACH,     ENUM_PLAYSTYLE2_GK_FOOTWORK},
    gkreflexes       = {ENUM_PLAYSTYLE2_GK_FOOTWORK,      ENUM_PLAYSTYLE2_GK_FAR_REACH,
                        ENUM_PLAYSTYLE2_GK_DEFLECTOR},
    gkkicking        = {ENUM_PLAYSTYLE2_GK_FAR_THROW},
    gkpositioning    = {ENUM_PLAYSTYLE2_GK_RUSH_OUT},
    gkhandling       = {ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER, ENUM_PLAYSTYLE2_GK_DEFLECTOR},
}

-- ── Flags internos (no modificar) ───────────────────────────
local GK_STATS = {
    gkdiving=true,gkreflexes=true,gkkicking=true,
    gkpositioning=true,gkhandling=true,
}
local IS_GK_PS = {
    [ENUM_PLAYSTYLE2_GK_FAR_REACH]=true,[ENUM_PLAYSTYLE2_GK_FOOTWORK]=true,
    [ENUM_PLAYSTYLE2_GK_DEFLECTOR]=true,[ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER]=true,
    [ENUM_PLAYSTYLE2_GK_RUSH_OUT]=true, [ENUM_PLAYSTYLE2_GK_FAR_THROW]=true,
}
local PRECISION_PS = {
    [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,[ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
    [ENUM_PLAYSTYLE1_PINGED_PASS]=true, [ENUM_PLAYSTYLE1_INVENTIVE]=true,
}
local DEFENSIVE_ONLY_PS = { [ENUM_PLAYSTYLE1_ENFORCER]=true }
local DEF_SHOOT_BLOCK = {
    [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,    [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
    [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true, [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
    [ENUM_PLAYSTYLE1_ACROBATIC]=true,       [ENUM_PLAYSTYLE1_GAMECHANGER]=true,
}

-- ============================================================
-- SECCIÓN 6: PS FUERA DE ROL
-- ============================================================
-- [CONFIGURABLE] Añade o quita PS del bloque de cada posición.
-- ============================================================
local PS_CROSS_POS = {
    { pmin=2,  pmax=8,  offrole={
        [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,    [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
        [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true, [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
        [ENUM_PLAYSTYLE1_ACROBATIC]=true,       [ENUM_PLAYSTYLE1_GAMECHANGER]=true,
        [ENUM_PLAYSTYLE1_TRICKSTER]=true,
    }},
    { pmin=20, pmax=27, offrole={
        [ENUM_PLAYSTYLE1_SLIDE_TACKLE]=true,[ENUM_PLAYSTYLE1_BLOCK]=true,
        [ENUM_PLAYSTYLE1_JOCKEY]=true,      [ENUM_PLAYSTYLE1_INTERCEPT]=true,
        [ENUM_PLAYSTYLE1_ENFORCER]=true,
    }},
    { pmin=17, pmax=19, offrole={
        [ENUM_PLAYSTYLE1_INTERCEPT]=true,[ENUM_PLAYSTYLE1_ENFORCER]=true,
    }},
}

local function is_offrole(ps_id, pos)
    for _, rule in ipairs(PS_CROSS_POS) do
        if pos >= rule.pmin and pos <= rule.pmax and rule.offrole[ps_id] then
            return true
        end
    end
    return false
end

-- ============================================================
-- SECCIÓN 7: PRIORIDAD DE ROL POR POSICIÓN
-- ============================================================
-- PS que reciben ROLE_BOOST en la ordenación final.
-- Para SHOOTING_PRIORITY_POS los PS de tiro reciben ADEMÁS
-- el SHOOTING_BOOST (sección 2) de forma acumulativa.
-- [CONFIGURABLE] Añade/quita PS por posición.
-- ============================================================
local POS_ROLE_PS = {}
local function build_pos_role_ps()
    local t = {}
    t[0] = {
        [ENUM_PLAYSTYLE2_GK_FAR_REACH]=true,[ENUM_PLAYSTYLE2_GK_FOOTWORK]=true,
        [ENUM_PLAYSTYLE2_GK_DEFLECTOR]=true,[ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER]=true,
        [ENUM_PLAYSTYLE2_GK_RUSH_OUT]=true, [ENUM_PLAYSTYLE2_GK_FAR_THROW]=true,
    }
    local cb = {
        [ENUM_PLAYSTYLE1_BLOCK]=true,           [ENUM_PLAYSTYLE1_INTERCEPT]=true,
        [ENUM_PLAYSTYLE1_ANTICIPATE]=true,      [ENUM_PLAYSTYLE1_BRUISER]=true,
        [ENUM_PLAYSTYLE1_AERIAL_FORTRESS]=true, [ENUM_PLAYSTYLE1_PRECISION_HEADER]=true,
        [ENUM_PLAYSTYLE1_ENFORCER]=true,        [ENUM_PLAYSTYLE1_SLIDE_TACKLE]=true,
        [ENUM_PLAYSTYLE1_JOCKEY]=true,          [ENUM_PLAYSTYLE1_LONG_THROW]=true,
        [ENUM_PLAYSTYLE1_LONG_BALL_PASS]=true,  [ENUM_PLAYSTYLE1_RELENTLESS]=true,
    }
    for _,p in ipairs({1,4,5,6}) do t[p]=cb end
    local fb = {
        [ENUM_PLAYSTYLE1_WHIPPED_PASS]=true,[ENUM_PLAYSTYLE1_RAPID]=true,
        [ENUM_PLAYSTYLE1_QUICK_STEP]=true,  [ENUM_PLAYSTYLE1_JOCKEY]=true,
        [ENUM_PLAYSTYLE1_INTERCEPT]=true,   [ENUM_PLAYSTYLE1_RELENTLESS]=true,
        [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true, [ENUM_PLAYSTYLE1_TRICKSTER]=true,
        [ENUM_PLAYSTYLE1_LONG_THROW]=true,  [ENUM_PLAYSTYLE1_PRESS_PROVEN]=true,
        [ENUM_PLAYSTYLE1_ANTICIPATE]=true,  [ENUM_PLAYSTYLE1_BRUISER]=true,
        [ENUM_PLAYSTYLE1_SLIDE_TACKLE]=true,
    }
    for _,p in ipairs({2,3,7,8}) do t[p]=fb end
    local cdm = {
        [ENUM_PLAYSTYLE1_PRESS_PROVEN]=true,[ENUM_PLAYSTYLE1_INTERCEPT]=true,
        [ENUM_PLAYSTYLE1_ANTICIPATE]=true,  [ENUM_PLAYSTYLE1_JOCKEY]=true,
        [ENUM_PLAYSTYLE1_RELENTLESS]=true,  [ENUM_PLAYSTYLE1_BLOCK]=true,
        [ENUM_PLAYSTYLE1_ENFORCER]=true,    [ENUM_PLAYSTYLE1_SLIDE_TACKLE]=true,
        [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,   [ENUM_PLAYSTYLE1_BRUISER]=true,
        [ENUM_PLAYSTYLE1_LONG_THROW]=true,
    }
    for _,p in ipairs({9,10,11}) do t[p]=cdm end
    local cm = {
        [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,     [ENUM_PLAYSTYLE1_INCISIVE_PASS]=true,
        [ENUM_PLAYSTYLE1_PINGED_PASS]=true,   [ENUM_PLAYSTYLE1_PRESS_PROVEN]=true,
        [ENUM_PLAYSTYLE1_INTERCEPT]=true,     [ENUM_PLAYSTYLE1_RELENTLESS]=true,
        [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,   [ENUM_PLAYSTYLE1_INVENTIVE]=true,
        [ENUM_PLAYSTYLE1_LONG_BALL_PASS]=true,[ENUM_PLAYSTYLE1_DEAD_BALL]=true,
    }
    for _,p in ipairs({13,14,15}) do t[p]=cm end
    -- LM/RM: rol mixto (extremo catalogado como medio)
    -- Shooting PS también aparecen en su tabla de rol, potenciados
    -- por SHOOTING_BOOST vía SHOOTING_PRIORITY_POS
    local wm = {
        [ENUM_PLAYSTYLE1_RAPID]=true,          [ENUM_PLAYSTYLE1_TRICKSTER]=true,
        [ENUM_PLAYSTYLE1_WHIPPED_PASS]=true,   [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,
        [ENUM_PLAYSTYLE1_TECHNICAL]=true,      [ENUM_PLAYSTYLE1_PRESS_PROVEN]=true,
        [ENUM_PLAYSTYLE1_QUICK_STEP]=true,     [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,
        [ENUM_PLAYSTYLE1_DEAD_BALL]=true,
        -- Tiro explícito en rol (reforzado por SHOOTING_BOOST además)
        [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,   [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true,
        [ENUM_PLAYSTYLE1_GAMECHANGER]=true,    [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
        [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
    }
    for _,p in ipairs({12,16}) do t[p]=wm end
    local cam = {
        [ENUM_PLAYSTYLE1_INCISIVE_PASS]=true,   [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,
        [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,       [ENUM_PLAYSTYLE1_TECHNICAL]=true,
        [ENUM_PLAYSTYLE1_PINGED_PASS]=true,     [ENUM_PLAYSTYLE1_GAMECHANGER]=true,
        [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,     [ENUM_PLAYSTYLE1_INVENTIVE]=true,
        [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true, [ENUM_PLAYSTYLE1_DEAD_BALL]=true,
        [ENUM_PLAYSTYLE1_QUICK_STEP]=true,      [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
        [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
    }
    for _,p in ipairs({17,18,19}) do t[p]=cam end
    local wing = {
        [ENUM_PLAYSTYLE1_RAPID]=true,           [ENUM_PLAYSTYLE1_TECHNICAL]=true,
        [ENUM_PLAYSTYLE1_QUICK_STEP]=true,      [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,
        [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true, [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,
        [ENUM_PLAYSTYLE1_GAMECHANGER]=true,     [ENUM_PLAYSTYLE1_TRICKSTER]=true,
        [ENUM_PLAYSTYLE1_DEAD_BALL]=true,       [ENUM_PLAYSTYLE1_ACROBATIC]=true,
        [ENUM_PLAYSTYLE1_WHIPPED_PASS]=true,    [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,
        [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
    }
    for _,p in ipairs({23,27}) do t[p]=wing end
    local cf = {
        [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,    [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true,
        [ENUM_PLAYSTYLE1_TECHNICAL]=true,       [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,
        [ENUM_PLAYSTYLE1_GAMECHANGER]=true,     [ENUM_PLAYSTYLE1_RAPID]=true,
        [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,       [ENUM_PLAYSTYLE1_ACROBATIC]=true,
        [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,       [ENUM_PLAYSTYLE1_QUICK_STEP]=true,
        [ENUM_PLAYSTYLE1_DEAD_BALL]=true,       [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
    }
    for _,p in ipairs({20,21,22}) do t[p]=cf end
    local st = {
        [ENUM_PLAYSTYLE1_FINESSE_SHOT]=true,    [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]=true,
        [ENUM_PLAYSTYLE1_QUICK_STEP]=true,      [ENUM_PLAYSTYLE1_TECHNICAL]=true,
        [ENUM_PLAYSTYLE1_RAPID]=true,           [ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,
        [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,       [ENUM_PLAYSTYLE1_POWER_SHOT]=true,
        [ENUM_PLAYSTYLE1_ACROBATIC]=true,       [ENUM_PLAYSTYLE1_AERIAL_FORTRESS]=true,
        [ENUM_PLAYSTYLE1_CHIP_SHOT]=true,       [ENUM_PLAYSTYLE1_GAMECHANGER]=true,
        [ENUM_PLAYSTYLE1_DEAD_BALL]=true,       [ENUM_PLAYSTYLE1_PRECISION_HEADER]=true,
    }
    for _,p in ipairs({24,25,26}) do t[p]=st end
    return t
end
POS_ROLE_PS = build_pos_role_ps()

-- ============================================================
-- SECCIÓN 8: SINERGIAS
-- ============================================================
-- [CONFIGURABLE] Añade pares origen → destino.
-- ============================================================
local SYNERGIES = {
    [ENUM_PLAYSTYLE1_TIKI_TAKA]       = ENUM_PLAYSTYLE1_FIRST_TOUCH,
    [ENUM_PLAYSTYLE1_INCISIVE_PASS]   = ENUM_PLAYSTYLE1_PINGED_PASS,
    [ENUM_PLAYSTYLE1_WHIPPED_PASS]    = ENUM_PLAYSTYLE1_LONG_BALL_PASS,
    [ENUM_PLAYSTYLE1_INVENTIVE]       = ENUM_PLAYSTYLE1_TIKI_TAKA,
    [ENUM_PLAYSTYLE1_TRICKSTER]       = ENUM_PLAYSTYLE1_FIRST_TOUCH,
    [ENUM_PLAYSTYLE1_TECHNICAL]       = ENUM_PLAYSTYLE1_TRICKSTER,
    [ENUM_PLAYSTYLE1_ACROBATIC]       = ENUM_PLAYSTYLE1_TECHNICAL,
    [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT] = ENUM_PLAYSTYLE1_FINESSE_SHOT,
    [ENUM_PLAYSTYLE1_INTERCEPT]       = ENUM_PLAYSTYLE1_ANTICIPATE,
    [ENUM_PLAYSTYLE1_PRESS_PROVEN]    = ENUM_PLAYSTYLE1_INTERCEPT,
    [ENUM_PLAYSTYLE1_SLIDE_TACKLE]    = ENUM_PLAYSTYLE1_BLOCK,
    [ENUM_PLAYSTYLE1_BRUISER]         = ENUM_PLAYSTYLE1_AERIAL_FORTRESS,
    [ENUM_PLAYSTYLE1_AERIAL_FORTRESS] = ENUM_PLAYSTYLE1_PRECISION_HEADER,
    [ENUM_PLAYSTYLE1_RELENTLESS]      = ENUM_PLAYSTYLE1_PRESS_PROVEN,
    [ENUM_PLAYSTYLE1_ENFORCER]        = ENUM_PLAYSTYLE1_BRUISER,
    [ENUM_PLAYSTYLE1_LONG_THROW]      = ENUM_PLAYSTYLE1_AERIAL_FORTRESS,
    [ENUM_PLAYSTYLE1_LONG_BALL_PASS]  = ENUM_PLAYSTYLE1_LONG_THROW,
    [ENUM_PLAYSTYLE1_DEAD_BALL]       = ENUM_PLAYSTYLE1_FINESSE_SHOT,
    [ENUM_PLAYSTYLE1_FINESSE_SHOT]    = ENUM_PLAYSTYLE1_CHIP_SHOT,
}

-- ============================================================
-- SECCIÓN 9: RIVALIDADES
-- ============================================================
-- [CONFIGURABLE] Añade pares teamid → ps_id.
-- ============================================================
local RIVALRIES = {
    [241]   ={style=ENUM_PLAYSTYLE1_BRUISER},
    [243]   ={style=ENUM_PLAYSTYLE1_TIKI_TAKA},
    [9]     ={style=ENUM_PLAYSTYLE1_JOCKEY},
    [11]    ={style=ENUM_PLAYSTYLE1_RELENTLESS},
    [45]    ={style=ENUM_PLAYSTYLE1_TRICKSTER},
    [52]    ={style=ENUM_PLAYSTYLE1_INTERCEPT},
    [115841]={style=ENUM_PLAYSTYLE1_RAPID},
    [78]    ={style=ENUM_PLAYSTYLE1_BRUISER},
    [86]    ={style=ENUM_PLAYSTYLE1_PRESS_PROVEN},
}

-- ============================================================
-- SECCIÓN 10: PREREQUISITOS (hard / soft)
-- ============================================================
-- hard_min → por debajo, score = 0 (elimina PS del pool)
-- min      → entre hard_min y min: score *= 0.5 (penaliza)
-- alt_*    → stat alternativo; lógica OR salvo require_both=true
--
-- [CONFIGURABLE] Sube hard_min para PS más exigentes.
-- Baja min para la zona blanda más amplia.
-- ============================================================
local PS_PREREQS = {
    [ENUM_PLAYSTYLE1_AERIAL_FORTRESS]  = {
        stat="headingaccuracy", hard_min=68, min=74,
        -- Nota: la altura se filtra por separado (HEIGHT_MIN_AERIAL)
        -- no aquí, para que el hard filter sea más explícito.
    },
    [ENUM_PLAYSTYLE1_PRECISION_HEADER] = {
        stat="headingaccuracy", hard_min=65, min=74,
        -- Altura filtrada por HEIGHT_MIN_HEADER en paso 5b
    },
    [ENUM_PLAYSTYLE1_FINESSE_SHOT]     = {
        stat="finishing",       hard_min=70, min=80,
        alt_stat="curve",       alt_hard_min=65, alt_min=75,
    },
    [ENUM_PLAYSTYLE1_CHIP_SHOT]        = {
        stat="finishing",       hard_min=68, min=78,
    },
    [ENUM_PLAYSTYLE1_POWER_SHOT]       = {
        stat="shotpower",       hard_min=70, min=80,
    },
    [ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT]  = {
        stat="finishing",       hard_min=70, min=80,
    },
    [ENUM_PLAYSTYLE1_ACROBATIC]        = {
        stat="volleys",         hard_min=63, min=73,
        alt_stat="agility",     alt_hard_min=60, alt_min=70,
    },
    [ENUM_PLAYSTYLE1_GAMECHANGER] = {
        stat= "finishing",    hard_min=65, min=76,
        alt_stat= "curve",        alt_hard_min=60, alt_min=70,
        alt_stat2= "skillmoves",   alt_hard_min2=3, alt_min2=4,
        require_all = true,
    },
    [ENUM_PLAYSTYLE1_DEAD_BALL]        = {
        stat="freekickaccuracy", hard_min=60, min=73,
    },
    [ENUM_PLAYSTYLE1_TIKI_TAKA]        = {
        stat="shortpassing",    hard_min=73, min=83,
    },
    [ENUM_PLAYSTYLE1_INCISIVE_PASS]    = {
        stat="shortpassing",    hard_min=68, min=78,
    },
    [ENUM_PLAYSTYLE1_PINGED_PASS]      = {
        stat="longpassing",     hard_min=68, min=78,
        alt_stat="shortpassing", alt_hard_min=70, alt_min=80,
    },
    [ENUM_PLAYSTYLE1_LONG_BALL_PASS]   = {
        stat="longpassing",     hard_min=68, min=78,
    },
    [ENUM_PLAYSTYLE1_WHIPPED_PASS]     = {
        stat="crossing",        hard_min=70, min=80,
    },
    [ENUM_PLAYSTYLE1_INVENTIVE]        = {
        stat="vision",          hard_min=68, min=78,
        alt_stat="longpassing", alt_hard_min=63, alt_min=73,
        alt_stat2= "skillmoves",   alt_hard_min2=3, alt_min2=4,
        require_all = true,
    },
    [ENUM_PLAYSTYLE1_TRICKSTER]        = {
        stat="dribbling",       hard_min=68, min=78,
        alt_stat= "skillmoves",   alt_hard_min=3, alt_min=4,
        require_both=true,
    },
    [ENUM_PLAYSTYLE1_TECHNICAL]        = {
        stat="dribbling",       hard_min=75, min=83,
    },
    [ENUM_PLAYSTYLE1_PRESS_PROVEN]     = {
        stat="stamina",         hard_min=68, min=78,
    },
    [ENUM_PLAYSTYLE1_RAPID]            = {
        stat="sprintspeed",     hard_min=76, min=83,
        alt_stat="dribbling",   alt_hard_min=60, alt_min=70,
        require_both=true,
    },
    [ENUM_PLAYSTYLE1_QUICK_STEP]       = {
        stat="acceleration",    hard_min=78, min=86,
    },
    [ENUM_PLAYSTYLE1_INTERCEPT]        = {
        stat="interceptions",   hard_min=70, min=80,
    },
    [ENUM_PLAYSTYLE1_ANTICIPATE]       = {
        stat="interceptions",   hard_min=65, min=76,
        alt_stat="defensiveawareness", alt_hard_min=63, alt_min=73,
    },
    [ENUM_PLAYSTYLE1_JOCKEY]           = {
        stat="interceptions",   hard_min=63, min=75,
        alt_stat="defensiveawareness", alt_hard_min=60, alt_min=70,
    },
    [ENUM_PLAYSTYLE1_BLOCK]            = {
        stat="standingtackle",  hard_min=70, min=80,
    },
    [ENUM_PLAYSTYLE1_SLIDE_TACKLE]     = {
        stat="slidingtackle",   hard_min=73, min=83,
    },
    [ENUM_PLAYSTYLE1_BRUISER]          = {
        stat="strength",        hard_min=68, min=78,
    },
    [ENUM_PLAYSTYLE1_ENFORCER]         = {
        stat="standingtackle",  hard_min=68, min=78,
        alt_stat="aggression",  alt_hard_min=66, alt_min=76,
    },
    [ENUM_PLAYSTYLE1_LONG_THROW]       = {
        stat="strength",        hard_min=63, min=73,
        alt_stat="height",      alt_hard_min=178, alt_min=183,
    },
    [ENUM_PLAYSTYLE1_RELENTLESS]       = {
        stat="stamina",         hard_min=73, min=83,
    },
    [ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER] = {stat="height",      hard_min=178, min=183},
    [ENUM_PLAYSTYLE2_GK_FAR_THROW]     = {stat="height",      hard_min=175, min=180},
    [ENUM_PLAYSTYLE2_GK_RUSH_OUT]      = {stat="sprintspeed", hard_min=40,  min=50},
    [ENUM_PLAYSTYLE2_GK_FAR_REACH]     = {stat="gkdiving",    hard_min=65,  min=76},
    [ENUM_PLAYSTYLE2_GK_FOOTWORK]      = {stat="gkreflexes",  hard_min=60,  min=70},
}

-- ============================================================
-- SECCIÓN 11: ARQUETIPOS FC26
-- ============================================================
-- score_aportado = base * factor(stat_cache)
-- factor = stat_relevante / ARCH_BASE_SCALE  (mínimo 0.5)
-- Ejemplo: Finisher con finishing=82 → LDS: 65*(82/100)=53
--          Finisher con finishing=65 → LDS: 65*(65/100)=42
-- El arquetipo define dirección; los stats controlan la magnitud.
--
-- [CONFIGURABLE]
--   qualify → sube/baja umbrales de activación
--   base    → hace el arquetipo más/menos influyente
--   valid   → cambia qué posiciones pueden tener el arquetipo
-- ============================================================
local ARCHETYPES = {
    -- ── ATACANTES ────────────────────────────────────────────
    {
        name="Magician", -- Ronaldinho: regate, control, creatividad
        valid=function(p) return (p>=17 and p<=27) or p==12 or p==16 end,
        qualify=function(sc) return sc.dribbling>=82 and sc.agility>=75 end,
        bonus={
            {ENUM_PLAYSTYLE1_TECHNICAL,    65, function(sc) return sc.dribbling/100 end},
            {ENUM_PLAYSTYLE1_FINESSE_SHOT, 55, function(sc) return (sc.finishing+sc.curve)/200 end},
            {ENUM_PLAYSTYLE1_TRICKSTER,    45, function(sc) return sc.dribbling/100 end},
            {ENUM_PLAYSTYLE1_FIRST_TOUCH,  35, function(sc) return (sc.dribbling+sc.reactions)/200 end},
        },
    },
    {
        name="Finisher", -- Cristiano Ronaldo: goles, 1v1
        valid=function(p) return (p>=20 and p<=27) or p==18 or p==19 end,
        qualify=function(sc) return sc.finishing>=82 and sc.reactions>=74 end,
        bonus={
            {ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT, 65, function(sc) return sc.finishing/100 end},
            {ENUM_PLAYSTYLE1_FIRST_TOUCH,     55, function(sc) return sc.reactions/100 end},
            {ENUM_PLAYSTYLE1_FINESSE_SHOT,    55, function(sc) return (sc.finishing+sc.curve)/200 end},
            {ENUM_PLAYSTYLE1_GAMECHANGER,     25, function(sc) return (sc.finishing+sc.curve)/200 end},
        },
    },
    {
        name="Target", -- Zlatan: físico, dominio aéreo
        valid=function(p) return p>=20 and p<=27 end,
        qualify=function(sc)
            return sc.strength>=78 and sc.headingaccuracy>=76 and
                   (sc.height>=183 or sc.jumping>=76)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_POWER_SHOT,       65, function(sc) return (sc.shotpower+sc.strength)/200 end},
            {ENUM_PLAYSTYLE1_PRECISION_HEADER, 55, function(sc) return sc.headingaccuracy/100 end},
            {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  50, function(sc) return sc.headingaccuracy/100 end},
            {ENUM_PLAYSTYLE1_BRUISER,          35, function(sc) return sc.strength/100 end},
        },
    },
    -- ── CENTROCAMPISTAS ──────────────────────────────────────
    {
        name="Recycler", -- Michael Essien: recuperar y distribuir
        valid=function(p) return p>=9 and p<=16 end,
        qualify=function(sc) return sc.stamina>=80 and sc.interceptions>=76 end,
        bonus={
            {ENUM_PLAYSTYLE1_PRESS_PROVEN, 65, function(sc) return sc.stamina/100 end},
            {ENUM_PLAYSTYLE1_INTERCEPT,    55, function(sc) return sc.interceptions/100 end},
            {ENUM_PLAYSTYLE1_RELENTLESS,   45, function(sc) return sc.stamina/100 end},
            {ENUM_PLAYSTYLE1_ANTICIPATE,   30, function(sc) return sc.defensiveawareness/100 end},
        },
    },
    {
        name="Maestro", -- Toni Kroos: tempo, orchestrar ataques
        valid=function(p) return p>=9 and p<=18 end,
        qualify=function(sc)
            return sc.shortpassing>=83 and sc.longpassing>=78 and sc.vision>=78
        end,
        bonus={
            {ENUM_PLAYSTYLE1_TIKI_TAKA,      65, function(sc) return sc.shortpassing/100 end},
            {ENUM_PLAYSTYLE1_PINGED_PASS,    55, function(sc) return (sc.longpassing+sc.shortpassing)/200 end},
            {ENUM_PLAYSTYLE1_LONG_BALL_PASS, 45, function(sc) return sc.longpassing/100 end},
            {ENUM_PLAYSTYLE1_INCISIVE_PASS,  35, function(sc) return sc.vision/100 end},
        },
    },
    {
        name="Creator", -- Andrés Iniesta: pases precisos
        valid=function(p) return p>=9 and p<=19 end,
        qualify=function(sc)
            return sc.vision>=80 and sc.shortpassing>=78 and
                   (sc.dribbling>=75 or sc.longpassing>=74)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_INCISIVE_PASS, 65, function(sc) return sc.vision/100 end},
            {ENUM_PLAYSTYLE1_INVENTIVE,     55, function(sc) return (sc.vision+sc.longpassing)/200 end},
            {ENUM_PLAYSTYLE1_TIKI_TAKA,     40, function(sc) return sc.shortpassing/100 end},
            {ENUM_PLAYSTYLE1_TECHNICAL,     35, function(sc) return sc.dribbling/100 end},
        },
    },
    {
        name="Spark", -- Luís Figo: velocidad explosiva
        valid=function(p)
            return p==12 or p==16 or p==23 or p==27 or (p>=13 and p<=15)
        end,
        qualify=function(sc)
            return sc.sprintspeed>=82 and sc.acceleration>=79 and
                   (sc.dribbling>=74 or sc.crossing>=72)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_RAPID,        65, function(sc) return (sc.sprintspeed+sc.acceleration)/200 end},
            {ENUM_PLAYSTYLE1_TRICKSTER,    55, function(sc) return sc.dribbling/100 end},
            {ENUM_PLAYSTYLE1_QUICK_STEP,   45, function(sc) return sc.acceleration/100 end},
            {ENUM_PLAYSTYLE1_WHIPPED_PASS, 35, function(sc) return sc.crossing/100 end},
        },
    },
    -- ── DEFENSAS ─────────────────────────────────────────────
    {
        name="Progressor", -- Fernando Hierro: CB que inicia ataques
        valid=function(p) return p>=2 and p<=11 end,
        qualify=function(sc)
            return sc.longpassing>=76 and (sc.vision>=68 or sc.defensiveawareness>=75)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_LONG_BALL_PASS, 65, function(sc) return sc.longpassing/100 end},
            {ENUM_PLAYSTYLE1_ANTICIPATE,     55, function(sc) return sc.defensiveawareness/100 end},
            {ENUM_PLAYSTYLE1_INTERCEPT,      35, function(sc) return sc.interceptions/100 end},
            {ENUM_PLAYSTYLE1_PINGED_PASS,    30, function(sc) return (sc.longpassing+sc.vision)/200 end},
        },
    },
    {
        name="Boss", -- Nemanja Vidić: fuerza, tackles
        valid=function(p) return p>=2 and p<=11 end,
        qualify=function(sc)
            return sc.strength>=80 and (sc.standingtackle>=77 or sc.headingaccuracy>=75)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_BRUISER,         65, function(sc) return sc.strength/100 end},
            {ENUM_PLAYSTYLE1_AERIAL_FORTRESS, 55, function(sc) return sc.headingaccuracy/100 end},
            {ENUM_PLAYSTYLE1_ENFORCER,        50, function(sc) return (sc.standingtackle+sc.aggression)/200 end},
            {ENUM_PLAYSTYLE1_BLOCK,           35, function(sc) return sc.standingtackle/100 end},
        },
    },
    {
        name="Engine", -- Park Ji Sung: stamina
        valid=function(p) return p>=2 and p<=16 end,
        qualify=function(sc)
            return sc.stamina>=82 and (sc.interceptions>=72 or sc.defensiveawareness>=75)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_JOCKEY,       65, function(sc) return (sc.interceptions+sc.defensiveawareness)/200 end},
            {ENUM_PLAYSTYLE1_RELENTLESS,   55, function(sc) return sc.stamina/100 end},
            {ENUM_PLAYSTYLE1_PRESS_PROVEN, 40, function(sc) return sc.stamina/100 end},
            {ENUM_PLAYSTYLE1_INTERCEPT,    30, function(sc) return sc.interceptions/100 end},
        },
    },
    {
        name="Marauder", -- Cafu: lateral veloz
        valid=function(p)
            return p==2 or p==3 or p==7 or p==8 or p==12 or p==16
        end,
        qualify=function(sc)
            return sc.sprintspeed>=79 and sc.crossing>=72 and
                   (sc.acceleration>=77 or sc.stamina>=74)
        end,
        bonus={
            {ENUM_PLAYSTYLE1_WHIPPED_PASS, 65, function(sc) return sc.crossing/100 end},
            {ENUM_PLAYSTYLE1_QUICK_STEP,   55, function(sc) return sc.acceleration/100 end},
            {ENUM_PLAYSTYLE1_RAPID,        45, function(sc) return sc.sprintspeed/100 end},
            {ENUM_PLAYSTYLE1_RELENTLESS,   30, function(sc) return sc.stamina/100 end},
        },
    },
    -- ── PORTEROS ─────────────────────────────────────────────
    {
        name="ShotStopper", -- Oliver Kahn: paradas difíciles
        valid=function(p) return p==0 end,
        qualify=function(sc)
            return sc.gkreflexes>=73 and (sc.gkdiving>=70 or sc.composure>=65)
        end,
        bonus={
            {ENUM_PLAYSTYLE2_GK_FOOTWORK,  70, function(sc) return sc.gkreflexes/100 end},
            {ENUM_PLAYSTYLE2_GK_FAR_REACH, 60, function(sc) return sc.gkdiving/100 end},
            {ENUM_PLAYSTYLE2_GK_DEFLECTOR, 45, function(sc) return (sc.gkreflexes+sc.gkdiving)/200 end},
        },
    },
    {
        name="SweeperKeeper", -- Lev Yashin: balonparado, área extendida
        valid=function(p) return p==0 end,
        qualify=function(sc)
            return sc.gkhandling>=73 and (sc.gkpositioning>=70 or sc.gkkicking>=66)
        end,
        bonus={
            {ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER, 70, function(sc) return sc.gkhandling/100 end},
            {ENUM_PLAYSTYLE2_GK_RUSH_OUT,      60, function(sc) return sc.gkpositioning/100 end},
            {ENUM_PLAYSTYLE2_GK_FAR_THROW,     35, function(sc) return sc.gkkicking/100 end},
        },
    },
}

-- ============================================================
-- SECCIÓN 12: DNA CULTURAL
-- ============================================================
-- [CONFIGURABLE] Añade nation_id, team_id o league_id → {PS1, PS2}
-- ============================================================
local NATION_DNA = {
    -- === EUROPA OCCIDENTAL ===
    [45]  = {ENUM_PLAYSTYLE1_TIKI_TAKA,       ENUM_PLAYSTYLE1_FIRST_TOUCH},    -- España
    [18]  = {ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_TECHNICAL},      -- Francia
    [14]  = {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_BRUISER},        -- Inglaterra
    [21]  = {ENUM_PLAYSTYLE1_POWER_SHOT,       ENUM_PLAYSTYLE1_RELENTLESS},     -- Alemania
    [27]  = {ENUM_PLAYSTYLE1_INTERCEPT,        ENUM_PLAYSTYLE1_JOCKEY},         -- Italia
    [38]  = {ENUM_PLAYSTYLE1_TRICKSTER,        ENUM_PLAYSTYLE1_POWER_SHOT},     -- Portugal
    [34]  = {ENUM_PLAYSTYLE1_TIKI_TAKA,        ENUM_PLAYSTYLE1_INCISIVE_PASS},  -- Países Bajos
    [7]   = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_TIKI_TAKA},      -- Bélgica
    [46]  = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_RELENTLESS},     -- Suecia
    [36]  = {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_LONG_BALL_PASS}, -- Noruega
    [42]  = {ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_RELENTLESS},     -- Escocia
    [25]  = {ENUM_PLAYSTYLE1_RELENTLESS,       ENUM_PLAYSTYLE1_BRUISER},        -- Rep. Irlanda
    [50]  = {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_RELENTLESS},     -- Gales
    [35]  = {ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_BLOCK},          -- Irlanda del Norte
    [13]  = {ENUM_PLAYSTYLE1_JOCKEY,           ENUM_PLAYSTYLE1_ANTICIPATE},     -- Dinamarca
    [47]  = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_INCISIVE_PASS},  -- Suiza
    [17]  = {ENUM_PLAYSTYLE1_INCISIVE_PASS,    ENUM_PLAYSTYLE1_ANTICIPATE},     -- Finlandia
    [10]  = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_INCISIVE_PASS},  -- Croacia
    [37]  = {ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RELENTLESS},     -- Polonia
    [43]  = {ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RELENTLESS},     -- Eslovaquia
    [12]  = {ENUM_PLAYSTYLE1_INCISIVE_PASS,    ENUM_PLAYSTYLE1_LONG_BALL_PASS}, -- Rep. Checa
    [9]   = {ENUM_PLAYSTYLE1_INTERCEPT,        ENUM_PLAYSTYLE1_BLOCK},          -- Bulgaria
    [23]  = {ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_AERIAL_FORTRESS},-- Hungría
    [49]  = {ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RELENTLESS},     -- Ucrania
    [51]  = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_FIRST_TOUCH},    -- Serbia
    [48]  = {ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_POWER_SHOT},     -- Turquía

    -- === SUDAMÉRICA ===
    [54]  = {ENUM_PLAYSTYLE1_TRICKSTER,        ENUM_PLAYSTYLE1_TECHNICAL},      -- Brasil
    [52]  = {ENUM_PLAYSTYLE1_INCISIVE_PASS,    ENUM_PLAYSTYLE1_PRESS_PROVEN},   -- Argentina
    [60]  = {ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_RELENTLESS},     -- Uruguay
    [55]  = {ENUM_PLAYSTYLE1_FIRST_TOUCH,      ENUM_PLAYSTYLE1_PINGED_PASS},    -- Chile
    [56]  = {ENUM_PLAYSTYLE1_TRICKSTER,        ENUM_PLAYSTYLE1_FIRST_TOUCH},    -- Colombia
    [57]  = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_TIKI_TAKA},      -- Ecuador
    [59]  = {ENUM_PLAYSTYLE1_FIRST_TOUCH,      ENUM_PLAYSTYLE1_TRICKSTER},      -- Perú

    -- === NORTEAMÉRICA / CARIBE ===
    [83]  = {ENUM_PLAYSTYLE1_FIRST_TOUCH,      ENUM_PLAYSTYLE1_TRICKSTER},      -- México
    [95]  = {ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_PRESS_PROVEN},   -- Estados Unidos
    [70]  = {ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_TECHNICAL},      -- Canadá
    -- [V10] Curaçao corregida: id 74 era Dominica (DB), Curaçao real = 85
    [85]  = {ENUM_PLAYSTYLE1_TRICKSTER,        ENUM_PLAYSTYLE1_RAPID},          -- Curaçao

    -- === ÁFRICA ===
    [133] = {ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_TECHNICAL},      -- Nigeria
    [103] = {ENUM_PLAYSTYLE1_TRICKSTER,        ENUM_PLAYSTYLE1_TECHNICAL},      -- Camerún
    [117] = {ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_TRICKSTER},      -- Ghana
    [108] = {ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_TRICKSTER},      -- Costa de Marfil
    [136] = {ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_BRUISER},        -- Senegal
    [129] = {ENUM_PLAYSTYLE1_INTERCEPT,        ENUM_PLAYSTYLE1_BLOCK},          -- Marruecos
    [140] = {ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RELENTLESS},     -- Sudáfrica

    -- === ASIA / OCEANÍA ===
    [163] = {ENUM_PLAYSTYLE1_TIKI_TAKA,        ENUM_PLAYSTYLE1_PRESS_PROVEN},   -- Japón
    [167] = {ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RELENTLESS},     -- Corea del Sur
    [195] = {ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_BRUISER},        -- Australia
}

local function build_club_dna()
    local t={}
    local function add(id,ps1,ps2)
        if t[id] then return end; t[id]={ps1,ps2}
    end
    -- *** ESPAÑA ***
    add(241,    ENUM_PLAYSTYLE1_TIKI_TAKA,        ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(243,    ENUM_PLAYSTYLE1_POWER_SHOT,        ENUM_PLAYSTYLE1_RAPID)
    add(240,    ENUM_PLAYSTYLE1_PRESS_PROVEN,      ENUM_PLAYSTYLE1_INTERCEPT)
    add(457,    ENUM_PLAYSTYLE1_TIKI_TAKA,         ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(448,    ENUM_PLAYSTYLE1_AERIAL_FORTRESS,   ENUM_PLAYSTYLE1_BRUISER)
    add(483,    ENUM_PLAYSTYLE1_TRICKSTER,         ENUM_PLAYSTYLE1_RAPID)
    add(481,    ENUM_PLAYSTYLE1_PRESS_PROVEN,      ENUM_PLAYSTYLE1_RELENTLESS)
    add(449,    ENUM_PLAYSTYLE1_TECHNICAL,         ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(461,    ENUM_PLAYSTYLE1_TIKI_TAKA,         ENUM_PLAYSTYLE1_TECHNICAL)
    add(479,    ENUM_PLAYSTYLE1_RELENTLESS,        ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(450,    ENUM_PLAYSTYLE1_FIRST_TOUCH,       ENUM_PLAYSTYLE1_RAPID)
    add(480,    ENUM_PLAYSTYLE1_RAPID,             ENUM_PLAYSTYLE1_TRICKSTER)
    add(452,    ENUM_PLAYSTYLE1_TECHNICAL,         ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(1860,   ENUM_PLAYSTYLE1_INTERCEPT,         ENUM_PLAYSTYLE1_BLOCK)
    add(110062, ENUM_PLAYSTYLE1_TIKI_TAKA,         ENUM_PLAYSTYLE1_RAPID)
    add(453,    ENUM_PLAYSTYLE1_BRUISER,           ENUM_PLAYSTYLE1_LONG_BALL_PASS)

    -- *** INGLATERRA ***
    add(10,  ENUM_PLAYSTYLE1_INCISIVE_PASS,    ENUM_PLAYSTYLE1_TIKI_TAKA)
    add(9,   ENUM_PLAYSTYLE1_RELENTLESS,       ENUM_PLAYSTYLE1_QUICK_STEP)
    add(11,  ENUM_PLAYSTYLE1_RELENTLESS,       ENUM_PLAYSTYLE1_POWER_SHOT)
    add(1,   ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(5,   ENUM_PLAYSTYLE1_WHIPPED_PASS,     ENUM_PLAYSTYLE1_BLOCK)
    add(18,  ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RAPID)
    add(13,  ENUM_PLAYSTYLE1_TRICKSTER,        ENUM_PLAYSTYLE1_RAPID)
    add(2,   ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_LONG_BALL_PASS)
    add(19,  ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_RELENTLESS)
    add(7,   ENUM_PLAYSTYLE1_AERIAL_FORTRESS,  ENUM_PLAYSTYLE1_RELENTLESS)
    add(1808,ENUM_PLAYSTYLE1_TIKI_TAKA,        ENUM_PLAYSTYLE1_TECHNICAL)
    add(1799,ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_TRICKSTER)
    add(14,  ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_RELENTLESS)
    add(8,   ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_AERIAL_FORTRESS)
    add(1943,ENUM_PLAYSTYLE1_RAPID,            ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(17,  ENUM_PLAYSTYLE1_BRUISER,          ENUM_PLAYSTYLE1_AERIAL_FORTRESS)

    -- *** ALEMANIA ***
    add(21,    ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    add(22,    ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_TRICKSTER)
    add(32,    ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(112172,ENUM_PLAYSTYLE1_INCISIVE_PASS,  ENUM_PLAYSTYLE1_TIKI_TAKA)
    add(23,    ENUM_PLAYSTYLE1_INTERCEPT,      ENUM_PLAYSTYLE1_BLOCK)
    add(1824,  ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RAPID)
    add(175,   ENUM_PLAYSTYLE1_RELENTLESS,     ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(36,    ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_RAPID)
    add(25,    ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TIKI_TAKA)
    add(38,    ENUM_PLAYSTYLE1_FIRST_TOUCH,    ENUM_PLAYSTYLE1_TECHNICAL)
    add(28,    ENUM_PLAYSTYLE1_AERIAL_FORTRESS,ENUM_PLAYSTYLE1_BRUISER)
    add(34,    ENUM_PLAYSTYLE1_BRUISER,        ENUM_PLAYSTYLE1_RELENTLESS)
    add(31,    ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_BLOCK)
    add(10029, ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(110329,ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(111235,ENUM_PLAYSTYLE1_RELENTLESS,     ENUM_PLAYSTYLE1_BRUISER)

    -- *** ITALIA ***
    add(45,    ENUM_PLAYSTYLE1_JOCKEY,         ENUM_PLAYSTYLE1_BRUISER)
    add(131681,ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(131682,ENUM_PLAYSTYLE1_INTERCEPT,      ENUM_PLAYSTYLE1_RELENTLESS)
    add(48,    ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(52,    ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(110374,ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(115845,ENUM_PLAYSTYLE1_AERIAL_FORTRESS,ENUM_PLAYSTYLE1_LONG_BALL_PASS)
    add(115841,ENUM_PLAYSTYLE1_INTERCEPT,      ENUM_PLAYSTYLE1_BRUISER)
    add(189,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(54,    ENUM_PLAYSTYLE1_BRUISER,        ENUM_PLAYSTYLE1_RELENTLESS)
    add(110556,ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    add(205,   ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(111811,ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(1745,  ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TECHNICAL)

    -- *** FRANCIA ***
    add(73,    ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_POWER_SHOT)
    add(66,    ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    add(219,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TRICKSTER)
    add(69,    ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(65,    ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_INTERCEPT)
    add(72,    ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TRICKSTER)
    add(64,    ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(74,    ENUM_PLAYSTYLE1_INCISIVE_PASS,  ENUM_PLAYSTYLE1_TIKI_TAKA)
    add(378,   ENUM_PLAYSTYLE1_RELENTLESS,     ENUM_PLAYSTYLE1_RAPID)

    -- *** PORTUGAL ***
    add(234,   ENUM_PLAYSTYLE1_INCISIVE_PASS,  ENUM_PLAYSTYLE1_TIKI_TAKA)
    add(237,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(236,   ENUM_PLAYSTYLE1_LONG_BALL_PASS, ENUM_PLAYSTYLE1_RAPID)
    add(1896,  ENUM_PLAYSTYLE1_BRUISER,        ENUM_PLAYSTYLE1_RELENTLESS)

    -- *** PAÍSES BAJOS ***
    add(245,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TRICKSTER)
    add(247,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RAPID)
    add(246,   ENUM_PLAYSTYLE1_INCISIVE_PASS,  ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(1906,  ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(1908,  ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_PRESS_PROVEN)

    -- *** ESCOCIA ***
    add(78,    ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_RAPID)
    add(86,    ENUM_PLAYSTYLE1_POWER_SHOT,     ENUM_PLAYSTYLE1_RELENTLESS)

    -- *** BÉLGICA ***
    add(229,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(231,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(673,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TIKI_TAKA)
    add(674,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    add(2014,  ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_TECHNICAL)

    -- *** TURQUÍA ***
    add(325,   ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_TRICKSTER)
    add(326,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(327,   ENUM_PLAYSTYLE1_BRUISER,        ENUM_PLAYSTYLE1_POWER_SHOT)

    -- *** NORUEGA ***
    add(918,   ENUM_PLAYSTYLE1_RELENTLESS,     ENUM_PLAYSTYLE1_RAPID)
    add(298,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)

    -- *** SUECIA ***
    add(320,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_RAPID)
    add(319,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(708,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RAPID)

    -- *** DINAMARCA ***
    add(269,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    add(1516,  ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(819,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TIKI_TAKA)

    -- *** REP. CHECA ***
    add(266,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_INTERCEPT)
    add(267,   ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_TECHNICAL)

    -- *** UCRANIA ***
    add(101059,ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_TECHNICAL)
    add(101047,ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_INTERCEPT)

    -- *** POLONIA ***
    add(1871,  ENUM_PLAYSTYLE1_INTERCEPT,      ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(873,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_RAPID)

    -- *** SUIZA ***
    add(322,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(900,   ENUM_PLAYSTYLE1_INCISIVE_PASS,  ENUM_PLAYSTYLE1_RELENTLESS)
    add(896,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TIKI_TAKA)

    -- *** ARGENTINA ***
    add(1877,  ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_TECHNICAL)
    add(1876,  ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(101085,ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_PRESS_PROVEN)
    add(101083,ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_FIRST_TOUCH)

    -- *** BRASIL ***
    add(383,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(1043,  ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_RAPID)
    add(567,   ENUM_PLAYSTYLE1_TIKI_TAKA,      ENUM_PLAYSTYLE1_INCISIVE_PASS)
    add(1041,  ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    add(1035,  ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_TECHNICAL)
    add(517,   ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_FIRST_TOUCH)

    -- *** ARABIA SAUDÍ ***
    add(605,   ENUM_PLAYSTYLE1_BRUISER,        ENUM_PLAYSTYLE1_POWER_SHOT)
    add(607,   ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_RAPID)
    add(112139,ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_POWER_SHOT)

    -- *** MLS ***
    add(697,   ENUM_PLAYSTYLE1_RAPID,          ENUM_PLAYSTYLE1_FIRST_TOUCH)
    add(112893,ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_RAPID)
    add(689,   ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RELENTLESS)
    return t
end
local CLUB_DNA = build_club_dna()

local LEAGUE_DNA = {
    [13]={ENUM_PLAYSTYLE1_AERIAL_FORTRESS, ENUM_PLAYSTYLE1_RELENTLESS},
    [53]={ENUM_PLAYSTYLE1_TIKI_TAKA,       ENUM_PLAYSTYLE1_TECHNICAL},
    [19]={ENUM_PLAYSTYLE1_PRESS_PROVEN,    ENUM_PLAYSTYLE1_INCISIVE_PASS},
    [31]={ENUM_PLAYSTYLE1_JOCKEY,          ENUM_PLAYSTYLE1_INTERCEPT},
    [16]={ENUM_PLAYSTYLE1_RAPID,           ENUM_PLAYSTYLE1_TRICKSTER},
    [10]={ENUM_PLAYSTYLE1_TIKI_TAKA,       ENUM_PLAYSTYLE1_TECHNICAL},
    [308]={ENUM_PLAYSTYLE1_LONG_BALL_PASS, ENUM_PLAYSTYLE1_RAPID},
    [50]={ENUM_PLAYSTYLE1_BRUISER,         ENUM_PLAYSTYLE1_RELENTLESS},
    [68]={ENUM_PLAYSTYLE1_BRUISER,         ENUM_PLAYSTYLE1_POWER_SHOT},
    [4]={ENUM_PLAYSTYLE1_PRESS_PROVEN,     ENUM_PLAYSTYLE1_TECHNICAL},
    [80]={ENUM_PLAYSTYLE1_PRESS_PROVEN,    ENUM_PLAYSTYLE1_INTERCEPT},
    [56]={ENUM_PLAYSTYLE1_TECHNICAL,       ENUM_PLAYSTYLE1_RELENTLESS},
    [41]={ENUM_PLAYSTYLE1_AERIAL_FORTRESS, ENUM_PLAYSTYLE1_BRUISER},
    [66]={ENUM_PLAYSTYLE1_INTERCEPT,       ENUM_PLAYSTYLE1_BLOCK},
    [1]={ENUM_PLAYSTYLE1_TECHNICAL,        ENUM_PLAYSTYLE1_INCISIVE_PASS},
    [83]={ENUM_PLAYSTYLE1_PRESS_PROVEN,    ENUM_PLAYSTYLE1_QUICK_STEP},
    [39]={ENUM_PLAYSTYLE1_RAPID,           ENUM_PLAYSTYLE1_FIRST_TOUCH},
    [65]={ENUM_PLAYSTYLE1_BRUISER,         ENUM_PLAYSTYLE1_RELENTLESS},
    [353]={ENUM_PLAYSTYLE1_TRICKSTER,      ENUM_PLAYSTYLE1_TECHNICAL},
    [350]={ENUM_PLAYSTYLE1_POWER_SHOT,     ENUM_PLAYSTYLE1_BRUISER},
    [189]={ENUM_PLAYSTYLE1_TECHNICAL,      ENUM_PLAYSTYLE1_TIKI_TAKA},
    [351]={ENUM_PLAYSTYLE1_PRESS_PROVEN,   ENUM_PLAYSTYLE1_RAPID},
}

local TEAM_LEAGUE = {
    [1]=13,[2]=13,[5]=13,[7]=13,[8]=13,[9]=13,[10]=13,[11]=13,
    [12]=13,[13]=13,[14]=13,[17]=13,[18]=13,[19]=13,[88]=13,
    [89]=13,[91]=13,[94]=13,[95]=13,[97]=13,[106]=13,[109]=13,
    [110]=13,[1790]=13,[1792]=13,[1793]=13,[1794]=13,[1795]=13,
    [1796]=13,[1797]=13,[1799]=13,[1800]=13,[1801]=13,[1806]=13,
    [1807]=13,[1808]=13,[1919]=13,[1925]=13,[1929]=13,[1943]=13,
    [1939]=13,[1951]=13,[1952]=13,[1960]=13,[1961]=13,
    [240]=53,[241]=53,[243]=53,[448]=53,[449]=53,[450]=53,
    [452]=53,[453]=53,[456]=53,[457]=53,[459]=53,[461]=53,
    [462]=53,[463]=53,[467]=53,[468]=53,[472]=53,[479]=53,
    [480]=53,[481]=53,[483]=53,[573]=53,[1853]=53,[1854]=53,
    [1860]=53,[1861]=53,[1867]=53,[1894]=53,[100852]=53,
    [100888]=53,[110062]=53,[110827]=53,[110832]=53,[110839]=53,
    [131391]=53,[132629]=53,
    [21]=19,[22]=19,[23]=19,[25]=19,[27]=19,[28]=19,[29]=19,
    [31]=19,[32]=19,[33]=19,[34]=19,[36]=19,[38]=19,[159]=19,
    [160]=19,[162]=19,[165]=19,[166]=19,[169]=19,[171]=19,
    [175]=19,[485]=19,[487]=19,[492]=19,[503]=19,[506]=19,
    [523]=19,[526]=19,[531]=19,[543]=19,[576]=19,[580]=19,
    [583]=19,[1824]=19,[1825]=19,[1826]=19,[1831]=19,[1832]=19,
    [10029]=19,[10030]=19,[110329]=19,[110500]=19,[110501]=19,
    [110502]=19,[110532]=19,[110588]=19,[110636]=19,[110645]=19,
    [110685]=19,[110697]=19,[111235]=19,[112172]=19,
    [45]=31,[48]=31,[50]=31,[52]=31,[54]=31,[55]=31,[189]=31,
    [200]=31,[205]=31,[206]=31,[347]=31,[1745]=31,[1746]=31,
    [1837]=31,[1842]=31,[1843]=31,[1848]=31,[2038]=31,
    [110374]=31,[110556]=31,[110738]=31,[110740]=31,[111433]=31,
    [111434]=31,[111657]=31,[111811]=31,[111974]=31,[112124]=31,
    [112493]=31,[112494]=31,[113147]=31,[113974]=31,[115841]=31,
    [115845]=31,[1744]=31,[110908]=31,[110912]=31,[110915]=31,
    [131682]=31,[131681]=31,
    [57]=16,[58]=16,[62]=16,[64]=16,[65]=16,[66]=16,[68]=16,
    [69]=16,[70]=16,[71]=16,[72]=16,[73]=16,[74]=16,[76]=16,
    [217]=16,[219]=16,[294]=16,[378]=16,[379]=16,[1530]=16,
    [1738]=16,[1739]=16,[1805]=16,[1809]=16,[1814]=16,[1815]=16,
    [1816]=16,[1819]=16,[1823]=16,[111273]=16,[111276]=16,
    [111659]=16,[116416]=16,[131447]=16,[131673]=16,[132588]=16,
    [245]=10,[246]=10,[247]=10,[634]=10,[645]=10,[1903]=10,
    [1904]=10,[1906]=10,[1908]=10,[1910]=10,[1913]=10,[1914]=10,
    [1915]=10,[100632]=10,[100634]=10,[100638]=10,[100646]=10,[1971]=10,
    [234]=308,[236]=308,[237]=308,[717]=308,[718]=308,[744]=308,
    [1438]=308,[1887]=308,[1888]=308,[1891]=308,[1896]=308,
    [1900]=308,[110513]=308,[112513]=308,[112516]=308,[112809]=308,
    [114510]=308,[131463]=308,[463]=308,
    [77]=50,[78]=50,[79]=50,[80]=50,[81]=50,[82]=50,[83]=50,
    [86]=50,[180]=50,[181]=50,[621]=50,[100805]=50,[131363]=50,
    [325]=68,[326]=68,[327]=68,[436]=68,[741]=68,[748]=68,
    [101014]=68,[101020]=68,[101025]=68,[101026]=68,[101032]=68,
    [101033]=68,[101037]=68,[111117]=68,[111339]=68,[113142]=68,[131174]=68,
    [229]=4,[230]=4,[231]=4,[232]=4,[537]=4,[670]=4,[673]=4,
    [674]=4,[680]=4,[681]=4,[750]=4,[1750]=4,[2014]=4,[15005]=4,
    [100087]=4,[110724]=4,[132231]=4,
    [191]=80,[209]=80,[252]=80,[254]=80,[256]=80,[780]=80,
    [1862]=80,[2017]=80,[15009]=80,[15040]=80,[110720]=80,
    [111822]=80,[113616]=80,
    [298]=41,[300]=41,[417]=41,[418]=41,[918]=41,[919]=41,
    [920]=41,[922]=41,[1463]=41,[1523]=41,[1756]=41,[1757]=41,
    [2041]=41,[112199]=41,[131491]=41,
    [319]=56,[320]=56,[321]=56,[433]=56,[700]=56,[702]=56,
    [708]=56,[710]=56,[711]=56,[1870]=56,[112072]=56,
    [112126]=56,[113458]=56,[113459]=56,[113892]=56,
    [269]=1,[270]=1,[271]=1,[272]=1,[822]=1,[1443]=1,[1447]=1,
    [1516]=1,[1786]=1,[1788]=1,[819]=1,[15006]=1,
    [301]=66,[420]=66,[873]=66,[1569]=66,[1871]=66,[110745]=66,
    [110746]=66,[110747]=66,[110749]=66,[111082]=66,[111083]=66,
    [111086]=66,[111088]=66,[111091]=66,[111097]=66,[114326]=66,
    [322]=189,[324]=189,[894]=189,[896]=189,[897]=189,[898]=189,
    [900]=189,[1713]=189,[1715]=189,[10032]=189,[110770]=189,[131361]=189,
    [687]=39,[688]=39,[689]=39,[691]=39,[693]=39,[694]=39,
    [695]=39,[696]=39,[697]=39,[698]=39,[111065]=39,[111138]=39,
    [111139]=39,[111140]=39,[111144]=39,[111596]=39,[111651]=39,
    [111928]=39,[112134]=39,[112606]=39,[112828]=39,[112885]=39,
    [112893]=39,[112996]=39,[113018]=39,[113149]=39,[114161]=39,
    [114162]=39,[114640]=39,[131439]=39,[131477]=39,[131478]=39,
    [305]=65,[306]=65,[422]=65,[423]=65,[445]=65,[563]=65,
    [753]=65,[834]=65,[1571]=65,[1572]=65,
    [1876]=353,[1877]=353,[101083]=353,[101084]=353,[101085]=353,
    [101088]=353,[110395]=353,[110396]=353,[110404]=353,
    [111019]=353,[111020]=353,[111022]=353,[112670]=353,
    [112689]=353,[112713]=353,[113044]=353,[1013]=353,
    [110093]=353,[111706]=353,[111707]=353,[111708]=353,
    [111710]=353,[111711]=353,[111713]=353,[111715]=353,
    [111716]=353,[115472]=353,[112965]=353,
    [605]=350,[607]=350,[111674]=350,[111701]=350,[112096]=350,
    [112139]=350,[112387]=350,[112390]=350,[112391]=350,
    [112393]=350,[112883]=350,[113037]=350,[113057]=350,
    [113060]=350,[113217]=350,[113222]=350,[115892]=350,
    [131735]=350,[131798]=350,
    [980]=83,[982]=83,[1473]=83,[1474]=83,[1477]=83,[1478]=83,
    [2055]=83,[2056]=83,[112115]=83,[112258]=83,[112555]=83,[112558]=83,
    [111393]=351,[111395]=351,[111396]=351,[111397]=351,[111398]=351,
    [111399]=351,[111400]=351,[111766]=351,[112224]=351,[112427]=351,
    [114023]=351,[114604]=351,
}

-- ============================================================
-- SECCIÓN 13: ESPECIALISTAS
-- ============================================================
local SPECIALIST_MAP_OUTFIELD = {
    sprintspeed=ENUM_PLAYSTYLE1_RAPID,         
    acceleration=ENUM_PLAYSTYLE1_QUICK_STEP,
    dribbling=ENUM_PLAYSTYLE1_TECHNICAL,        
    finishing=ENUM_PLAYSTYLE1_FINESSE_SHOT,
    shotpower=ENUM_PLAYSTYLE1_POWER_SHOT,       
    volleys=ENUM_PLAYSTYLE1_ACROBATIC,          
    shortpassing=ENUM_PLAYSTYLE1_TIKI_TAKA,
    headingaccuracy=ENUM_PLAYSTYLE1_AERIAL_FORTRESS,
    interceptions=ENUM_PLAYSTYLE1_INTERCEPT,
    defensiveawareness=ENUM_PLAYSTYLE1_ANTICIPATE,
    stamina=ENUM_PLAYSTYLE1_RELENTLESS,         
    longpassing=ENUM_PLAYSTYLE1_LONG_BALL_PASS,
    strength=ENUM_PLAYSTYLE1_BRUISER,           
    reactions=ENUM_PLAYSTYLE1_FIRST_TOUCH,        
    vision=ENUM_PLAYSTYLE1_INCISIVE_PASS,         
    aggression=ENUM_PLAYSTYLE1_ENFORCER,        
    freekickaccuracy=ENUM_PLAYSTYLE1_DEAD_BALL,
}
local SPECIALIST_MAP_GK = {
    gkdiving=ENUM_PLAYSTYLE2_GK_FAR_REACH,     gkreflexes=ENUM_PLAYSTYLE2_GK_FOOTWORK,
    gkhandling=ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER,
    gkpositioning=ENUM_PLAYSTYLE2_GK_RUSH_OUT, gkkicking=ENUM_PLAYSTYLE2_GK_FAR_THROW,
}
local SPECIALIST_STATS_OUTFIELD = {
    "sprintspeed","acceleration","dribbling","finishing","shotpower","longshots",
    "volleys","shortpassing","headingaccuracy","interceptions","defensiveawareness",
    "stamina","longpassing","strength","reactions","agility","vision","curve",
    "standingtackle","aggression","freekickaccuracy",
}
local SPECIALIST_STATS_GK = {
    "gkdiving","gkreflexes","gkhandling","gkpositioning","gkkicking",
}

-- ============================================================
-- SECCIÓN 14: FUNCIONES CORE
-- ============================================================

local function get_stat(p_table,record,field)
    local val=p_table:GetRecordFieldValue(record,field)
    return tonumber(val) or 0
end

local function calc_age(bd)
    if not bd or bd<=0 then return 25 end
    return math.max(15,math.min(50,math.floor((CFG.CURRENT_DAY_FC26-bd)/365.25)))
end

local function get_limits(ovr,pot)
    local tot
    if     ovr>=90 then tot=10
    elseif ovr>=87 then tot=9
    elseif ovr>=84 then tot=8
    elseif ovr>=81 then tot=7
    elseif ovr>=78 then tot=6
    elseif ovr>=75 then tot=5
    elseif ovr>=72 then tot=4
    elseif ovr>=70 then tot=3
    else                tot=2 end
    if (pot-ovr)>=CFG.WONDERKID_DIFF and ovr>=72 then
        tot=math.min(10,tot+1)
    end
    return tot,tot
end

local function stat_score(val,threshold)
    local ex=val-threshold
    if ex<=0 then return 0 end
    return math.floor(ex*ex*0.15)
end

local function proportional_noise(val,comp)
    local base=math.max(1,math.floor((val-60)*0.06))
    local factor=(comp>=75) and 0.5 or (comp<55 and 1.8 or 1.0)
    return math.random(0,math.max(1,math.floor(base*factor)))
end

local function age_bonus(age,ps_id)
    local speed_ps={
        [ENUM_PLAYSTYLE1_RAPID]=true,[ENUM_PLAYSTYLE1_QUICK_STEP]=true,
        [ENUM_PLAYSTYLE1_TRICKSTER]=true,[ENUM_PLAYSTYLE1_TECHNICAL]=true,
        [ENUM_PLAYSTYLE1_ACROBATIC]=true,
    }
    local read_ps={
        [ENUM_PLAYSTYLE1_ANTICIPATE]=true,[ENUM_PLAYSTYLE1_FIRST_TOUCH]=true,
        [ENUM_PLAYSTYLE1_INCISIVE_PASS]=true,[ENUM_PLAYSTYLE1_JOCKEY]=true,
        [ENUM_PLAYSTYLE1_TIKI_TAKA]=true,[ENUM_PLAYSTYLE1_INTERCEPT]=true,
        [ENUM_PLAYSTYLE1_INVENTIVE]=true,[ENUM_PLAYSTYLE1_ENFORCER]=true,
    }
    if not ps_id then return 0 end
    local ab=CFG.NORM_AGE_BONUS
    if     age<=CFG.NORM_AGE_YOUNG and speed_ps[ps_id] then return  ab*2
    elseif age<=CFG.NORM_AGE_YOUNG and read_ps[ps_id]  then return -ab
    elseif age>=CFG.NORM_AGE_VETERAN and read_ps[ps_id]  then return  ab*2
    elseif age>=CFG.NORM_AGE_VETERAN and speed_ps[ps_id] then return -ab
    end
    return 0
end

-- pool_add: fuente normal → sujeta a MAX_POOL_SCORE
local function pool_add(pool,ps_id,score_delta,base_val)
    if not ps_id or ps_id==0 then return end
    local capped=math.min(math.max(score_delta,0),CFG.SOURCE_CAP)
    if capped<=0 then return end
    if not pool[ps_id] then pool[ps_id]={score=0,base=base_val or 80} end
    local new_score=pool[ps_id].score+capped
    pool[ps_id].score=math.min(new_score,CFG.MAX_POOL_SCORE)
    if base_val and base_val>pool[ps_id].base then pool[ps_id].base=base_val end
end

-- pool_add_specialist: sin cap de MAX_POOL_SCORE
-- Los especialistas T2/T3 NECESITAN scores altos para ganar siempre
local function pool_add_specialist(pool,ps_id,score_delta,base_val)
    if not ps_id or ps_id==0 then return end
    local capped=math.max(score_delta,0)
    if capped<=0 then return end
    if not pool[ps_id] then pool[ps_id]={score=0,base=base_val or 80} end
    pool[ps_id].score=pool[ps_id].score+capped
    if base_val and base_val>pool[ps_id].base then pool[ps_id].base=base_val end
end

-- pool_add_cultural: con cap cultural y validación mínima de prereqs
local function pool_add_cultural(pool,cultural_acc,ps_id,delta,base_val,sc)
    if not ps_id or ps_id==0 then return end
    local p=PS_PREREQS[ps_id]
    if p and sc then
        local sv=sc[p.stat] or 0
        local ok=sv>=(p.hard_min or 0)
        if p.alt_stat and not ok then
            ok=(sc[p.alt_stat] or 0)>=(p.alt_hard_min or 0)
        end
        if not ok then return end
    end
    local cur=cultural_acc[ps_id] or 0
    if cur>=CFG.CULTURAL_CAP then return end
    local eff=math.min(delta,CFG.CULTURAL_CAP-cur)
    cultural_acc[ps_id]=cur+eff
    pool_add(pool,ps_id,eff,base_val)
end

-- Filtro de prereqs hard/soft (paso 5)
local function apply_prereq_filter(pool, sc)
    for ps_id, data in pairs(pool) do
        local p = PS_PREREQS[ps_id]
        if p then
            local sv  = sc[p.stat] or 0
            local av  = p.alt_stat  and (sc[p.alt_stat]  or 0) or nil
            local av2 = p.alt_stat2 and (sc[p.alt_stat2] or 0) or nil

            -- ── require_all: TODOS los stats deben pasar ────────────
            -- Útil para PS que exigen perfil completo (finishing + curve + skills)
            if p.require_all then
                local hard_ok = sv >= (p.hard_min or 0)
                local soft_ok = sv >= p.min
                if av then
                    hard_ok = hard_ok and (av >= (p.alt_hard_min  or 0))
                    soft_ok = soft_ok and (av >= (p.alt_min       or 0))
                end
                if av2 then
                    hard_ok = hard_ok and (av2 >= (p.alt_hard_min2 or 0))
                    soft_ok = soft_ok and (av2 >= (p.alt_min2      or 0))
                end
                if not hard_ok then
                    data.score = 0
                elseif not soft_ok then
                    data.score = math.floor(data.score * 0.5)
                end

            -- ── require_both: AMBOS (stat + alt_stat) deben pasar ───
            elseif p.require_both then
                local main_hard = sv >= (p.hard_min or 0)
                local alt_hard  = av  and (av >= (p.alt_hard_min or 0)) or true
                if not main_hard or not alt_hard then
                    data.score = 0
                elseif sv < p.min or (av and av < (p.alt_min or 0)) then
                    data.score = math.floor(data.score * 0.5)
                end

            -- ── lógica OR estándar ───────────────────────────────────
            else
                local ph = sv >= (p.hard_min or 0)
                local ps = sv >= p.min
                if av then
                    ph = ph or (av >= (p.alt_hard_min or 0))
                    ps = ps or (av >= (p.alt_min      or 0))
                end
                if not ph then
                    data.score = 0
                elseif not ps then
                    data.score = math.floor(data.score * 0.5)
                end
            end
        end
    end

    for ps_id, data in pairs(pool) do
        if data.score <= 0 then pool[ps_id] = nil end
    end
end
-- ============================================================
-- SECCIÓN 15: LOGGING
-- ============================================================
local log_handle=nil

local function log_init()
    if not CFG.LOG_ENABLED then return end
    log_handle=io.open(CFG.LOG_PATH,"w")
    if log_handle then
        log_handle:write("playerid,name,ovr,pos,age,"..
            "top1_ps,top1_score,top2_ps,top2_score,top3_ps,top3_score,"..
            "anomaly,hidden\n")
    end
end

local function log_player(pid,ovr,pos,age,pool,anomaly,hidden_ps)
    if not CFG.LOG_ENABLED or not log_handle then return end
    local sorted={}
    for id,data in pairs(pool) do table.insert(sorted,{id=id,score=data.score}) end
    table.sort(sorted,function(a,b) return a.score>b.score end)
    local e={}
    for i=1,CFG.LOG_TOP_SCORES do
        e[i]=sorted[i] and (tostring(sorted[i].id)..","..tostring(math.floor(sorted[i].score))) or "0,0"
    end
    local pname=GetPlayerName(pid) or "?"
    log_handle:write(string.format("%d,%s,%d,%d,%d,%s,%s,%s,%s,%s\n",
        pid,pname,ovr,pos,age,
        e[1],e[2],e[3],
        (anomaly and "1" or "0"),tostring(hidden_ps or 0)))
end

local function log_close()
    if log_handle then log_handle:close() end
end

-- ============================================================
-- SECCIÓN 16: HIDDEN PS
-- ============================================================
-- ~HIDDEN_PS_CHANCE% de jugadores reciben uno.
-- Se escribe en trait2 con OR (slot adicional, no consume límite).
-- [CONFIGURABLE] Modifica umbrales y pesos.
-- ============================================================
local function get_hidden_ps(ovr,age,pos,comp,pas,sta,height,str)
    if math.random(1,100)>CFG.HIDDEN_PS_CHANCE then return 0 end
    local candidates={}
    if ovr>=72 and comp>=67 and age>=21 then
        table.insert(candidates,{id=ENUM_PLAYSTYLE2_CAREER_SOLID_PLAYER,w=40})
    end
    if (pas>=70 or sta>=73) and age>=18 then
        table.insert(candidates,{id=ENUM_PLAYSTYLE2_CAREER_TEAM_PLAYER,w=35})
    end
    if age>=27 and ovr>=68 then
        local w=12+math.min(18,(age-27)*2)
        table.insert(candidates,{id=ENUM_PLAYSTYLE2_CAREER_ONE_CLUB_PLAYER,w=w})
    end
    local iw=0
    if age>=30 then iw=iw+10 end
    if height>=190 and str>=80 then iw=iw+8 end
    if pos>=4 and pos<=6 then iw=iw+4 end
    if iw>=8 then table.insert(candidates,{id=ENUM_PLAYSTYLE2_CAREER_INJURY_PRONE,w=iw}) end
    if age>=25 and (comp>=76 or ovr>=79) then
        table.insert(candidates,{id=ENUM_PLAYSTYLE2_CAREER_LEADERSHIP,w=25})
    end
    if #candidates==0 then return 0 end
    local total=0
    for _,c in ipairs(candidates) do total=total+c.w end
    local roll=math.random(1,total); local acc=0
    for _,c in ipairs(candidates) do
        acc=acc+c.w
        if roll<=acc then return c.id end
    end
    return candidates[#candidates].id
end

-- ============================================================
-- SECCIÓN 17: PROCESO MAESTRO — EL EMBUDO
-- ============================================================
local function process_player(record,p_table)

    -- ── PASO 0: LECTURA Y STAT_CACHE ────────────────────────
    local pid  =get_stat(p_table,record,"playerid")
    local ovr  =get_stat(p_table,record,"overallrating")
    local pot  =get_stat(p_table,record,"potential")
    local pos  =get_stat(p_table,record,"preferredposition1")
    local pos2 =get_stat(p_table,record,"preferredposition2")
    local nat  =get_stat(p_table,record,"nationality")
    local bd   =get_stat(p_table,record,"birthdate")
    local age  =calc_age(bd)
    local height=get_stat(p_table,record,"height")
    local skills=get_stat(p_table,record,"skillmoves")
    local weakft=get_stat(p_table,record,"weakfootabilitytypecode")
    local comp  =get_stat(p_table,record,"composure")
    local spd   =get_stat(p_table,record,"sprintspeed")
    local acc2  =get_stat(p_table,record,"acceleration")
    local dri   =get_stat(p_table,record,"dribbling")
    local fin   =get_stat(p_table,record,"finishing")
    local pas   =get_stat(p_table,record,"shortpassing")
    local vis   =get_stat(p_table,record,"vision")
    local str   =get_stat(p_table,record,"strength")
    local hea   =get_stat(p_table,record,"headingaccuracy")
    local icp   =get_stat(p_table,record,"interceptions")
    local crs   =get_stat(p_table,record,"crossing")
    local sta   =get_stat(p_table,record,"stamina")
    local lpa   =get_stat(p_table,record,"longpassing")
    local voll  =get_stat(p_table,record,"volleys")
    local agl   =get_stat(p_table,record,"agility")
    local defaw =get_stat(p_table,record,"defensiveawareness")
    local slitp =get_stat(p_table,record,"slidingtackle")
    local stntk =get_stat(p_table,record,"standingtackle")
    local fka   =get_stat(p_table,record,"freekickaccuracy")
    local curv  =get_stat(p_table,record,"curve")
    local shpow =get_stat(p_table,record,"shotpower")
    local lngs  =get_stat(p_table,record,"longshots")
    local agg   =get_stat(p_table,record,"aggression")
    local reac  =get_stat(p_table,record,"reactions")
    local jump  =get_stat(p_table,record,"jumping")
    local pen   =get_stat(p_table,record,"penalties")
    local posi  =get_stat(p_table,record,"positioning")
    local bc    =get_stat(p_table,record,"ballcontrol")
    local gkdiv =get_stat(p_table,record,"gkdiving")
    local gkref =get_stat(p_table,record,"gkreflexes")
    local gkhan =get_stat(p_table,record,"gkhandling")
    local gkpos =get_stat(p_table,record,"gkpositioning")
    local gkkic =get_stat(p_table,record,"gkkicking")

    local sc={
        sprintspeed=spd,        acceleration=acc2,
        dribbling=dri,          finishing=fin,
        shortpassing=pas,       vision=vis,
        strength=str,           headingaccuracy=hea,
        interceptions=icp,      crossing=crs,
        stamina=sta,            longpassing=lpa,
        volleys=voll,           agility=agl,
        defensiveawareness=defaw,slidingtackle=slitp,
        standingtackle=stntk,   freekickaccuracy=fka,
        curve=curv,             shotpower=shpow,
        longshots=lngs,         aggression=agg,
        reactions=reac,         jumping=jump,
        penalties=pen,          positioning=posi,
        ballcontrol=bc,         gkdiving=gkdiv,
        gkreflexes=gkref,       gkhandling=gkhan,
        gkpositioning=gkpos,    gkkicking=gkkic,
        composure=comp,         height=height,
        skillmoves=skills,
    }

    -- ── PASO 1: NORMALIZACIONES ──────────────────────────────
    pos    =tonumber(pos)    or 0
    pos2   =tonumber(pos2)   or 0
    height =tonumber(height) or 175
    skills =math.max(1,math.min(5,math.floor(tonumber(skills) or 1)))
    weakft =math.max(1,math.min(5,math.floor(tonumber(weakft) or 1)))
    comp   =math.max(0,tonumber(comp) or 50)

    -- Semilla determinista → reproducibilidad por jugador
    math.randomseed(pid+CFG.CURRENT_DAY_FC26)

    local is_gk      =(pos==0)
    local is_def     =not is_gk and (pos>=2 and pos<=8)
    local is_cb      =(pos>=4 and pos<=6) or (pos==1)
    local is_fb      =(pos==2 or pos==3 or pos==7 or pos==8)
    local is_cdm     =(pos>=9 and pos<=11)
    local is_mid     =(pos>=9 and pos<=19)
    local is_att     =(pos>=20 and pos<=27)
    local is_att_all =(pos>=17 and pos<=27)
    local has_shoot_pri=SHOOTING_PRIORITY_POS[pos] or false

    local teamid  =GetTeamIdFromPlayerId(pid)
    if type(teamid)~="number" then teamid=-1 end
    local leagueid=TEAM_LEAGUE[teamid] or -1
    local tier    =LEAGUE_TIER[leagueid] or 3
    local league_bonus=(tier==1) and CFG.NORM_TOP_BONUS or 0

    local pool={}
    local cultural_acc={}

    -- ── PASO 2: PISO DE ARQUETIPOS ───────────────────────────
    -- score = base * factor(stat_cache), mínimo factor = 0.5
    if ovr>=CFG.ARCHETYPE_MIN_OVR then
        for _,arch in ipairs(ARCHETYPES) do
            if arch.valid(pos) and arch.qualify(sc) then
                for _,bp in ipairs(arch.bonus) do
                    local ps_id,base,fn=bp[1],bp[2],bp[3]
                    local factor=math.max(0.5,fn(sc))
                    local score=math.floor(base*factor)
                    local gk_ps=IS_GK_PS[ps_id]==true
                    if (is_gk and gk_ps) or (not is_gk and not gk_ps) then
                        pool_add(pool,ps_id,score,80)
                    end
                end
            end
        end
    end

    -- ── PASO 3: SCANNER TÉCNICO ──────────────────────────────
    for stat_name,ps_list in pairs(ATTR_MAP) do
        local is_gk_stat=GK_STATS[stat_name]==true
        if (is_gk and not is_gk_stat) or (not is_gk and is_gk_stat) then
            -- rama incorrecta: saltar
        else
            local threshold=is_gk_stat and CFG.MIN_STAT_GK or CFG.MIN_STAT_QUALIFY
            local val=sc[stat_name] or 0
            if val>=threshold then
                local base_score=stat_score(val,threshold)+league_bonus
                for _,ps_id in ipairs(ps_list) do
                    local skip=false
                    local pt=PS_SCANNER_THRESH[ps_id]
                    if pt and val<pt then skip=true
                    elseif not is_gk and is_def and DEF_SHOOT_BLOCK[ps_id] then skip=true
                    elseif DEFENSIVE_ONLY_PS[ps_id] and is_att_all then skip=true
                    elseif PRECISION_PS[ps_id] and comp<63 then skip=true
                    elseif ps_id==ENUM_PLAYSTYLE1_RAPID and dri<70 then skip=true
                    elseif IS_GK_PS[ps_id] and not is_gk then skip=true
                    end
                    if not skip then
                        local s=base_score+proportional_noise(val,comp)+age_bonus(age,ps_id)
                        if is_offrole(ps_id,pos) then s=math.floor(s*0.4) end
                        pool_add(pool,ps_id,s,val)
                    end
                end
            end
        end
    end

    -- Scanner extra: tiro para defensas (probabilístico)
    if is_def and fin>=70 then
        local roll=math.random(100)
        if roll<=9 then pool_add(pool,ENUM_PLAYSTYLE1_POWER_SHOT,50,fin)
        elseif roll<=16 and fka>=68 then pool_add(pool,ENUM_PLAYSTYLE1_DEAD_BALL,45,fka) end
    end
    if is_gk and fka>=68 then
        pool_add(pool,ENUM_PLAYSTYLE2_GK_FAR_THROW,stat_score(fka,65),gkkic)
    end

    -- ── PASO 4: BONUSES FÍSICOS Y SITUACIONALES ──────────────
    if is_gk then
        if height>=186 then
            pool_add(pool,ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER,math.min(45,(height-186)*4),height)
        end
        if height>=181 then
            pool_add(pool,ENUM_PLAYSTYLE2_GK_FAR_THROW,math.min(35,(height-181)*3),height)
        end
        if spd>=48 then pool_add(pool,ENUM_PLAYSTYLE2_GK_RUSH_OUT,stat_score(spd,44),spd) end
        if gkdiv>=76 then
            pool_add(pool,ENUM_PLAYSTYLE2_GK_FAR_REACH,math.min(55,(gkdiv-76)*5),gkdiv)
        end
        if gkref>=68 then
            pool_add(pool,ENUM_PLAYSTYLE2_GK_FOOTWORK,math.min(65,(gkref-68)*6),gkref)
        end
    else
        if height>=185 then
            local hb=math.min(45,(height-185)*3)
            pool_add(pool,ENUM_PLAYSTYLE1_AERIAL_FORTRESS,hb,hea)
            pool_add(pool,ENUM_PLAYSTYLE1_PRECISION_HEADER,math.floor(hb*0.7),hea)
            if height>=191 then pool_add(pool,ENUM_PLAYSTYLE1_BRUISER,18,str) end
        end
        if height>=182 and str>=72 and (is_def or is_cdm) then
            local lt=math.min(55,math.floor((height-182)*2.5+(str-72)*1.5))
            pool_add(pool,ENUM_PLAYSTYLE1_LONG_THROW,lt,str)
        end
        if (is_def or is_cdm) and str>=78 and stntk>=76 then
            pool_add(pool,ENUM_PLAYSTYLE1_ENFORCER,
                math.min(40,(str-78)*3+(stntk-76)*2),stntk)
        end
    end

    -- Skill stars
    if not is_gk and skills>=3 then
        local sk=(skills-2)*20
        pool_add(pool,ENUM_PLAYSTYLE1_TRICKSTER,sk,dri)
        pool_add(pool,ENUM_PLAYSTYLE1_TECHNICAL,math.floor(sk*0.75),dri)
        if skills==5 then
            pool_add(pool,ENUM_PLAYSTYLE1_QUICK_STEP,15,acc2)
            pool_add(pool,ENUM_PLAYSTYLE1_ACROBATIC,12,voll)
        end
    end

    -- Pierna débil
    if not is_gk and not is_def and weakft>=3 then
        local wf=(weakft-2)*15
        if comp>=63 then pool_add(pool,ENUM_PLAYSTYLE1_FINESSE_SHOT,wf,fin) end
        pool_add(pool,ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,math.floor(wf*0.4),fin)
    end

    -- Posición secundaria
    if not is_gk and pos2 and pos2>0 and pos2~=pos then
        local p2_fb=(pos2==2 or pos2==3 or pos2==7 or pos2==8)
        local p2_cb=(pos2>=4 and pos2<=6)
        local p2_cdm=(pos2>=9 and pos2<=11)
        local p2_cm=(pos2>=13 and pos2<=15)
        local p2_att=(pos2>=20 and pos2<=27)
        local p2_cam=(pos2>=17 and pos2<=19)
        if p2_fb and crs>=72 then pool_add(pool,ENUM_PLAYSTYLE1_WHIPPED_PASS,25,crs) end
        if (p2_att or pos2==23 or pos2==27) and spd>=74 then
            pool_add(pool,ENUM_PLAYSTYLE1_RAPID,22,spd)
        end
        if p2_cdm and icp>=70 then
            pool_add(pool,ENUM_PLAYSTYLE1_INTERCEPT,22,icp)
            pool_add(pool,ENUM_PLAYSTYLE1_PRESS_PROVEN,16,sta)
        end
        if p2_cb and hea>=72 then pool_add(pool,ENUM_PLAYSTYLE1_AERIAL_FORTRESS,20,hea) end
        if p2_cb and height>=182 and str>=72 then pool_add(pool,ENUM_PLAYSTYLE1_LONG_THROW,18,str) end
        if p2_att and fin>=72 and not is_def then
            pool_add(pool,ENUM_PLAYSTYLE1_FINESSE_SHOT,18,fin)
            pool_add(pool,ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,14,fin)
        end
        if (p2_cam or p2_cm) and vis>=72 then pool_add(pool,ENUM_PLAYSTYLE1_INCISIVE_PASS,18,vis) end
        if (p2_cm or pos2==14 or pos2==18) and pas>=74 then pool_add(pool,ENUM_PLAYSTYLE1_TIKI_TAKA,18,pas) end
        if (p2_cb or p2_cdm) and lpa>=72 and not is_att then pool_add(pool,ENUM_PLAYSTYLE1_LONG_BALL_PASS,18,lpa) end
    end

    -- ── PASO 4b: ESPECIALISTAS (sin cap de pool) ─────────────
    -- Se aplican ANTES del filtro para que tengan score suficiente
    if fka>=CFG.SPECIALIST_T3 then pool_add_specialist(pool,ENUM_PLAYSTYLE1_DEAD_BALL,800,fka)
    elseif fka>=CFG.SPECIALIST_T2 then pool_add_specialist(pool,ENUM_PLAYSTYLE1_DEAD_BALL,350,fka)
    elseif fka>=CFG.SPECIALIST_T1 then pool_add_specialist(pool,ENUM_PLAYSTYLE1_DEAD_BALL,120,fka) end

    local stat_list=is_gk and SPECIALIST_STATS_GK or SPECIALIST_STATS_OUTFIELD
    for _,sname in ipairs(stat_list) do
        local sp_id=is_gk and SPECIALIST_MAP_GK[sname] or SPECIALIST_MAP_OUTFIELD[sname]
        if sp_id then
            local sv=sc[sname] or 0
            local bs=0
            if     sv>=CFG.SPECIALIST_T3 then bs=800
            elseif sv>=CFG.SPECIALIST_T2 then bs=350
            elseif sv>=CFG.SPECIALIST_T1 then bs=120 end
            if bs>0 then
                if is_def and DEF_SHOOT_BLOCK[sp_id] then bs=0
                elseif DEFENSIVE_ONLY_PS[sp_id] and is_att_all then bs=0
                elseif sp_id==ENUM_PLAYSTYLE1_RAPID and dri<70 then bs=0
                elseif IS_GK_PS[sp_id] and not is_gk then bs=0
                elseif not IS_GK_PS[sp_id] and is_gk then bs=0
                elseif is_offrole(sp_id,pos) then bs=math.floor(bs*0.4) end
            end
            if bs>0 then pool_add_specialist(pool,sp_id,bs,sv) end
        end
    end

    -- ── PASO 5: FILTRO DE PREREQS HARD/SOFT ──────────────────
    apply_prereq_filter(pool,sc)

    -- ── PASO 5b: FILTRO DURO DE ALTURA PARA PS AÉREOS ────────
    -- NUEVO V4: sin importar el headingaccuracy, si el jugador
    -- es muy bajo queda excluido de estos PS definitivamente.
    if not is_gk then
        if height<CFG.HEIGHT_MIN_AERIAL then
            pool[ENUM_PLAYSTYLE1_AERIAL_FORTRESS]=nil
        end
        if height<CFG.HEIGHT_MIN_HEADER then
            pool[ENUM_PLAYSTYLE1_PRECISION_HEADER]=nil
        end
    end

    -- ── PASO 6: CULTURA ──────────────────────────────────────
    if LEAGUE_DNA[leagueid] then
        for _,ps_id in ipairs(LEAGUE_DNA[leagueid]) do
            pool_add_cultural(pool,cultural_acc,ps_id,CFG.CULTURAL_DELTA_LEAGUE,80,sc)
        end
    end
    if NATION_DNA[nat] then
        for _,ps_id in ipairs(NATION_DNA[nat]) do
            pool_add_cultural(pool,cultural_acc,ps_id,CFG.CULTURAL_DELTA_NATION,80,sc)
        end
    end
    if CLUB_DNA[teamid] then
        for _,ps_id in ipairs(CLUB_DNA[teamid]) do
            pool_add_cultural(pool,cultural_acc,ps_id,CFG.CULTURAL_DELTA_CLUB,82,sc)
        end
    end

    -- ── PASO 7: SINERGIAS ────────────────────────────────────
    local snap={}
    for id,data in pairs(pool) do snap[id]=data.score end
    for ps_id,score in pairs(snap) do
        if score>=CFG.SYNERGY_THRESHOLD and SYNERGIES[ps_id] then
            local tgt=SYNERGIES[ps_id]
            local tgt_gk=IS_GK_PS[tgt]==true
            if (is_gk and tgt_gk) or (not is_gk and not tgt_gk) then
                local sb=pool[ps_id] and (pool[ps_id].base-5) or 75
                pool_add(pool,tgt,CFG.SYNERGY_SCORE,sb)
            end
        end
    end

    -- Fallback
    local pool_count=0
    for _ in pairs(pool) do pool_count=pool_count+1 end
    if pool_count==0 then
        if is_gk then pool_add(pool,ENUM_PLAYSTYLE2_GK_RUSH_OUT,30,70)
        elseif is_def then pool_add(pool,ENUM_PLAYSTYLE1_JOCKEY,30,70)
        elseif is_cdm then pool_add(pool,ENUM_PLAYSTYLE1_PRESS_PROVEN,30,70)
        else pool_add(pool,ENUM_PLAYSTYLE1_FIRST_TOUCH,30,70) end
        --Log(string.format("[DNA V4] FALLBACK: pid=%d pos=%d ovr=%d",pid,pos,ovr))
    end

    -- ── PASO 8: SHOOTING_BOOST + ROLE_BOOST + ORDENACIÓN ─────
    -- NUEVO V4: los PS de tiro reciben SHOOTING_BOOST adicional
    -- para posiciones atacantes, extremos, CAM, LM/RM.
    -- El boost NO modifica el score base; solo afecta el orden.
    local role_set=POS_ROLE_PS[pos] or {}
    local sorted_pool={}
    for ps_id,data in pairs(pool) do
        local boosted=data.score
        if role_set[ps_id] then boosted=boosted+CFG.ROLE_BOOST end
        if has_shoot_pri and SHOOTING_PS[ps_id] then boosted=boosted+CFG.SHOOTING_BOOST end
        table.insert(sorted_pool,{
            id=ps_id, score=data.score, boosted=boosted, base=data.base,
        })
    end
    table.sort(sorted_pool,function(a,b) return a.boosted>b.boosted end)

    local total_limit,plus_limit=get_limits(ovr,pot)

    local trait_field,icon_field
    if is_gk then
        trait_field="trait2"; icon_field="icontrait2"
    else
        trait_field="trait1"; icon_field="icontrait1"
    end

    -- Limpiar bits residuales antes de escribir
    if trait_field then p_table:SetRecordFieldValue(record,trait_field,0) end
    if icon_field  then p_table:SetRecordFieldValue(record,icon_field,0)  end

    -- Asignación principal
    local final_trait=0
    local count_total=0
    local offrole_used=0

    for _,cand in ipairs(sorted_pool) do
        if count_total>=total_limit then break end
        if cand.id and cand.id~=0 and (final_trait&cand.id)==0 then
            local offrole=is_offrole(cand.id,pos)
            if offrole and (offrole_used>=CFG.OFFROLE_MAX or count_total==0) then
                -- saltar
            else
                final_trait=final_trait|cand.id
                if offrole then offrole_used=offrole_used+1 end
                count_total=count_total+1
            end
        end
    end

    -- GARANTÍA DE TIRO — mínimo 2 PS de tiro para atacantes/extremos
    local SHOOTING_MIN = 2  -- [CONFIGURABLE]

    if has_shoot_pri then
        -- 1. Contar cuántos PS de tiro ya están asignados
        local shoot_count = 0
        for _, cand in ipairs(sorted_pool) do
            if (final_trait & cand.id) ~= 0 and SHOOTING_PS[cand.id] then
                shoot_count = shoot_count + 1
            end
        end

        if shoot_count < SHOOTING_MIN then
            -- 2. Recolectar PS de tiro del pool (ordenados por boosted)
            local shoot_candidates = {}
            for _, cand in ipairs(sorted_pool) do
                if cand.id ~= 0
                   and SHOOTING_PS[cand.id]
                   and (final_trait & cand.id) == 0
                   and not is_offrole(cand.id, pos) then
                    table.insert(shoot_candidates, cand.id)
                end
            end

            -- 3. Si faltan, forzar desde la lista base de tiro (aunque no estén en pool)
            local needed = SHOOTING_MIN - shoot_count
            if #shoot_candidates < needed then
                for _, ps_id in ipairs(SHOOTING_FORCE_ORDER) do
                    if (final_trait & ps_id) == 0 and not is_offrole(ps_id, pos) then
                        local already = false
                        for _, sid in ipairs(shoot_candidates) do
                            if sid == ps_id then already = true; break end
                        end
                        if not already then table.insert(shoot_candidates, ps_id) end
                    end
                end
            end

            -- 4. Recolectar víctimas: primero no-tiro no-offrole, luego no-tiro offrole
            local replaceable = {}
            local replaceable_off = {}
            for _, c2 in ipairs(sorted_pool) do
                if (final_trait & c2.id) ~= 0 and not SHOOTING_PS[c2.id] then
                    if is_offrole(c2.id, pos) then
                        table.insert(replaceable_off, c2)
                    else
                        table.insert(replaceable, c2)
                    end
                end
            end
            table.sort(replaceable, function(a, b) return a.boosted < b.boosted end)
            table.sort(replaceable_off, function(a, b) return a.boosted < b.boosted end)

            -- 5. Añadir/forzar PS de tiro hasta llegar al mínimo
            local replace_idx = 1
            local replace_off_idx = 1
            for _, shoot_id in ipairs(shoot_candidates) do
                if shoot_count >= SHOOTING_MIN then break end
                if (final_trait & shoot_id) ~= 0 then
                    -- ya está asignado (por si entró en la lista por fallback)
                elseif count_total < total_limit then
                    final_trait = final_trait | shoot_id
                    count_total = count_total + 1
                    shoot_count = shoot_count + 1
                else
                    local victim = nil
                    if replace_idx <= #replaceable then
                        victim = replaceable[replace_idx]; replace_idx = replace_idx + 1
                    elseif replace_off_idx <= #replaceable_off then
                        victim = replaceable_off[replace_off_idx]; replace_off_idx = replace_off_idx + 1
                    end
                    if victim then
                        final_trait = (final_trait & ~victim.id) | shoot_id
                        shoot_count = shoot_count + 1
                    else
                        break
                    end
                end
            end
        end
    end

    -- PS+ en dos niveles
    local final_icon=0
    local count_plus=0
    for _,cand in ipairs(sorted_pool) do  -- élite
        if count_plus>=plus_limit then break end
        if cand.id and cand.id~=0
           and (final_trait&cand.id)~=0
           and (final_icon &cand.id)==0
           and cand.base>=CFG.PLUS_STAT_ELITE
           and not is_offrole(cand.id,pos) then
            final_icon=final_icon|cand.id; count_plus=count_plus+1
        end
    end
    for _,cand in ipairs(sorted_pool) do  -- normal
        if count_plus>=plus_limit then break end
        if cand.id and cand.id~=0
           and (final_trait&cand.id)~=0
           and (final_icon &cand.id)==0
           and cand.base>=CFG.PLUS_STAT_NORMAL
           and cand.base<CFG.PLUS_STAT_ELITE
           and not is_offrole(cand.id,pos) then
            final_icon=final_icon|cand.id; count_plus=count_plus+1
        end
    end

    if trait_field then p_table:SetRecordFieldValue(record,trait_field,final_trait) end
    if icon_field  then p_table:SetRecordFieldValue(record,icon_field,final_icon)  end

    -- ── PASO 9: ANOMALÍA POST-PROCESO ────────────────────────
    local anomaly_triggered=false
    if ovr>=CFG.ANOMALY_MIN_OVR and trait_field
       and math.random(1,CFG.ANOMALY_CHANCE)==1 then
        anomaly_triggered=true
        local aid
        if     pos==0              then aid=ENUM_PLAYSTYLE1_LONG_BALL_PASS
        elseif is_cb               then aid=ENUM_PLAYSTYLE1_LONG_THROW
        elseif is_cb               then aid=ENUM_PLAYSTYLE1_POWER_SHOT
        elseif is_cb               then aid=ENUM_PLAYSTYLE1_TRICKSTER
        elseif is_fb               then aid=ENUM_PLAYSTYLE1_TRICKSTER
        elseif is_cdm              then aid=ENUM_PLAYSTYLE1_POWER_SHOT
        elseif pos==12 or pos==16  then aid=ENUM_PLAYSTYLE1_ACROBATIC
        elseif pos==14             then aid=ENUM_PLAYSTYLE1_POWER_SHOT
        elseif pos==18             then aid=ENUM_PLAYSTYLE1_BRUISER
        elseif pos==23 or pos==27  then aid=ENUM_PLAYSTYLE1_INTERCEPT
        elseif pos==25             then aid=ENUM_PLAYSTYLE1_DEAD_BALL
        else                            aid=ENUM_PLAYSTYLE1_INVENTIVE end
        if aid and aid~=0 and (final_trait&aid)==0 then
            final_trait=final_trait|aid
            p_table:SetRecordFieldValue(record,trait_field,final_trait)
        elseif RIVALRIES[teamid] then
            local rv=RIVALRIES[teamid].style
            if rv and rv~=0 and (final_trait&rv)==0 then
                final_trait=final_trait|rv
                p_table:SetRecordFieldValue(record,trait_field,final_trait)
            end
        end
    end

    -- ── PASO 10: HIDDEN PS ───────────────────────────────────
    local hidden_ps=get_hidden_ps(ovr,age,pos,comp,pas,sta,height,str)
    if hidden_ps and hidden_ps~=0 then
        local t2=p_table:GetRecordFieldValue(record,"trait2") or 0
        t2=tonumber(t2) or 0
        if (t2&hidden_ps)==0 then
            p_table:SetRecordFieldValue(record,"trait2",t2|hidden_ps)
        end
    end

    log_player(pid,ovr,pos,age,pool,anomaly_triggered,hidden_ps)
end

-- ============================================================
-- SECCIÓN 18: EJECUCIÓN
-- ============================================================
log_init()

local p_table=LE.db:GetTable("players")
if not p_table then
    MessageBox("DNA ENGINE V4",
        "ERROR CRITICO: tabla 'players' no encontrada.\n"..
        "Verifica que el Live Editor esté conectado.")
    return
end

local record=p_table:GetFirstRecord()
local total=0
while record>0 do
    process_player(record,p_table)
    record=p_table:GetNextValidRecord()
    total=total+1
end

log_close()

MessageBox("DNA ENGINE V4 — COMPLETADO",
    string.format(
        "Procesados: %d jugadores.\n"..
        "Log: %s\n\n"..
        "CAMBIOS V4:\n"..
        "  Aerial Fortress: requiere altura >= %d cm (hard)\n"..
        "  Precision Header: requiere altura >= %d cm (hard)\n"..
        "  Shooting boost (%d pts) para LM/RM/CAM/Wings/ST\n"..
        "  Garantía de tiro: atacantes siempre tienen >= 2 PS tiro\n"..
        "  Pool cap (%d pts) evita dominancia de PS genéricos\n"..
        "  Especialistas conservan su score sin cap",
        total,
        CFG.LOG_ENABLED and CFG.LOG_PATH or "desactivado",
        CFG.HEIGHT_MIN_AERIAL,
        CFG.HEIGHT_MIN_HEADER,
        CFG.SHOOTING_BOOST,
        CFG.MAX_POOL_SCORE
    )
)
