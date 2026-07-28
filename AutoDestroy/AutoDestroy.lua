-- ---------------------------------------------------------------------------
-- Auto Destroy - watches your bags and destroys items you marked as junk.
--
-- Why this is an addon and not a WeakAura:
--   Blizzard made DeleteCursorItem() require a hardware event (patch 9.0.2)
--   and protected it against macro scripts (patch 9.1.5), and WeakAuras on top
--   of that blocks the function outright inside custom code - it lives in the
--   blockedFunctions table in WeakAuras/AuraEnvironment.lua, where reading it
--   hands back an empty stub and flags the aura with "Forbidden function or
--   table". A WeakAura therefore cannot destroy an item at all.
--
-- What happens instead:
--   Scanning the bags, matching the item and picking the stack up are all
--   unrestricted, so those are fully automatic. Only the final delete needs a
--   hardware event. The addon tries the direct call first; if the client
--   refuses it, it falls back to a one-click prompt, because a real click or
--   key press is exactly the hardware event Blizzard asks for.
-- ---------------------------------------------------------------------------

local _, ns = ...;

local PREFIX = "|cAA27AE60Auto Destroy|r: ";

-- 1.15 ships the C_Container namespace; the flat API is kept as a fallback so
-- the file still loads on older clients.
local container     = C_Container;
local get_num_slots = container and container.GetContainerNumSlots or GetContainerNumSlots;
local get_slot_info = container and container.GetContainerItemInfo  or GetContainerItemInfo;
local pickup_slot   = container and container.PickupContainerItem   or PickupContainerItem;

local LAST_BAG            = NUM_BAG_SLOTS or 4;
local QUALITY_RARE        = 3;
local MAX_AUTO_ATTEMPTS   = 3;    -- give up on the silent path and ask the player

-- Set once the client refuses a direct delete, so we stop poking at it and go
-- straight to the prompt for the rest of the session.
local hardware_event_required = false;
local scan_pending = false;
local attempts = {};              -- [itemID] = direct delete attempts made
local prompt;                     -- built lazily, the first time it is needed

local scan, schedule_scan;

-- ------------------------------------------------------------------- helpers

local function chat(msg)
    print(PREFIX .. msg);
end

local function db()
    if AutoDestroyDB == nil then AutoDestroyDB = {}; end

    local d = AutoDestroyDB;
    if d.items    == nil then d.items = {}; end
    if d.enabled  == nil then d.enabled = true; end
    if d.announce == nil then d.announce = true; end
    if d.dry_run  == nil then d.dry_run = false; end

    return d;
end

-- GetContainerItemInfo() returns a table on modern clients and a flat list on
-- the old one; normalise both down to the values this addon cares about.
local function read_slot(bag, slot)
    local first, count, locked, quality, _, _, link, _, _, id = get_slot_info(bag, slot);

    if type(first) == "table" then
        return first.itemID, first.hyperlink, first.isLocked, first.quality, first.stackCount;
    end

    return id, link, locked, quality, count;
end

-- Accepts a numeric id, an item link, or a plain name that the client has
-- already cached.
local function item_id_from(text)
    if text == nil or text == "" then
        return nil;
    end

    local id = tonumber(text);
    if id then
        return id;
    end

    id = tonumber(text:match("item:(%d+)"));
    if id then
        return id;
    end

    local _, link = GetItemInfo(text);
    if link then
        return tonumber(link:match("item:(%d+)"));
    end

    return nil;
end

local function display_name(id)
    local name, link = GetItemInfo(id);
    return link or name or ("item:" .. tostring(id));
end

local function with_count(label, count)
    if count and count > 1 then
        return label .. " x" .. count;
    end
    return label;
end

local function find_target()
    local items = db().items;

    for bag = 0, LAST_BAG do
        for slot = 1, (get_num_slots(bag) or 0) do
            local id, link, locked, quality, count = read_slot(bag, slot);

            if id and items[id] then
                return bag, slot, id, link, locked, quality, count;
            end
        end
    end

    return nil;
end

