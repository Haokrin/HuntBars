local _, fluffy = ...

local hit_conversion_table = {
	0.38,
	0.38,
	0.38,
	0.38,
	0.38,
	0.38,
	0.38,
	0.38,
	0.38,
	0.38,
	0.58,
	0.77,
	0.96,
	1.15,
	1.35,
	1.54,
	1.73,
	1.92,
	2.12,
	2.31,
	2.50,
	2.69,
	2.88,
	3.08,
	3.27,
	3.46,
	3.65,
	3.85,
	4.04,
	4.23,
	4.42,
	4.62,
	4.81,
	5.00,
	5.19,
	5.38,
	5.58,
	5.77,
	5.96,
	6.15,
	6.35,
	6.54,
	6.73,
	6.92,
	7.12,
	7.31,
	7.50,
	7.69,
	7.88,
	8.08,
	8.27,
	8.46,
	8.65,
	8.85,
	9.04,
	9.23,
	9.42,
	9.62,
	9.81,
	10.00,
	10.38,
	10.79,
	11.23,
	11.71,
	12.24,
	12.81,
	13.44,
	14.14,
	14.91,
	15.77
};

-- RANGED HASTE MODIFIER GAINED SOLELY FROM BUFFS
local function get_haste_mod_ranged(t)
	-- quiver_haste is 0.0 when no quiver is equipped, or e.g. 0.15 for a
	-- 15% quiver. The original code hardcoded 1/1.15 which always assumed a
	-- quiver was present. We now use the actual detected value so the bars
	-- work correctly with or without a quiver equipped.
	local quiver_mult = 1 + fluffy.quiver_haste;  -- e.g. 1.15, or 1.0 with no quiver
	local haste = 1 / quiver_mult / fluffy.serpent_swiftness;
	local haste_rating = 0;
	local player_level = UnitLevel("player");
	local haste_rating_base = GetCombatRating(CR_HASTE_RANGED);

	local t_now = GetTime();

	for _, T in pairs(fluffy.haste_buffs_table) do
		local is_ranged = (T[4] >= 2);

		if is_ranged then
			local expiration_time = T[1];
			local haste_value = T[2];
			local is_rating = T[3];

			if expiration_time >= t then
				if is_rating then
					haste_rating = haste_rating +  haste_value;
				else
					haste = haste / haste_value;
				end
			end
	
			if expiration_time >= t_now and is_rating then
				haste_rating_base = haste_rating_base - haste_value;
			end
		end

	end
	-- return  haste / (1 + (haste_rating) / hit_conversion_table[player_level]);
	return  haste / (1 + 0.01 * (haste_rating_base + haste_rating) / hit_conversion_table[player_level]);
end

-- MELEE HASTE MODIFIER
local function get_haste_mod_melee(t)
	local haste = 1;
	local haste_rating = 0;
	local player_level = UnitLevel("player");
	local haste_rating_base = GetCombatRating(CR_HASTE_MELEE);
	
	local t_now = GetTime();

	for _, T in pairs(fluffy.haste_buffs_table) do
		local is_melee = ((T[4] % 2) == 1);

		if is_melee then
			local expiration_time = T[1];
			local haste_value = T[2];
			local is_rating = T[3];

			if expiration_time >= t then
				if is_rating then
					haste_rating = haste_rating +  haste_value;
				else
					haste = haste / haste_value;
				end
			end
	
			if expiration_time >= t_now and is_rating then
				haste_rating_base = haste_rating_base - haste_value;
			end
		end

	end
	
	return  haste / (1 + 0.01 * (haste_rating_base + haste_rating) / hit_conversion_table[player_level]);
end

local function getMeleeHitCoefficients()
	local cc = GetCritChance();
	local melee_hit_rating = GetCombatRating(6);
	local player_level = UnitLevel("player");

	local out_cc = 0;
	local out_hc = 0;

	if cc ~= nil then
		out_cc = cc;
	end

	if melee_hit_rating ~= nil then
		out_hc =  melee_hit_rating / hit_conversion_table[player_level];
	end

	return out_cc, out_hc;
