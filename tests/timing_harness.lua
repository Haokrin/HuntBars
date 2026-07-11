-- ---------------------------------------------------------------------------
-- Offline timing-model verification harness for Fluffy Hunter Bars.
--
--   Run from the repository root with plain Lua 5.1 (same version as WoW):
--     lua5.1 tests/timing_harness.lua
--
-- Stubs just enough of the WoW API to load the real addon logic files
-- (preamble.*, player.stats, abilities, recommendation_calculation) and then
-- replays a high-haste combat timeline, asserting:
--
--   1. The auto shot cycle prediction written by SPELL_CAST_SUCCESS
--      (fire-to-fire = UnitRangedDamage speed, aim = 0.5 * speed / base).
--   2. The Steady Shot safe-press deadline: pressing at the displayed window
--      end must finish the cast server-side no later than the server-side
--      aim start, accounting for both one-way latency legs (full RTT).
--   3. Mid-swing haste changes apply from the NEXT shot only: the shot in
--      flight keeps the schedule it was given at its fire (next_start /
--      next_fired and the first spark must not move), while the gaps after
--      it use the new attack speed.
--   4. Cast pushback: a cast in progress that ends after the predicted aim
--      start pushes next_start to the cast end exactly once.
--   5. The overdue-freeze grace keeps an absolute floor at high haste.
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
function GetSpellCooldown() return 0, 0, 1; end
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
fluffy.ranged_dmg_avg = 200;
fluffy.ability_steadyshot["known"] = true;
fluffy.InitDB();

-- pin latency to known values for deterministic assertions
-- (one-way 40 ms, RTT 80 ms; refresh_latency is disabled via last_check)
local ONE_WAY, RTT = 0.04, 0.08;
fluffy.latency = ONE_WAY;
fluffy.latency_rtt = RTT;
fluffy.latency_last_check = math.huge;

-- dispatch helper: feed a combat log event through the real addon handler
local function combat_log(event, spell_id)
    combat_log_payload = {now, event, nil, "guid-player", nil, nil, nil, nil,
                          nil, nil, nil, spell_id, "Auto Shot", nil};
    for _, f in ipairs(frames) do
        if f.OnEvent then f.OnEvent(f, "COMBAT_LOG_EVENT_UNFILTERED"); end
    end
end

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

-- =====================================================================
-- Scenario: base speed 3.0, 100% haste rating (mod = 0.5, eWS = 1.5 s).
-- Rating 1577 -> 1 + 0.01*1577/15.77 = 2.0 -> haste_mod = 0.5 exactly,
-- keeping the buff-table path and the UnitRangedDamage API consistent,
-- as they are in the live game.
-- =====================================================================
haste_rating_ranged = 1577;
api_ranged_speed = 1.5;

-- (1) auto shot cycle prediction -------------------------------------------
now = 10.0;  combat_log("SPELL_CAST_START", 75);    -- aim begins (bootstrap)
now = 10.25; combat_log("SPELL_CAST_SUCCESS", 75);  -- shot fires

check("fire: next_start = fired - cast + speed",
      fluffy.ability_autoshot["next_start"], 10.25 - 0.25 + 1.5);
check("fire: next_fired = fired + speed",
      fluffy.ability_autoshot["next_fired"], 10.25 + 1.5);
check("fire: aim model = 0.5 * speed / base",
      fluffy.ability_autoshot["next_fired"] - fluffy.ability_autoshot["next_start"],
      0.5 * 1.5 / 3.0);

-- (2) Steady Shot safe-press deadline ---------------------------------------
now = 10.3;
fluffy.analyze_game_state(3, now);

