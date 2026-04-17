-- This script assigns Playstyles and Playstyles+ to players.
-- - Players with no playstyles get two random ones based on their position.
-- - Players >= 75 OVR get one Playstyle+.
-- - Players >= 80 OVR get a second Playstyle+.
-- - Players >= 85 OVR get a third Playstyle+.
-- - Players >= 90 OVR get a fourth Playstyle+.
-- - Players >= 95 OVR get a fifth Playstyle+.
-- - If a player needs more regular playstyles to reach their Playstyle+ threshold,
--   additional random regular playstyles will be assigned first.
-- - GK Playstyles use trait2/icontrait2.

require 'imports/other/helpers'
require 'imports/other/playstyles_enum' -- Make sure this file contains the ENUMs provided (FC26 list)

-- Seed the random number generator
math.randomseed(os.time())

-- Define thresholds for Playstyle+ assignments
local playstyle_plus_threshold = 75
local playstyle_double_plus_threshold = 80
local playstyle_triple_plus_threshold = 85
local playstyle_quad_plus_threshold = 90
local playstyle_quint_plus_threshold = 95

--[[ 
    Position-to-Playstyle mapping (using FC26 ENUM names).
    Each position maps to a LIST (table) of suitable ENUM values for random assignment.
    Position 0 (GK) uses ENUM_PLAYSTYLE2_GK_* (trait2) pool.
    Other positions use ENUM_PLAYSTYLE1_*.
    Keep the original position IDs used in your script:
      0 = GK
      3 = RB
      5 = CB
      7 = LB
      10 = CDM
      12 = RM
      14 = CM
      16 = LM
      18 = CAM
      23 = RW
      25 = ST
      27 = LW
--]]
local position_playstyles = {
    -- Goalkeepers (Use ENUM_PLAYSTYLE2_GK_* for trait2/icontrait2)
    [0] = {
        ENUM_PLAYSTYLE2_GK_FAR_THROW,
        ENUM_PLAYSTYLE2_GK_FOOTWORK,
        ENUM_PLAYSTYLE2_GK_CROSS_CLAIMER,
        ENUM_PLAYSTYLE2_GK_RUSH_OUT,
        ENUM_PLAYSTYLE2_GK_FAR_REACH,
        ENUM_PLAYSTYLE2_GK_DEFLECTOR
    }, -- GK

    -- Defenders (Use ENUM_PLAYSTYLE1_*)
    -- RB
    [3] = {
        ENUM_PLAYSTYLE1_JOCKEY,
        ENUM_PLAYSTYLE1_SLIDE_TACKLE,
        ENUM_PLAYSTYLE1_INTERCEPT,
        ENUM_PLAYSTYLE1_QUICK_STEP,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_RAPID,
        ENUM_PLAYSTYLE1_WHIPPED_PASS,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_AERIAL_FORTRESS,   -- new for defenders
        ENUM_PLAYSTYLE1_PRECISION_HEADER   -- new for defenders
    },
    -- CB
    [5] = {
        ENUM_PLAYSTYLE1_BLOCK,
        ENUM_PLAYSTYLE1_ANTICIPATE,
        ENUM_PLAYSTYLE1_SLIDE_TACKLE,
        ENUM_PLAYSTYLE1_BRUISER,
        ENUM_PLAYSTYLE1_AERIAL_FORTRESS,   -- new for defenders
        ENUM_PLAYSTYLE1_PRECISION_HEADER   -- new for defenders
    },
    -- LB
    [7] = {
        ENUM_PLAYSTYLE1_JOCKEY,
        ENUM_PLAYSTYLE1_SLIDE_TACKLE,
        ENUM_PLAYSTYLE1_INTERCEPT,
        ENUM_PLAYSTYLE1_QUICK_STEP,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_RAPID,
        ENUM_PLAYSTYLE1_WHIPPED_PASS,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_AERIAL_FORTRESS,   -- new for defenders
        ENUM_PLAYSTYLE1_PRECISION_HEADER   -- new for defenders
    },

    -- Midfielders (Use ENUM_PLAYSTYLE1_*)
    -- CDM
    [10] = {
        ENUM_PLAYSTYLE1_INTERCEPT,
        ENUM_PLAYSTYLE1_ANTICIPATE,
        ENUM_PLAYSTYLE1_BRUISER,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_LONG_BALL_PASS,
        ENUM_PLAYSTYLE1_SLIDE_TACKLE,
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },
    -- RM
    [12] = {
        ENUM_PLAYSTYLE1_RAPID,
        ENUM_PLAYSTYLE1_WHIPPED_PASS,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_QUICK_STEP,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_TRICKSTER,
        -- midfield additions
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },
    -- CM
    [14] = {
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_INCISIVE_PASS,
        ENUM_PLAYSTYLE1_PINGED_PASS,
        ENUM_PLAYSTYLE1_LONG_BALL_PASS,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_PRESS_PROVEN,
        -- midfield additions
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },
    -- LM
    [16] = {
        ENUM_PLAYSTYLE1_RAPID,
        ENUM_PLAYSTYLE1_WHIPPED_PASS,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_QUICK_STEP,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_TRICKSTER,
        -- midfield additions
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },
    -- CAM
    [18] = {
        ENUM_PLAYSTYLE1_INCISIVE_PASS,
        ENUM_PLAYSTYLE1_TIKI_TAKA,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_FIRST_TOUCH,
        ENUM_PLAYSTYLE1_DEAD_BALL,
        ENUM_PLAYSTYLE1_TRICKSTER,
        -- midfield additions
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },

    -- Attackers (Use ENUM_PLAYSTYLE1_*)
    -- RW
    [23] = {
        ENUM_PLAYSTYLE1_RAPID,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_QUICK_STEP,
        ENUM_PLAYSTYLE1_FINESSE_SHOT,
        ENUM_PLAYSTYLE1_TRICKSTER,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_ACROBATIC,
        -- attacker additions (required)
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },
    -- ST
    [25] = {
        ENUM_PLAYSTYLE1_FINESSE_SHOT,
        ENUM_PLAYSTYLE1_POWER_SHOT,
        ENUM_PLAYSTYLE1_FIRST_TOUCH,
        ENUM_PLAYSTYLE1_ACROBATIC,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_TRICKSTER,
        -- attacker additions (required)
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    },
    -- LW
    [27] = {
        ENUM_PLAYSTYLE1_RAPID,
        ENUM_PLAYSTYLE1_TECHNICAL,
        ENUM_PLAYSTYLE1_QUICK_STEP,
        ENUM_PLAYSTYLE1_FINESSE_SHOT,
        ENUM_PLAYSTYLE1_TRICKSTER,
        ENUM_PLAYSTYLE1_RELENTLESS,
        ENUM_PLAYSTYLE1_ACROBATIC,
        -- attacker additions (required)
        ENUM_PLAYSTYLE1_INVENTIVE,
        ENUM_PLAYSTYLE1_GAMECHANGER,
        ENUM_PLAYSTYLE1_LOW_DRIVEN_SHOT,
        ENUM_PLAYSTYLE1_PRECISION_HEADER,
        ENUM_PLAYSTYLE1_ENFORCER
    }
}