end

-- ability specifications
fluffy.ability_autoshot = {};
fluffy.ability_aimedshot = {};
fluffy.ability_arcaneshot = {};
fluffy.ability_multishot = {};
fluffy.ability_steadyshot = {};
fluffy.ability_raptorstrike = {};
fluffy.ability_meleestrike = {};

-- windows of opportunity for each ability
fluffy.ability_autoshot["windows_s"] = {};
fluffy.ability_aimedshot["windows_s"] = {};
fluffy.ability_arcaneshot["windows_s"] = {};
fluffy.ability_multishot["windows_s"] = {};
fluffy.ability_steadyshot["windows_s"] = {};
fluffy.ability_raptorstrike["windows_s"] = {};
fluffy.ability_meleestrike["windows_s"] = {};
fluffy.ability_autoshot["windows_e"] = {};
fluffy.ability_aimedshot["windows_e"] = {};
fluffy.ability_arcaneshot["windows_e"] = {};
fluffy.ability_multishot["windows_e"] = {};
fluffy.ability_steadyshot["windows_e"] = {};
fluffy.ability_raptorstrike["windows_e"] = {};
fluffy.ability_meleestrike["windows_e"] = {};

-- UI elements associated with each ability
fluffy.ability_autoshot["bars"] = {};
fluffy.ability_aimedshot["bars"] = {};
fluffy.ability_arcaneshot["bars"] = {};
fluffy.ability_multishot["bars"] = {};
fluffy.ability_steadyshot["bars"] = {};
fluffy.ability_raptorstrike["bars"] = {};
fluffy.ability_meleestrike["bars"] = {};

fluffy.ability_autoshot["align"] = 'TOPLEFT';
fluffy.ability_aimedshot["align"] = 'TOPLEFT';
fluffy.ability_arcaneshot["align"] = 'TOPLEFT';
fluffy.ability_multishot["align"] = 'TOPLEFT';
fluffy.ability_steadyshot["align"] = 'TOPLEFT';
fluffy.ability_raptorstrike["align"] = 'TOPLEFT';
fluffy.ability_meleestrike["align"] = 'TOPLEFT';

fluffy.ability_autoshot["active_id"] = fluffy.spell_id_auto;
fluffy.ability_aimedshot["active_id"] = fluffy.spell_id_aimed;
fluffy.ability_arcaneshot["active_id"] = fluffy.spell_id_arcane;
fluffy.ability_multishot["active_id"] = fluffy.spell_id_multi;
fluffy.ability_steadyshot["active_id"] = fluffy.spell_id_steady;
fluffy.ability_raptorstrike["active_id"] = fluffy.spell_id_raptor;


-- ability IDs and associated flat damage modifiers
fluffy.ability_autoshot["ids"] = {{fluffy.spell_id_auto, 0, 0}};
fluffy.ability_aimedshot["ids"] = {{27065, 870, 870}, {20904, 600, 600}, {20903, 460, 460}, {20902, 330, 330}, {20901, 200, 200}, {20900, 125, 125}, {fluffy.spell_id_aimed, 70, 70}};
fluffy.ability_arcaneshot["ids"] = {{27019, 273, 273}, {14287, 200, 183}, {14286, 158, 145}, {14285, 125, 115}, {14284, 91, 83}, {14283, 65, 59}, {14282, 36, 33}, {14281, 23, 21}, {fluffy.spell_id_arcane, 15, 13}};
fluffy.ability_multishot["ids"] = {{27021, 205, 205}, {25294, 150, 150}, {14290, 120, 120}, {14289, 80, 80}, {14288, 40, 40}, {fluffy.spell_id_multi, 0, 0}};
fluffy.ability_steadyshot["ids"] = {{fluffy.spell_id_steady, 150, 150}};
fluffy.ability_raptorstrike["ids"] = {{27014, 170, 170}, {14266, 140, 140}, {14265, 110, 110}, {14264, 80, 80}, {14263, 50, 50}, {14262, 34, 34}, {14261, 21, 21}, {14260, 11, 11}, {fluffy.spell_id_raptor, 5, 5}};
fluffy.ability_meleestrike["ids"] = {};
fluffy.ability_autoshot["flat_bonus"] = 0;
fluffy.ability_aimedshot["flat_bonus"] = 0
fluffy.ability_arcaneshot["flat_bonus"] = 0;
fluffy.ability_multishot["flat_bonus"] = 0;
fluffy.ability_steadyshot["flat_bonus"] = 0;
fluffy.ability_raptorstrike["flat_bonus"] = 0;
fluffy.ability_meleestrike["flat_bonus"] = 0;
fluffy.ability_autoshot["known"] = true;
fluffy.ability_aimedshot["known"] = false;
fluffy.ability_arcaneshot["known"] = false;
fluffy.ability_multishot["known"] = false;
fluffy.ability_steadyshot["known"] = false;
fluffy.ability_raptorstrike["known"] = false;
fluffy.ability_meleestrike["known"] = true;

