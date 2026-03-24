local _, fluffy = ...

local color_code = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
}
local function ColorCode(c)
	c = max(0, min(255, math.ceil(c)))
	c0 = c % 16
	c1 = math.ceil((c - c0) / 16)
	return color_code[c1 + 1] .. color_code[c0 + 1]
end

function fluffy.ConvertColorsToCode(R, G, B, A)
	return 'ff' .. ColorCode(R) .. ColorCode(G) .. ColorCode(B)
end

function mysplit_damage (inputstr)
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

function mysplit_speed (inputstr)
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

function get_percent(inputstr)
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

function comma_value(amount)
	local formatted = amount
	while true do  
	  formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
	  if (k==0) then
		break
	  end
	end
	return formatted
  end
  
function round(val, decimal)
	if (decimal) then
	  return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
	else
	  return math.floor(val+0.5)
	end
  end
  
  function format_num(amount, decimal, prefix, neg_prefix)
	local str_amount,  formatted, famount, remain
  
	decimal = decimal or 2  -- default 2 decimal places
	neg_prefix = neg_prefix or "-" -- default negative sign
  
	famount = math.abs(round(amount,decimal))
	famount = math.floor(famount)
  
	remain = round(math.abs(amount) - famount, decimal)
  
		  -- comma to separate the thousands
	formatted = comma_value(famount)
  
		  -- attach the decimal portion
	if (decimal > 0) then
	  remain = string.sub(tostring(remain),3)
	  formatted = formatted .. "." .. remain ..
				  string.rep("0", decimal - string.len(remain))
	end
  
		  -- attach prefix string e.g '$' 
	formatted = (prefix or "") .. formatted 
  
		  -- if value is negative then format accordingly
	if (amount<0) then
	  if (neg_prefix=="()") then
		formatted = "("..formatted ..")"
	  else
		formatted = neg_prefix .. formatted 
	  end
	end
  
	return formatted
  end


  function InitDB()

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
	
	if FluffyDBPC["window_length"] == nil then
		FluffyDBPC["window_length"] = 3;
	end

	if FluffyDBPC["hide_autoshotbar_when_casting"] == nil then
		FluffyDBPC["hide_autoshotbar_when_casting"] = {false};
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