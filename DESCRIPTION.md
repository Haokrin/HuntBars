# Fluffy Hunter Bars (FluffyHunterCastBar)

## Overview

Fluffy Hunter Bars is a World of Warcraft (TBC Classic, Interface 20504) addon designed specifically for **Hunter** players. It provides real-time visual cast bar recommendations that tell the player exactly when to use each ability in order to maximize single-target DPS, based on best-practice rotation theory from the hunter community and the [Rotation Tools](https://diziet559.github.io/rotationtools/) resource.

## What It Does

### Shot Rotation Advisor
The addon continuously analyzes the player's current game state — including auto shot timing, ability cooldowns, haste buffs, latency, and equipped gear — and displays colored recommendation bars showing optimal windows to fire each ability:

- **Auto Shot** (red) — Tracks your ranged auto shot swing timer and displays upcoming auto shot fire times as spark indicators on the bar.
- **Steady Shot** (orange) — Shows when to weave Steady Shot between auto shots without clipping. When Multi-Shot is off cooldown the window takes Multi-Shot's color instead: press Multi-Shot there in place of the Steady (per Rotation Tools, a Multi-Shot should replace a Steady whenever it is off cooldown — its shorter cast always fits inside a steady window).
- **Multi-Shot** (blue) — Shows extra windows where a Multi-Shot fits *around* the Steady Shot weave: its cast finishes before the incoming auto shot and its global cooldown cannot push the next Steady Shot past its deadline.
- **Arcane Shot** (purple) — Shows windows where neither a Steady Shot nor a Multi-Shot fits. A press may never *cost* a Steady Shot, but at slow (French-band) speeds it may *delay* the next Steady by up to the gap's idle GCD time — the Rotation Tools French rotation (5:5:1:1) explicitly accepts these micro auto delays to fit its extra Multi/Arcane in. At 1:1 speeds, where any Arcane press would replace a Steady outright, the window correctly stays empty.
- **Raptor Strike** (green) — Shows when Raptor Strike is available while a melee weapon is equipped and melee recommendations are enabled. (The addon does not check melee range; it shows the timing windows.)
- **Melee Auto Attack** (grey) — Tracks melee swing timer when a melee weapon is equipped.

Melee windows are **weave-aware**: per Rotation Tools, ranged damage has priority over weaving, so the addon removes the region before each predicted auto shot (aim start minus weave time minus latency) from every melee window — a recommended weave can never clip an auto shot. The weave allowance is 0.4 s ("even slow weavers will manage to stay below 0.4 seconds").

### Rotation Mode Detection
The addon automatically detects your current rotation mode based on your effective weapon speed (eWS). The bands are read from the best-rotation crossings in the Rotation Tools DPS-over-haste graphs:

| Effective Weapon Speed | Rotation Mode | Typical haste state (BM) |
|------------------------|---------------|--------------------------|
| >= 2.4s (no Serpent's Swiftness) | Short French (5:4:1:1) | SV base |
| >= 1.95s | French (5:5:1:1) | BM base / SV with Hawk proc |
| 1.65 - 1.95s | Long French (5:6:1:1) | Hawk proc |
| 1.45 - 1.65s | 1:1 | Rapid Fire or Bloodlust |
| 1.05 - 1.45s | Skipping (5:9:1:1) | RF + Hawk, RF + Bloodlust |
| 0.85 - 1.05s | 2:3 | RF + Hawk + Bloodlust |
| 0.70 - 0.85s | 1:2 | RF + Bloodlust + Haste Potion |
| 0.62 - 0.70s | 2:5 | RF + (Hawk or DST) + Bloodlust + Pot |
| < 0.62s | 1:3 | full stacking |

### Haste Buff Tracking
Dynamically tracks all relevant haste effects and adjusts recommendations in real time:
- Rapid Fire, Quick Shots (Improved Aspect of the Hawk)
- Bloodlust / Heroism
- Berserking (Troll racial, scales with health)
- Haste Potion, Dragonspine Trophy, Abacus of Violent Odds, Drums of Battle
- And more (Crowd Pummeler, Jackhammer, Hammer Haste)

### Latency Compensation
Reads network latency (home/world) every 0.5 seconds (exponentially smoothed) and applies two compensation values: a one-way (RTT/2) offset for window starts, and a full-RTT margin on the safe-press deadline before each incoming auto shot (the press must reach the server AND the displayed timeline is event-arrival anchored, so both halves of the round trip apply). This prevents auto shot clipping on higher-ping connections. One-way is clamped to 25–250ms, RTT to 50–400ms.

### Gear and Talent Awareness
- Scans equipped ranged weapon stats (damage, speed), ammo DPS, and quiver haste bonus.
- Reads talent investments for crit modifiers, damage multipliers, cooldown reductions, and Serpent's Swiftness.
- Automatically recalculates when gear, talents, or known spells change (event-driven, not per-frame).
- Monitors ranged-AP-relevant debuffs on the current target (Hunter's Mark by rank, Expose Weakness), matched by spell ID so non-English clients work.

## Customization

All settings are accessed via the `/fluffy` slash command. Numeric arguments are validated and clamped to sane ranges; invalid input prints the help text instead of being stored.

| Command | Description |
|---------|-------------|
| `/fluffy info` | Print all current settings |
| `/fluffy resize W H` | Set bar width and height in pixels |
| `/fluffy move X Y` | Shift bar position by X/Y pixel offsets |
| `/fluffy show` / `hide` | Toggle bar visibility |
| `/fluffy lock` / `unlock` | Lock/unlock bar dragging (Shift+Click to drag) |
| `/fluffy reset` | Reset all settings to defaults |
| `/fluffy freq N` | Set label refresh rate (N times per second) |
| `/fluffy showicons` | Toggle ability icons on bars |
| `/fluffy icosize L` | Set icon size to L x L pixels |
| `/fluffy color_auto R G B A` | Set Auto Shot bar color (also: `color_steady`, `color_multi`, `color_arcane`, `color_spark`, `color_raptor`, `color_melee`) |
| `/fluffy spark N` | Set auto shot spark indicator width in pixels |
| `/fluffy use_arcane` | Toggle Arcane Shot recommendations |
| `/fluffy use_multi` | Toggle Multi-Shot recommendations |
| `/fluffy use_melee` | Toggle melee ability recommendations |
| `/fluffy rangeonly` | Move Multi-Shot and Arcane Shot to the secondary (lower) row |
| `/fluffy incombat` | Toggle showing bars only during combat |
| `/fluffy length N` | Set how many seconds into the future recommendations are shown (1-10) |
| `/fluffy latency` | Display current measured latency and compensation offset |
| `/fluffy baked_rotation` | Toggle rotation-aware mode (shows only the next ability to cast) |
| `/fluffy show_mode` | Toggle the rotation mode label above the bar |
| `/fluffy baked_melee` | Include melee abilities in baked rotation recommendations |
| `/fluffy debug` | Print measured vs modeled auto shot timings after every shot |
| `/fluffy purgedb` | Clear cached gear/ammo data |

## Technical Details

- **Version:** 2.5.0 (internal version code 250)
- **Author:** Fluffydork of Nethergarde Keep (EU)
- **Interface:** 20504 (TBC Classic)
- **Category:** Combat
- **Curse Project ID:** 470317
- **Saved Variables:** Per-character (`FluffyDBPC`)

### Known Limitations

- Weapon, ammo, and quiver stats are read from tooltip text; on non-English clients the parsing may fail (the addon then leaves the affected values at 0 and retries on the next inventory event rather than erroring).
- Talent bonuses are looked up by English talent names; on non-English clients they default to untrained.

## File Structure

| File | Purpose |
|------|---------|
| `FluffyHunterBars.toc` | Addon manifest (load order, metadata) |
| `preamble.debug.lua` | Debug print helper (`/fluffy debug`) |
| `preamble.variables.lua` | Namespace variable declarations, spell IDs, haste buff tables, UI constants |
| `preamble.auxiliary.lua` | Helper/utility functions and saved-variable initialization |
| `player.stats.lua` | Tracks player AP and target debuffs (Hunter's Mark, Expose Weakness) |
| `abilities.lua` | Ability definitions (cooldowns, cast times, damage formulas) and combat-log event handling |
| `recommendation_calculation.lua` | Core rotation optimizer — computes optimal ability windows |
| `talent_handler.lua` | Reads talent tree and applies modifiers |
| `ammo_handler.lua` | Tracks ammo type and DPS, quiver haste |
| `equipment_handler.lua` | Tracks equipped weapons |
| `ui.elems.lua` | UI element creation (bars, sparks, labels) |
| `ui.layout.lua` | Size/position/visibility management |
| `ui.render.lua` | Per-frame bar and spark rendering |
| `ui.labels.lua` | Rotation mode / eWS / latency label updates |
| `ui.core.lua` | UI update loop and drag handling |
| `core.lua` | Addon initialization, slash command handler, event registration |
| `tests/` | Offline Lua 5.1 harnesses for the timing model and rotation priorities |
