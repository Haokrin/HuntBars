local _, fluffy = ...

function update_player_stats()
    if fluffy.is_player_hunter == false then
		return;
	end    

	local base, posBuff, negBuff = UnitRangedAttackPower("player");
	fluffy.rap = base + posBuff - negBuff;

	local base, posBuff, negBuff = UnitAttackPower("player");
	fluffy.map = base + posBuff - negBuff;
	
	for i=1, 40 do
		local name = UnitDebuff("target",i);
		if name ~= nil then
			if name == "Hunter's Mark" then
				fluffy.rap = fluffy.rap + 110;
			end
			if name == "Expose Weakness" then
				fluffy.rap = fluffy.rap + 300;
			end
		end
	end

end