fluffy.ability_autoshot["name"] = "Autoshot";
fluffy.ability_aimedshot["name"] = "Aimedshot";
fluffy.ability_arcaneshot["name"] = "Arcane shot";
fluffy.ability_multishot["name"] = "Multi-shot";
fluffy.ability_steadyshot["name"] = "Steadyshot";
fluffy.ability_raptorstrike["name"] = "Raptor strike";
fluffy.ability_meleestrike["name"] = "Melee strike";

-- do we want to include these abilities in our calculations?
fluffy.ability_autoshot["forbid"] = false;
fluffy.ability_aimedshot["forbid"] = true;
fluffy.ability_arcaneshot["forbid"] = false;
fluffy.ability_multishot["forbid"] = false;
fluffy.ability_steadyshot["forbid"] = false;
fluffy.ability_raptorstrike["forbid"] = false;
fluffy.ability_meleestrike["forbid"] = false;

-- last time the ability was fired off
fluffy.ability_autoshot["fired"] = 0.0;
fluffy.ability_autoshot["next_start"] = 0.0;
fluffy.ability_autoshot["next_fired"] = 0.0;
fluffy.ability_aimedshot["fired"] = 0.0;
fluffy.ability_arcaneshot["fired"] = 0.0;
fluffy.ability_multishot["fired"] = 0.0;
fluffy.ability_steadyshot["fired"] = 0.0;
fluffy.ability_raptorstrike["fired"] = 0.0;
fluffy.ability_meleestrike["fired"] = 0.0;
fluffy.ability_meleestrike["next_start"] = 0.0;

-- damage of abilities
-- The ranged values are BASE damages used to rank abilities against each
-- other and against auto shot in the window optimizer; crit/hit/talent
-- multipliers are close to a common factor across the ranged abilities and
-- are intentionally left out of the comparison.
fluffy.ability_autoshot["dmg"] = function()
	return fluffy.ranged_dmg_avg + (fluffy.ammo_dps + fluffy.rap/14) * fluffy.ranged_base_speed;
end

fluffy.ability_aimedshot["dmg"] = function()
	return fluffy.ranged_dmg_avg + fluffy.ability_aimedshot["flat_bonus"] + fluffy.ammo_dps * fluffy.ranged_base_speed + fluffy.rap * 0.2;
end

fluffy.ability_arcaneshot["dmg"] = function()
	local base_dmg = fluffy.ability_arcaneshot["flat_bonus"];

	if fluffy.client_version > 11307 then
		base_dmg = base_dmg + fluffy.rap * 0.15;
	else
		base_dmg = base_dmg + GetSpellBonusDamage(7) * 1.5 / 3.5;
	end

	return base_dmg;
end

fluffy.ability_multishot["dmg"] = function()
	return fluffy.ranged_dmg_avg + fluffy.ability_multishot["flat_bonus"] + fluffy.ammo_dps * fluffy.ranged_base_speed + fluffy.rap * 0.2;
end

fluffy.ability_steadyshot["dmg"] = function()
	return fluffy.ranged_dmg_avg + fluffy.ability_steadyshot["flat_bonus"] + fluffy.rap * 0.2;
