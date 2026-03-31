local _, fluffy = ...


local function print_help(msg)
	if msg ~= nil then
		if msg:len() > 0 then
			print("Error while using the |c"..fluffy.msg_color_ok.."/fluffy|r command!");
			print("'" .. msg .. "'" .. " is not a recognized option");
		end
	end

	print("Available Fluffy commands:");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."info|r' prints out the current settings of all variables");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."resize|r |c"..fluffy.msg_color_caution.."w h|r' sets the UI elements to fit the specified width |c"..fluffy.msg_color_caution.."w|r and height |c"..fluffy.msg_color_caution.."h|r in pixels");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."move|r |c"..fluffy.msg_color_caution.."x y|r' moves the UI elements along the axi with respect to offsets |c"..fluffy.msg_color_caution.."x|r and |c"..fluffy.msg_color_caution.."y|r pixels");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."showicons|r' |c"..fluffy.msg_color_caution.."toggles|r displaying icons on the bars");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."icosize|r |c"..fluffy.msg_color_caution.."l|r' sets the size of the ability icons to |c"..fluffy.msg_color_caution.."l x l|r pixels");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."freq|r |c"..fluffy.msg_color_caution.."n|r'          sets the refresh rate of the UI elements to |c"..fluffy.msg_color_caution.."n|r times per second");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."hide|r' |c"..fluffy.msg_color_caution.."hides|r the UI elements");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."show|r' |c"..fluffy.msg_color_caution.."shows|r the UI elements");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."reset|r' |c"..fluffy.msg_color_caution.."resets|r the position and size of the UI element to default values");
	print("------------------");
	print("|c"..fluffy.msg_color_ok.."Furthermore you may use|r |c"..fluffy.msg_color_info.."SHIFT+CLICK|r |c"..fluffy.msg_color_ok.."to drag the UI elements around|r");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."lock|r' |c"..fluffy.msg_color_caution.."prevents|r the UI elements from being draggable");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."unlock|r' |c"..fluffy.msg_color_caution.."allows|r the UI elements to be moved by mouse");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_auto|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Auto Shot'|r cast window");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_spark|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Auto Shot indicator'|r");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_arcane|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Arcane Shot'|r recommendation window");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_steady|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Steady Shot'|r recommendation window");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_multi|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Multi-Shot'|r recommendation window");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_raptor|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Raptor Strike'|r window");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."color_melee|r |c"..fluffy.msg_color_caution.."R G B A|r' sets the color and alpha of the |c"..fluffy.msg_color_info.."'Auto Attack'|r window");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."spark|r |c"..fluffy.msg_color_caution.."n|r' sets the width of the autoshot indicator in pixels");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."use_arcane|r' |c"..fluffy.msg_color_caution.." toggles|r displaying recommendations for |c"..fluffy.msg_color_info.."'Arcane Shot'|r");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."use_multi|r' |c"..fluffy.msg_color_caution.." toggles|r displaying recommendations for |c"..fluffy.msg_color_info.."'Multi-Shot'|r");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."use_melee|r' |c"..fluffy.msg_color_caution.." toggles|r displaying recommendations for |c"..fluffy.msg_color_info.."'Melee abilities'|r");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."incombat|r' |c"..fluffy.msg_color_caution.." toggles|r displaying the bars only in combat");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."length|r |c"..fluffy.msg_color_caution.."n|r' sets the bar length to show recommendations 'n' seconds into the future");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."latency|r' shows current measured latency and compensation offset");
	print("------------------");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."baked_rotation|r' |c"..fluffy.msg_color_caution.."toggles|r rotation-aware mode (shows only next ability to cast for your speed)");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."show_mode|r' |c"..fluffy.msg_color_caution.."toggles|r displaying the rotation mode label above the bar");
	print("'|c"..fluffy.msg_color_ok.."/fluffy|r |c"..fluffy.msg_color_info.."baked_melee|r' |c"..fluffy.msg_color_caution.."toggles|r including melee abilities in baked rotation recommendations");

end



local function update_frequency()
	if fluffy.is_player_hunter == false then
		return;
	end
	if FluffyDBPC == nil then
		InitDB();
	end
	fluffy.update_frequency_val = FluffyDBPC["update"][1];
end



function fix()
	update_spell_data()
	update_frequency();
	update_visibility();
	update_size();
	update_position();
end

function print_info_position()
	local pos_x = math.floor(FluffyDBPC["pos"][2]*100 + 0.5)*0.01;
	local pos_y = math.floor(FluffyDBPC["pos"][3]*100 + 0.5)*0.01;
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."position|r     ] = (" .. pos_x .. ", " .. pos_y .. ")");
end

