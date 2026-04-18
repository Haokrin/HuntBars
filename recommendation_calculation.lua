local _, fluffy = ...

local last_update = 0;

fluffy.autoshot_sparks = {};
local show_steady = false;
local show_multi = false;
local show_arcane = false;

local function get_point_of_equilibrium_autoshot(A, ats, ate)

    local h = (ate - ats) * 2;
    local d_A = A["dmg"]();
    local cd_A = A["cd"](ats);

    local cast_A = A["cast"](ats);
    local cdb_A = A["cdb"](ats);
    local dps_A = d_A/(cdb_A + cast_A);

    -- (t + cast_A - ats) * dps_auto <  (ate - t) * dps_A
    -- t * (dps_auto + dps_A) <  (ate) * dps_A - (cast_A - ats) * dps_auto
    -- t * (dps_auto + dps_A) <  ate * dps_A - (cast_A - ats) * dps_auto
    -- t <  (ate * dps_A - (cast_A - ats) * dps_auto)/(dps_auto + dps_A)

    local cast_auto = (ate - ats);
    local eWS = fluffy.ability_autoshot["cdb"](ats) + cast_auto;
    local d_auto = fluffy.ability_autoshot["dmg"]();
    local dps_auto = d_auto / eWS;

    return (ate * dps_A - (cast_A - ats) * dps_auto)/(dps_auto + dps_A);
end

local function get_point_of_equilibrium_abilities(dmg_1, dmg_2)

    local alpha = 1.4;

    return 1.5 * (alpha * dmg_2 - dmg_1)/(alpha * dmg_2 + dmg_1);

end

-- local function get_point_of_equilibrium(A_dmg, B_dmg, A_cast, B_cast)
--     return (A_dmg*(B_cast)-fluffy.recommendation_tolerance*B_dmg*(A_cast))/(fluffy.recommendation_tolerance*B_dmg + A_dmg);
-- end

local intervals_autoshot_starts  = {};
local intervals_autoshot_ends    = {};
local intervals_abilities_starts = {};
local intervals_abilities_ends   = {};

local intervals_abilities_starts_tmp = {};
local intervals_abilities_ends_tmp   = {};



local function optimize_towards_autoshot()
    for A, v in pairs(intervals_abilities_starts) do
        for i = 1,#v do
            local ts = v[i];
            local te = intervals_abilities_ends[A][i];

            for j = 1,#intervals_autoshot_starts do
                local auto_ts = intervals_autoshot_starts[j];
                local auto_te =   intervals_autoshot_ends[j];
                local f = auto_ts;

                if A == fluffy.ability_steadyshot then
                    -- Steady: use DPS equilibrium to find how early to stop.
                    -- Also apply the same cast_time + latency hard cap used for
                    -- Multi-Shot: even if DPS says to keep casting until the
                    -- equilibrium point, the server won't receive the cast start
                    -- until fluffy.latency seconds later, so the full 1.5 s cast
                    -- would finish after the autoshot arrives on high-ping
                    -- connections.
                    local cast_time = A["cast"](auto_ts);
                    f = min(f, get_point_of_equilibrium_autoshot(A, auto_ts, auto_te));
                    local hard_cap = auto_ts - cast_time - fluffy.latency;
                    if hard_cap > ts then
                        f = min(f, hard_cap);
                    end
                else
                    -- Multi/Arcane also have a cast time. Pulling the window
                    -- end back by cast(t) ensures we never suggest firing them
                    -- when the cast itself would overlap the incoming autoshot.
                    -- We also subtract the measured network latency so that
                    -- by the time the server receives and starts the cast, the
                    -- full cast duration still finishes before the auto shot.
                    -- Without this, the bar shows multi-shot as safe to cast
                    -- when it would actually clip the auto on higher-latency
                    -- connections.
                    local cast_time = A["cast"](auto_ts);
                    if cast_time > 0 then
                        f = auto_ts - cast_time - fluffy.latency;
                    end
                end

                local new_ts_1 = ts;
                local new_te_1 = min(f, te);

				if new_ts_1 < new_te_1 + 0.005 then
					table.insert(intervals_abilities_starts_tmp, new_ts_1);
					table.insert(intervals_abilities_ends_tmp, new_te_1);
				end

                local new_ts_2 = max(auto_te, ts);
                local new_te_2 = te;

				ts = new_ts_2;
				te = new_te_2;
            end
			
			if ts < te + 0.005 then
				table.insert(intervals_abilities_starts_tmp, ts);
				table.insert(intervals_abilities_ends_tmp, te);
			end
        end

        -- Always replace intervals to avoid preserving stale full-bar when
        -- clipping produces zero-width windows (e.g. steady at extreme haste).
        -- If _tmp is empty, wipe original to show ability has no windows.
        wipe(intervals_abilities_starts[A]);
        wipe(intervals_abilities_ends[A]);

        for k, v in pairs(intervals_abilities_starts_tmp) do
            table.insert(intervals_abilities_starts[A], v);
        end

        for k, v in pairs(intervals_abilities_ends_tmp) do
            table.insert(intervals_abilities_ends[A], v);
        end

        wipe(intervals_abilities_starts_tmp);
        wipe(intervals_abilities_ends_tmp);
    end