end

fluffy.ability_raptorstrike["dmg"] = function()
	local cc, hc = getMeleeHitCoefficients();

	local base_dmg = (fluffy.melee_dmg_avg_main + fluffy.ability_raptorstrike["flat_bonus"] + fluffy.map / 14 * fluffy.main_hand_base_speed);
	local melee_crit_coeff = 2;

	local crit_chance_coeff = min(1, max(0, fluffy.raptor_crit_bonus + cc - 4.8) * 0.01);
	local hit_chance_coeff = min(100, max(0, 92 + max(0, fluffy.hit_bonus + hc - 1))) * 0.01;

	return base_dmg * (1 + crit_chance_coeff * (melee_crit_coeff - 1)) * hit_chance_coeff * fluffy.melee_modifier;
end

fluffy.ability_meleestrike["dmg"] = function()
	local cc, hc = getMeleeHitCoefficients();

	local base_dmg = (fluffy.melee_dmg_avg_main + 0.5 * fluffy.melee_dmg_avg_off + fluffy.map / 14 * (fluffy.main_hand_base_speed + 0.5 * fluffy.off_hand_base_speed));
	local melee_crit_coeff = 2;

	local crit_chance_coeff = min(1, max(0, cc - 4.8) * 0.01);
	local hit_chance_coeff = min(100, max(0, 92 + max(0, fluffy.hit_bonus + hc - 1))) * 0.01;

	return base_dmg * (1 + crit_chance_coeff * (melee_crit_coeff - 1)) * hit_chance_coeff * fluffy.melee_modifier;
end

-- are abilities on global cooldowns?
fluffy.ability_autoshot["gcd"] = 0;
fluffy.ability_aimedshot["gcd"] = 1;
fluffy.ability_arcaneshot["gcd"] = 1;
fluffy.ability_multishot["gcd"] = 1;
fluffy.ability_steadyshot["gcd"] = 1;
fluffy.ability_raptorstrike["gcd"] = 0;
fluffy.ability_meleestrike["gcd"] = 0;

-- base cooldowns of abilities
fluffy.ability_autoshot["cdb"] = function(t)
	return (fluffy.ranged_base_speed - 0.5) * get_haste_mod_ranged(t);
end
fluffy.ability_aimedshot["cdb"] = function(t)
	if fluffy.client_version > 11307 then
		return 6 + fluffy.ranged_base_speed * get_haste_mod_ranged(t);
	else
		return 6;
	end	
end
fluffy.ability_arcaneshot["cdb"] = function(t)
	return 6 - fluffy.arcane_cd_reduction;
end
fluffy.ability_multishot["cdb"] = function(t)
	return 10;
end
-- Steady Shot occupies a fixed 1.5 s GCD; cdb is the lockout remaining
-- AFTER the cast finishes, so cast + cdb always totals 1.5 s.
fluffy.ability_steadyshot["cdb"] = function(t)
	return 1.5 - 1.5 * get_haste_mod_ranged(t);
end
fluffy.ability_raptorstrike["cdb"] = function(t)
	return 6.0;
end
fluffy.ability_meleestrike["cdb"] = function(t)
	return fluffy.main_hand_base_speed * get_haste_mod_melee(t);
end

-- cast times
fluffy.ability_autoshot["cast"] = function(t)
	return 0.5 * get_haste_mod_ranged(t);
end
fluffy.ability_aimedshot["cast"] = function(t)
	if fluffy.client_version > 11307 then
		return 3.0 * get_haste_mod_ranged(t);
	else
		return 3.5 * get_haste_mod_ranged(t);
	end	
end
fluffy.ability_arcaneshot["cast"] = function(t)
	return 0.0;
end
fluffy.ability_multishot["cast"] = function(t)
	return 0.5 * get_haste_mod_ranged(t);
