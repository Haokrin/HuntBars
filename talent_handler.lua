local _, fluffy = ...

-- Scan all talents across all tabs and build a lookup table keyed by
-- talent name.  This is robust against client versions that change the
-- sequential talent index ordering (e.g. client 20505 vs the original
-- hardcoded indices).  Returns an empty table if talent data is not yet
-- available (e.g. during ADDON_LOADED before the server sends it).
local function scan_talents()
	local ranks = {};
	for tab = 1, GetNumTalentTabs() do
		local count = GetNumTalents(tab);
		if count then
			for i = 1, count do
				local name, _, _, _, rank, _ = GetTalentInfo(tab, i);
				if name and rank then
					ranks[name] = rank;
				end
			end
		end
	end
	return ranks;
end

function update_talent_stats()
	if fluffy.is_player_hunter == false then
		return;
	end

	local ranks = scan_talents();

	-- If the scan returned nothing, talent data is not yet available.
	-- Bail out and let a later event (PLAYER_ENTERING_WORLD,
	-- CHARACTER_POINTS_CHANGED) retry.
	local has_data = false;
	for _ in pairs(ranks) do has_data = true; break; end
	if not has_data then return; end

	-- Helper: look up a talent rank by name, defaulting to 0 if not
	-- found (talent not trained or locale mismatch).
	local function r(name)
		return ranks[name] or 0;
	end

	-- Marksmanship talents
	fluffy.ranged_crit_modifier = 0.06 * r("Mortal Shots");
	fluffy.multishot_modifier   = 1 + 0.04 * r("Barrage");
	fluffy.ranged_modifier      = 1 + 0.01 * r("Ranged Weapon Specialization");
	fluffy.arcane_cd_reduction  = 0.2 * r("Improved Arcane Shot");

	if fluffy.client_version > 11307 then
		fluffy.multishot_crit_bonus = 4 * r("Improved Barrage");
	else
		fluffy.multishot_crit_bonus = 0;
	end

	-- Survival talents
	fluffy.raptor_crit_bonus = 10 * r("Savage Strikes");
	fluffy.hit_bonus         = r("Surefooted");

	-- Beast Mastery talents
	-- Quick Shots (Improved Aspect of the Hawk): the buff always gives
	-- a fixed haste amount when it procs; the talent rank only controls
	-- the proc chance (handled by the game engine).  In TBC Classic the
	-- haste is 15%; in older clients it is 30%.
	if fluffy.client_version > 11307 then
		fluffy.haste_buffs_table[fluffy.haste_id_quick_shots][2] = 1.15;
	else
		fluffy.haste_buffs_table[fluffy.haste_id_quick_shots][2] = 1.3;
	end

	fluffy.serpent_swiftness = 1 + 0.04 * r("Serpent's Swiftness");
end