-- Helper function to count set bits (number of playstyles)
local function countSetBits(n)
    local count = 0
    while n > 0 do
        n = n & (n - 1) -- Clear the least significant set bit
        count = count + 1
    end
    return count
end

-- Helper function to get a list of set bits (playstyle enum values)
local function getSetBitsAsList(n)
    local list = {}
    for i = 0, 30 do -- Check bits 0 to 30 (corresponding to 2^0 to 2^30)
        local bitValue = 1 << i
        if (n & bitValue) ~= 0 then
            table.insert(list, bitValue)
        end
    end
    return list
end

-- Helper function to add N distinct playstyles to a bitmask from a pool
-- Returns the new bitmask and true if any playstyles were added
local function addDistinctPlaystyles(current_bitmask, num_to_add, playstyle_pool)
    local new_bitmask = current_bitmask
    local added_any = false
    local already_in_bitmask = getSetBitsAsList(current_bitmask)

    -- Create a list of playstyles from the pool that are not already in current_bitmask
    local available_to_add = {}
    for _, ps_candidate in ipairs(playstyle_pool) do
        local found = false
        for _, existing_ps in ipairs(already_in_bitmask) do
            if ps_candidate == existing_ps then
                found = true
                break
            end
        end
        if not found then
            table.insert(available_to_add, ps_candidate)
        end
    end

    -- Shuffle the available_to_add list to pick randomly without replacement
    for i = #available_to_add, 2, -1 do
        local j = math.random(i)
        available_to_add[i], available_to_add[j] = available_to_add[j], available_to_add[i]
    end

    -- Add the required number of distinct playstyles
    for i = 1, math.min(num_to_add, #available_to_add) do
        new_bitmask = new_bitmask | available_to_add[i]
        added_any = true
    end
    return new_bitmask, added_any
end

-- Get Players Table
local players_table = LE.db:GetTable("players")
if not players_table then
    MessageBox("Error", "Could not get 'players' table.")
    return
end
local current_record = players_table:GetFirstRecord()

local overall = 0
local preferred_position = 0
local trait1 = 0
local icontrait1 = 0
local trait2 = 0
local icontrait2 = 0
local player_updated = false
local update_count = 0

while current_record > 0 do
    player_updated = false -- Reset flag for each player

    overall = players_table:GetRecordFieldValue(current_record, "overallrating")
    preferred_position = players_table:GetRecordFieldValue(current_record, "preferredposition1")
    trait1 = players_table:GetRecordFieldValue(current_record, "trait1")
    icontrait1 = players_table:GetRecordFieldValue(current_record, "icontrait1")
    trait2 = players_table:GetRecordFieldValue(current_record, "trait2")
    icontrait2 = players_table:GetRecordFieldValue(current_record, "icontrait2")

    local current_trait, current_icontrait, trait_field, icontrait_field
    local is_gk = (preferred_position == 0)

    -- Determine which trait fields to use (GK uses trait2/icontrait2, outfield uses trait1/icontrait1)
    if is_gk then
        current_trait = trait2
        current_icontrait = icontrait2
        trait_field = "trait2"
        icontrait_field = "icontrait2"
    else
        current_trait = trait1
        current_icontrait = icontrait1
        trait_field = "trait1"
        icontrait_field = "icontrait1"
    end

    -- 1. Assign initial random regular playstyles if player has none (assign two)
    if current_trait == 0 then
        local possible_playstyles = position_playstyles[preferred_position]
        if possible_playstyles and #possible_playstyles >= 2 then
            -- Assign two distinct random playstyles
            local new_trait_value, added = addDistinctPlaystyles(0, 2, possible_playstyles)
            if added then
                players_table:SetRecordFieldValue(current_record, trait_field, new_trait_value)
                current_trait = new_trait_value -- Update local variable for subsequent checks
                player_updated = true
            end
        end
    end

    -- Only proceed with Playstyle+ logic if the player has any regular playstyles
    if current_trait ~= 0 then
        -- 2. Determine the target number of Playstyle+ based on overall rating
        local target_ps_plus_count = 0
        if overall >= playstyle_quint_plus_threshold then
            target_ps_plus_count = 5
        elseif overall >= playstyle_quad_plus_threshold then
            target_ps_plus_count = 4
        elseif overall >= playstyle_triple_plus_threshold then
            target_ps_plus_count = 3
        elseif overall >= playstyle_double_plus_threshold then
            target_ps_plus_count = 2
        elseif overall >= playstyle_plus_threshold then
            target_ps_plus_count = 1
        end

        -- 3. Ensure player has enough *regular* playstyles to convert into Playstyle+
        local current_regular_playstyle_count = countSetBits(current_trait)
        local needed_regular_for_ps_plus = target_ps_plus_count - current_regular_playstyle_count

        if needed_regular_for_ps_plus > 0 then
            local possible_regular_playstyles_for_position = position_playstyles[preferred_position]
            if possible_regular_playstyles_for_position then
                local updated_trait, added = addDistinctPlaystyles(current_trait, needed_regular_for_ps_plus, possible_regular_playstyles_for_position)
                if added then
                    players_table:SetRecordFieldValue(current_record, trait_field, updated_trait)
                    current_trait = updated_trait -- Update local variable
                    player_updated = true
                    -- Re-calculate count since trait might have changed
                    current_regular_playstyle_count = countSetBits(current_trait)
                end
            end
        end

        -- 4. Assign Playstyle+ iteratively up to the target count
        local current_icontrait_count = countSetBits(current_icontrait)
        -- Re-get available_regular_playstyles in case current_trait was updated
        local available_regular_playstyles = getSetBitsAsList(current_trait)

        for i = 1, target_ps_plus_count do
            if current_icontrait_count < i then -- If we still need to assign the i-th Playstyle+
                -- Find regular playstyles that are NOT already Playstyle+
                local eligible_for_current_plus = {}
                for _, ps in ipairs(available_regular_playstyles) do
                    -- Check if this playstyle is NOT already one of the current Playstyle+
                    if (current_icontrait & ps) == 0 then
                        table.insert(eligible_for_current_plus, ps)
                    end
                end

                if #eligible_for_current_plus > 0 then
                    local random_index = math.random(#eligible_for_current_plus)
                    local selected_playstyle_plus = eligible_for_current_plus[random_index]

                    local new_icontrait_value = current_icontrait | selected_playstyle_plus
                    players_table:SetRecordFieldValue(current_record, icontrait_field, new_icontrait_value)
                    current_icontrait = new_icontrait_value -- Update local variable
                    current_icontrait_count = current_icontrait_count + 1 -- Increment count
                    player_updated = true
                else
                    -- No more eligible regular playstyles to convert to Playstyle+
                    break -- Exit the loop as we cannot assign any more Playstyle+
                end
            end
        end
    end

    if player_updated then
        update_count = update_count + 1
    end

    current_record = players_table:GetNextValidRecord()
end

MessageBox("Done", string.format("Playstyle script finished.\n%d players had playstyles updated.", update_count))
