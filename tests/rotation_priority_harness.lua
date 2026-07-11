-- ---------------------------------------------------------------------------
-- Offline rotation-priority verification harness for Fluffy Hunter Bars.
--
--   Run from the repository root with plain Lua 5.1 (same version as WoW):
--     lua5.1 tests/rotation_priority_harness.lua
--
-- Verifies the Steady > Multi > Arcane window priority against the model on
-- diziet559.github.io/rotationtools ("only cast steady immediately following
-- an auto; cast multi/arcane tastefully where you cannot fit a steady"):
--
--   1. Multi/Arcane windows never overlap Steady windows (Arcane must only
--      appear where a Steady cannot be fired).
--   2. GCD safety: a press at ANY point of a shown Multi/Arcane window,
--      plus the 1.5 s global cooldown it triggers, still lets the next
--      Steady window be used before its deadline.  Without this, the bars
--      recommend Arcane presses that silently cost a Steady Shot.
--   3. French rotation (eWS 3.0): Steady, then Multi, then Arcane windows
--      tile the gap at the expected boundaries.
--   4. 1:1 rotation (eWS 1.5): Multi/Arcane windows are EMPTY — every gap
--      belongs to Steady and any instant press there would cost a Steady.
-- ---------------------------------------------------------------------------

-- ------------------------------------------------------------------ WoW API
local now = 0;                  -- simulated client clock
local api_ranged_speed = 3.0;   -- UnitRangedDamage("player") return
local casting_info = nil;       -- {name, endTime_ms}
local frames = {};              -- frames created by the addon

min, max, floor = math.min, math.max, math.floor;
function wipe(t) for k in pairs(t) do t[k] = nil; end return t; end
function GetTime() return now; end
function CreateFrame() local f = {};
    f.RegisterEvent = function() end;
    f.SetScript = function(self, kind, fn) self[kind] = fn; end;
    table.insert(frames, f); return f;
end
CR_HASTE_RANGED, CR_HASTE_MELEE = 20, 18;
local haste_rating_ranged = 0;
function GetCombatRating(i) return (i == CR_HASTE_RANGED) and haste_rating_ranged or 0; end
function UnitLevel() return 70; end
function UnitClass() return "Hunter", "HUNTER", 3; end
function UnitGUID() return "guid-player"; end
function UnitRangedDamage() return api_ranged_speed, 100, 200, 0, 0, 0; end
function UnitAttackSpeed() return 2.0, nil; end
function UnitRangedAttackPower() return 1000, 0, 0; end
function UnitAttackPower() return 500, 0, 0; end
function UnitBuff() return nil; end
function UnitDebuff() return nil; end
function UnitCastingInfo()
    if casting_info then return casting_info[1], "", "", 0, casting_info[2]; end
    return nil;
end
function UnitChannelInfo() return nil; end
function UnitAffectingCombat() return true; end
function UnitHealth() return 100; end
function UnitHealthMax() return 100; end
function IsUsableSpell() return true, false; end
function IsSpellKnown() return false; end
local spell_cooldowns = {};  -- [spell_id] = {start, duration}
function GetSpellCooldown(id)
    local cd = spell_cooldowns[id];
    if cd then return cd[1], cd[2], 1; end
    return 0, 0, 1;
end
function GetSpellBonusDamage() return 0; end
function GetRangedCritChance() return 10; end
function GetCritChance() return 10; end
function GetHitModifier() return 0; end
function GetNetStats() return 0, 0, 60, 80; end
function GetInventoryItemID() return nil; end
function GetBuildInfo() return "2.5.4", "0", "0", 20504; end

local combat_log_payload = nil;
-- explicit bounds: the payload contains embedded nils, and unpack(t) would
-- otherwise stop at the first hole
function CombatLogGetCurrentEventInfo() return unpack(combat_log_payload, 1, 21); end

-- ----------------------------------------------------------- load the addon
local fluffy = {};
local function load_addon_file(path)
    local fn = assert(loadfile(path));
    fn("FluffyHunterBars", fluffy);
end
load_addon_file("preamble.debug.lua");
load_addon_file("preamble.variables.lua");
load_addon_file("preamble.auxiliary.lua");
load_addon_file("player.stats.lua");
load_addon_file("abilities.lua");
load_addon_file("recommendation_calculation.lua");

-- minimal post-load state normally set by ADDON_LOADED / handlers
fluffy.is_player_hunter = true;
fluffy.player_id = "guid-player";
fluffy.client_version = 20504;
fluffy.ranged_base_speed = 3.0;
fluffy.ranged_weapon_id = 42;
fluffy.ranged_dmg_avg = 250;
fluffy.ability_steadyshot["known"] = true;
fluffy.ability_multishot["known"] = true;
fluffy.ability_arcaneshot["known"] = true;
-- max-rank flat bonuses, normally assigned by update_spell_data()
fluffy.ability_steadyshot["flat_bonus"] = 150;
fluffy.ability_multishot["flat_bonus"]  = 205;
fluffy.ability_arcaneshot["flat_bonus"] = 273;
fluffy.InitDB();

-- pin latency to known values for deterministic assertions
local ONE_WAY, RTT = 0.04, 0.08;
fluffy.latency = ONE_WAY;
fluffy.latency_rtt = RTT;
fluffy.latency_last_check = math.huge;

local GCD = 1.5;

local failures = 0;
local function check(label, got, want, tolerance)
    tolerance = tolerance or 1e-9;
    if math.abs(got - want) <= tolerance then
        print(string.format("PASS  %-58s %.4f", label, got));
    else
        failures = failures + 1;
        print(string.format("FAIL  %-58s got %.4f, want %.4f", label, got, want));
    end
end

-- Sets up a clean mid-cycle auto shot state: last shot fired `frac` of a
-- cycle ago, prediction consistent with `ews`, nothing casting.
local function setup_cycle_state(ews, frac, t)
    local mod = ews / fluffy.ranged_base_speed;
    api_ranged_speed = ews;
    -- rating such that the buff-table haste mod equals the API speed
    haste_rating_ranged = (1 / mod - 1) * 1577;
    local aim = 0.5 * mod;
    local fired = t - frac * ews;
    fluffy.ability_autoshot["fired"] = fired;
    fluffy.ability_autoshot["next_fired"] = fired + ews;
    fluffy.ability_autoshot["next_start"] = fired + ews - aim;
    fluffy.rotation_ews = ews;
    fluffy.is_casting_autoshot = false;
    fluffy.cast_finishes = 0;
    fluffy.autoshot_delay = 0;
    casting_info = nil;
end

-- Property checks shared by all scenarios.  Returns the number of steady
-- windows so callers can assert the checks were not vacuous.
local function check_priority_properties(label, t)
    local sWs, sWe = fluffy.ability_steadyshot["windows_s"], fluffy.ability_steadyshot["windows_e"];
    local horizon = t + 3.4;  -- visible bar range
    -- GCD spillover allowance: up to one gap's idle GCD time may be
    -- borrowed (the French band's "slightly delays the auto shots");
    -- zero at 1:1 speeds where the strict rule must hold.
    local slack = math.max(0, fluffy.rotation_ews - GCD);

    for _, low in ipairs({fluffy.ability_multishot, fluffy.ability_arcaneshot}) do
        local lWs, lWe = low["windows_s"], low["windows_e"];
        for i = 1, #lWs do
            -- (1) no overlap with any steady window
            for j = 1, #sWs do
                local lo = math.max(lWs[i], sWs[j]);
                local hi = math.min(lWe[i], sWe[j]);
                if hi - lo > 0.005 then
                    failures = failures + 1;
                    print(string.format("FAIL  %s: %s window [%.3f..%.3f] overlaps steady [%.3f..%.3f]",
                        label, low["name"], lWs[i], lWe[i], sWs[j], sWe[j]));
                end
            end
            -- (2) GCD safety at the worst press time (window end): the GCD
            -- may push the next steady past its deadline by at most slack
            local x = math.min(lWe[i], horizon);
            if x >= lWs[i] then
                for j = 1, #sWs do
                    if sWe[j] > x then
                        if x + GCD > sWe[j] + slack + 1e-6 then
                            failures = failures + 1;
                            print(string.format(
                                "FAIL  %s: %s press at %.3f + GCD ends %.3f, past steady deadline %.3f + slack %.3f",
                                label, low["name"], x, x + GCD, sWe[j], slack));
                        end
                        break;
                    end
                end
            end
        end
    end
    return #sWs;
end

-- =====================================================================
-- Scenario A: eWS 3.0 (slowest band), fresh auto fire.
-- Fire at 10.5 (aim 10.0..10.5), evaluated at t = 10.6.
-- Expected first-gap tiling (aim start of next auto = 13.0):
--   steady [10.6 .. 11.82]   (13.0 - 1.5 cast - 0.08 RTT + 0.4 accepted
--                             clip: min(0.4, half the per-gap GCD slack))
--   multi  [11.82 .. 12.42]  (up to 13.0 - 0.5 cast - 0.08 RTT; casts
--                             other than Steady never clip)
--   arcane [12.42 .. 13.0]   (instant; up to the aim start — the GCD
--                             reservation is non-binding here because the
--                             per-gap slack 1.5 covers the spillover)
-- =====================================================================
now = 10.0;  combat_log_payload = {now, "SPELL_CAST_START", nil, "guid-player",
    nil, nil, nil, nil, nil, nil, nil, 75, "Auto Shot", nil};
for _, f in ipairs(frames) do if f.OnEvent then f.OnEvent(f, "COMBAT_LOG_EVENT_UNFILTERED"); end end
now = 10.5;  combat_log_payload[1] = now; combat_log_payload[2] = "SPELL_CAST_SUCCESS";
for _, f in ipairs(frames) do if f.OnEvent then f.OnEvent(f, "COMBAT_LOG_EVENT_UNFILTERED"); end end

now = 10.6;
fluffy.analyze_game_state(3, now);

local sWe = fluffy.ability_steadyshot["windows_e"];
local mWs, mWe = fluffy.ability_multishot["windows_s"], fluffy.ability_multishot["windows_e"];
local aWs, aWe = fluffy.ability_arcaneshot["windows_s"], fluffy.ability_arcaneshot["windows_e"];

check("A: steady deadline = aim - cast - RTT + 0.4 clip", sWe[1], 11.82, 1e-6);
check("A: multi opens at steady deadline",            mWs[1], 11.82, 1e-6);
check("A: multi deadline = aim - cast - RTT",         mWe[1], 12.42, 1e-6);
check("A: arcane opens at multi deadline",            aWs[1], 12.42, 1e-6);
check("A: arcane extends to the aim start",           aWe[1], 13.0, 1e-6);
check_priority_properties("A", now);

-- =====================================================================
-- Scenario B: eWS 1.5 (1:1 rotation), fresh auto fire.
-- No Multi/Arcane window may appear: every inter-shot gap is a Steady
-- gap, and any instant pressed there delays the next Steady past its
-- deadline (this was the reported "arcane covers steady" bug).
-- =====================================================================
setup_cycle_state(1.5, 0.05, 20.3);
now = 20.3;
fluffy.analyze_game_state(3, now);

check("B: 1:1 rotation shows no multi windows",  #fluffy.ability_multishot["windows_s"], 0);
check("B: 1:1 rotation shows no arcane windows", #fluffy.ability_arcaneshot["windows_s"], 0);
assert(#fluffy.ability_steadyshot["windows_s"] >= 2, "expected steady windows at 1:1");
check_priority_properties("B", now);

-- =====================================================================
-- Scenario C: sweep effective speed and cycle position; the overlap and
-- GCD-safety properties must hold everywhere.
-- =====================================================================
local sweep_checks, sweep_steady_windows = 0, 0;
for ews10 = 9, 30 do          -- eWS 0.9 .. 3.0
    for _, frac in ipairs({0.1, 0.5, 0.9}) do
        local ews = ews10 / 10;
        local t = 100 + ews10 * 40 + frac * 10;
        setup_cycle_state(ews, frac, t);
        now = t;
        fluffy.analyze_game_state(3, t);
        sweep_steady_windows = sweep_steady_windows +
            check_priority_properties(string.format("C ews=%.1f frac=%.1f", ews, frac), t);
        sweep_checks = sweep_checks + 1;
    end
end
assert(sweep_steady_windows > sweep_checks, "sweep produced too few steady windows to be meaningful");
print(string.format("INFO  sweep: %d states checked, %d steady windows seen", sweep_checks, sweep_steady_windows));

-- =====================================================================
-- Scenario D: multi_ready_at, the timestamp driving the steady-slot
-- recolor ("use multi shot instead of a steady shot whenever it is off
-- CD").  Must ignore the GCD (the steady window start already accounts
-- for it) but honor the tracked fire time and any real API cooldown.
-- =====================================================================
setup_cycle_state(3.0, 0.1, 5000);
now = 5000;
fluffy.ability_multishot["fired"] = 0;
fluffy.analyze_game_state(3, now);
check("D: multi never fired -> ready now", fluffy.multi_ready_at, now, 1e-6);

fluffy.ability_multishot["fired"] = now - 3;
fluffy.analyze_game_state(3, now);
check("D: multi fired 3s ago -> ready in 7 (10s cd)", fluffy.multi_ready_at, now + 7, 1e-6);

fluffy.ability_multishot["fired"] = 0;
spell_cooldowns[fluffy.spell_id_multi] = {now - 4, 10};
fluffy.analyze_game_state(3, now);
check("D: API cooldown (no tracked fire) -> ready in 6", fluffy.multi_ready_at, now + 6, 1e-6);
spell_cooldowns[fluffy.spell_id_multi] = nil;

FluffyDBPC["consider_multi"][1] = false;
fluffy.analyze_game_state(3, now);
assert(fluffy.multi_ready_at == math.huge, "multi disabled must yield math.huge");
print(string.format("PASS  %-58s %s", "D: multi disabled -> never recolors", "inf"));
FluffyDBPC["consider_multi"][1] = true;

-- =====================================================================
-- Scenario E: rotation-mode label thresholds, checked at the anchor
-- points from the rotationtools DPS-over-haste graphs (a 3.0 weapon for
-- clean numbers; the graphs use the 2.9 Sunfury bow).  BM = with 5/5
-- Serpent's Swiftness (haste 1.38 with quiver), SV = quiver only (1.15).
-- =====================================================================
local function check_label(label, got, want)
    if got == want then
        print(string.format("PASS  %-58s %s", label, got));
    else
        failures = failures + 1;
        print(string.format("FAIL  %-58s got %s, want %s", label, got, want));
    end
end

fluffy.serpent_swiftness = 1.2;  -- BM: 5/5 Serpent's Swiftness
check_label("E: BM base 2.17 -> French",            fluffy.derive_rotation_mode(2.17), "French");
check_label("E: BM hawk 1.89 -> LongFrench",        fluffy.derive_rotation_mode(1.89), "LongFrench");
check_label("E: BM RF 1.55 -> 1:1",                 fluffy.derive_rotation_mode(1.55), "1:1");
check_label("E: BM RF+hawk 1.35 -> Skipping",       fluffy.derive_rotation_mode(1.35), "Skipping");
check_label("E: BM RF+lust 1.19 -> Skipping",       fluffy.derive_rotation_mode(1.19), "Skipping");
check_label("E: BM RF+hawk+lust 0.94 -> 2:3",       fluffy.derive_rotation_mode(0.94), "2:3");
check_label("E: BM RF+lust+pot 0.83 -> 1:2",        fluffy.derive_rotation_mode(0.83), "1:2");
check_label("E: BM RF+hawk+lust+pot+DST 0.66 -> 2:5", fluffy.derive_rotation_mode(0.66), "2:5");
check_label("E: below 0.62 -> 1:3",                 fluffy.derive_rotation_mode(0.60), "1:3");

fluffy.serpent_swiftness = 1.0;  -- SV: no Serpent's Swiftness
check_label("E: SV base 2.61 -> ShortFrench",       fluffy.derive_rotation_mode(2.61), "ShortFrench");
check_label("E: SV hawk 2.27 -> French",            fluffy.derive_rotation_mode(2.27), "French");
check_label("E: SV RF 1.86 -> LongFrench",          fluffy.derive_rotation_mode(1.86), "LongFrench");

-- =====================================================================
-- Scenario F: weave-aware melee windows.  Per the rotation overview,
-- ranged damage has priority over weaving: no melee window may suggest
-- starting a weave inside [aim_start - weave_time - RTT, fire] of any
-- predicted auto shot, and windows must resume at the fire time.
-- =====================================================================
setup_cycle_state(3.0, 0.1, 6000);
now = 6000;
fluffy.ability_raptorstrike["known"] = true;
fluffy.melee_mh_weapon_id = 1;
fluffy.ability_meleestrike["next_start"] = 0;
fluffy.analyze_game_state(3, now);

local rWs, rWe = fluffy.ability_raptorstrike["windows_s"], fluffy.ability_raptorstrike["windows_e"];
assert(#rWs >= 2, "expected raptor windows split around predicted autos");
local weave_overlap_checks = 0;
for i = 1, #rWs do
    for k = 1, #fluffy.autoshot_sparks do
        local fire = fluffy.autoshot_sparks[k];
        local blocked_from = fire - fluffy.ability_autoshot["cast"](fire) - fluffy.weave_time - RTT;
        local lo = math.max(rWs[i], blocked_from);
        local hi = math.min(rWe[i], fire);
        if hi - lo > 0.005 then
            failures = failures + 1;
            print(string.format("FAIL  F: raptor window [%.3f..%.3f] overlaps weave-blocked [%.3f..%.3f]",
                rWs[i], rWe[i], blocked_from, fire));
        end
        weave_overlap_checks = weave_overlap_checks + 1;
    end
end
print(string.format("INFO  F: %d weave overlap checks across %d raptor windows", weave_overlap_checks, #rWs));

local first_fire = fluffy.autoshot_sparks[1];
check("F: first raptor window ends before the incoming auto",
      rWe[1], first_fire - fluffy.ability_autoshot["cast"](first_fire) - fluffy.weave_time - RTT, 1e-6);
check("F: second raptor window resumes at the auto fire time",
      rWs[2], first_fire, 1e-6);
fluffy.ability_raptorstrike["known"] = false;
fluffy.melee_mh_weapon_id = 0;

-- =====================================================================
-- Scenario G: BM-base French band (eWS 2.17).  Regression for "arcane
-- never appears between two autos under the French rotation": the strict
-- GCD reservation (next steady deadline - 1.5) empties arcane at every
-- eWS below ~2.25, but the reference 5:5:1:1 cycle includes one arcane —
-- the rotation absorbs the GCD spillover as a micro auto delay.  With
-- the per-gap slack allowance the gap must tile as
--   auto -> steady -> multi -> arcane -> auto.
-- =====================================================================
setup_cycle_state(2.17, 0.05, 7000);
now = 7000;
fluffy.analyze_game_state(3, now);

local g_aim_start = fluffy.ability_autoshot["next_start"];
local g_steady_cast = 1.5 * (2.17 / 3.0);
local g_clip_allowance = math.min(0.4, 0.5 * (2.17 - GCD));

local gWs, gWe = fluffy.ability_arcaneshot["windows_s"], fluffy.ability_arcaneshot["windows_e"];
local gmWe = fluffy.ability_multishot["windows_e"];
local gsWe = fluffy.ability_steadyshot["windows_e"];
assert(#gWs >= 1, "expected an arcane window in the French gap");
check("G: French arcane opens at the multi deadline",
      gWs[1], gmWe[1], 1e-6);
check("G: French arcane extends to the aim start",
      gWe[1], g_aim_start, 1e-6);
-- Steady presses may run a bounded amount past the strict no-clip
-- deadline: the reference French rotation clips autos by 0.12-0.36 s
-- with Steady casts pressed at GCD boundaries.
check("G: steady deadline = strict deadline + accepted clip",
      gsWe[1], g_aim_start - g_steady_cast - RTT + g_clip_allowance, 1e-6);
assert(g_clip_allowance > 0.1 and g_clip_allowance <= 0.4,
       "clip allowance must stay within the reference autodelay range");
-- the strict reservation (no slack, no clip) would have emptied the
-- arcane window entirely at this speed
local g_strict_next_deadline = g_aim_start + 2.17 - g_steady_cast - RTT;
assert(g_strict_next_deadline - GCD < gWs[1],
       "strict reservation must be binding at this speed for the regression to be meaningful");
check_priority_properties("G", now);

-- ---------------------------------------------------------------------------
print("");
if failures == 0 then
    print("ALL ROTATION PRIORITY CHECKS PASSED");
else
    print(failures .. " ROTATION PRIORITY CHECK(S) FAILED");
    os.exit(1);
end
