local _, fluffy = ...

function update_talent_stats()
    if fluffy.is_player_hunter == false then
		return;
	end    

	local currRank;

	if fluffy.client_version > 11307 then
		_, _, _, _, currRank, _ = GetTalentInfo(2,10); -- Mortal Shots
		fluffy.ranged_crit_modifier = 0.06*currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,13); -- Barrage
		fluffy.multishot_modifier = 1 + 0.04 * currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,18); -- Improved Barrage
		fluffy.multishot_crit_bonus = 4 * currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,15); -- Ranged Weapon Specialization
		fluffy.ranged_modifier = 1 + 0.01 * currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(3,4); -- Savage Strikes
		fluffy.raptor_crit_bonus = 10*currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(3,12); -- Surefooted
		fluffy.hit_bonus = currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,6); -- Improved Arcane Shot
		fluffy.arcane_cd_reduction = 0.2 * currRank;

		_, _, _, _, currRank, _ = GetTalentInfo(1,1); -- Quick Shots
		fluffy.haste_buffs_table[fluffy.haste_id_quick_shots][2] = 1 + 0.03 * currRank;

		_, _, _, _, currRank, _ = GetTalentInfo(1,20); -- serpent's swiftness
		fluffy.serpent_swiftness = 1 + 0.04 * currRank;

	else
		_, _, _, _, currRank, _ = GetTalentInfo(2,9); -- Mortal Shots
		fluffy.ranged_crit_modifier = 0.06*currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,11); -- Barrage
		fluffy.multishot_modifier = 1 + 0.04 * currRank;
	
		fluffy.multishot_crit_bonus = 0;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,13); -- Ranged Weapon Specialization
		fluffy.ranged_modifier = 1 + 0.01 * currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(3,5); -- Savage Strikes
		fluffy.raptor_crit_bonus = 10*currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(3,11); -- Surefooted
		fluffy.hit_bonus = currRank;
	
		_, _, _, _, currRank, _ = GetTalentInfo(2,6); -- Improved Arcane Shot
		fluffy.arcane_cd_reduction = 0.2 * currRank;

		fluffy.haste_buffs_table[fluffy.haste_id_quick_shots][2] = 1.3; -- Quick Shots
	end	


	-- print(fluffy.ranged_crit_modifier, fluffy.multishot_modifier, fluffy.multishot_crit_bonus, fluffy.ranged_modifier, fluffy.raptor_crit_bonus, fluffy.hit_bonus);
end