end


-- trimms the intervals in A such as A := A \setminus [ts_B, te_B]
local function set_minus(A, ts_B, te_B)
    local ints_A_tgt_s = intervals_abilities_starts[A];
    local ints_A_tgt_e = intervals_abilities_ends[A];

    for i=1,#ints_A_tgt_s do
        local ts_A = ints_A_tgt_s[i];
        local te_A = ints_A_tgt_e[i];

        if te_B >= ts_A and ts_B <= te_A then

            local new_ts_A = ts_A;
            local new_te_A = ts_B;

            if new_ts_A < new_te_A + 0.005 then
                table.insert(intervals_abilities_starts_tmp, new_ts_A);
                table.insert(intervals_abilities_ends_tmp, new_te_A);
            end

            ts_A = te_B;
        end

        if ts_A < te_A + 0.005 then
            table.insert(intervals_abilities_starts_tmp, ts_A);
            table.insert(intervals_abilities_ends_tmp, te_A);
        end
    end

    -- Always replace intervals to avoid preserving stale full-bar when
    -- clipping produces zero-width windows.
    wipe(intervals_abilities_starts[A]);
    wipe(intervals_abilities_ends[A]);

    for k, v in pairs(intervals_abilities_starts_tmp) do
        table.insert(intervals_abilities_starts[A], v);
    end

    for k, v in pairs(intervals_abilities_ends_tmp) do
        table.insert(intervals_abilities_ends[A], v);
    end

    wipe(intervals_abilities_starts_tmp);
    wipe(intervals_abilities_ends_tmp);
end

local ability_priority_indices = {};
local ability_priority_abilities = {};
local ability_priority_dmg = {};
local function sort_ability_priority(a, b)
    return ability_priority_dmg[a] > ability_priority_dmg[b];
end

-- Rotation-aware priority: Steady > Multi > Arcane.
-- Per diziet559's rotation tools: "Only cast steady immediately following
-- an auto. Cast multi/arcane tastefully where you cannot fit a steady."
-- Steady Shot is the primary weaver (highest priority), Multi and Arcane
-- are situational gap-fillers (lower priority). Among Multi and Arcane,
-- sort by damage to break ties.
local function sort_ability_priority_rotation(a, b)
    local A = ability_priority_abilities[a];
    local B = ability_priority_abilities[b];
    local a_is_steady = (A == fluffy.ability_steadyshot);
    local b_is_steady = (B == fluffy.ability_steadyshot);

    if a_is_steady ~= b_is_steady then
        return a_is_steady;  -- Steady beats non-Steady
    end
    -- Both Steady or both non-Steady: sort by damage
    return ability_priority_dmg[a] > ability_priority_dmg[b];
end