-- Picks the stack up and asks the server to destroy it. Returns true when the
-- cursor came back empty (the item is gone), or false plus a reason:
--   "cursor"   - the slot did not hand us the item we expected, nothing done
--   "hardware" - the delete was refused, the stack has been put back
local function destroy_slot(bag, slot, id)
    pickup_slot(bag, slot);

    local kind, cursor_id = GetCursorInfo();
    if kind ~= "item" or cursor_id ~= id then
        ClearCursor();
        return false, "cursor";
    end

    pcall(DeleteCursorItem);

    if GetCursorInfo() then
        ClearCursor();
        return false, "hardware";
    end

    return true;
end

-- -------------------------------------------------------------------- prompt

local function on_destroy_click()
    local bag, slot, id, link = find_target();

    if not bag then
        if prompt then prompt:Hide(); end
        return;
    end

    if GetCursorInfo() then
        chat("your cursor is holding something - drop it first.");
        return;
    end

    local ok = destroy_slot(bag, slot, id);
    if ok then
        if db().announce then
            chat("destroyed " .. (link or display_name(id)) .. ".");
        end
    else
        chat("could not destroy " .. (link or display_name(id)) .. ".");
    end

    -- One item per hardware event, so re-check for the next stack instead of
    -- looping here.
    schedule_scan(0.2);
end

local function build_prompt()
    local f = CreateFrame("Frame", "AutoDestroyPrompt", UIParent);
    f:SetSize(250, 62);
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 180);
    f:SetMovable(true);
    f:EnableMouse(true);
    f:RegisterForDrag("LeftButton");
    f:SetScript("OnDragStart", f.StartMoving);
    f:SetScript("OnDragStop", f.StopMovingOrSizing);
    f:SetClampedToScreen(true);

    local bg = f:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(f);
    if bg.SetColorTexture then
        bg:SetColorTexture(0, 0, 0, 0.75);
    else
        bg:SetTexture(0, 0, 0, 0.75);
    end

    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("TOP", f, "TOP", 0, -9);
    label:SetWidth(236);
    f.label = label;

    local button = CreateFrame("Button", "AutoDestroyButton", f, "UIPanelButtonTemplate");
    button:SetSize(230, 24);
    button:SetPoint("BOTTOM", f, "BOTTOM", 0, 9);
    button:SetText("Destroy");
    button:SetScript("OnClick", on_destroy_click);
    f.button = button;

    f:Hide();
    return f;
end

local function show_prompt(id, link, count)
    prompt = prompt or build_prompt();
    prompt.label:SetText("Destroy " .. with_count(link or display_name(id), count) .. "?");
    prompt:Show();
end

local function hide_prompt()
    if prompt then prompt:Hide(); end
end

local function apply_binding(key, quiet)
    prompt = prompt or build_prompt();

    if InCombatLockdown() then
        if not quiet then chat("key bindings cannot be changed in combat."); end
        return;
    end

    ClearOverrideBindings(prompt);

    if key == nil or key == "" then
        db().key = nil;
        if not quiet then chat("key binding cleared."); end
        return;
    end

    SetOverrideBindingClick(prompt, true, key, "AutoDestroyButton");
    db().key = key;
    if not quiet then chat("bound " .. key .. " to the destroy button."); end
end

-- ---------------------------------------------------------------------- scan

function schedule_scan(delay)
    if scan_pending then
        return;
    end

    scan_pending = true;
    C_Timer.After(delay, function() scan(); end);
end

function scan()
    scan_pending = false;

    local d = db();
    if not d.enabled then
        hide_prompt();
        return;
    end

    local bag, slot, id, link, locked, _, count = find_target();

    if not bag then
        hide_prompt();
        wipe(attempts);
        return;
    end

    -- A server operation is still in flight on that slot; let it settle.
    if locked then
        schedule_scan(0.3);
        return;
    end

    if d.dry_run then
        chat("would destroy " .. with_count(link or display_name(id), count) .. " (dry run is on).");
        return;
    end

    -- Never take the cursor away from the player.
    if GetCursorInfo() then
        schedule_scan(0.5);
        return;
    end

    if hardware_event_required or (attempts[id] or 0) >= MAX_AUTO_ATTEMPTS then
        show_prompt(id, link, count);
        return;
    end

    attempts[id] = (attempts[id] or 0) + 1;

    local ok, reason = destroy_slot(bag, slot, id);

    if ok then
        attempts[id] = nil;
        if d.announce then
            chat("destroyed " .. with_count(link or display_name(id), count) .. ".");
        end
        schedule_scan(0.2);
    elseif reason == "hardware" then
        hardware_event_required = true;
        chat("this client only destroys items on a key press or click - use the button, "
             .. "or bind a key with |cffffff00/autodestroy key <KEY>|r.");
        show_prompt(id, link, count);
    else
        schedule_scan(0.5);
    end
