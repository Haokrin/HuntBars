-- ---------------------------------------------------------------------------
-- Offline verification harness for the Auto Destroy addon.
--
--   Run from the repository root with plain Lua 5.1 (same version as WoW):
--     lua5.1 tests/auto_destroy_harness.lua
--
-- Stubs the container/cursor API and a fake bag, then asserts the behaviour
-- that matters for something that deletes items for a living:
--
--   1. Items that are not on the list are never touched.
--   2. An item on the list is destroyed on its own when the client allows the
--      direct DeleteCursorItem() call.
--   3. When the client refuses that call (the live 1.15 behaviour, since the
--      function needs a hardware event) the stack is handed back to the bag
--      untouched and a prompt is shown instead - and clicking that prompt,
--      which is a hardware event, does destroy it.
--   4. A locked slot is left alone until the server operation on it settles.
--   5. The player's cursor is never stolen while it is holding something.
--   6. Rare or better quality needs an explicit "force" before it is listed.
--   7. The stack on the cursor is confirmed to be the intended item before
--      anything is deleted, so a slot that shifts underneath the scan cannot
--      make the addon destroy the wrong thing.
--   8. read_slot() understands both the modern table return and the old flat
--      return of GetContainerItemInfo().
-- ---------------------------------------------------------------------------

-- ------------------------------------------------------------------ WoW API

local bags;             -- [bag][slot] = {id, link, quality, count, locked}
local cursor;           -- nil, or {id = , link = }
local allow_delete;     -- false simulates the hardware-event refusal
local timers;           -- queued C_Timer.After callbacks
local messages;         -- captured chat output
local frames;           -- created frames, by name
local in_combat;

local item_db = {
    [4306]  = { name = "Silk Cloth",       quality = 1 },
    [2589]  = { name = "Linen Cloth",      quality = 1 },
    [18422] = { name = "Head of Onyxia",   quality = 4 },
};

local function link_for(id)
    return "|cffffffff|Hitem:" .. id .. "::::::::60:::::|h[" .. (item_db[id] and item_db[id].name or id) .. "]|h|r";
end

function wipe(t) for k in pairs(t) do t[k] = nil; end return t; end

