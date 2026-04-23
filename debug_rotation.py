#!/usr/bin/env python3
"""
CLI debug tool for hunter rotation calculations.

Test any haste combination instantly from the terminal without editing code.

Usage examples:
  python debug_rotation.py
  python debug_rotation.py --buffs rapid_fire,bloodlust --speed 2.0
  python debug_rotation.py --buffs bloodlust,drums,dragonspine --speed 1.8 --haste-rating 300
  python debug_rotation.py --list-buffs
  python debug_rotation.py --sweep-speed --buffs bloodlust
"""

import argparse
import sys
from rotation_calculator import (
    RotationCalculator,
    PlayerStats,
    HasteConfig,
    HASTE_BUFFS,
    RotationMode,
)

# Colour codes (fall back silently if terminal doesn't support them)
C_RESET  = "\033[0m"
C_BOLD   = "\033[1m"
C_GREEN  = "\033[92m"
C_YELLOW = "\033[93m"
C_CYAN   = "\033[96m"
C_RED    = "\033[91m"
C_DIM    = "\033[2m"

MODE_COLOUR = {
    RotationMode.FRENCH:       C_DIM,
    RotationMode.LONG_FRENCH:  C_DIM,
    RotationMode.SKIPPING:     C_YELLOW,
    RotationMode.ONE_TO_ONE:   C_YELLOW,
    RotationMode.TWO_TO_THREE: C_GREEN,
    RotationMode.ONE_TO_TWO:   C_GREEN,
    RotationMode.TWO_TO_FIVE:  C_CYAN,
    RotationMode.ONE_TO_THREE: C_RED,
}


def colour_mode(mode: RotationMode) -> str:
    c = MODE_COLOUR.get(mode, "")
    return f"{c}{C_BOLD}{mode.value}{C_RESET}"


def print_result(result: dict, label: str = ""):
    eWS  = result["eWS"]
    mode = result["rotation_mode"]
    hr   = result["haste_mod_ranged"]
    hm   = result["haste_mod_melee"]
    bufs = ", ".join(result["active_buffs"]) or "none"

    if label:
        print(f"\n{C_BOLD}{label}{C_RESET}")
    print(f"  eWS            : {C_BOLD}{eWS:.3f}s{C_RESET}")
    print(f"  Rotation mode  : {colour_mode(mode)}")
    print(f"  Haste mod ranged: {hr:.4f}x  ({(1/hr - 1)*100:+.1f}% faster)")
    print(f"  Haste mod melee : {hm:.4f}x  ({(1/hm - 1)*100:+.1f}% faster)")
    print(f"  Active buffs   : {bufs}")


def cmd_calculate(args):
    """Run a single calculation with given parameters."""
    player = PlayerStats(
        ranged_base_speed=args.speed,
        quiver_haste=args.quiver,
        serpent_swiftness=args.serpent_swiftness,
        ranged_haste_rating=args.haste_rating,
        level=args.level,
    )
    calc = RotationCalculator(player)

    config = HasteConfig(current_time=0.0)
    unknown = []
    for buff in args.buffs:
        if not buff:
            continue
        if buff not in HASTE_BUFFS:
            unknown.append(buff)
        else:
            config.add_buff(buff)

    if unknown:
        print(f"{C_RED}Unknown buffs (ignored): {', '.join(unknown)}{C_RESET}")
        print(f"Run with --list-buffs to see valid names.\n")

    label = f"weapon {args.speed:.2f}s  haste-rating {args.haste_rating}  quiver {args.quiver*100:.0f}%"
    result = calc.calculate(config)
    print_result(result, label)


def cmd_list_buffs(_args):
    """Print all available buff keys and their properties."""
    print(f"\n{C_BOLD}Available haste buffs{C_RESET} (use the key with --buffs):\n")
    print(f"  {'Key':25} {'Name':30} {'Value':10} {'Type':8} {'Rating?'}")
    print("  " + "-" * 80)
    for key, buff in sorted(HASTE_BUFFS.items()):
        kind  = "rating" if buff.is_rating else "mult"
        btype = buff.buff_type.name.lower()
        val   = f"{buff.value:.0f}" if buff.is_rating else f"{buff.value:.2f}x"
        print(f"  {key:25} {buff.name:30} {val:10} {btype:8} {kind}")
    print()


