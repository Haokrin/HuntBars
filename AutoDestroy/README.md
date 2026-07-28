# Auto Destroy

Watches your bags and destroys items you have put on a list, as soon as they land there. Built for the WoW Classic Anniversary realms (1.15.x client).

## Why this is an addon and not a WeakAura

A WeakAura cannot do this. Destroying an item comes down to `DeleteCursorItem()`, and that call is blocked twice over:

1. **Blizzard** made `DeleteCursorItem()` require a hardware event in patch 9.0.2, then protected it against macro scripts in 9.1.5 and limited it to one item per hardware event. Nothing can call it purely from a timer or an event handler any more.
2. **WeakAuras** blocks the function outright inside custom code. It sits in the `blockedFunctions` table in `WeakAuras/AuraEnvironment.lua`; reading it from an aura hands back an empty stub and flags the aura with *"Forbidden function or table: DeleteCursorItem"*. This is deliberate, so that a downloaded aura cannot quietly delete your bags.

So no import string can be made to work, no matter how the aura is written. What *is* unrestricted is everything up to the delete: watching the bags, matching the item, and picking the stack up. That is what this addon automates, which leaves at most one key press per stack.

## How it behaves

On every bag update the addon looks for a listed item and then tries the direct `DeleteCursorItem()` call first. What happens next depends on your client:

- **If the client allows it** — the item is destroyed on its own, with no input from you at all. Nothing else to do.
- **If the client refuses it** (what a live 1.15 client does) — the stack is handed straight back to the bag, and a small movable prompt appears instead. Clicking it, or pressing the key you bound to it, destroys the item; a real click or key press is exactly the hardware event Blizzard is asking for. One press per stack.

The addon probes this once per session and remembers the answer, so it does not keep poking at a call the client will not honour.

## Installation

1. Copy the `AutoDestroy` folder into your `Interface/AddOns/` folder.
2. Make sure the folder is named `AutoDestroy` and contains `AutoDestroy.toc`.
3. Restart WoW or type `/reload`.

If the addon shows up greyed out, tick **Load out of date AddOns** in the character-select addon list, or bump the `## Interface:` number in `AutoDestroy.toc` to match your client.

## Usage

Add an item by shift-clicking it into the chat box after the command:

```
/autodestroy add [Silk Cloth]
```

| Command | Description |
|---------|-------------|
| `/autodestroy add <link or id>` | Destroy this item on sight |
| `/autodestroy remove <link or id>` | Stop destroying it |
| `/autodestroy list` | Show everything on the list |
| `/autodestroy on` / `off` | Enable or disable the addon |
| `/autodestroy dry` | Dry run — only report what *would* be destroyed |
| `/autodestroy quiet` | Toggle the chat message on each destroy |
| `/autodestroy key <KEY>` | Bind a key to the destroy button, e.g. `key SHIFT-D`. Run it with no key to unbind |

`/adestroy` works as a shorter alias. The list is saved account-wide.

Items can be added by item link, numeric item ID, or plain name if your client has the item cached. Links and IDs are the reliable options — a name only resolves once the client has seen the item.

## Safety

Destroying an item cannot be undone in-game, so the addon is deliberately conservative:

- Only items you explicitly added are ever touched. There is no "destroy all greys" mode.
- Adding an item of **rare quality or better** is refused unless you repeat the command with `force` on the end. That is the guard against a mistyped item ID.
- The stack on the cursor is confirmed to be the item you meant before anything is deleted, so a bag slot that shifts underneath the scan cannot make it destroy the wrong thing.
- Your cursor is never taken away from you. If you are already holding something, the addon waits.
- Locked slots — ones with a server operation still in flight — are left alone until they settle.
- Only your normal bags are scanned. Bank, keyring and equipped items are never touched.

Try `/autodestroy dry` first if you want to watch what it would do before letting it do it.

## Tests

The logic runs offline against a stubbed bag and cursor:

```
lua5.1 tests/auto_destroy_harness.lua
```

It covers the automatic path, the hardware-event fallback and the click that resolves it, locked slots, a busy cursor, the quality guard, the cursor identity check, and both shapes of `GetContainerItemInfo()`. It runs in CI on every push.

## If you would rather have the WeakAura

There is a middle road, if you already run WeakAuras and want the prompt to live there: the [DeleteCursorItemFix](https://www.curseforge.com/wow/addons/deletecursoritemfix) addon exposes a clickable button that calls `DeleteCursorItem()` once per hardware event, and an aura can pick the item up and then tell you to press the key bound to `/click DelItem`. It needs the same one key press per item, and it needs that addon installed anyway — which is why this addon does the whole job by itself instead.
