local _, fluffy = ...

local tooltip_weapon = CreateFrame('GameTooltip', "WeaponTooltip", UIParent, 'GameTooltipTemplate');
tooltip_weapon:SetOwner(WorldFrame, "ANCHOR_NONE");
tooltip_weapon:AddFontStrings(
    tooltip_weapon:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    tooltip_weapon:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" )
);

local function get_weapon_speed(tooltip_line)
	local out = 0;

	local splt = fluffy.mysplit_speed(tooltip_line);
	local val = tonumber(splt[2]);

	if val ~= nil then
		out = val;
	end
	wipe(splt);
	return out;
end

local function get_weapon_damage_range(tooltip_line)
	local dmg_min = 0;
	local dmg_max = 0;

	local splt = fluffy.mysplit_damage(tooltip_line);

	local idx1 = 1;
	local idx2 = 2;

	if #splt >= 2 then
		local val1 = tonumber(splt[idx1]);
		local val2 = tonumber(splt[idx2]);

		if val1 ~= nil then
			dmg_min = val1;
			dmg_max = val1;
		end

		if val2 ~= nil then
			dmg_max = val2;
		end
	end


	wipe(splt);
	return dmg_min, dmg_max;
end

local function parse_weapon_info(slot_id, db)

	local item_id_ = GetInventoryItemID("player", slot_id);
	local dmg_min;
	local dmg_max;
	local speed;

	if item_id_ ~= nil and item_id_ ~= 0 then
		if db[item_id_] == nil then
			local _, itemLink = GetItemInfo(item_id_);

			tooltip_weapon:ClearLines()
			tooltip_weapon:SetOwner(WorldFrame, "ANCHOR_NONE");

			if pcall(function() tooltip_weapon:SetHyperlink(itemLink) end) then
				-- Scan tooltip lines until we find a valid damage range AND speed.
				-- We stop updating once we have both, so later lines (like the
				-- "(X damage per second)" line) cannot overwrite the real values
				-- with zeros from a failed parse.
				local found_dmg = false;
				local found_speed = false;
				for line_idx = 1, 8 do
					local rstr = _G["WeaponTooltipTextRight" .. line_idx]:GetText();
					local lstr = _G["WeaponTooltipTextLeft"  .. line_idx]:GetText();
					if not found_speed and rstr ~= nil then
						local s = get_weapon_speed(rstr);
						if s > 0.05 then
							speed = s;
							found_speed = true;
						end
					end
					if not found_dmg and lstr ~= nil then
						local d1, d2 = get_weapon_damage_range(lstr);
						if d1 > 0 then
							dmg_min = d1;
							dmg_max = d2;
							found_dmg = true;
						end
					end
					if found_dmg and found_speed then break end
				end
				-- Only cache COMPLETE entries.  A partial parse (e.g. item
				-- info not loaded yet) must stay uncached so a later scan
				-- retries, instead of poisoning the cache with nil fields.
				if found_dmg and found_speed then
					db[item_id_] = {dmg_min, dmg_max, speed};
				end
			end

			tooltip_weapon:Hide();
		end
	end
end

-- Validates a cached weapon entry.  Returns the entry when it is complete,
-- nil otherwise; incomplete entries (written by older addon versions) are
-- dropped from the cache so the next scan re-parses the tooltip.
local function read_weapon_cache(db, item_id)
	if item_id == nil or item_id == 0 then
		return nil;
	end
	local weapon_data = db[item_id];
	if weapon_data == nil then
		-- not cached yet (tooltip parse failed); retry on a later event
		return nil;
	end
	if weapon_data[1] == nil or weapon_data[2] == nil
			or weapon_data[3] == nil or weapon_data[3] <= 0.05 then
		db[item_id] = nil;
		return nil;
	end
	return weapon_data;
end

