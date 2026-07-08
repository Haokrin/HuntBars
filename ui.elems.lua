local _, fluffy = ...

FluffyBar = CreateFrame("Frame","FluffyBar",UIParent);

FluffyBars_autoshotsparks = {};
FluffyBars_bars = {};

function fluffy.create_main_bar()
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

function fluffy.create_autoshotTrackers(nbars)
    local C = FluffyDBPC["color_spark"];
    local r1 = C[1]/255;
    local g1 = C[2]/255;
    local b1 = C[3]/255;
    local a1 = C[4];

    for i = 1,nbars do
        local spark = CreateFrame("Frame","FluffyBarAutoshotSpark",FluffyBar);
        spark:SetPoint("CENTER",0,0);
        local t = spark:CreateTexture("AutoSparkTex","OVERLAY")
        t:SetColorTexture(r1, g1, b1, a1);
        t:SetAllPoints(spark)
        spark.texture = t

        table.insert(FluffyBars_autoshotsparks, spark);
    end

end

function fluffy.create_bars(ability, align, nbars, r, g, b, a, icon_path)
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
