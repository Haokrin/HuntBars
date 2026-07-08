local _, fluffy = ...

local color_code = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
}
local function ColorCode(c)
	c = max(0, min(255, math.ceil(c)))
	local c0 = c % 16
	local c1 = math.ceil((c - c0) / 16)
	return color_code[c1 + 1] .. color_code[c0 + 1]
end

function fluffy.ConvertColorsToCode(R, G, B, A)
	return 'ff' .. ColorCode(R) .. ColorCode(G) .. ColorCode(B)
end

function fluffy.mysplit_damage(inputstr)
	local t={}

	if inputstr == nil or #inputstr < 1 then
		return t;
	end

	inputstr = inputstr:gsub( ",", ".")

	for str in string.gmatch(inputstr, "([^%D]+)") do
		table.insert(t, str)
	end
	return t
end

function fluffy.mysplit_speed(inputstr)
	local t={}

	if inputstr == nil or #inputstr < 1 then
		return t;
	end

	inputstr = inputstr:gsub( ",", ".")

	for str in string.gmatch(inputstr, "([^%s]+)") do
		table.insert(t, str);
	end
	return t
end

function fluffy.get_percent(inputstr)
	local out = 0;

	if inputstr == nil or #inputstr < 1 then
		return out;
	end

	if string.find(inputstr, "%%") == nil then
		return out;
	end

	for str in string.gmatch(inputstr, "([^%%]+)") do

		local val = tonumber(str);
		if val ~= nil then
			out = 0.01 * val;
			break;
		end
	end

	return out;
end

function fluffy.latency_to_ms(latency)
	return math.floor(latency * 1000 + 0.5)
end

function fluffy.InitDB()

	if fluffy.is_player_hunter == false then
		FluffyDBPC = {};
		FluffyDBPC["hidden"] = {true};
		return;
	end

	if FluffyDBPC == nil then
		FluffyDBPC = {};
	end

	if FluffyDBPC["version"] == nil then
		FluffyDBPC["version"] = fluffy.current_addon_version;
	end

	if FluffyDBPC["pos"] == nil then
		FluffyDBPC["pos"] = {"CENTER", 0, 0};
	end

	if FluffyDBPC["size"] == nil then
		FluffyDBPC["size"] = {321, 25};
	end

	if FluffyDBPC["update"] == nil then
		FluffyDBPC["update"] = {45};
	end

	if FluffyDBPC["hidden"] == nil then
		FluffyDBPC["hidden"] = {false};
	end

	if FluffyDBPC["show_icons"] == nil then
		FluffyDBPC["show_icons"] = {false};
	end

	if FluffyDBPC["icosize"] == nil then
		FluffyDBPC["icosize"] = {24};
	end

	if FluffyDBPC["locked"] == nil then
		FluffyDBPC["locked"] = {false};
	end

	if FluffyDBPC["color_auto"] == nil then
		FluffyDBPC["color_auto"] = {231, 76, 60, 0.5};
	end

	if FluffyDBPC["color_spark"] == nil then
		FluffyDBPC["color_spark"] = {255, 255, 255, 1};
	end

	if FluffyDBPC["color_arcane"] == nil then
		FluffyDBPC["color_arcane"] = {175, 122, 197, 0.9};
	end

	if FluffyDBPC["color_multi"] == nil then
		FluffyDBPC["color_multi"] = {3, 134, 254, 0.9};
	end

	if FluffyDBPC["color_steady"] == nil then
		FluffyDBPC["color_steady"] = {252, 152, 3, 0.9};
	end

	if FluffyDBPC["color_raptor"] == nil then
		FluffyDBPC["color_raptor"] = {39, 174, 96, 0.9};
	end

	if FluffyDBPC["color_melee"] == nil then
		FluffyDBPC["color_melee"] = {213, 216, 220, 0.9};
	end

	if FluffyDBPC["spark_width"] == nil then
		FluffyDBPC["spark_width"] = 2;
	end

	if FluffyDBPC["consider_arcane"] == nil then
		FluffyDBPC["consider_arcane"] = {true};
	end

	if FluffyDBPC["consider_multi"] == nil then
		FluffyDBPC["consider_multi"] = {true};
	end

	if FluffyDBPC["consider_melee"] == nil then
		FluffyDBPC["consider_melee"] = {true};
	end

	if FluffyDBPC["show_only_in_combat"] == nil then
		FluffyDBPC["show_only_in_combat"] = {false};
	end

	if FluffyDBPC["range_secondary"] == nil then
		FluffyDBPC["range_secondary"] = {false};
	end

	if FluffyDBPC["window_length"] == nil then
		FluffyDBPC["window_length"] = 3;
	end

	if FluffyDBPC["hide_autoshotbar_when_casting"] == nil then
		FluffyDBPC["hide_autoshotbar_when_casting"] = {false};
	end

	if FluffyDBPC["baked_rotation"] == nil then
		FluffyDBPC["baked_rotation"] = {false};
	end

	if FluffyDBPC["show_rotation_mode"] == nil then
		FluffyDBPC["show_rotation_mode"] = {true};
	end

	if FluffyDBPC["baked_include_melee"] == nil then
		FluffyDBPC["baked_include_melee"] = {false};
	end

	if FluffyDBPC["quiver"] == nil then
		FluffyDBPC["quiver"] = {};
	end

	if FluffyDBPC["ammo"] == nil then
		FluffyDBPC["ammo"] = {};
	end

	if FluffyDBPC["ranged_weapons"] == nil then
		FluffyDBPC["ranged_weapons"] = {};
	end

	if FluffyDBPC["melee_weapons"] == nil then
		FluffyDBPC["melee_weapons"] = {};
	end

end