end

-- ------------------------------------------------------------------ commands

local function add_item(text, force)
    local id = item_id_from(text);

    if not id then
        chat("could not read an item there - shift-click it into the chat box, or use its numeric id.");
        return;
    end

    local name, link, quality = GetItemInfo(id);

    if quality and quality >= QUALITY_RARE and not force then
        local tier = _G["ITEM_QUALITY" .. quality .. "_DESC"] or "high quality";
        chat((link or name or id) .. " is " .. tier
             .. ". Repeat the command with |cffffff00force|r on the end to add it anyway.");
        return;
    end

    db().items[id] = name or tostring(id);
    chat("will destroy " .. (link or name or id) .. " from now on.");
    schedule_scan(0.1);
end

local function remove_item(text)
    local id = item_id_from(text);
    local items = db().items;

    if id and items[id] then
        local name = items[id];
        items[id] = nil;
        hide_prompt();
        chat("no longer destroying " .. name .. ".");
    else
        chat("that item is not on the list.");
    end
end

local function list_items()
    local items = db().items;
    local count = 0;

    for id, name in pairs(items) do
        count = count + 1;
        chat("  " .. (select(2, GetItemInfo(id)) or name) .. "  (" .. id .. ")");
    end

    if count == 0 then
        chat("the list is empty - add something with |cffffff00/autodestroy add <item>|r.");
    end
end

local function print_help()
    chat("commands:");
    chat("  |cffffff00/autodestroy add <link or id>|r - destroy this item on sight");
    chat("  |cffffff00/autodestroy remove <link or id>|r - stop destroying it");
    chat("  |cffffff00/autodestroy list|r - show the list");
    chat("  |cffffff00/autodestroy on|r / |cffffff00off|r - enable or disable");
    chat("  |cffffff00/autodestroy dry|r - only report what would be destroyed");
    chat("  |cffffff00/autodestroy quiet|r - toggle the chat message on each destroy");
    chat("  |cffffff00/autodestroy key <KEY>|r - bind a key to the destroy button");
end

local function handle_command(input)
    local cmd, rest = (input or ""):match("^(%S*)%s*(.-)%s*$");
    cmd = (cmd or ""):lower();

    local d = db();

    if cmd == "add" then
        local without_force = rest:match("^(.-)%s+force$");
        add_item(without_force or rest, without_force ~= nil);

    elseif cmd == "remove" or cmd == "rem" or cmd == "delete" then
        remove_item(rest);

    elseif cmd == "list" then
        list_items();

    elseif cmd == "on" then
        d.enabled = true;
        chat("enabled.");
        schedule_scan(0.1);

    elseif cmd == "off" then
        d.enabled = false;
        hide_prompt();
        chat("disabled.");

    elseif cmd == "dry" then
        d.dry_run = not d.dry_run;
        chat(d.dry_run and "dry run on - nothing will actually be destroyed."
                        or "dry run off - items on the list will be destroyed.");

    elseif cmd == "quiet" then
        d.announce = not d.announce;
        chat(d.announce and "announcing every destroy." or "staying quiet.");

    elseif cmd == "key" then
        apply_binding(rest ~= "" and rest:upper() or nil, false);

    else
        print_help();
    end
end

ns.handle_command = handle_command;
ns.destroy_slot   = destroy_slot;
ns.find_target    = find_target;
ns.item_id_from   = item_id_from;
ns.read_slot      = read_slot;
ns.scan           = scan;
ns.db             = db;

-- --------------------------------------------------------------------- setup

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_LOGIN");
events:RegisterEvent("BAG_UPDATE_DELAYED");
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local key = db().key;
        if key then
            apply_binding(key, true);
        end
    end

    schedule_scan(0.2);
end);

SLASH_AUTODESTROY1 = "/autodestroy";
SLASH_AUTODESTROY2 = "/adestroy";
SlashCmdList["AUTODESTROY"] = handle_command;
