local _, fluffy = ...

-- ---------------------------------------------------------------------------
-- Label updates — throttled to the configured fps (default 45 fps).
-- Handles the rotation mode label, eWS readout, haste indicator, and
-- latency display that sit above the main bar.
-- To change label colours, thresholds, or text format edit this file.
-- ---------------------------------------------------------------------------
fluffy.update_labels = function(t)
    if (FluffyDBPC["update"][1] * (t - fluffy.last_update) < 1) then
        return;
    end
    fluffy.last_update = t;

    -- Rotation mode label (top-left) ----------------------------------------
    if fluffy.rotation_label then
        if FluffyDBPC["show_rotation_mode"][1] then
            local label_text = fluffy.rotation_mode or "...";
            -- In baked mode also show the next ability name after the mode.
            if FluffyDBPC["baked_rotation"][1] and fluffy.baked_next_ability_name then
                label_text = label_text .. " > " .. fluffy.baked_next_ability_name;
            end
            fluffy.rotation_label:SetText(label_text);
            fluffy.rotation_label:Show();

            -- Colour by rotation speed: gold = slow, orange = medium, green = fast, red = extreme.
            local mode = fluffy.rotation_mode;
            if mode == "French" or mode == "LongFrench" then
                fluffy.rotation_label:SetTextColor(1, 0.82, 0, 1);    -- gold
            elseif mode == "Skipping" or mode == "1:1" then
                fluffy.rotation_label:SetTextColor(1, 0.55, 0.05, 1); -- orange
            elseif mode == "2:3" or mode == "1:2" or mode == "2:5" then
                fluffy.rotation_label:SetTextColor(0.6, 1, 0.2, 1);   -- green
            else
                fluffy.rotation_label:SetTextColor(1, 0.2, 0.2, 1);   -- red (1:3, extreme)
            end
        else
            fluffy.rotation_label:Hide();
        end
    end

    -- Effective weapon speed label (top-centre) ------------------------------
    if fluffy.ews_label and fluffy.rotation_ews > 0 then
        fluffy.ews_label:SetText(string.format("%.2fs", fluffy.rotation_ews));

        -- Colour by active ranged haste: cyan = QS, green = RF, orange = both, grey = none.
        local qs_active = fluffy.haste_buffs_table[fluffy.haste_id_quick_shots][1] >= t;
        local rf_active = fluffy.haste_buffs_table[fluffy.haste_id_rapid_fire][1] >= t;
        if qs_active and rf_active then
            fluffy.ews_label:SetTextColor(1, 0.65, 0, 1);    -- orange
        elseif rf_active then
            fluffy.ews_label:SetTextColor(0.2, 1, 0.2, 1);   -- green
        elseif qs_active then
            fluffy.ews_label:SetTextColor(0, 0.9, 1, 1);     -- cyan
        else
            fluffy.ews_label:SetTextColor(0.7, 0.7, 0.7, 1); -- grey
        end
    end

    -- Haste buff indicator (top-left, after rotation label) ------------------
    -- Shows "QS", "RF", or "QS+RF" when those buffs are active.
    if fluffy.haste_indicator_label then
        local parts = {};
        if fluffy.haste_buffs_table[fluffy.haste_id_quick_shots][1] >= t then
            table.insert(parts, "QS");
        end
        if fluffy.haste_buffs_table[fluffy.haste_id_rapid_fire][1] >= t then
            table.insert(parts, "RF");
        end
        if #parts > 0 then
            fluffy.haste_indicator_label:SetText(table.concat(parts, "+"));
            fluffy.haste_indicator_label:Show();
        else
            fluffy.haste_indicator_label:SetText("");
            fluffy.haste_indicator_label:Hide();
        end
    end

    -- Latency label (top-right) ----------------------------------------------
    -- Shows one-way compensation value. Colour thresholds (one-way):
    -- green < 50 ms (RTT: < 100 ms), yellow < 100 ms (RTT: < 200 ms), red >= 100 ms
    if fluffy.latency_label then
        local ms = latency_to_ms(fluffy.latency);
        fluffy.latency_label:SetText(ms .. " ms");
        if fluffy.latency < fluffy.latency_color_threshold_green then
            fluffy.latency_label:SetTextColor(0.4, 1, 0.4, 1);
        elseif fluffy.latency < fluffy.latency_color_threshold_yellow then
            fluffy.latency_label:SetTextColor(1, 0.85, 0.1, 1);
        else
            fluffy.latency_label:SetTextColor(1, 0.3, 0.3, 1);
        end
    end
end