local function optimize_intervals_simple()

    -- calculating disjoint intervals
    local idx = 1;
    for B, ints_B in pairs(intervals_abilities_starts) do 
        local dmg_B = B["dmg"]();
        local ints_B_tmp = intervals_abilities_ends[B];
        table.insert(ability_priority_dmg, dmg_B);
        table.insert(ability_priority_abilities, B);
        table.insert(ability_priority_indices, idx);
        idx = idx + 1;
    end

    -- clipping of interval ends
    -- Use rotation-aware sort so Steady gets priority (primary weaver),
    -- then Multi and Arcane (secondary gap-fillers). Steady must claim
    -- windows first so Multi/Arcane don't squeeze it out.
    table.sort(ability_priority_indices, sort_ability_priority_rotation);

    for i_tmp=1,#ability_priority_indices do 
        local i = ability_priority_indices[i_tmp];

        local B = ability_priority_abilities[i];
        local ints_B_s = intervals_abilities_starts[B];
        local ints_B_e = intervals_abilities_ends[B];

        for j_tmp=i_tmp+1,#ability_priority_indices do 
            local j = ability_priority_indices[j_tmp];

            local A = ability_priority_abilities[j];

            for i=1,#ints_B_s do
                local ts_B = ints_B_s[i];
                local te_B = ints_B_e[i];
    
                set_minus(A, ts_B, te_B);
            end
        end
    end

    -- clipping of interval ends
    -- table.sort(ability_priority_indices, sort_ability_priority);
    -- table.sort(ability_priority_indices, sort_ability_priority_2);

    for i_tmp=1,#ability_priority_indices do 
        local i = ability_priority_indices[i_tmp];

        local B = ability_priority_abilities[i];
        local dmg_B = ability_priority_dmg[i];
        local ints_B_s = intervals_abilities_starts[B];
        local ints_B_e = intervals_abilities_ends[B];

        for j_tmp=i_tmp+1,#ability_priority_indices do 
            local j = ability_priority_indices[j_tmp];

            local A = ability_priority_abilities[j];
            local dmg_A = ability_priority_dmg[j];
            local ints_A_s = intervals_abilities_starts[A];
            local ints_A_e = intervals_abilities_ends[A];

            --intervals in A will be clipped by intervals in B
            for k=1,#ints_A_e do
                local ts_A = ints_A_s[k];
                local te_A = ints_A_e[k];

                if ts_A < te_A then
                    for l=1,#ints_B_s do
                        local ts_B = ints_B_s[l];
                        local te_B = ints_B_e[l];

                        if (ts_B < te_B) and (ts_B >= te_A) then
                            -- print(- get_point_of_equilibrium_abilities(dmg_A, dmg_B));
                            -- Reserve cast time + latency for B (priority ability) to complete before A's window ends.
                            -- At high haste, B's cast time is short; without this buffer, lower-priority A squeezes in.
                            local b_cast_time = B["cast"](ts_B);
                            te_A = min(te_A, ts_B - get_point_of_equilibrium_abilities(dmg_A, dmg_B) - b_cast_time - fluffy.latency);
                        end
                    end
    
                    ints_A_e[k] = te_A;
                end
            end
        end
    end

    wipe(ability_priority_abilities);
    wipe(ability_priority_dmg);
    wipe(ability_priority_indices);
end

-- local function clip_interval_starts()
-- 	for A, _ in pairs(intervals_abilities_starts) do
-- 		for B, _ in pairs(intervals_abilities_starts) do
-- 			if A ~= B then
-- 				clip_intervals_abilities(A, B);
-- 			end
-- 		end
-- 	end
-- end


