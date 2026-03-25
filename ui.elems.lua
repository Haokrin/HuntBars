local _, fluffy = ...

FluffyBar = CreateFrame("Frame","FluffyBar",UIParent);
FluffyBars_icon_background = CreateFrame("Frame","FluffyBarIconBackground",FluffyBar);

FluffyBars_autoshotsparks = {};
FluffyBars_autoshotmovements = {};
FluffyBars_icon_glows = {};
FluffyBars_icons = {};
FluffyBars_bars = {};

function create_main_bar()
    if fluffy.client_version > 11307 then
        FluffyBar = CreateFrame("Frame","FluffyBar",UIParent, "BackdropTemplate");
    else
        FluffyBar = CreateFrame("Frame","FluffyBar",UIParent);
    end
    FluffyBar:SetFrameStrata("BACKGROUND");
    FluffyBar:SetWidth(100); 
    FluffyBar:SetHeight(100);
    FluffyBar:SetPoint("CENTER",0,0);
    local backdropInfo = {
        bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 6,
        edgeSize = 7,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    }
    FluffyBar:SetBackdrop(backdropInfo);
    FluffyBar:SetMovable(true);
    FluffyBar:EnableMouse(true);

    -- Rotation mode label — sits just above the left edge of the bar.
    -- Shows the current rotation name derived from effective weapon speed,
    -- e.g. "French", "1:1", "Skipping", "2:3" etc.
    fluffy.rotation_label = FluffyBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    fluffy.rotation_label:SetPoint("BOTTOMLEFT", FluffyBar, "TOPLEFT", 2, 2);
    fluffy.rotation_label:SetText("...");
    fluffy.rotation_label:SetTextColor(1, 0.82, 0, 1);  -- gold

    -- eWS value — sits just above centre of the bar.
    fluffy.ews_label = FluffyBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    fluffy.ews_label:SetPoint("BOTTOM", FluffyBar, "TOP", 0, 2);
    fluffy.ews_label:SetText("");
    fluffy.ews_label:SetTextColor(0.7, 0.7, 0.7, 1);  -- grey

    -- Latency indicator — sits just above the right edge of the bar.
    -- Shows the measured network latency in ms so the player can verify
    -- how much compensation is being applied.
    fluffy.latency_label = FluffyBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    fluffy.latency_label:SetPoint("BOTTOMRIGHT", FluffyBar, "TOPRIGHT", -2, 2);
    fluffy.latency_label:SetText("? ms");
    fluffy.latency_label:SetTextColor(0.6, 0.9, 0.6, 1);  -- light green

    -- Haste buff indicator — shows between rotation label and eWS label.
    -- Displays "QS" (Quick Shots) or "RF" (Rapid Fire) when those buffs
    -- are active so the player gets clear visual feedback on haste procs.
    fluffy.haste_indicator_label = FluffyBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    fluffy.haste_indicator_label:SetPoint("BOTTOMLEFT", FluffyBar, "TOPLEFT", 70, 2);
    fluffy.haste_indicator_label:SetText("");
    fluffy.haste_indicator_label:SetTextColor(0, 1, 1, 1);  -- cyan
end

function create_icon_anchor()
    FluffyBars_icon_background:SetFrameStrata("BACKGROUND");
    FluffyBars_icon_background:SetPoint("CENTER",0,0);
end

function create_autoshotTrackers(nbars)
    local C = FluffyDBPC["color_spark"];
    local r1 = C[1]/255;
    local g1 = C[2]/255;
    local b1 = C[3]/255;
    local a1 = C[4];
--[[
    local r2 = fluffy.forbidden_movement_bar_color[1]/255;
    local g2 = fluffy.forbidden_movement_bar_color[2]/255;
    local b2 = fluffy.forbidden_movement_bar_color[3]/255;
    local a2 = fluffy.forbidden_movement_bar_color[4];
--]]

    for i = 1,nbars do
        FluffyBarAutoshotSpark = CreateFrame("Frame","FluffyBarAutoshotSpark",FluffyBar);
        FluffyBarAutoshotSpark:SetPoint("CENTER",0,0);
        local t = FluffyBarAutoshotSpark:CreateTexture("AutoSparkTex","OVERLAY")
        t:SetColorTexture(r1, g1, b1, a1);
        t:SetAllPoints(FluffyBarAutoshotSpark)
        FluffyBarAutoshotSpark.texture = t
    
        table.insert(FluffyBars_autoshotsparks, FluffyBarAutoshotSpark);
    
--[[
        frame = CreateFrame("Frame","FluffyBarAutoshotMovementBar",FluffyBarAutoshotSpark);
        frame:SetPoint("CENTER",0,0);
        local t = frame:CreateTexture("AutoshotMovTex","OVERLAY")
        t:SetColorTexture(r2, g2, b2, a2);
        t:SetAllPoints(frame)
        frame.texture = t
    
        table.insert(FluffyBars_autoshotmovements, frame);
--]]
    end

end

function create_bars(ability, align, nbars, r, g, b, a, icon_path)
    ability["align"] = align;

    for i=1,nbars do
        local frame = CreateFrame("Frame","FluffyBarAbility", FluffyBar);
        frame:SetPoint(align,0,0);

        local coloredTexture = frame:CreateTexture("AbilityTex","ARTWORK")
        coloredTexture:SetColorTexture(r/255, g/255, b/255, a);
        coloredTexture:SetAllPoints(frame);
        frame.texture = coloredTexture;
        
        local tIcon = frame:CreateTexture(nil, "OVERLAY");
        tIcon:SetTexture(icon_path, "CLAMPTOBLACKADDITIVE");
        tIcon:SetAlpha(0.75);
        tIcon:SetPoint("TOPLEFT", frame);
        frame.icon = tIcon;

        table.insert(ability["bars"], frame);
        table.insert(FluffyBars_bars, frame);
    end
end

function create_icon(ability, icon_path, r, g, b, a)
    frame_icon = CreateFrame("Frame","FluffyBarsIcon",FluffyBars_icon_background);
    frame_icon:SetPoint("CENTER",0,0);
    local t = frame_icon:CreateTexture(nil,"OVERLAY");
    t:SetTexture(icon_path, false);
    t:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    t:SetAllPoints(frame_icon);
    frame_icon.texture = t;

    table.insert(FluffyBars_icons, frame_icon);
    ability["icon"] = frame_icon;

    
    frame_glow = CreateFrame("Frame","FluffyBarsIconGlow",frame_icon);
    frame_glow:SetPoint("CENTER",0,0);
    local tg = frame_glow:CreateTexture(nil,"OVERLAY");
    tg:SetTexture("Interface\\SpellActivationOverlay\\IconAlert", false);
    tg:SetColorTexture(r, g, b, a);
    tg:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625);
    tg:SetAllPoints(frame_glow)
    frame_glow.texture = tg

    table.insert(FluffyBars_icon_glows, frame_glow);
    ability["glow"] = frame_glow;
end