end
-- Steady Shot: 1.5 s BASE cast time, scaled by ranged haste.  This matches
-- diziet559's rotationtools reference model (cast = 1.5 / (1 + haste)) and
-- the original addon formula.  Do NOT "fix" the base to 1.0 s — that widens
-- the recommended press window past the true safe deadline, and every press
-- near the window end then clips (delays) the incoming auto shot.  The
-- clipping is most visible at high haste, where the hard safety cap
-- (auto_ts - cast - latency) is the binding constraint on the window.
fluffy.ability_steadyshot["cast"] = function(t)
	return 1.5 * get_haste_mod_ranged(t);
end
fluffy.ability_raptorstrike["cast"] = function(t)
	if fluffy.client_version > 11307 then
		return 0.3;
	else
		return 1.0;
	end	
end
fluffy.ability_meleestrike["cast"] = function(t)
	if fluffy.client_version > 11307 then
		return 0.3;
	else
		return 1.0;
	end	
end

-- current cooldowns of abilities
fluffy.ability_autoshot["cd"] = function(t)
    return fluffy.ability_autoshot["next_start"] - t;
end

fluffy.ability_steadyshot["cd"] = function(t)
    local start_, gcd_, _ = GetSpellCooldown(fluffy.spell_id_steady);
	return start_ + gcd_ - t;
end

fluffy.ability_aimedshot["cd"] = function(t)
	local start_, gcd_, _ = GetSpellCooldown(fluffy.spell_id_aimed);
	if start_ + gcd_ > fluffy.ability_aimedshot["fired"] then
		return fluffy.ability_aimedshot["fired"] + fluffy.ability_aimedshot["cdb"](t) - t;
	end
    return start_ + gcd_ - t;
end
fluffy.ability_arcaneshot["cd"] = function(t)
	local start_, gcd_, _ = GetSpellCooldown(fluffy.spell_id_arcane);
    return start_ + gcd_ - t;
end
fluffy.ability_multishot["cd"] = function(t)
	local start_, gcd_, _ = GetSpellCooldown(fluffy.spell_id_multi);
    return start_ + gcd_ - t;
end
fluffy.ability_meleestrike["cd"] = function(t)
    return fluffy.ability_meleestrike["next_start"] - t;
end
fluffy.ability_raptorstrike["cd"] = function(t)
	local start_, gcd_, _ = GetSpellCooldown(fluffy.spell_id_raptor);
    return max(start_ + gcd_ - t, fluffy.ability_meleestrike["cd"](t));
end

local function update_ability_stats(ability)

	ability["known"] = false;
	ability["flat_bonus"] = 0;

	if ability["forbid"] == true then
		return;
	end

	if ability == fluffy.ability_meleestrike then
		ability["known"] = true;
	end

	for i=1,#ability["ids"] do
		local id = ability["ids"][i][1];
		local modifier;
		if fluffy.client_version > 11307 then
			modifier = ability["ids"][i][2];
		else
			if #ability["ids"][i] == 3 then
				modifier = ability["ids"][i][3];
			else
				modifier = ability["ids"][i][2];
			end
		end	

	
		if IsSpellKnown(id) then
			ability["active_id"] = max(ability["active_id"], id);
			ability["flat_bonus"] = max(ability["flat_bonus"], modifier);
			ability["known"] = true;
		end
	end
end

function fluffy.update_spell_data()

	-- Guard: the UNIT_SPELLCAST_SENT handler calls this for every class,
	-- but the consider_* keys only exist in a hunter's saved variables.
	if fluffy.is_player_hunter == false or FluffyDBPC == nil then
		return;
	end

	fluffy.ability_autoshot["forbid"] = false;
	fluffy.ability_aimedshot["forbid"] = true;
	fluffy.ability_arcaneshot["forbid"] = (not FluffyDBPC["consider_arcane"][1]);
	fluffy.ability_multishot["forbid"] = (not FluffyDBPC["consider_multi"][1]);
	fluffy.ability_steadyshot["forbid"] = false;
	fluffy.ability_raptorstrike["forbid"] = (not FluffyDBPC["consider_melee"][1]);
	fluffy.ability_meleestrike["forbid"] = (not FluffyDBPC["consider_melee"][1]);

	update_ability_stats(fluffy.ability_aimedshot);
	update_ability_stats(fluffy.ability_autoshot);
	update_ability_stats(fluffy.ability_arcaneshot);
	update_ability_stats(fluffy.ability_multishot);
	update_ability_stats(fluffy.ability_steadyshot);
	update_ability_stats(fluffy.ability_raptorstrike);
	update_ability_stats(fluffy.ability_meleestrike);