function print(...)
    local parts = {};
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))); end
    messages[#messages + 1] = table.concat(parts, " ");
end

function GetItemInfo(key)
    local id = tonumber(key);

    if not id then
        for candidate, info in pairs(item_db) do
            if info.name == key then id = candidate; break; end
        end
    end

    local info = id and item_db[id];
    if not info then return nil; end

    return info.name, link_for(id), info.quality;
end

NUM_BAG_SLOTS = 4;

local function slot_entry(bag, slot)
    return bags[bag] and bags[bag][slot];
end

C_Container = {
    GetContainerNumSlots = function(bag)
        return bags[bag] and #bags[bag] or 0;
    end,

    GetContainerItemInfo = function(bag, slot)
        local entry = slot_entry(bag, slot);
        if not entry then return nil; end

        return {
            itemID     = entry.id,
            hyperlink  = link_for(entry.id),
            isLocked   = entry.locked or false,
            quality    = item_db[entry.id] and item_db[entry.id].quality or 1,
            stackCount = entry.count or 1,
        };
    end,

    PickupContainerItem = function(bag, slot)
        local entry = slot_entry(bag, slot);
        if not entry or cursor then return; end
        cursor = { id = entry.id, link = link_for(entry.id), bag = bag, slot = slot };
    end,
};

function GetCursorInfo()
    if not cursor then return nil; end
    return "item", cursor.id, cursor.link;
end

function ClearCursor()
    cursor = nil;
end

function DeleteCursorItem()
    -- Blizzard requires a hardware event; when there is not one the call is a
    -- no-op and the item stays on the cursor.
    if not allow_delete or not cursor then return; end

    local held = bags[cursor.bag];
    if held then table.remove(held, cursor.slot); end
    cursor = nil;
end

C_Timer = {
    After = function(delay, fn)
        timers[#timers + 1] = { delay = delay, fn = fn };
    end,
};

function InCombatLockdown() return in_combat; end
function SetOverrideBindingClick() return true; end
function ClearOverrideBindings() end

UIParent = {};
SlashCmdList = {};

local function stub_region()
    local r = {};
    setmetatable(r, { __index = function() return function() end; end });
    return r;
end

function CreateFrame(_, name, _, _)
    local f = {
        name    = name,
        shown   = false,
        scripts = {},
        text    = nil,
    };

    f.SetScript          = function(self, kind, fn) self.scripts[kind] = fn; end;
    f.GetScript          = function(self, kind) return self.scripts[kind]; end;
    f.RegisterEvent      = function() end;
    f.Show               = function(self) self.shown = true; end;
    f.Hide               = function(self) self.shown = false; end;
    f.SetText            = function(self, value) self.text = value; end;
    f.CreateTexture      = function() return stub_region(); end;
    f.CreateFontString   = function() return stub_region(); end;
    f.StartMoving        = function() end;
    f.StopMovingOrSizing = function() end;

    setmetatable(f, { __index = function() return function() end; end });

    if name then frames[name] = f; end
    return f;
end

-- --------------------------------------------------------------- harness bits

local function run_timers()
    -- The addon reschedules itself, so drain the queue with a hard cap rather
    -- than looping forever if it ever starts spinning.
    for _ = 1, 50 do
        if #timers == 0 then return; end

        local queued = timers;
        timers = {};

        for _, t in ipairs(queued) do t.fn(); end
    end

    error("timer queue never drained - the addon is rescheduling forever");
end

local function fresh(opts)
    opts = opts or {};

    bags         = opts.bags or {};
    cursor       = nil;
    allow_delete = (opts.allow_delete ~= false);
    timers       = {};
    messages     = {};
    frames       = {};
    in_combat    = false;
    AutoDestroyDB = nil;

    if opts.no_c_container then C_Container = nil; end

    local ns = {};
    local chunk = assert(loadfile("AutoDestroy/AutoDestroy.lua"));
    chunk("AutoDestroy", ns);

    for id in pairs(opts.destroy or {}) do
        ns.db().items[id] = item_db[id].name;
    end

    return ns;
end

local function bag_ids(bag)
    local out = {};
    for _, entry in ipairs(bags[bag] or {}) do out[#out + 1] = entry.id; end
    return out;
end

local function said(pattern)
    for _, msg in ipairs(messages) do
        if msg:find(pattern, 1, true) then return true; end
    end
    return false;
end

local checks = 0;

-- Deliberately quiet on success: `messages` holds only the addon's own chat
-- output, so said() can be trusted.
local function check(condition, label)
    checks = checks + 1;
    if not condition then
        error("FAILED: " .. label, 2);
    end
end

local function report(name)
    io.write(("%-58s %d checks\n"):format(name, checks));
    checks = 0;
end

-- ---------------------------------------------------------------- 1. no match

do
    local ns = fresh({
        bags = { [0] = { { id = 2589 }, { id = 4306 } } },
        destroy = {},
    });

    ns.scan();
    run_timers();

    check(#bag_ids(0) == 2, "an empty list leaves every item alone");
    check(cursor == nil, "the cursor is left empty");
    report("no items listed");
end

-- ------------------------------------------------------- 2. automatic destroy

do
    local ns = fresh({
        bags = { [0] = { { id = 2589 }, { id = 4306, count = 5 } } },
        destroy = { [4306] = true },
    });

    ns.scan();
    run_timers();

    local left = bag_ids(0);
    check(#left == 1 and left[1] == 2589, "the listed item is destroyed, the other one is kept");
    check(cursor == nil, "the cursor is empty afterwards");
    check(said("destroyed"), "the destroy is announced in chat");
    report("automatic destroy (client allows it)");
end

-- ------------------------------------------- 3. refusal falls back to a prompt

do
    local ns = fresh({
        bags = { [0] = { { id = 4306 } } },
        destroy = { [4306] = true },
        allow_delete = false,
    });

    ns.scan();
    run_timers();

    check(#bag_ids(0) == 1, "a refused delete leaves the item in the bag");
    check(cursor == nil, "the stack is handed back rather than left on the cursor");
    check(frames["AutoDestroyPrompt"] and frames["AutoDestroyPrompt"].shown,
          "the prompt is shown instead");
    check(said("key press or click"), "the player is told why");

    -- The click is the hardware event, so the delete goes through this time.
    allow_delete = true;
    frames["AutoDestroyButton"].scripts.OnClick();
    run_timers();

    check(#bag_ids(0) == 0, "clicking the prompt destroys the item");
    check(cursor == nil, "and leaves the cursor empty");
    check(not frames["AutoDestroyPrompt"].shown, "the prompt hides once the bag is clean");
    report("hardware event required (live client behaviour)");
end

-- --------------------------------------------------------------- 4. locked slot

do
    local ns = fresh({
        bags = { [0] = { { id = 4306, locked = true } } },
        destroy = { [4306] = true },
    });

    ns.scan();
    check(#bag_ids(0) == 1, "a locked slot is not touched");

    bags[0][1].locked = false;
    run_timers();

    check(#bag_ids(0) == 0, "and is destroyed once the slot unlocks");
    report("locked slot");
end

-- --------------------------------------------------------------- 5. busy cursor

do
    local ns = fresh({
        bags = { [0] = { { id = 4306 } } },
        destroy = { [4306] = true },
    });

    cursor = { id = 99999, link = "something the player picked up" };
    ns.scan();

    check(cursor ~= nil and cursor.id == 99999, "the player's cursor is not stolen");
    check(#bag_ids(0) == 1, "and nothing is destroyed while it is busy");

    cursor = nil;
    run_timers();

    check(#bag_ids(0) == 0, "the item is destroyed once the cursor frees up");
    report("cursor already in use");
end

-- ------------------------------------------------------------ 6. quality guard

do
    local ns = fresh({ bags = {}, destroy = {} });

    ns.handle_command("add 18422");
    check(next(ns.db().items) == nil, "an epic item is not listed without confirmation");
    check(said("force"), "the player is told how to confirm");

    ns.handle_command("add 18422 force");
    check(ns.db().items[18422] ~= nil, "'force' adds it");

    ns.handle_command("add 4306");
    check(ns.db().items[4306] ~= nil, "an ordinary item needs no confirmation");

    ns.handle_command("remove 4306");
    check(ns.db().items[4306] == nil, "remove takes it off the list again");
    report("quality guard on add");
end

-- --------------------------------------------------- 7. cursor identity check

local real_pickup = C_Container.PickupContainerItem;

-- The addon resolves the container API once, at load, so these overrides have
-- to be in place before fresh() loads it.
do
    -- The slot moved between the scan and the pickup, so the cursor comes back
    -- holding a different item than the one we meant to destroy.
    C_Container.PickupContainerItem = function(bag) real_pickup(bag, 2); end;

    local ns = fresh({
        bags = { [0] = { { id = 4306 }, { id = 2589 } } },
        destroy = { [4306] = true },
    });

    local ok, reason = ns.destroy_slot(0, 1, 4306);

    check(ok == false and reason == "cursor", "a mismatched cursor aborts the delete");
    check(#bag_ids(0) == 2, "nothing is destroyed");
    check(cursor == nil, "and the cursor is released again");

    -- A scan must not quietly destroy the wrong item either.
    ns.scan();
    run_timers();
    check(#bag_ids(0) == 2, "a full scan cannot destroy the wrong item either");
end

do
    -- The pickup silently did nothing at all.
    C_Container.PickupContainerItem = function() end;

    local ns = fresh({
        bags = { [0] = { { id = 4306 } } },
        destroy = { [4306] = true },
    });

    local ok, reason = ns.destroy_slot(0, 1, 4306);

    check(ok == false and reason == "cursor", "an empty cursor aborts the delete too");
    check(#bag_ids(0) == 1, "and still nothing is destroyed");

    C_Container.PickupContainerItem = real_pickup;
    report("cursor identity is confirmed before deleting");
end

-- ------------------------------------------------------------ 8. API shapes

do
    local ns = fresh({
        bags = { [0] = { { id = 4306, count = 3 } } },
        destroy = { [4306] = true },
    });

    local id, link, locked, quality, count = ns.read_slot(0, 1);
    check(id == 4306 and count == 3 and locked == false and quality == 1 and link:find("Silk Cloth", 1, true),
          "the modern table return is understood");

    check(ns.item_id_from("4306") == 4306, "a numeric id is accepted");
    check(ns.item_id_from(link_for(4306)) == 4306, "an item link is accepted");
    check(ns.item_id_from("Silk Cloth") == 4306, "a cached item name is accepted");
    check(ns.item_id_from("nonsense") == nil, "junk input is rejected");
end

do
    -- Reload against the pre-C_Container flat API.
    local saved = C_Container;

    GetContainerNumSlots    = saved.GetContainerNumSlots;
    GetContainerItemInfo    = function(bag, slot)
        local info = saved.GetContainerItemInfo(bag, slot);
        if not info then return nil; end
        -- icon, count, locked, quality, readable, lootable, link, filtered, noValue, id
        return "icon", info.stackCount, info.isLocked, info.quality, false, false,
               info.hyperlink, false, false, info.itemID;
    end;
    PickupContainerItem     = saved.PickupContainerItem;

    local ns = fresh({
        bags = { [0] = { { id = 4306, count = 3 } } },
        destroy = { [4306] = true },
        no_c_container = true,
    });

    local id, link, locked, quality, count = ns.read_slot(0, 1);
    check(id == 4306 and count == 3 and locked == false and quality == 1 and link:find("Silk Cloth", 1, true),
          "the old flat return is understood");

    ns.scan();
    run_timers();
    check(#bag_ids(0) == 0, "and the item is destroyed through the flat API too");

    C_Container = saved;
    report("both GetContainerItemInfo shapes");
end

io.write("\nAuto Destroy harness passed.\n");