local function analyze_windows_of_opportunities_experimental(abilities, window_length)

    local t = GetTime();

    -- first we define curently expected windows for autoshot casts
    for k, auto_fired_time in pairs(fluffy.autoshot_sparks) do
        local auto_cast = fluffy.ability_autoshot["cast"](auto_fired_time);
        table.insert(intervals_autoshot_ends, auto_fired_time);
        table.insert(intervals_autoshot_starts, auto_fired_time - auto_cast);

        -- Show only the cast portion of each autoshot window.  Extending
        -- vis_start back to "fired" caused the bar to fill the entire
        -- display whenever cast_finishes pushed the next spark far into
        -- the future (e.g. after Steady/Multi-Shot): ts was clamped to 0
        -- (fired is always in the past) while te hit the full bar length.
        table.insert(fluffy.ability_autoshot["windows_s"], auto_fired_time - auto_cast);
        table.insert(fluffy.ability_autoshot["windows_e"], auto_fired_time);
    end

    --then we start with defining intervals for each ability
    for k, A in pairs(abilities) do
        local tmp_ = max(fluffy.cast_finishes, max(t, t + A["cd"](t)));
        table.insert(intervals_abilities_starts[A], tmp_);
        table.insert(intervals_abilities_ends[A], t + window_length);
    end

    optimize_towards_autoshot();
    optimize_intervals_simple();

    -- DONE, we post process the results
    for A, TMP_START in pairs(intervals_abilities_starts) do
        local TMP_END = intervals_abilities_ends[A];

        for i = 1,#TMP_START do
            local ts = TMP_START[i];
            local te = TMP_END[i];

            if ts < te then
                table.insert(A["windows_s"], ts);
                table.insert(A["windows_e"], te);
            end
        end
    end
    
    if fluffy.ability_raptorstrike["known"] then
        local cd_raptor = max(fluffy.cast_finishes, max(t + fluffy.ability_raptorstrike["cd"](t), t));
        local cd_melee = max(fluffy.cast_finishes, max(t + fluffy.ability_meleestrike["cd"](t), t));
        -- print(cd_melee - t);

        if fluffy.melee_mh_weapon_id > 0 then
            if (cd_melee < cd_raptor) then

                if (IsUsableSpell(fluffy.ability_raptorstrike["active_id"])) then
                    table.insert(fluffy.ability_meleestrike["windows_s"], cd_melee);
                    table.insert(fluffy.ability_meleestrike["windows_e"], cd_raptor);
        
                    
                    table.insert(fluffy.ability_raptorstrike["windows_s"], cd_raptor);
                    table.insert(fluffy.ability_raptorstrike["windows_e"], cd_raptor + 25);
                else
                    table.insert(fluffy.ability_meleestrike["windows_s"], cd_melee);
                    table.insert(fluffy.ability_meleestrike["windows_e"], cd_melee + 25);
                end
            else
                if (IsUsableSpell(fluffy.ability_raptorstrike["active_id"])) then
                    table.insert(fluffy.ability_raptorstrike["windows_s"], cd_raptor);
                    table.insert(fluffy.ability_raptorstrike["windows_e"], cd_raptor + 25);
                else
                    table.insert(fluffy.ability_meleestrike["windows_s"], cd_melee);
                    table.insert(fluffy.ability_meleestrike["windows_e"], cd_melee + 25);
                end
            end
        end
    end
    
    wipe(intervals_autoshot_starts);
    wipe(intervals_autoshot_ends);
    for k,v in pairs(intervals_abilities_starts) do
        wipe(v);
    end
    for k,v in pairs(intervals_abilities_ends) do
        wipe(v);
    end
end

-- ---------------------------------------------------------------------------
-- Latency helper
-- ---------------------------------------------------------------------------
-- Reads GetNetStats() at most once every 0.5 seconds. The function returns
-- bandwidthIn, bandwidthOut, latencyHome, latencyWorld in milliseconds.
-- We take the larger of the two latency figures and convert to seconds,
-- clamping to a sensible [50 ms, 500 ms] window. An exponential moving
-- average (alpha=0.3) smooths out transient spikes.
local function refresh_latency()
    local t = GetTime();
    if t - fluffy.latency_last_check < 0.5 then return end
    fluffy.latency_last_check = t;
    local _, _, home, world = GetNetStats();
    if home and world then
        local ms = max(home or 0, world or 0);
        local new_latency = max(0.05, min(0.5, ms * 0.001));
        -- Exponential moving average (alpha=0.3) so a single ping spike does
        -- not instantly shift all ability windows; sustained changes still
        -- propagate within a few seconds.
        fluffy.latency = fluffy.latency * 0.7 + new_latency * 0.3;
    end
end

