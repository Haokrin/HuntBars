local _, fluffy = ...

-- File-level coords shared between mouse-down/up/hide handlers.
local x_coord_before_moving = 0;
local y_coord_before_moving = 0;
local is_moving = false;

-- ---------------------------------------------------------------------------
-- Input handlers (drag to reposition the bar with Shift+Click)
-- ---------------------------------------------------------------------------
local function gui_MouseDown(self, button)

    local shift_key = IsShiftKeyDown();

    if button == "LeftButton" and not self.isMoving and shift_key == true then
        x_coord_before_moving, y_coord_before_moving = self:GetCenter();

        if FluffyDBPC["locked"][1] == true then
            print("Fluffy bars are locked! Please use '|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."unlock|r' to enable repositioning via drag&drop");
            return;
        end

        self:StartMoving();
        self.isMoving = true;
        is_moving = true;
    end
end

local function gui_MouseUp(self, button)
    if button == "LeftButton" and self.isMoving then
        if FluffyDBPC["locked"][1] == false then
            print("Fluffy bars are unlocked! Please consider '|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."lock|r' to disable repositioning via drag&drop");
        end

        self:StopMovingOrSizing();
        self.isMoving = false;
        is_moving = false;

        local x_coord_after_moving, y_coord_after_moving = self:GetCenter();
        local shift_x = x_coord_after_moving - x_coord_before_moving;
        local shift_y = y_coord_after_moving - y_coord_before_moving;

        FluffyDBPC["pos"][2] = FluffyDBPC["pos"][2] + shift_x;
        FluffyDBPC["pos"][3] = FluffyDBPC["pos"][3] + shift_y;
    end
end

local function gui_Hide(self, button)
    if ( self.isMoving ) then
        self:StopMovingOrSizing();
        self.isMoving = false;

        local x_coord_after_moving, y_coord_after_moving = self:GetCenter();
        local shift_x = x_coord_after_moving - x_coord_before_moving;
        local shift_y = y_coord_after_moving - y_coord_before_moving;

        FluffyDBPC["pos"][2] = FluffyDBPC["pos"][2] + shift_x;
        FluffyDBPC["pos"][3] = FluffyDBPC["pos"][3] + shift_y;
    end
end

-- ---------------------------------------------------------------------------
-- Main per-frame update loop
-- Runs every frame via FluffyBar:SetScript("OnUpdate", gui_Update).
-- Delegates rendering to fluffy.draw_frame (ui.render.lua) and label
-- updates to fluffy.update_labels (ui.labels.lua).
-- ---------------------------------------------------------------------------
local function gui_Update(self, elapsed)

    if fluffy.is_player_hunter == false or FluffyDBPC["hidden"][1] == true or is_moving == true then
        return;
    end

    local t = GetTime();

    if fluffy.time_loaded > t then
        return;
    end

    -- -----------------------------------------------------------------------
    -- IDLE FREEZE: skip computation when out of combat with a stale timer.
    -- The dirty flag is set by combat-log handlers so the first auto of a
    -- new pull is picked up immediately.
    -- -----------------------------------------------------------------------
    if fluffy.logic_dirty then
        fluffy.last_dirty_time = t;
    end
    local autoshot_stale = fluffy.ability_autoshot["next_start"] < t - 2;
    if autoshot_stale and not UnitAffectingCombat("player") and not fluffy.logic_dirty and (t - fluffy.last_dirty_time) > 12 then
        return;
    end

    local fluffyBar_len   = FluffyDBPC["size"][1] - 6;
    local fluffyBar_len_s = fluffy.bar_len_seconds;

    -- -----------------------------------------------------------------------
    -- OVERDUE FREEZE: if autoshot should have fired but didn't, freeze bars
    -- in place instead of rolling back to a new predicted position.
    -- -----------------------------------------------------------------------
    local next_start_check = fluffy.ability_autoshot["next_start"];
    local autoshot_overdue = false;
    if next_start_check > 0 and not fluffy.is_casting_autoshot then
        local est_cast = 0.5;
        if fluffy.rotation_ews > 0.1 and fluffy.ranged_base_speed > 0 then
            est_cast = fluffy.rotation_ews * 0.5 / fluffy.ranged_base_speed;
        end
        autoshot_overdue = (next_start_check + est_cast * 1.2) < t;
    end

    if autoshot_overdue then
        if not fluffy.autoshot_frozen then
            fluffy.autoshot_frozen = true;
            fluffy.freeze_time = t;
        end
        -- Decay spark correction during freeze to avoid buildup.
        if fluffy.spark_correction ~= 0 then
            local dt    = min(elapsed, 0.1);
            local decay = 0.5 ^ (dt / 0.15);
            fluffy.spark_correction = fluffy.spark_correction * decay;
            if math.abs(fluffy.spark_correction) < 0.001 then
                fluffy.spark_correction = 0;
            end
        end
        fluffy.draw_frame(fluffy.freeze_time, fluffyBar_len, fluffyBar_len_s);
        fluffy.update_labels(fluffy.freeze_time);
        return;
    end

    if fluffy.autoshot_frozen then
        fluffy.autoshot_frozen = false;
        fluffy.prev_spark_1 = 0;
        fluffy.prev_spark_2 = 0;
    end

    -- -----------------------------------------------------------------------
    -- LOGIC: recalculate ability windows every frame so render t == logic t,
    -- eliminating the sawtooth jitter that throttling caused.
    -- -----------------------------------------------------------------------
    fluffy.logic_dirty = false;
    update_spell_data();

    fluffy.bar_len_seconds = FluffyDBPC["window_length"] + fluffy.latency;
    fluffyBar_len_s = fluffy.bar_len_seconds;
    analyze_game_state(fluffyBar_len_s, t);

    -- -----------------------------------------------------------------------
    -- SPARK JUMP DETECTION: compare new spark positions against previous
    -- frame to detect haste-change or fire-event shifts, then fold the diff
    -- into spark_correction for a smooth glide rather than a hard snap.
    -- -----------------------------------------------------------------------
    local n_sparks_now = table.getn(fluffy.autoshot_sparks);
    if n_sparks_now >= 1 and fluffy.prev_spark_1 > 0 then
        local new_s1   = fluffy.autoshot_sparks[1];
        local half_ews = (fluffy.rotation_ews or 1) * 0.5;

        local shift_a = fluffy.prev_spark_1 - new_s1;
        local shift_b = (fluffy.prev_spark_2 > 0) and (fluffy.prev_spark_2 - new_s1) or 999;

        local shift;
        if math.abs(shift_a) <= math.abs(shift_b) then
            shift = shift_a;
        else
            shift = shift_b;
        end

        -- Only correct visible but non-intentional jumps (50 ms – half eWS).
        if math.abs(shift) > 0.05 and math.abs(shift) < half_ews then
            fluffy.spark_correction = fluffy.spark_correction + shift;
        end
    end

    if n_sparks_now >= 1 then
        fluffy.prev_spark_1 = fluffy.autoshot_sparks[1];
    else
        fluffy.prev_spark_1 = 0;
    end
    if n_sparks_now >= 2 then
        fluffy.prev_spark_2 = fluffy.autoshot_sparks[2];
    else
        fluffy.prev_spark_2 = 0;
    end

    -- -----------------------------------------------------------------------
    -- SPARK CORRECTION DECAY: half-life ~150 ms so the glide settles in ~1 s.
    -- -----------------------------------------------------------------------
    if fluffy.spark_correction ~= 0 then
        local dt    = min(elapsed, 0.1);
        local decay = 0.5 ^ (dt / 0.15);
        fluffy.spark_correction = fluffy.spark_correction * decay;
        if math.abs(fluffy.spark_correction) < 0.001 then
            fluffy.spark_correction = 0;
        end
    end

    -- -----------------------------------------------------------------------
    -- RENDER: bars + sparks (every frame), then labels (throttled).
    -- -----------------------------------------------------------------------
    fluffy.draw_frame(t, fluffyBar_len, fluffyBar_len_s);
    fluffy.update_labels(t);
end

-- ---------------------------------------------------------------------------
-- UI construction — called once from core.lua after ADDON_LOADED.
-- Creates all bar/spark frames and wires up the input/update scripts.
-- ---------------------------------------------------------------------------
function create_ui()

    create_main_bar();
    create_icon_anchor();
    local nbars = 16;

    create_autoshotTrackers(nbars);

    local align = 'CENTER';
    create_bars(fluffy.ability_autoshot,     align, nbars, FluffyDBPC["color_auto"][1],    FluffyDBPC["color_auto"][2],    FluffyDBPC["color_auto"][3],    FluffyDBPC["color_auto"][4],    fluffy.icon_path_auto);
    create_bars(fluffy.ability_arcaneshot,   align, nbars, FluffyDBPC["color_arcane"][1],  FluffyDBPC["color_arcane"][2],  FluffyDBPC["color_arcane"][3],  FluffyDBPC["color_arcane"][4],  fluffy.icon_path_arcane);
    create_bars(fluffy.ability_multishot,    align, nbars, FluffyDBPC["color_multi"][1],   FluffyDBPC["color_multi"][2],   FluffyDBPC["color_multi"][3],   FluffyDBPC["color_multi"][4],   fluffy.icon_path_multi);
    create_bars(fluffy.ability_steadyshot,   align, nbars, FluffyDBPC["color_steady"][1],  FluffyDBPC["color_steady"][2],  FluffyDBPC["color_steady"][3],  FluffyDBPC["color_steady"][4],  fluffy.icon_path_steady);
    create_bars(fluffy.ability_raptorstrike, align, nbars, FluffyDBPC["color_raptor"][1],  FluffyDBPC["color_raptor"][2],  FluffyDBPC["color_raptor"][3],  FluffyDBPC["color_raptor"][4],  fluffy.icon_path_raptor);
    create_bars(fluffy.ability_meleestrike,  align, nbars, FluffyDBPC["color_melee"][1],   FluffyDBPC["color_melee"][2],   FluffyDBPC["color_melee"][3],   FluffyDBPC["color_melee"][4],   fluffy.icon_path_melee);

    FluffyBar:SetScript("OnMouseDown", gui_MouseDown);
    FluffyBar:SetScript("OnMouseUp",   gui_MouseUp);
    FluffyBar:SetScript("OnHide",      gui_Hide);
    FluffyBar:SetScript("OnUpdate",    gui_Update);
end
