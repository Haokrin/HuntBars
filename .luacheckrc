std = "lua51"
self = false
max_line_length = false
unused_args = false

-- Whitespace style (trailing/blank-line whitespace) is not enforced.
ignore = { "611", "612", "614" }

-- Globals owned by this addon: SavedVariables, named frames, frame arrays,
-- and the slash command registration.
globals = {
    "FluffyDBPC",
    "FluffyBar",
    "FluffyBars_autoshotsparks",
    "FluffyBars_bars",
    "SLASH_FLUFFY_BAR1",
    SlashCmdList = { other_fields = true },
}

read_globals = {
    -- WoW API
    "CreateFrame", "GetTime", "GetNetStats", "GetBuildInfo",
    "UnitClass", "UnitGUID", "UnitLevel", "UnitBuff", "UnitDebuff",
    "UnitHealth", "UnitHealthMax", "UnitAffectingCombat",
    "UnitCastingInfo", "UnitChannelInfo", "UnitRangedDamage",
    "UnitAttackSpeed", "UnitRangedAttackPower", "UnitAttackPower",
    "GetCombatRating", "GetRangedCritChance", "GetCritChance",
    "GetHitModifier", "GetSpellBonusDamage", "GetSpellCooldown",
    "IsSpellKnown", "IsUsableSpell", "GetInventoryItemID",
    "GetInventoryItemLink", "GetItemInfo", "GetNumTalentTabs",
    "GetNumTalents", "GetTalentInfo", "IsShiftKeyDown",
    "CombatLogGetCurrentEventInfo", "UIParent", "WorldFrame",
    "CR_HASTE_RANGED", "CR_HASTE_MELEE",
    -- WoW-provided Lua extensions
    "wipe", "min", "max", "floor",
    -- named tooltip regions created via GameTooltipTemplate
    "AmmoTooltipTextLeft3", "AmmoTooltipTextLeft4",
    "QuiverTooltipTextLeft3", "QuiverTooltipTextLeft4",
    "QuiverTooltipTextLeft5", "QuiverTooltipTextLeft6",
    "QuiverTooltipTextLeft7", "QuiverTooltipTextLeft8",
}

files["tests/"] = {
    -- The harnesses stub the WoW API as globals and poke addon state;
    -- silence global-definition warnings there.
    ignore = { "111", "112", "113", "121", "122", "131" },
}