-- ---------------------------------------------------------------------------
-- Rotation-mode derivation (diziet559.github.io/rotationtools)
-- ---------------------------------------------------------------------------
-- Thresholds are taken directly from the DPS graphs on that page.
-- eWS = cdb(t) + cast(t) = base_speed * haste_mod = full attack period.
--
--   eWS >= 2.5   French (5:5:1:1) or Short French (5:4:1:1) for SV
--   1.7–2.5      Long French (5:6:1:1) — IAotH proc or minor haste buffs
--   1.5–1.7      Skipping (5:9:1:1)   — RF + Hawk or RF + BL
--   1.3–1.5      1:1
--   0.94–1.3     2:3  (alternating 1:1 / 1:2 cycles, RF+BL range)
--   0.75–0.94    1:2
--   0.62–0.75    2:5  (1:2 / 1:3 mix, extreme haste only)
--   < 0.62       1:3  (not realistically reachable in P1)
--
local function derive_rotation_mode(ews)
    if     ews >= 2.5  then return "French";
    elseif ews >= 1.7  then return "LongFrench";
    elseif ews >= 1.5  then return "Skipping";
    elseif ews >= 1.3  then return "1:1";
    elseif ews >= 0.94 then return "2:3";
    elseif ews >= 0.75 then return "1:2";
    elseif ews >= 0.62 then return "2:5";
    else                    return "1:3";
    end
end

local abilities_to_consider = {};

