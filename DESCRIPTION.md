# Fluffy Hunter Bars (FluffyHunterCastBar)

## Overview

Fluffy Hunter Bars is a World of Warcraft (TBC / WotLK Classic, Interface 20504) addon designed specifically for **Hunter** players. It provides real-time visual cast bar recommendations that tell the player exactly when to use each ability in order to maximize single-target DPS, based on best-practice rotation theory from the hunter community and the [Rotation Tools](https://diziet559.github.io/rotationtools/) resource.

## What It Does

### Shot Rotation Advisor
The addon continuously analyzes the player's current game state — including auto shot timing, ability cooldowns, haste buffs, latency, and equipped gear — and displays colored recommendation bars showing optimal windows to fire each ability:

- **Auto Shot** (red) — Tracks your ranged auto shot swing timer and displays upcoming auto shot fire times as spark indicators on the bar.
- **Steady Shot** (orange) — Shows when to weave Steady Shot between auto shots without clipping.
- **Multi-Shot** (blue) — Indicates optimal Multi-Shot windows, prioritized above Steady Shot.
- **Arcane Shot** (purple) — Indicates optimal Arcane Shot windows, also prioritized above Steady Shot.
- **Raptor Strike** (green) — Shows Raptor Strike availability when in melee range.
- **Melee Auto Attack** (grey) — Tracks melee swing timer when a melee weapon is equipped.

### Rotation Mode Detection
The addon automatically detects your current rotation mode based on your effective weapon speed (eWS), supporting all standard hunter rotations:

| Effective Weapon Speed | Rotation Mode |
|------------------------|---------------|
| >= 2.5s | French (5:5:1:1) |
| 1.7 - 2.5s | Long French (5:6:1:1) |
| 1.5 - 1.7s | Skipping (5:9:1:1) |
| 1.3 - 1.5s | 1:1 |
| 0.94 - 1.3s | 2:3 |
| 0.75 - 0.94s | 1:2 |
| 0.62 - 0.75s | 2:5 |
| < 0.62s | 1:3 |

### Haste Buff Tracking
Dynamically tracks all relevant haste effects and adjusts recommendations in real time:
- Rapid Fire, Quick Shots (Improved Aspect of the Hawk)
- Bloodlust / Heroism
- Berserking (Troll racial, scales with health)
- Haste Potion, Dragonspine Trophy, Abacus of Violent Odds, Drums of Battle
- And more (Crowd Pummeler, Jackhammer, Hammer Haste)

### Latency Compensation
Reads network latency (home/world) every 5 seconds and compensates auto shot timing so recommendations account for server-side cast registration delay. This prevents auto shot clipping on higher-ping connections (common on EU servers). Latency is clamped between 50ms and 500ms.

### Gear and Talent Awareness
- Scans equipped ranged weapon stats (damage, speed), ammo DPS, and quiver haste bonus.
- Reads talent investments for crit modifiers, damage multipliers, cooldown reductions, and Serpent's Swiftness.
- Automatically recalculates when gear or talents change.

### Target Debuff Tracking
Monitors debuffs on the current target that affect the player's damage output.

## Customization

All settings are accessed via the `/fluffy` slash command:

| Command | Description |
|---------|-------------|
| `/fluffy info` | Print all current settings |
| `/fluffy resize W H` | Set bar width and height in pixels |
| `/fluffy move X Y` | Shift bar position by X/Y pixel offsets |
| `/fluffy show` / `hide` | Toggle bar visibility |
| `/fluffy lock` / `unlock` | Lock/unlock bar dragging (Shift+Click to drag) |
| `/fluffy reset` | Reset all settings to defaults |
| `/fluffy freq N` | Set UI refresh rate (N times per second) |
| `/fluffy showicons` | Toggle ability icons on bars |
| `/fluffy icosize L` | Set icon size to L x L pixels |
| `/fluffy color_auto R G B A` | Set Auto Shot bar color (also: `color_steady`, `color_multi`, `color_arcane`, `color_spark`, `color_raptor`, `color_melee`) |
| `/fluffy spark N` | Set auto shot spark indicator width in pixels |
| `/fluffy use_arcane` | Toggle Arcane Shot recommendations |
| `/fluffy use_multi` | Toggle Multi-Shot recommendations |
| `/fluffy use_melee` | Toggle melee ability recommendations |
| `/fluffy incombat` | Toggle showing bars only during combat |
| `/fluffy length N` | Set how many seconds into the future recommendations are shown |
| `/fluffy latency` | Display current measured latency and compensation offset |
| `/fluffy purgedb` | Clear cached gear/ammo data |

## Technical Details

- **Version:** 2.3.0 (internal version code 221)
- **Author:** Fluffydork of Nethergarde Keep (EU)
- **Interface:** 20504 (TBC Classic)
- **Category:** Combat
- **Curse Project ID:** 470317
- **Saved Variables:** Per-character (`FluffyDBPC`)

## File Structure

| File | Purpose |
|------|---------|
| `FluffyHunterBars.toc` | Addon manifest (load order, metadata) |
| `preamble.debug.lua` | Debug utilities |
| `preamble.variables.lua` | Global variable declarations, spell IDs, haste buff tables, UI constants |
| `preamble.auxiliary.lua` | Helper/utility functions |
| `player.stats.lua` | Tracks player stats (agility, AP, hit, crit) over time |
| `player.haste.lua` | Tracks haste buffs and computes effective haste |
| `player.arp.lua` | Tracks armor penetration buffs |
| `player.damage.lua` | Damage calculation logic |
| `abilities.lua` | Ability definitions (cooldowns, cast times, damage formulas) |
| `recommendation_calculation.lua` | Core rotation optimizer — computes optimal ability windows |
| `talent_handler.lua` | Reads talent tree and applies modifiers |
| `ammo_handler.lua` | Tracks ammo type and DPS |
| `equipment_handler.lua` | Tracks equipped weapons and quiver |
| `target.debuffs.lua` | Monitors target debuffs |
| `ui.elems.lua` | UI element creation (bars, sparks, icons) |
| `ui.core.lua` | UI update loop, rendering, drag handling |
| `core.lua` | Addon initialization, slash command handler, event registration |