def cmd_sweep_speed(args):
    """Show rotation mode across a sweep of weapon base speeds."""
    player_base = PlayerStats(
        quiver_haste=args.quiver,
        serpent_swiftness=args.serpent_swiftness,
        ranged_haste_rating=args.haste_rating,
        level=args.level,
    )

    config = HasteConfig(current_time=0.0)
    for buff in args.buffs:
        if buff and buff in HASTE_BUFFS:
            config.add_buff(buff)

    buffs_label = ", ".join(args.buffs) if any(args.buffs) else "no buffs"
    print(f"\n{C_BOLD}Weapon speed sweep{C_RESET} — buffs: {buffs_label}\n")
    print(f"  {'Base speed':12} {'eWS':10} {'Mode':14} {'Haste mod'}")
    print("  " + "-" * 55)

    speeds = [s / 10 for s in range(10, 36)]  # 1.0 to 3.5 in 0.1 steps
    prev_mode = None
    for spd in speeds:
        player = PlayerStats(
            ranged_base_speed=spd,
            quiver_haste=player_base.quiver_haste,
            serpent_swiftness=player_base.serpent_swiftness,
            ranged_haste_rating=player_base.ranged_haste_rating,
            level=player_base.level,
        )
        calc = RotationCalculator(player)
        result = calc.calculate(config)
        mode = result["rotation_mode"]
        marker = " <-- mode change" if mode != prev_mode and prev_mode is not None else ""
        print(
            f"  {spd:6.1f}s      {result['eWS']:6.3f}s    "
            f"{colour_mode(mode):30}{C_DIM}{marker}{C_RESET}"
        )
        prev_mode = mode
    print()


def cmd_compare(args):
    """Compare no-buffs vs every individual buff for quick sanity check."""
    player = PlayerStats(
        ranged_base_speed=args.speed,
        quiver_haste=args.quiver,
        serpent_swiftness=args.serpent_swiftness,
        ranged_haste_rating=args.haste_rating,
        level=args.level,
    )
    calc = RotationCalculator(player)

    baseline = calc.calculate(HasteConfig(current_time=0.0))
    base_ews = baseline["eWS"]

    print(f"\n{C_BOLD}Per-buff comparison{C_RESET} — weapon {args.speed:.2f}s, haste-rating {args.haste_rating}\n")
    print(f"  {'Buff':25} {'eWS':10} {'Delta':10} {'Mode'}")
    print("  " + "-" * 65)
    print(f"  {'(no buffs)':25} {base_ews:7.3f}s   {'':10} {colour_mode(baseline['rotation_mode'])}")

    for key in sorted(HASTE_BUFFS):
        config = HasteConfig(current_time=0.0)
        config.add_buff(key)
        result = calc.calculate(config)
        delta = result["eWS"] - base_ews
        print(
            f"  {key:25} {result['eWS']:7.3f}s   {delta:+7.3f}s   {colour_mode(result['rotation_mode'])}"
        )
    print()


def main():
    parser = argparse.ArgumentParser(
        prog="debug_rotation",
        description="Hunter rotation calculator — test haste combos without being in-game.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  python debug_rotation.py
  python debug_rotation.py --buffs rapid_fire,bloodlust --speed 2.0
  python debug_rotation.py --buffs bloodlust,drums,dragonspine --speed 1.8 --haste-rating 300
  python debug_rotation.py --list-buffs
  python debug_rotation.py --sweep-speed --buffs bloodlust
  python debug_rotation.py --compare --speed 2.0 --haste-rating 200
        """,
    )

    # Shared player-stat flags
    parser.add_argument("--speed",            type=float, default=2.0,  metavar="S",  help="Weapon base speed in seconds (default: 2.0)")
    parser.add_argument("--quiver",           type=float, default=0.15, metavar="Q",  help="Quiver haste fraction, e.g. 0.15 for 15%% (default: 0.15)")
    parser.add_argument("--haste-rating",     type=int,   default=0,    metavar="HR", help="Ranged haste rating on gear (default: 0)")
    parser.add_argument("--level",            type=int,   default=70,   metavar="L",  help="Player level (default: 70)")
    parser.add_argument("--serpent-swiftness",type=float, default=1.0,  metavar="SS", help="Serpent Swiftness multiplier, e.g. 1.2 for rank 5 (default: 1.0)")
    parser.add_argument("--buffs",            type=lambda s: s.split(","), default=[], metavar="B", help="Comma-separated buff keys, e.g. rapid_fire,bloodlust")

    # Subcommand-style flags
    parser.add_argument("--list-buffs",  action="store_true", help="List all available buff keys and exit")
    parser.add_argument("--sweep-speed", action="store_true", help="Show rotation mode for weapon speeds 1.0–3.5s")
    parser.add_argument("--compare",     action="store_true", help="Compare every buff individually against no-buffs baseline")

    args = parser.parse_args()

    if args.list_buffs:
        cmd_list_buffs(args)
        return

    if args.sweep_speed:
        cmd_sweep_speed(args)
        return

    if args.compare:
        cmd_compare(args)
        return

    # Default: single calculation
    cmd_calculate(args)


if __name__ == "__main__":
    main()