-- local function can_consider_melee(mode)
--     -- if mode == 0 then
--     --     return false;
--     -- elseif mode == 1 then
--     --     return true;
--     -- else
--     --     if IsItemInRange(8149, "target") and UnitExists("target") and UnitIsVisible("target") and UnitCanAttack("player", "target") and (not UnitIsDead("target")) then
--     --         return true;
--     --     end
--     -- end
--     return false;
-- end
local last_time_moved = 0;
function analyze_game_state(window_len, t)


    -- t is passed in from gui_Update so logic and render share one timestamp.
    -- The throttle is now handled entirely by gui_Update (last_logic_update).
    t = t or GetTime();
    -- local name, text, texture, startTime, endTime, isTradeSkill, castID, spellID = CastingInfo();
    -- if name ~= nil then
    --     print(startTime/1000 - fluffy.cast_finishes, endTime/1000 - fluffy.cast_finishes);
    -- end
    

    wipe(fluffy.ability_autoshot["windows_s"]);
    wipe(fluffy.ability_aimedshot["windows_s"]);
    wipe(fluffy.ability_arcaneshot["windows_s"]);
    wipe(fluffy.ability_multishot["windows_s"]);
    wipe(fluffy.ability_steadyshot["windows_s"]);
    wipe(fluffy.ability_raptorstrike["windows_s"]);
    wipe(fluffy.ability_meleestrike["windows_s"]);
    wipe(fluffy.ability_autoshot["windows_e"]);
    wipe(fluffy.ability_aimedshot["windows_e"]);
    wipe(fluffy.ability_arcaneshot["windows_e"]);
    wipe(fluffy.ability_multishot["windows_e"]);
    wipe(fluffy.ability_steadyshot["windows_e"]);
    wipe(fluffy.ability_raptorstrike["windows_e"]);
    wipe(fluffy.ability_meleestrike["windows_e"]);
    wipe(fluffy.autoshot_sparks);
    if fluffy.is_player_hunter == false or fluffy.ranged_weapon_id == 0 then
		return;
	end    
    update_player_stats();

    -- Refresh cached latency reading (throttled to once per 5 s)
    refresh_latency();

    -- Derive current effective weapon speed and rotation mode label.
    -- eWS = full attack period = swing cooldown + cast time = base_speed * haste.
    -- Use UnitRangedDamage() as the authoritative speed source instead of
    -- computing from the buff table.  The game engine already knows the exact
    -- haste from ALL effects; our manual buff tracking can drift and cause
    -- the spark prediction to disagree with the actual fire time, which is
    -- the root cause of visual jumps.  Fall back to buff table computation
    -- only if the API returns an invalid value.
    if fluffy.ranged_base_speed > 0 then
        local api_speed = UnitRangedDamage("player");
        local new_ews;
        if api_speed and api_speed > 0.1 then
            new_ews = api_speed;
        else
            new_ews = fluffy.ability_autoshot["cdb"](t) + fluffy.ability_autoshot["cast"](t);
        end

        -- Do NOT rescale next_start mid-swing when haste changes.
        -- The old code adjusted next_start proportionally every frame,
        -- which caused visible spark jumps the instant a haste buff was
        -- gained or lost.  Instead, let next_start stay where the last
        -- SPELL_CAST_SUCCESS set it.  When the auto fires at a slightly
        -- different time (the game engine does adjust mid-swing), the
        -- SPELL_CAST_SUCCESS handler will set the authoritative next
        -- cycle, and spark_correction will smooth the small transition.
        -- This matches WeaponSwingTimer's approach: speed is only
        -- applied on fire events, never mid-swing.

        fluffy.rotation_ews  = new_ews;
        fluffy.rotation_mode = derive_rotation_mode(new_ews);
    end

    local spell, _, _, _, endTime = UnitCastingInfo("player");
    if not fluffy.is_casting_autoshot then
        fluffy.cast_finishes = t;
    else
        -- During autoshot cast, set cast_finishes to next_start (cooldown end).
        -- Do NOT push it forward with UnitCastingInfo's endTime — the autoshot
        -- cast is already blocked by the autoshot intervals in the optimizer.
        -- Pushing cast_finishes with endTime + latency caused ability windows
        -- to jump left on fire (they started at endTime + latency during cast,
        -- then snapped to t after fire, creating a visible gap/shift).
        fluffy.cast_finishes = fluffy.ability_autoshot["next_start"];
    end
    if spell and not fluffy.is_casting_autoshot then
        -- Only push cast_finishes for non-autoshot casts (Steady, Multi, etc.).
        -- Add measured network latency so the addon waits for server-side
        -- registration before recommending the next ability.  Without this,
        -- on connections with >~80 ms ping the bar lights up slightly too
        -- early and causes the next cast to clip the outgoing auto shot.
        fluffy.cast_finishes = max(fluffy.cast_finishes, endTime * 0.001 + fluffy.latency);
    else
        local spellC, _, _, _, endTimeC = UnitChannelInfo("player");
        if spellC then
            fluffy.cast_finishes = max(fluffy.cast_finishes, endTimeC * 0.001 + fluffy.latency);
        end
    end

    if fluffy.feign_death_active == 1 then
		fluffy.ability_autoshot["fired"] = t;
		fluffy.ability_autoshot["next_start"] = t + fluffy.ability_autoshot["cdb"](t);

		local mainSpeed, _ = UnitAttackSpeed("player");
		fluffy.ability_meleestrike["fired"] = t;
		fluffy.ability_meleestrike["next_start"] = t + mainSpeed;
    end

    -- Use API-derived effective weapon speed for autoshot spark computation
    -- so spark positions are perfectly consistent with the fire handler.
    -- The buff table cast()/cdb() can drift slightly from UnitRangedDamage(),
    -- causing a small shift every time the auto fires.
    local api_ews = fluffy.rotation_ews;
    local api_cast_time;
    if api_ews > 0.1 and fluffy.ranged_base_speed > 0 then
        api_cast_time = api_ews * 0.5 / fluffy.ranged_base_speed;
    else
        api_cast_time = fluffy.ability_autoshot["cast"](t);
        api_ews = api_cast_time + fluffy.ability_autoshot["cdb"](t);
    end

    local autoshot_shift = fluffy.ability_autoshot["next_start"];
    if autoshot_shift < t - 1.2 * api_cast_time then
        autoshot_shift = t;
    end
    -- Only apply cast_finishes constraint for NON-autoshot casts (e.g. Steady,
    -- Multi).  During the autoshot cast itself, cast_finishes already includes
    -- endTime + latency (= next_start + cast_time + latency).  Using that to
    -- push autoshot_shift and then adding cast() again would double-count the
    -- cast time, causing the spark to jump forward by ~cast_time + latency
    -- every frame during the autoshot cast and snap back when it fires.
    if not fluffy.is_casting_autoshot then
        autoshot_shift = max(fluffy.cast_finishes, max(autoshot_shift, fluffy.autoshot_delay));
    else
        autoshot_shift = max(autoshot_shift, fluffy.autoshot_delay);
    end
    autoshot_shift = autoshot_shift + api_cast_time;
    table.insert(fluffy.autoshot_sparks, autoshot_shift);

    while autoshot_shift < t + 3*window_len do
        -- Safety guard: if advance is zero or negative (can happen when
        -- ranged_base_speed is 0 or not yet loaded) the loop would hang forever.
        -- Break out and let the next frame try again once stats are loaded.
        if api_ews <= 0.05 then break end
        autoshot_shift = autoshot_shift + api_ews;
        table.insert(fluffy.autoshot_sparks, autoshot_shift);
    end


    -- if fluffy.ability_aimedshot["known"] and IsUsableSpell(fluffy.ability_aimedshot["active_id"]) then
    --     table.insert(abilities_to_consider, fluffy.ability_aimedshot);
    -- end

    -- if fluffy.ability_meleestrike["known"] and can_consider_melee(fluffy.ability_meleestrike["forbid"]) then
    --     table.insert(abilities_to_consider, fluffy.ability_meleestrike);
    -- end

    -- if fluffy.ability_raptorstrike["known"] and (can_consider_melee(fluffy.ability_raptorstrike["forbid"]) and IsUsableSpell(fluffy.ability_raptorstrike["active_id"])) then
    --     table.insert(abilities_to_consider, fluffy.ability_raptorstrike);
    -- end
    -- Evaluate mana availability FIRST, then decide what to show.
    -- Previously show_* was set using low_mana_* before IsUsableSpell() had
    -- assigned them, meaning they were always nil (falsy) on the first check.
    local _, low_mana_arcane = IsUsableSpell(fluffy.ability_arcaneshot["active_id"]);
    local _, low_mana_multi  = IsUsableSpell(fluffy.ability_multishot["active_id"]);
    local _, low_mana_steady = IsUsableSpell(fluffy.ability_steadyshot["active_id"]);

    show_steady = (fluffy.ability_steadyshot["known"] and not low_mana_steady);
    show_multi  = (fluffy.ability_multishot["known"]  and not low_mana_multi and FluffyDBPC["consider_multi"][1]);
    show_arcane = (fluffy.ability_arcaneshot["known"] and not low_mana_arcane and FluffyDBPC["consider_arcane"][1]);

    if show_arcane then
        table.insert(abilities_to_consider, fluffy.ability_arcaneshot);
        if intervals_abilities_starts[fluffy.ability_arcaneshot] == nil then
            intervals_abilities_starts[fluffy.ability_arcaneshot] = {};
        end
        if intervals_abilities_ends[fluffy.ability_arcaneshot] == nil then
            intervals_abilities_ends[fluffy.ability_arcaneshot] = {};
        end
    end

    if show_multi then
        table.insert(abilities_to_consider, fluffy.ability_multishot);
        if intervals_abilities_starts[fluffy.ability_multishot] == nil then
            intervals_abilities_starts[fluffy.ability_multishot] = {};
        end
        if intervals_abilities_ends[fluffy.ability_multishot] == nil then
            intervals_abilities_ends[fluffy.ability_multishot] = {};
        end
    end

    if show_steady then
        table.insert(abilities_to_consider, fluffy.ability_steadyshot);
        if intervals_abilities_starts[fluffy.ability_steadyshot] == nil then
            intervals_abilities_starts[fluffy.ability_steadyshot] = {};
        end
        if intervals_abilities_ends[fluffy.ability_steadyshot] == nil then
            intervals_abilities_ends[fluffy.ability_steadyshot] = {};
        end
    end
    if intervals_abilities_starts[fluffy.ability_autoshot] == nil then
        intervals_abilities_starts[fluffy.ability_autoshot] = {};
    end
    if intervals_abilities_ends[fluffy.ability_autoshot] == nil then
        intervals_abilities_ends[fluffy.ability_autoshot] = {};
    end

    -- print(fluffy.ability_arcaneshot["dmg"]());
    -- print(fluffy.ability_steadyshot["dmg"]());
    -- print("---");

    -- if fluffy.ability_autoshot["known"] and IsUsableSpell(fluffy.ability_autoshot["active_id"]) then
    --     table.insert(abilities_to_consider, fluffy.ability_autoshot);
    -- end

    -- table.insert(fluffy.ability_arcaneshot["windows_s"], 0);
    -- table.insert(fluffy.ability_arcaneshot["windows_e"], t + 5*window_len);

    
    -- local tinit = GetTime();
    -- analyze_windows_of_opportunities_cd(abilities_to_consider, t, t + 5*window_len);
    analyze_windows_of_opportunities_experimental(abilities_to_consider, 2*window_len);
    -- print(GetTime() - tinit);
    wipe(abilities_to_consider);
end