end

local function isSpellAnAbility(spellID, ability)
	for key, value in pairs(ability["ids"]) do
		if value[1] == spellID then
			return true;
		end
	end
	return false;
end

local function update_spell_finished(spellID)

	local t = GetTime();

	if isSpellAnAbility(spellID, fluffy.ability_aimedshot) then
		fluffy.ability_aimedshot["fired"] = t;

		local speed, _, _, _, _, _ = UnitRangedDamage("player");
		fluffy.ability_autoshot["fired"] = t;
		fluffy.ability_autoshot["next_start"] = t + speed - fluffy.ability_autoshot["cast"](t);
		fluffy.ability_autoshot["next_fired"] = t + speed;

	elseif isSpellAnAbility(spellID, fluffy.ability_multishot) then
		fluffy.ability_multishot["fired"] = t;

	elseif isSpellAnAbility(spellID, fluffy.ability_arcaneshot) then
		fluffy.ability_arcaneshot["fired"] = t;

	elseif isSpellAnAbility(spellID, fluffy.ability_autoshot) then
		-- Auto shot timing is set exclusively by the COMBAT_LOG_EVENT_UNFILTERED
		-- SPELL_CAST_SUCCESS handler (parse_combat_event).  Setting next_start
		-- here too caused a double-write: this event fires first with one haste
		-- value, then the combat log fires ~1 frame later with a slightly
		-- different calculation, producing a visible jump every auto shot cycle.
		fluffy.ability_autoshot["fired"] = t;

	elseif isSpellAnAbility(spellID, fluffy.ability_steadyshot) then
		fluffy.ability_steadyshot["fired"] = t;

	elseif (spellID == fluffy.spell_id_FD) then
		fluffy.ability_autoshot["fired"] = t;

		fluffy.autoshot_delay = t + fluffy.ability_autoshot["cdb"](t);

		local mainSpeed, _ = UnitAttackSpeed("player");
		fluffy.ability_meleestrike["fired"] = t;
		fluffy.ability_meleestrike["next_start"] = t + mainSpeed;

	elseif (spellID == fluffy.spell_id_readiness) then

		fluffy.autoshot_delay = t + 0.5;
		fluffy.ability_autoshot["next_start"] = fluffy.autoshot_delay;
		fluffy.ability_autoshot["next_fired"] = fluffy.ability_autoshot["next_start"] + fluffy.ability_autoshot["cast"](t);

	end
	fluffy.logic_dirty = true;
end

fluffy.autoshot_delay = 0;
fluffy.is_casting = false;

local function update_spell_started(spellID)

	local t = GetTime();
	fluffy.autoshot_delay = 0;

	if isSpellAnAbility(spellID, fluffy.ability_aimedshot) then
		-- An Aimed Shot cast blocks the pending auto shot; the next auto
		-- cannot start before the cast end plus a full swing cooldown.
		fluffy.autoshot_delay = t + fluffy.ability_aimedshot["cast"](t) + fluffy.ability_autoshot["cdb"](t + fluffy.ability_aimedshot["cast"](t));
	end
end

fluffy.cast_finishes = 0;
local function update_spell_interrupted()
	fluffy.autoshot_delay = 0;
	fluffy.cast_finishes = 0;
end

