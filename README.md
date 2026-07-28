# Fluffy Hunter Bars

A World of Warcraft (TBC Classic) addon for **Hunters** that displays real-time cast bar recommendations to maximize single-target DPS. Built on rotation best practices from the hunter community and [Rotation Tools](https://diziet559.github.io/rotationtools/).

## Features

- **Shot Rotation Bars** — Color-coded bars show when to cast Steady Shot, Multi-Shot, Arcane Shot, and Raptor Strike relative to your auto shot timer, preventing clipping and maximizing DPS.
- **Automatic Rotation Detection** — Detects your current rotation mode (French, 1:1, Skipping, 2:3, etc.) based on your effective weapon speed and adjusts recommendations accordingly.
- **Haste Buff Tracking** — Dynamically accounts for Rapid Fire, Bloodlust/Heroism, Berserking, haste potions, trinket procs (DST, Abacus), and Drums of Battle.
- **Latency Compensation** — Measures network latency and offsets recommendations to prevent auto shot clipping on higher-ping connections.
- **Weave-Safe Melee Windows** — Melee recommendations are clipped around incoming auto shots so a weave never costs ranged damage.
- **Gear & Talent Aware** — Reads your equipped ranged weapon, ammo, quiver, and talent build to produce accurate damage and timing calculations.
- **Fully Customizable UI** — Resize, reposition, recolor, toggle icons, lock/unlock dragging, and show bars only in combat — all via `/fluffy` commands.

## Installation

1. Download and extract into your `Interface/AddOns/` folder.
2. Ensure the folder is named `FluffyHunterBars`.
3. Restart WoW or type `/reload` to load the addon.

## Usage

Type `/fluffy` in chat to see all available commands. Key commands:

| Command | Description |
|---------|-------------|
| `/fluffy info` | Show all current settings |
| `/fluffy resize W H` | Set bar size (pixels) |
| `/fluffy move X Y` | Offset bar position |
| `/fluffy show` / `hide` | Toggle visibility |
| `/fluffy lock` / `unlock` | Lock/unlock bar dragging |
| `/fluffy reset` | Reset to defaults |
| `/fluffy latency` | Show latency info and current rotation mode |
| `/fluffy use_arcane` | Toggle Arcane Shot recommendations |
| `/fluffy use_multi` | Toggle Multi-Shot recommendations |
| `/fluffy use_melee` | Toggle melee recommendations |
| `/fluffy incombat` | Show bars only in combat |
| `/fluffy length N` | Set recommendation window length (seconds) |

Use **Shift+Click** to drag the bars when unlocked.

See [DESCRIPTION.md](DESCRIPTION.md) for a full detailed breakdown of the addon's internals, file structure, and all configuration options.

## Rotation Modes

The rotation label above the bar is derived from your effective weapon speed (eWS), with bands taken from the DPS-over-haste graphs on [Rotation Tools](https://diziet559.github.io/rotationtools/):

| Effective Weapon Speed | Rotation Mode |
|------------------------|---------------|
| >= 2.4s (no Serpent's Swiftness) | Short French (5:4:1:1) |
| >= 1.95s | French (5:5:1:1) |
| 1.65 - 1.95s | Long French (5:6:1:1) |
| 1.45 - 1.65s | 1:1 |
| 1.05 - 1.45s | Skipping (5:9:1:1) |
| 0.85 - 1.05s | 2:3 |
| 0.70 - 0.85s | 1:2 |
| 0.62 - 0.70s | 2:5 |
| < 0.62s | 1:3 |

## Development

Offline test harnesses (plain Lua 5.1, no WoW client needed) verify the timing model and rotation priorities:

```
lua5.1 tests/timing_harness.lua
lua5.1 tests/rotation_priority_harness.lua
lua5.1 tests/auto_destroy_harness.lua
luacheck .
```

The same checks run in CI on every push and pull request.

## Also in this repository

[`AutoDestroy/`](AutoDestroy/) is a separate, standalone addon for Classic Anniversary that destroys items you have marked as junk as soon as they land in your bags. It is not loaded by Fluffy Hunter Bars and is installed on its own — see [AutoDestroy/README.md](AutoDestroy/README.md).

## Details

- **Version:** 2.5.0
- **Interface:** 20504 (TBC Classic)
- **Author:** Fluffydork of Nethergarde Keep (EU)
- **Category:** Combat
- **Curse Project ID:** 470317

## Credits

Rotation theory and DPS calculations based on work from the hunter community and [diziet559's Rotation Tools](https://diziet559.github.io/rotationtools/).