function print_info_width()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."width|r     ] = " .. FluffyDBPC["size"][1]);
end

function print_info_height()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."height|r    ] = " .. FluffyDBPC["size"][2]);
end

function print_info_iconsize()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."icon size|r] = " .. FluffyDBPC["icosize"][1]);
end

function print_info_showicons()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."showicons|r] = " .. (FluffyDBPC["show_icons"][1] and "on" or "off"));
end

function print_info_update_freqency()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."update frequency|r] = " .. FluffyDBPC["update"][1] .. " fps");
end

function print_info_hidden()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."hidden|r] = " .. (FluffyDBPC["hidden"][1] and "yes" or "no"));
end

function print_info_locked()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."locked|r] = " .. (FluffyDBPC["locked"][1] and "yes" or "no"));
end

function print_info_colors()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."colors|r]");
	local r = FluffyDBPC["color_auto"][1]
	local g = FluffyDBPC["color_auto"][2]
	local b = FluffyDBPC["color_auto"][3]
	local a = FluffyDBPC["color_auto"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Auto Shot Cast|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");

	local r = FluffyDBPC["color_spark"][1]
	local g = FluffyDBPC["color_spark"][2]
	local b = FluffyDBPC["color_spark"][3]
	local a = FluffyDBPC["color_spark"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Auto Shot Spark|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");
	
	local r = FluffyDBPC["color_arcane"][1]
	local g = FluffyDBPC["color_arcane"][2]
	local b = FluffyDBPC["color_arcane"][3]
	local a = FluffyDBPC["color_arcane"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Arcane Shot|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");
	
	local r = FluffyDBPC["color_multi"][1]
	local g = FluffyDBPC["color_multi"][2]
	local b = FluffyDBPC["color_multi"][3]
	local a = FluffyDBPC["color_multi"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Multi-Shot|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");
	
	local r = FluffyDBPC["color_steady"][1]
	local g = FluffyDBPC["color_steady"][2]
	local b = FluffyDBPC["color_steady"][3]
	local a = FluffyDBPC["color_steady"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Steady Shot|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");
	
	local r = FluffyDBPC["color_raptor"][1]
	local g = FluffyDBPC["color_raptor"][2]
	local b = FluffyDBPC["color_raptor"][3]
	local a = FluffyDBPC["color_raptor"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Raptor Strike|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");
	
	local r = FluffyDBPC["color_melee"][1]
	local g = FluffyDBPC["color_melee"][2]
	local b = FluffyDBPC["color_melee"][3]
	local a = FluffyDBPC["color_melee"][4]
	print("|c"..fluffy.ConvertColorsToCode(r, g, b, a).."Melee Hit|r = (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")");
	
end

function print_info_spark()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."Auto Shot Spark width|r] = " .. FluffyDBPC["spark_width"] .. " pixels");
end

function print_info_abilities()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."Show Abilities|r]");
	print("|c"..fluffy.msg_color_info.."Arcane Shot|r = " .. (FluffyDBPC["consider_arcane"][1] and "yes" or "no"));
	print("|c"..fluffy.msg_color_info.."Multi-Shot|r = " .. (FluffyDBPC["consider_multi"][1] and "yes" or "no"));
	print("|c"..fluffy.msg_color_info.."Melee|r = " .. (FluffyDBPC["consider_melee"][1] and "yes" or "no"));
end

function print_info_combat()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."Show only in combat|r] = " .. (FluffyDBPC["show_only_in_combat"][1] and "yes" or "no"));
end

function print_info_length()
	print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."Future length|r] = " .. FluffyDBPC["window_length"] .. " [s]");
end

function print_info()
	print_info_position();
	print_info_width();
	print_info_height();
	print_info_iconsize();
	print_info_showicons();
	print_info_update_freqency();
	print_info_hidden();
	print_info_locked();
	print_info_colors();
	print_info_spark();
	print_info_abilities();
	print_info_combat();
	print_info_length();
end

function reset()
	if fluffy.is_player_hunter == false then
		FluffyDBPC = {};
		FluffyDBPC["hidden"] = {true};
		fix();
		return;
	end
	
	FluffyDBPC = {};
	FluffyDBPC["version"] = fluffy.current_addon_version;
	FluffyDBPC["pos"] = {"CENTER", 0, 0};
	FluffyDBPC["size"] = {321, 25};
	FluffyDBPC["update"] = {45};
	FluffyDBPC["hidden"] = {false};
	FluffyDBPC["icosize"] = {24};
	FluffyDBPC["locked"] = {false};
	FluffyDBPC["show_icons"] = {false};

	FluffyDBPC["color_auto"] = {231, 76, 60, 0.5};
	FluffyDBPC["color_spark"] = {255, 255, 255, 1};
	FluffyDBPC["color_arcane"] = {175, 122, 197, 0.9};
	FluffyDBPC["color_multi"] = {3, 134, 254, 0.9};
	FluffyDBPC["color_steady"] = {252, 152, 3, 0.9};
	FluffyDBPC["color_raptor"] = {39, 174, 96, 0.9};
	FluffyDBPC["color_melee"] = {213, 216, 220, 0.9};

	FluffyDBPC["spark_width"] = 2;
	
	FluffyDBPC["consider_arcane"] = {true};
	FluffyDBPC["consider_multi"] = {true};
	FluffyDBPC["consider_melee"] = {true};
	FluffyDBPC["show_only_in_combat"] = {false};

	FluffyDBPC["window_length"] = 3;

	FluffyDBPC["hide_autoshotbar_when_casting"] = {false};

	fix();

	print_info();
	
end

function purge()
	FluffyDBPC["quiver"] = {};
	FluffyDBPC["ammo"] = {};
	FluffyDBPC["ranged_weapons"] = {};

	update_ammo_stats();
	update_quiver_haste();
	update_weapon_stats();
end



SLASH_FLUFFY_BAR1 = "/fluffy";
SlashCmdList["FLUFFY_BAR"] = function(msg)
	
	if fluffy.is_player_hunter == false then
		print("'/fluffy' command disabled because this Character is not a hunter")
		return
	end
	
	local idx = 0;
	local args = {};
	local cmd = nil;
	
	for token in string.gmatch(msg, "[^%s]+") do
		if idx == 0 then
			cmd = token;
		else
			args[idx] = token;
		end
		idx = idx + 1;
	end
	
	if FluffyDBPC == nil then
		InitDB();
	end
	
	local nargs = table.getn(args);
	
	if cmd == "resize" and nargs == 2 then
		local w = tonumber(args[1]);
		local h = tonumber(args[2]);
		
		if w ~= nil and h ~= nil then
			FluffyDBPC["size"] = {w, h};
			
			update_size();
		else
			print_help(msg);
			return;
		end
	elseif cmd == "move" and nargs == 2 then
		local x = tonumber(args[1]);
		local y = tonumber(args[2]);

		if x ~= nil and y ~= nil then
			FluffyDBPC["pos"] = {FluffyDBPC["pos"][1], FluffyDBPC["pos"][2] + x, FluffyDBPC["pos"][3] + y};
			update_position();
		else
			print_help(msg);
			return;
		end
	elseif cmd == "freq" and nargs == 1 then
		local n = tonumber(args[1]);

		if n ~= nil then
			FluffyDBPC["update"] = {n};
			update_frequency();
		else
			print_help(msg);
			return;
		end
	elseif cmd == "hide" and nargs == 0 then
		FluffyDBPC["hidden"] = {true};
		update_visibility();
	elseif cmd == "info" and nargs == 0 then
		print_info();
	elseif cmd == "show" and nargs == 0 then
		FluffyDBPC["hidden"] = {false};
		update_visibility();
	elseif cmd == "lock" and nargs == 0 then
		FluffyDBPC["locked"] = {true};
		print("Fluffy Hunter Bars are now locked");
	elseif cmd == "unlock" and nargs == 0 then
		FluffyDBPC["locked"] = {false};
		print("Fluffy Hunter Bars are now unlocked");
	elseif cmd == "reset" and nargs == 0 then
		reset();
	elseif cmd == "purgedb" and nargs == 0 then
		purge();
		print("Fluffy Hunter Bars Cache cleared");
	elseif cmd == "showicons" and nargs == 0 then
		FluffyDBPC["show_icons"] = {not FluffyDBPC["show_icons"][1]};
		print("Hunter Bars icons are now toggled to ".. (FluffyDBPC["show_icons"][1] and "on" or "off"));
		update_bar_icon_visibility();
	elseif cmd == "icosize" and nargs == 1 then
		local l = tonumber(args[1]);
		
		if l ~= nil then
			FluffyDBPC["icosize"] = {l};
			
			update_size();
		else
			print_help(msg);
			return;
		end
	elseif cmd == "color_auto" and nargs == 4 then
		FluffyDBPC["color_auto"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "color_spark" and nargs == 4 then
		FluffyDBPC["color_spark"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "color_arcane" and nargs == 4 then
		FluffyDBPC["color_arcane"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "color_steady" and nargs == 4 then
		FluffyDBPC["color_steady"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "color_multi" and nargs == 4 then
		FluffyDBPC["color_multi"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "color_raptor" and nargs == 4 then
		FluffyDBPC["color_raptor"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "color_melee" and nargs == 4 then
		FluffyDBPC["color_melee"] = {tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])};
	elseif cmd == "spark" and nargs == 1 then
		FluffyDBPC["spark_width"] = tonumber(args[1]);
	elseif cmd == "use_arcane" and nargs == 0 then
		FluffyDBPC["consider_arcane"][1] = not FluffyDBPC["consider_arcane"][1]
	elseif cmd == "use_multi" and nargs == 0 then
		FluffyDBPC["consider_multi"][1] = not FluffyDBPC["consider_multi"][1]
	elseif cmd == "use_melee" and nargs == 0 then
		FluffyDBPC["consider_melee"][1] = not FluffyDBPC["consider_melee"][1]
	elseif cmd == "incombat" and nargs == 0 then
		FluffyDBPC["show_only_in_combat"][1] = not FluffyDBPC["show_only_in_combat"][1]
	elseif cmd == "length" and nargs == 1 then
		FluffyDBPC["window_length"] = tonumber(args[1]);
	elseif cmd == "latency" and nargs == 0 then
		local ms = math.floor(fluffy.latency * 1000 + 0.5);
		local _, _, home, world = GetNetStats();
		print("|c"..fluffy.msg_color_ok.."Fluffy Hunter Bars|r [|c"..fluffy.msg_color_info.."Latency|r]");
		print("  Home: " .. (home or "?") .. " ms  |  World: " .. (world or "?") .. " ms");
		print("  Compensation offset applied: |c"..fluffy.msg_color_info.. ms .."|r ms  (clamped to 50-500 ms)");
		print("  Current rotation: |c"..fluffy.msg_color_info..fluffy.rotation_mode.."|r  (eWS: " .. string.format("%.2f", fluffy.rotation_ews) .. "s)");
	elseif cmd == "baked_rotation" and nargs == 0 then
		FluffyDBPC["baked_rotation"][1] = not FluffyDBPC["baked_rotation"][1];
		local state = FluffyDBPC["baked_rotation"][1] and "|c"..fluffy.msg_color_ok.."ON" or "|c"..fluffy.msg_color_caution.."OFF";
		print("|c"..fluffy.msg_color_info.."Baked Rotation Mode|r set to " .. state .. "|r (shows only next recommended ability for your rotation speed)");
	elseif cmd == "show_mode" and nargs == 0 then
		FluffyDBPC["show_rotation_mode"][1] = not FluffyDBPC["show_rotation_mode"][1];
		local state = FluffyDBPC["show_rotation_mode"][1] and "|c"..fluffy.msg_color_ok.."ON" or "|c"..fluffy.msg_color_caution.."OFF";
		print("|c"..fluffy.msg_color_info.."Rotation Mode Display|r set to " .. state .. "|r");
	elseif cmd == "baked_melee" and nargs == 0 then
		FluffyDBPC["baked_include_melee"][1] = not FluffyDBPC["baked_include_melee"][1];
		local state = FluffyDBPC["baked_include_melee"][1] and "|c"..fluffy.msg_color_ok.."ON" or "|c"..fluffy.msg_color_caution.."OFF";
		print("|c"..fluffy.msg_color_info.."Melee Weaving in Baked Rotation|r set to " .. state .. "|r (Raptor Strike / Melee Auto will be included in rotation recommendations)");
	else
		print_help(msg);
	end
end 

local variables_frame = CreateFrame("FRAME");
variables_frame:RegisterEvent("ADDON_LOADED");
function variables_frame:OnEvent(event, name )

	fluffy.time_loaded = GetTime() + 2;

	if event == "ADDON_LOADED" and name == "FluffyHunterBars" then
		
		fluffy.time_loaded = GetTime() + 5;

		local _, _, cid = UnitClass("player");
		if cid == 3 then
			fluffy.is_player_hunter = true;
		end

		InitDB();

		if fluffy.is_player_hunter == false then 
			return;
		end
		
		fluffy.player_id = UnitGUID("player");

		if FluffyDBPC["version"] ~= fluffy.current_addon_version then
			purge();
			FluffyDBPC["version"] = fluffy.current_addon_version;
		end
	
	
		fluffy.client_version = select(4, GetBuildInfo());



		update_spell_data();
		

		create_ui();
		-- create_configuration_ui();

		update_frequency();
		update_visibility();
		update_bar_icon_visibility();
		update_position();
		update_size();

		update_ammo_stats();
		update_quiver_haste();
		update_weapon_stats();
		update_talent_stats();
		update_player_stats();

	end
end

variables_frame:SetScript("OnEvent", variables_frame.OnEvent);

local fluffy_frame_items = CreateFrame("Frame");
fluffy_frame_items:RegisterEvent("UNIT_INVENTORY_CHANGED");
fluffy_frame_items:SetScript("OnEvent",
    function(self, event, arg1)
		if arg1 ~= "player" then 
			return; 
		end
		local weapon_ids_current = {fluffy.melee_mh_weapon_id, fluffy.melee_oh_weapon_id, fluffy.ranged_weapon_id};

		update_spell_data();
		update_weapon_stats();
		update_ammo_stats();
		update_quiver_haste();
		update_talent_stats();

		local weapon_ids_new = {fluffy.melee_mh_weapon_id, fluffy.melee_oh_weapon_id, fluffy.ranged_weapon_id};

		if weapon_ids_new[3] ~= nil then
			if weapon_ids_current[3] ~= nil then
				if weapon_ids_new[3] ~= weapon_ids_current[3] then
					--reset ranged swing
					fluffy.ability_autoshot["fired"] = GetTime();
				end
			else
				--reset ranged swing
				fluffy.ability_autoshot["fired"] = GetTime();
			end
		end
	
		if weapon_ids_new[1] ~= nil then
			if weapon_ids_current[1] ~= nil then
				if weapon_ids_new[1] ~= weapon_ids_current[1] then
					--reset main-hand swing
					fluffy.ability_meleestrike["fired"] = GetTime();
				end
			else
				--reset main-hand swing
				fluffy.ability_meleestrike["fired"] = GetTime();
			end
		end
	
		-- analyze_game_state(fluffy.future_window_lenght);
    end
);

fluffy.feign_death_active = 0;

local fluffy_frame_buffs = CreateFrame("Frame");
fluffy_frame_buffs:RegisterEvent("UNIT_AURA");
fluffy_frame_buffs:SetScript("OnEvent",
    function(self, event, arg1)
		if arg1 ~= "player" then 
			return; 
		end
		local haste_table = fluffy.haste_buffs_table;


		local tmp_tab = {};

		for i=1, 40 do
			local _, _, _, _, _, etime, _, _, _, id = UnitBuff("player",i);
			if id ~= nil then
				tmp_tab[id] = etime;
			end
		end
		
		-- losing buffs prematurely
		local tcurr = GetTime();
		for k, etime in pairs(haste_table) do
			if etime[1] > tcurr and tmp_tab[k] == nil then
				haste_table[k][1] = 0;
			end
		end

		-- gaining buffs
		local fd_found = 0;
		for i=1, 40 do
			local _, _, _, _, _, etime, _, _, _, id = UnitBuff("player",i);

			if id == 5384 then
				fd_found = 1;
				fluffy.feign_death_active = 1;
			else
				if haste_table[id] ~= nil then
					if id == fluffy.haste_id_berserking then
						if etime > haste_table[id][1] + 0.5 then
							local player_health_ratio = UnitHealth("player") / UnitHealthMax("player");
							haste_table[id][2] = 1.1 + 0.2 * (1 - (math.max(0.4, player_health_ratio)))/0.6;
						end
					end
	
					haste_table[id][1] = etime;
				end
			end

			if fd_found == 0 then
				fluffy.feign_death_active = 0;
			end
		end
		fluffy.logic_dirty = true;
    end
);

local fluffy_frame_loading = CreateFrame("Frame");

fluffy_frame_loading:RegisterEvent("PLAYER_LEAVING_WORLD");
fluffy_frame_loading:RegisterEvent("PLAYER_ENTERING_WORLD");
fluffy_frame_loading:RegisterEvent("CHARACTER_POINTS_CHANGED");
fluffy_frame_loading:SetScript("OnEvent",
    function(self, event)
		if event == "PLAYER_LEAVING_WORLD" then
			fluffy.time_loaded = GetTime() + 5;
		elseif event == "PLAYER_ENTERING_WORLD" then
			fluffy.time_loaded = GetTime() + 5;
			-- Re-read talents here because talent data is not yet available
			-- during ADDON_LOADED (GetTalentInfo returns nil at that point).
			if fluffy.is_player_hunter then
				update_talent_stats();
			end
		elseif event == "CHARACTER_POINTS_CHANGED" then
			-- Talent respec or level-up: refresh talent-derived values.
			if fluffy.is_player_hunter then
				update_talent_stats();
			end
		end
    end
);





