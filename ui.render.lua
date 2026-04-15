local _, fluffy = ...

-- ---------------------------------------------------------------------------
-- Baked rotation: next ability selector
-- Finds the ability whose recommendation window starts earliest.
-- Only ranged abilities are considered unless baked_include_melee is on.
-- ---------------------------------------------------------------------------
local function find_next_ability_to_cast(t, look_ahead_seconds)
	local next_ability = nil;
	local earliest_time = math.huge;

	look_ahead_seconds = look_ahead_seconds or 3.4;

	local abilities = {
		fluffy.ability_steadyshot,
		fluffy.ability_multishot,
		fluffy.ability_arcaneshot
	};

	if FluffyDBPC["baked_include_melee"][1] then
		table.insert(abilities, fluffy.ability_raptorstrike);
		table.insert(abilities, fluffy.ability_meleestrike);
	end

	for _, ability in pairs(abilities) do
		local Ws = ability["windows_s"];
		local We = ability["windows_e"];
		for i = 1, #Ws do
			local ws = Ws[i];
			local we = We[i];
			-- Skip windows that have already ended
			if we > t and ws < t + look_ahead_seconds then
				if ws < earliest_time then
					earliest_time = ws;
					next_ability = ability;
				end
				break;  -- first valid window per ability is enough
			end
		end
	end

	return next_ability;
end

-- ---------------------------------------------------------------------------
-- Ability bar rendering
-- Positions and sizes one ability's bar frames for the current frame.
-- In baked rotation mode only the next ability's bars are shown.
-- ---------------------------------------------------------------------------
local function update_bars(ability, left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height, t, next_ability_to_show)
	local bar_min_width = 1;

    local baked_rotation_enabled = FluffyDBPC["baked_rotation"][1];
    if baked_rotation_enabled and next_ability_to_show ~= nil
            and ability ~= fluffy.ability_autoshot
            and ability ~= fluffy.ability_aimedshot then
        if ability ~= next_ability_to_show then
            for j = 1, #ability["bars"] do
                ability["bars"][j]:Hide();
            end
            return;
        end
    end

    -- Apply spark correction to all bars so sparks and bars stay in sync.
    local bar_correction = fluffy.spark_correction or 0;

    local bar_idx = 1;
    local Ws = ability["windows_s"];
    local We = ability["windows_e"];
    local n = #Ws;
    local m = #ability["bars"];

    for i=1,min(n, m) do
        if i > 1
                or ((ability ~= fluffy.ability_autoshot or (not fluffy.is_casting_autoshot)))
                or not FluffyDBPC["hide_autoshotbar_when_casting"][1] then

            local ts = max(0, Ws[i] + bar_correction - t);
            local te = min(fluffyBar_len_seconds, max(0, We[i] + bar_correction - t));

            if ts <= fluffyBar_len_seconds and te > 0 then
                local ps = (fluffyBar_len) * ts / fluffyBar_len_seconds;
                local pe = (fluffyBar_len) * te / fluffyBar_len_seconds;

                local px_width = pe - ps;

                local bar = ability["bars"][bar_idx];

                if px_width > bar_min_width then
                    bar:SetWidth(px_width);
                    bar:ClearAllPoints();
                    bar:SetPoint('LEFT', ps + 3, height);
                    bar:Show();
                else
                    bar:Hide();
                end
            else
                if bar_idx <= m then
                    ability["bars"][bar_idx]:Hide();
                end
            end
            bar_idx = bar_idx + 1;
        end
    end
    -- Hide unused bar slots for this ability.
    for j = bar_idx, m do
        ability["bars"][j]:Hide();
    end
end

-- ---------------------------------------------------------------------------
-- Autoshot spark rendering
-- Positions the thin spark indicator that shows when the next auto shot fires.
-- ---------------------------------------------------------------------------
local function update_autoshot_spark(idx, t, fluffyBar_len, fluffyBar_len_seconds)

    local shift_y = 0.5;

    if fluffy.display_mode == 0 then
        FluffyBars_autoshotsparks[idx]:Hide();

        local nmax = #FluffyBars_autoshotsparks;
        if idx > nmax then
            return;
        end

        local auto_t = fluffy.autoshot_sparks[idx] + (fluffy.spark_correction or 0);
        local spark_bar = FluffyBars_autoshotsparks[idx];

        local active_spark_position_seconds = auto_t - t;
        local active_spark_position = fluffyBar_len * active_spark_position_seconds / (fluffyBar_len_seconds);

        if active_spark_position_seconds <= 0
                or active_spark_position_seconds > fluffyBar_len_seconds + fluffy.movement_spark_interval then
            spark_bar:Hide();
        elseif active_spark_position_seconds > fluffyBar_len_seconds then
            spark_bar:ClearAllPoints();
            spark_bar:SetPoint('LEFT', fluffyBar_len + 3, shift_y - 1);
            spark_bar:Show();
        else
            local movement_start_seconds = max(0, active_spark_position_seconds - fluffy.movement_spark_interval);
            local ps = movement_start_seconds * fluffyBar_len / (fluffyBar_len_seconds);

            spark_bar:ClearAllPoints();
            spark_bar:SetPoint('LEFT', active_spark_position + 3, shift_y - 1);
            spark_bar:Show();
        end
    elseif fluffy.display_mode == 1 then
        -- display_mode 1 (dual-spark mirror layout) is not yet implemented.
    end
end

-- ---------------------------------------------------------------------------
-- Interval drawing: orchestrates bars across all abilities for one frame.
-- ---------------------------------------------------------------------------
local function draw_intervals(t, left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds)

    -- Ranged bars sit in the top half; melee in the bottom half.
    local height_m = 0;
    local height_r = 0;
    if FluffyDBPC["consider_melee"][1] ~= false then
        height_m = -0.5 * (0.5 * FluffyDBPC["size"][2] - 2);
        height_r =  0.5 * (0.5 * FluffyDBPC["size"][2] - 1);
    end

    local next_ability = find_next_ability_to_cast(t, fluffyBar_len_seconds);
    fluffy.baked_next_ability_name = next_ability and next_ability["name"] or nil;

    update_bars(fluffy.ability_autoshot,     left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_r, t, next_ability);
    update_bars(fluffy.ability_aimedshot,    left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_r, t, next_ability);
    update_bars(fluffy.ability_arcaneshot,   left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_r, t, next_ability);
    update_bars(fluffy.ability_steadyshot,   left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_r, t, next_ability);
    update_bars(fluffy.ability_multishot,    left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_r, t, next_ability);
    update_bars(fluffy.ability_raptorstrike, left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_m, t, next_ability);
    update_bars(fluffy.ability_meleestrike,  left_shift_px, shift_y, fluffyBar_len, fluffyBar_len_seconds, height_m, t, next_ability);
end

-- ---------------------------------------------------------------------------
-- Public entry point called from gui_Update every frame.
-- Renders all autoshot sparks and ability bars.
-- ---------------------------------------------------------------------------
fluffy.draw_frame = function(t, fluffyBar_len, fluffyBar_len_s)
    local n_sparks = table.getn(fluffy.autoshot_sparks);

    for i=1, min(n_sparks, #FluffyBars_autoshotsparks) do
        update_autoshot_spark(i, t, fluffyBar_len, fluffyBar_len_s);
    end
    -- Hide spark frames beyond the current predicted count.
    for i=n_sparks+1, #FluffyBars_autoshotsparks do
        FluffyBars_autoshotsparks[i]:Hide();
    end

    draw_intervals(t, 3, -3, fluffyBar_len, fluffyBar_len_s);
end