local function update_ranged_weapon_stats()
    if fluffy.is_player_hunter == false then
		return;
	end

	fluffy.ranged_weapon_id = 0;
	fluffy.ranged_dmg_min = 0;
	fluffy.ranged_dmg_max = 0;
	fluffy.ranged_base_speed = 0;
	fluffy.ranged_dmg_avg = 0;

	if FluffyDBPC == nil then
		FluffyDBPC = {};
	end

	if FluffyDBPC["ranged_weapons"] == nil then
		FluffyDBPC["ranged_weapons"] = {};
	end

	parse_weapon_info(18, FluffyDBPC["ranged_weapons"]);

	local item_string = GetInventoryItemLink("player",18);

	local i_ = 0;
	local item_id = 0;
	local enchant_id = 0;
	if item_string ~= nil then
		for str in string.gmatch(item_string, "([^:]+)") do
			if i_ == 1 then
				item_id = tonumber(str);
			elseif i_ == 2 then
				enchant_id = tonumber(str);
				break;
			end

			i_ = i_ + 1;
		end
	end

	local weapon_data = read_weapon_cache(FluffyDBPC["ranged_weapons"], item_id);
	if weapon_data == nil then
		return;
	end

	fluffy.ranged_dmg_min = weapon_data[1];
	fluffy.ranged_dmg_max = weapon_data[2];
	fluffy.ranged_base_speed = weapon_data[3];
	fluffy.ranged_weapon_id = item_id;

	local bonus_dmg = 0;
	if enchant_id == 30 then
		bonus_dmg = 1; -- crude scope
	elseif enchant_id == 32 then
		bonus_dmg = 2; -- standard scope
	elseif enchant_id == 33 then
		bonus_dmg = 3; -- accurate scope
	elseif enchant_id == 663 then
		bonus_dmg = 5; -- deadly scope
	elseif enchant_id == 664 then
		bonus_dmg = 7; -- sniper scope
	end

	fluffy.ranged_dmg_min = fluffy.ranged_dmg_min + bonus_dmg;
	fluffy.ranged_dmg_max = fluffy.ranged_dmg_max + bonus_dmg;
	fluffy.ranged_dmg_avg = (fluffy.ranged_dmg_min + fluffy.ranged_dmg_max) / 2;
end

local function update_melee_weapon_stats()
    if fluffy.is_player_hunter == false then
		return;
	end

	fluffy.melee_dmg_avg_main = 0;
	fluffy.main_hand_base_speed = 1;
	fluffy.melee_dmg_avg_off = 0;
	fluffy.off_hand_base_speed = 1;
	fluffy.melee_mh_weapon_id = 0;
	fluffy.melee_oh_weapon_id = 0;

	if FluffyDBPC == nil then
		FluffyDBPC = {};
	end

	if FluffyDBPC["melee_weapons"] == nil then
		FluffyDBPC["melee_weapons"] = {};
	end

	-- main hand
	parse_weapon_info(16, FluffyDBPC["melee_weapons"]);
	local item_id_mh = GetInventoryItemID("player", 16);

	-- off hand
	parse_weapon_info(17, FluffyDBPC["melee_weapons"]);
	local item_id_oh = GetInventoryItemID("player", 17);

	local weapon_data = read_weapon_cache(FluffyDBPC["melee_weapons"], item_id_mh);
	if weapon_data ~= nil then
		fluffy.melee_dmg_avg_main = 0.5 * (weapon_data[1] + weapon_data[2]);
		fluffy.main_hand_base_speed = weapon_data[3];
		fluffy.melee_mh_weapon_id = item_id_mh;
	end

	weapon_data = read_weapon_cache(FluffyDBPC["melee_weapons"], item_id_oh);
	if weapon_data ~= nil then
		fluffy.melee_dmg_avg_off = 0.5 * (weapon_data[1] + weapon_data[2]);
		fluffy.off_hand_base_speed = weapon_data[3];
		fluffy.melee_oh_weapon_id = item_id_oh;
	end
end

function fluffy.update_weapon_stats()
	update_ranged_weapon_stats();
	update_melee_weapon_stats();
end
