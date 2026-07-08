local _, fluffy = ...

-- Target debuffs that raise the player's ranged attack power, matched by
-- spell id so non-English clients work.  Hunter's Mark values per rank (TBC).
local hunters_mark_rap = {
	[1130]  = 20,   -- rank 1
	[14323] = 45,   -- rank 2
	[14324] = 75,   -- rank 3
	[14325] = 110,  -- rank 4
};
-- Expose Weakness (SV talent proc) grants attackers 25% of the casting
-- hunter's agility as AP; ~300 approximates a raid-geared SV hunter.
local expose_weakness_id = 34501;
local expose_weakness_rap = 300;

function fluffy.update_player_stats()
    if fluffy.is_player_hunter == false then
		return;
	end

	local base, posBuff, negBuff = UnitRangedAttackPower("player");
	fluffy.rap = base + posBuff - negBuff;

	base, posBuff, negBuff = UnitAttackPower("player");
	fluffy.map = base + posBuff - negBuff;

	for i=1, 40 do
		local name, _, _, _, _, _, _, _, _, spell_id = UnitDebuff("target", i);
		if name == nil then
			break;
		end
		if hunters_mark_rap[spell_id] ~= nil then
			fluffy.rap = fluffy.rap + hunters_mark_rap[spell_id];
		elseif spell_id == expose_weakness_id then
			fluffy.rap = fluffy.rap + expose_weakness_rap;
		end
	end

end