local current_auto_start = 0;
local current_auto_finish = 0;
local next_auto_start = 0;
local next_auto_finish = 0;
-- Previous auto fire as seen by THIS combat-log handler.  The /fluffy debug
-- cycle printout cannot use ability_autoshot["fired"]: the
-- UNIT_SPELLCAST_SUCCEEDED handler arrives first and overwrites it with
-- "now", which made the printed cycle always read 0.000.
local last_debug_auto_fire = 0;
local function parse_combat_event(log_message)

	local t = GetTime();
	local event = log_message[2];
	local src = log_message[4];

    if src == fluffy.player_id then

		local current_casting_info = fluffy.is_casting;

        if event == "SWING_DAMAGE" or event == 'SWING_MISSED' then
			local offhand_hit = log_message[21];
            if not offhand_hit then
				local mainSpeed, _ = UnitAttackSpeed("player");
				fluffy.ability_meleestrike["fired"] = t;
				fluffy.ability_meleestrike["next_start"] = t + mainSpeed;
			end
		elseif event == "SPELL_DAMAGE" or event == 'SPELL_MISSED' then
			local spell_id = log_message[12];

			if isSpellAnAbility(spell_id, fluffy.ability_raptorstrike) then
				local mainSpeed, _ = UnitAttackSpeed("player");
				fluffy.ability_raptorstrike["fired"] = t;
				fluffy.ability_meleestrike["fired"] = t;
				fluffy.ability_meleestrike["next_start"] = t + mainSpeed;
			end
		elseif event == "SPELL_CAST_START" and log_message[12] == fluffy.spell_id_auto then

			current_auto_start =  GetTime();
			current_auto_finish = current_auto_start + 0.5 * get_haste_mod_ranged(current_auto_start);
			fluffy.is_casting_autoshot = true;
			fluffy.is_casting = true;
			fluffy.logic_dirty = true;

			-- On the FIRST autoshot (fired == 0), bootstrap the cycle so the
			-- bar starts moving immediately instead of waiting for SPELL_CAST_SUCCESS.
			-- After the first fire, we do NOT snap values here — the predictions
			-- from the previous SPELL_CAST_SUCCESS are close enough, and snapping
			-- would cause a visible jump in spark positions.
			if fluffy.ability_autoshot["fired"] == 0 then
				local api_speed = UnitRangedDamage("player");
				local init_speed;
				if api_speed and api_speed > 0.1 then
					init_speed = api_speed;
				else
					init_speed = fluffy.ranged_base_speed * get_haste_mod_ranged(current_auto_start);
				end
				local init_cast = init_speed * 0.5 / fluffy.ranged_base_speed;
				fluffy.ability_autoshot["fired"] = current_auto_start;
				fluffy.ability_autoshot["next_start"] = current_auto_start;
				fluffy.ability_autoshot["next_fired"] = current_auto_start + init_cast;
				fluffy.rotation_ews = init_speed;
			end
		elseif event == "SPELL_CAST_START" then
			
			fluffy.is_casting = true;
	
		elseif event == "SPELL_CAST_SUCCESS" and log_message[12] == fluffy.spell_id_auto then

			current_auto_finish = GetTime();
			fluffy.is_casting_autoshot = false;
			fluffy.is_casting = false;

			-- Timing verification (enable via /fluffy debug): capture the
			-- MEASURED aim duration and this fire's prediction error before
			-- the cycle variables are overwritten below.
			local measured_aim = current_auto_finish - current_auto_start;
			local prev_fired = last_debug_auto_fire;
			last_debug_auto_fire = current_auto_finish;
			local predicted_fire = fluffy.ability_autoshot["next_fired"];

			-- Use UnitRangedDamage() as the authoritative speed source.
			-- This returns the game engine's actual current attack period
			-- with ALL haste effects already applied, eliminating drift
			-- from manual buff table computation that causes visual jumps.
			local api_speed = UnitRangedDamage("player");
			local curr_speed;
			if api_speed and api_speed > 0.1 then
				curr_speed = api_speed;
			else
				-- Fallback to buff table computation if API returns invalid
				curr_speed = fluffy.ranged_base_speed * get_haste_mod_ranged(current_auto_finish);
			end

			local curr_cast = curr_speed * 0.5 / fluffy.ranged_base_speed;
			current_auto_start = current_auto_finish - curr_cast;

			next_auto_start =  current_auto_start + curr_speed;
			next_auto_finish = current_auto_finish + curr_speed;


			fluffy.ability_autoshot["fired"] = current_auto_finish;
			fluffy.ability_autoshot["next_start"] = next_auto_start;
			fluffy.ability_autoshot["next_fired"] = next_auto_finish;
			fluffy.logic_dirty = true;

			-- The fire is THE moment haste takes effect: the next cycle is
			-- scheduled here with the speed current at this shot.  A haste
			-- change later in the swing will not touch this schedule (the
			-- server applies it from the next shot onward); analyze reads
			-- the scheduled aim back via next_fired - next_start.
			fluffy.rotation_ews = curr_speed;

			-- /fluffy debug: ground-truth check of the timing model.
			--   aim      = SPELL_CAST_START -> SPELL_CAST_SUCCESS, vs modeled
			--              0.5 * speed / base_speed (should match within a frame)
			--   cycle    = fire-to-fire, vs eWS (matches when haste was stable)
			--   pred err = actual fire vs predicted next_fired (+ = fired late;
			--              should stay within ~±50 ms when nothing clipped)
			if fluffy.debug_output and prev_fired > 0 and predicted_fire > 0 then
				fluffy.print_debug(string.format(
					"AS fired | aim %.3fs (model %.3fs) | cycle %.3fs (eWS %.3f) | pred err %+d ms",
					measured_aim, curr_cast,
					current_auto_finish - prev_fired, curr_speed,
					floor((current_auto_finish - predicted_fire) * 1000 + 0.5)));
			end
			
		elseif event == "SPELL_CAST_SUCCESS" then

			fluffy.is_casting = false;

		elseif event == "SPELL_CAST_FAILED" and log_message[12] == fluffy.spell_id_auto then
			fluffy.is_casting_autoshot = false;
			fluffy.is_casting = false;
			fluffy.logic_dirty = true;

		elseif event == "SPELL_CAST_FAILED" then
			
			fluffy.is_casting = false;

		elseif event == "SPELL_CAST_INTERRUPTED" then

			fluffy.is_casting = false;

		end

		if current_casting_info ~= fluffy.is_casting then
			local CR = FluffyDBPC["color_raptor"];
			local CM = FluffyDBPC["color_melee"];

			if fluffy.is_casting then

				for A, v in pairs(fluffy.ability_raptorstrike["bars"]) do
					v.texture:SetColorTexture(CR[1]/255, CR[2]/255, CR[3]/255, CR[4]*0.5);
				end

				for A, v in pairs(fluffy.ability_meleestrike["bars"]) do
					v.texture:SetColorTexture(CM[1]/255, CM[2]/255, CM[3]/255, CM[4]*0.5);
				end

			else
				for A, v in pairs(fluffy.ability_raptorstrike["bars"]) do
					v.texture:SetColorTexture(CR[1]/255, CR[2]/255, CR[3]/255, CR[4]);
				end

				for A, v in pairs(fluffy.ability_meleestrike["bars"]) do
					v.texture:SetColorTexture(CM[1]/255, CM[2]/255, CM[3]/255, CM[4]);
				end
			end

		end


    end
end

-- registers sucessful casts and updates appropriate variables
local fluffy_frame = CreateFrame("Frame");
fluffy_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
fluffy_frame:RegisterEvent("UNIT_SPELLCAST_SENT");
fluffy_frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
fluffy_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

fluffy_frame:SetScript("OnEvent",
    function(self, event, arg1, arg2, arg3, arg4)

		if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
			update_spell_finished(arg3);

		elseif event == "UNIT_SPELLCAST_SENT" and arg1 == "player"  then
			update_spell_started(arg4);
			fluffy.update_player_stats();
			fluffy.update_spell_data();

		elseif event == "UNIT_SPELLCAST_INTERRUPTED" and arg1 == "player"  then
			update_spell_interrupted();
			fluffy.update_player_stats();
			fluffy.update_spell_data();

		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			parse_combat_event({CombatLogGetCurrentEventInfo()});

		end

    end
);