local ws = fluffy.ability_steadyshot["windows_s"];
local we = fluffy.ability_steadyshot["windows_e"];
assert(#ws >= 2, "expected at least two steady windows");

-- displayed aim start (client clock) for the incoming auto: spark - aim
local aim_start_client = fluffy.ability_autoshot["next_start"];
local steady_cast = 1.5 * 0.5; -- 1.5 s base at mod 0.5

check("steady window 1 starts now", ws[1], 10.3);
check("steady deadline = aim_start - cast(1.5*mod) - RTT",
      we[1], aim_start_client - steady_cast - RTT, 1e-6);

-- ground truth: press at the displayed deadline and replay on the SERVER
-- clock. The client timeline is anchored to event arrival (one-way late),
-- so server aim start = client aim start - one_way. The press takes one_way
-- to reach the server. The boundary press must NOT clip.
local press = we[1];
local server_cast_end = press + ONE_WAY + steady_cast;
local server_aim_start = aim_start_client - ONE_WAY;
check("boundary press: server cast end <= server aim start",
      math.max(0, server_cast_end - server_aim_start), 0, 1e-6);

-- regression guard: the old model (1.0 s base + RTT/2 margin) overshoots
local old_deadline = aim_start_client - (1.0 * 0.5) - ONE_WAY;
local old_clip = (old_deadline + ONE_WAY + steady_cast) - server_aim_start;
print(string.format("INFO  old 1.0s-base + RTT/2 model would clip by %.0f ms here",
      old_clip * 1000));
assert(old_clip > 0.2, "expected the old model to clip at this haste");

check("steady window 2 opens at previous auto fire",
      ws[2], fluffy.ability_autoshot["next_fired"], 1e-6);

-- (3) mid-swing haste change: applies from the NEXT shot only ---------------
-- The shot already in flight keeps the schedule it was given when it
-- fired; the new attack speed shows up from the following cycle onward.
-- The bar must NOT move the first spark when a proc comes up or falls
-- off mid-swing — rescaling it desyncs the bar from the actual fire.
now = 10.5;
api_ranged_speed = 1.5 * 1.15;                         -- Quick Shots fell off
haste_rating_ranged = 1577 / 1.15 / (2.0 / 1.15 - 1);  -- keep table mod consistent
fluffy.analyze_game_state(3, now);

check("haste change: next_start untouched mid-swing",
      fluffy.ability_autoshot["next_start"], 11.5, 1e-9);
check("haste change: next_fired untouched mid-swing",
      fluffy.ability_autoshot["next_fired"], 11.75, 1e-9);
check("haste change: first spark keeps its scheduled fire time",
      fluffy.autoshot_sparks[1], 11.75, 1e-6);
check("haste change: following gap uses the new speed",
      fluffy.autoshot_sparks[2] - fluffy.autoshot_sparks[1], 1.725, 1e-6);
check("haste change: first aim window uses the scheduled aim",
      fluffy.scheduled_aim, 0.25, 1e-9);

local nf_before, ns_before =
    fluffy.ability_autoshot["next_fired"], fluffy.ability_autoshot["next_start"];
now = 10.6;
fluffy.analyze_game_state(3, now);
check("haste change: next_fired still untouched on a later frame",
      fluffy.ability_autoshot["next_fired"], nf_before, 1e-9);
check("haste change: next_start still untouched on a later frame",
      fluffy.ability_autoshot["next_start"], ns_before, 1e-9);

-- (4) cast pushback into the prediction -------------------------------------
now = 10.7;
casting_info = {"Steady Shot", 12000};  -- cast ends at t = 12.0 (> next_start)
fluffy.analyze_game_state(3, now);
check("pushback: next_start moves to cast end",
      fluffy.ability_autoshot["next_start"], 12.0, 1e-6);
check("pushback: next_fired shifted by the same delay",
      fluffy.ability_autoshot["next_fired"], nf_before + (12.0 - ns_before), 1e-6);

now = 10.8;
fluffy.analyze_game_state(3, now);
check("pushback idempotent while the same cast is in progress",
      fluffy.ability_autoshot["next_start"], 12.0, 1e-6);
casting_info = nil;

-- (5) overdue-freeze grace floor (mirrors ui.core.lua formula) ---------------
local est_cast = fluffy.rotation_ews * 0.5 / fluffy.ranged_base_speed;
local grace = max(0.15, est_cast * 0.2);
check("freeze grace uses absolute floor at high haste", grace, 0.15);
assert(est_cast * 1.2 - est_cast < 0.15,
       "floor must exceed the old 0.2*est_cast margin at this haste");

-- ---------------------------------------------------------------------------
print("");
if failures == 0 then
    print("ALL TIMING CHECKS PASSED");
else
    print(failures .. " TIMING CHECK(S) FAILED");
    os.exit(1);
end
