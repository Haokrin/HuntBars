local _, fluffy = ...

-- ---------------------------------------------------------------------------
-- Icon visibility
-- Toggles the small spell icons that sit on top of each ability bar.
-- ---------------------------------------------------------------------------
function update_bar_icon_visibility()
    if (FluffyDBPC == nil) then
        InitDB();
    end

    local show_icons = FluffyDBPC["show_icons"][1];

    for i=1,#FluffyBars_bars do
        if (show_icons) then
            FluffyBars_bars[i].icon:Show();
        else
            FluffyBars_bars[i].icon:Hide();
        end
    end
end

-- ---------------------------------------------------------------------------
-- Overall frame visibility
-- Hides or shows every UI element based on FluffyDBPC["hidden"].
-- ---------------------------------------------------------------------------
function update_visibility()

	if FluffyDBPC == nil then
		InitDB();
	end


	if FluffyDBPC["hidden"][1] then

		FluffyBar:Hide();
		FluffyBars_icon_background:Hide();

        for i=1,#FluffyBars_bars do
            FluffyBars_bars[i]:Hide();
        end
        for i=1,#FluffyBars_icons do
            FluffyBars_icons[i]:Hide();
        end
        for i=1,#FluffyBars_icon_glows do
            FluffyBars_icon_glows[i]:Hide();
        end

        for i=1,#FluffyBars_autoshotsparks do
            FluffyBars_autoshotsparks[i]:Hide();
        end
        for i=1,#FluffyBars_autoshotmovements do
            FluffyBars_autoshotmovements[i]:Hide();
        end
	else
		if fluffy.is_player_hunter == false then
			return;
		end


		FluffyBar:Show();
		FluffyBars_icon_background:Hide();

        for i=1,#FluffyBars_bars do
            FluffyBars_bars[i]:Hide();
        end
        for i=1,#FluffyBars_icons do
            FluffyBars_icons[i]:Hide();
        end
        for i=1,#FluffyBars_icon_glows do
            FluffyBars_icon_glows[i]:Hide();
        end

        for i=1,#FluffyBars_autoshotsparks do
            FluffyBars_autoshotsparks[i]:Hide();
        end
        for i=1,#FluffyBars_autoshotmovements do
            FluffyBars_autoshotmovements[i]:Hide();
        end

		if FluffyDBPC["icosize"][1] > 0 then
            -- icon frames intentionally kept hidden for now
        else
            FluffyBars_icon_background:Hide();

            for i=1,#FluffyBars_icons do
                FluffyBars_icons[i]:Hide();
            end
            for i=1,#FluffyBars_icon_glows do
                FluffyBars_icon_glows[i]:Hide();
            end
        end
	end
end

-- ---------------------------------------------------------------------------
-- Position
-- Applies saved anchor position to the main bar frame.
-- ---------------------------------------------------------------------------
function update_position()
	if fluffy.is_player_hunter == false then
		return;
	end

	if FluffyDBPC == nil then
		InitDB();
	end

    FluffyBar:SetPoint(FluffyDBPC["pos"][1], FluffyDBPC["pos"][2], FluffyDBPC["pos"][3]);
end

-- ---------------------------------------------------------------------------
-- Size
-- Resizes the main bar, spark frames, and ability bar frames.
-- Also refreshes position and visibility after a resize.
-- ---------------------------------------------------------------------------
function update_size()
	if not fluffy.is_player_hunter then
		return;
	end

	if FluffyDBPC == nil then
		InitDB();
	end

	FluffyBar:SetSize(FluffyDBPC["size"][1], FluffyDBPC["size"][2]);

    for i=1,#FluffyBars_autoshotsparks do
        FluffyBars_autoshotsparks[i]:SetSize(FluffyDBPC["spark_width"], FluffyDBPC["size"][2] - 5);
    end
    for i=1,#FluffyBars_autoshotmovements do
        FluffyBars_autoshotmovements[i]:SetSize(1, FluffyDBPC["size"][2] - 5);
    end

    -- Ranged abilities use the full bar height; melee uses the bottom half.
    local h_ = 0;
    if FluffyDBPC["consider_melee"][1] == false then
        h_ = (FluffyDBPC["size"][2] - 5);
    else
        h_ = (0.5 * FluffyDBPC["size"][2] - 3.5);
    end
    for i=1,#FluffyBars_bars do
        FluffyBars_bars[i]:SetSize(1, h_);
        if (FluffyBars_bars[i].icon) then
            FluffyBars_bars[i].icon:SetSize(h_,h_);
        end
    end

	update_position();
	update_visibility();
end

-- ---------------------------------------------------------------------------
-- Combat-only visibility tracker
-- When "show_only_in_combat" is enabled this frame hides the bar out of
-- combat and shows it again as soon as combat starts.
-- ---------------------------------------------------------------------------
local frame_combat_hidden = CreateFrame("Frame", "CombatTracker", UIParent);
local combat_status_last_update = 0;
frame_combat_hidden:SetScript("OnUpdate",
    function(self, elapsed)
        if fluffy.is_player_hunter == false or fluffy.is_player_hunter == nil then
            return;
        end

        if FluffyDBPC["show_only_in_combat"][1] == false then
            FluffyBar:Show();
            return;
        end

        local t = GetTime();
        if (FluffyDBPC["update"][1] * (t - combat_status_last_update) < 1) then
            return;
        end
        combat_status_last_update = t;

        if not UnitAffectingCombat("player") then
            FluffyBar:Hide();
        else
            FluffyBar:Show();
        end
    end
);
frame_combat_hidden:Show();
