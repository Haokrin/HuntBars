local _, fluffy = ...

local tooltip_ammo = CreateFrame('GameTooltip', "AmmoTooltip", UIParent, 'GameTooltipTemplate');
tooltip_ammo:SetOwner(WorldFrame, "ANCHOR_NONE");
tooltip_ammo:AddFontStrings(
    tooltip_ammo:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    tooltip_ammo:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) 
);


local function get_arrow_dps(tooltip_text)
	local out = 0;

	if tooltip_text ~= nil then
		local splt = mysplit_speed(tooltip_text);

		for i = 1,table.getn(splt) do
			local val = tonumber(splt[i]);

			if val ~= nil then
				out = val;
				break;
			end
		end
	end

	return out;
end

function update_ammo_stats()
    if fluffy.is_player_hunter == false then
		return;
	end    

	fluffy.ammo_dps = 0;

	if FluffyDBPC == nil then
		FluffyDBPC = {};
	end

	if FluffyDBPC["ammo"] == nil then
		FluffyDBPC["ammo"] = {};
	end
	local item_id = GetInventoryItemID("player", 0);

	if item_id ~= nil and item_id ~= 0 then
		if FluffyDBPC["ammo"][item_id] == nil then
			local itemName, itemLink = GetItemInfo(item_id);
		
			tooltip_ammo:ClearLines()
			tooltip_ammo:SetOwner(WorldFrame, "ANCHOR_NONE");

			if pcall(function() tooltip_ammo:SetHyperlink(itemLink) end) then

				local ammo_dps = get_arrow_dps(AmmoTooltipTextLeft3:GetText());

				if ammo_dps < 0.005 then
					ammo_dps = get_arrow_dps(AmmoTooltipTextLeft4:GetText());
				end
				
				FluffyDBPC["ammo"][item_id] = ammo_dps;
			end
		
			tooltip_ammo:Hide();
		end

		fluffy.ammo_dps = FluffyDBPC["ammo"][item_id];
	end

end


local tooltip_quiver = CreateFrame('GameTooltip', "QuiverTooltip", UIParent, 'GameTooltipTemplate');
tooltip_quiver:SetOwner(WorldFrame, "ANCHOR_NONE");
tooltip_quiver:AddFontStrings(
    tooltip_quiver:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    tooltip_quiver:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) 
);

local function get_bag_haste(line)
	local out = 0;

	if line == nil then
		return out;
	end

	local splt = mysplit_speed(line);
	for i = 1,table.getn(splt) do
		local val = get_percent(splt[i]);
		out = max(out, val);
	end	
	
	return out;
end

function update_quiver_haste()
    if fluffy.is_player_hunter == false then
		return;
	end    

	fluffy.quiver_haste = 0.0;

	if FluffyDBPC == nil then
		FluffyDBPC = {};
	end

	if FluffyDBPC["quiver"] == nil then
		FluffyDBPC["quiver"] = {};
	end

	for bagId = 20, 23, 1 do
		local item_id = GetInventoryItemID("player", bagId);

		if item_id ~= nil then
			if FluffyDBPC["quiver"][item_id] == nil then
				local itemName, itemLink = GetItemInfo(item_id);
		
				tooltip_quiver:ClearLines()
				tooltip_quiver:SetOwner(WorldFrame, "ANCHOR_NONE");

				if pcall(function() tooltip_quiver:SetHyperlink(itemLink) end) then
					local max_haste_bag = get_bag_haste(QuiverTooltipTextLeft3:GetText());
					max_haste_bag = max(max_haste_bag, get_bag_haste(QuiverTooltipTextLeft4:GetText()));
					max_haste_bag = max(max_haste_bag, get_bag_haste(QuiverTooltipTextLeft5:GetText()));
					max_haste_bag = max(max_haste_bag, get_bag_haste(QuiverTooltipTextLeft6:GetText()));
					max_haste_bag = max(max_haste_bag, get_bag_haste(QuiverTooltipTextLeft7:GetText()));
					max_haste_bag = max(max_haste_bag, get_bag_haste(QuiverTooltipTextLeft8:GetText()));
		
					FluffyDBPC["quiver"][item_id] = max_haste_bag;
					-- print("Fluffy Hunter Bars detected new bag item:" .. itemName .. " with " .. max_haste_bag .. " bonus haste to Autoshots");
				end
	
				tooltip_quiver:Hide();
			end
		
			fluffy.quiver_haste = max(fluffy.quiver_haste, FluffyDBPC["quiver"][item_id]);
		end

	end
end

