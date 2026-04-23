#!/usr/bin/env python3
"""
Example: Interactive rotation calculator for testing haste combinations.

Run this to quickly test rotation mode detection with different buff combos
without needing to be in-game or have haste buffs active.
"""

from rotation_calculator import (
    RotationCalculator,
    PlayerStats,
    HasteConfig,
)


def print_result(config_name, result):
    """Pretty-print rotation calculation result."""
    print(f"\n{config_name:40} | eWS: {result['eWS']:.2f}s | Mode: {result['rotation_mode'].value:12}")


def test_raid_progression():
    """Test rotation modes through raid progression (slow to fast gear)."""
    print("\n" + "="*90)
    print("RAID PROGRESSION TEST - Gear progression from T1 to T5+")
    print("="*90)

    progression = [
        ("T1 Gear (1-2 haste rating)", PlayerStats(
            ranged_base_speed=2.2, ranged_haste_rating=0
        )),
        ("T2 Gear (50 haste rating)", PlayerStats(
            ranged_base_speed=2.1, ranged_haste_rating=50
        )),
        ("T3 Gear (150 haste rating)", PlayerStats(
            ranged_base_speed=2.0, ranged_haste_rating=150
        )),
        ("T4 Gear (300 haste rating)", PlayerStats(
            ranged_base_speed=1.9, ranged_haste_rating=300
        )),
        ("T5+ Gear (500+ haste rating)", PlayerStats(
            ranged_base_speed=1.8, ranged_haste_rating=500
        )),
    ]

    # Test each gear tier with different buff levels
    print(f"\n{'Gear':25} | {'No Buffs':35} | {'Bloodlust+Drums':35} | {'Extreme':35}")
    print("-" * 130)

    for gear_name, player in progression:
        calc = RotationCalculator(player)

        # No buffs
        no_buff_result = calc.calculate(HasteConfig(current_time=0.0))

        # Raid buffs
        raid_config = HasteConfig(current_time=0.0)
        raid_config.add_buff("bloodlust")
        raid_config.add_buff("drums")
        raid_result = calc.calculate(raid_config)

        # Extreme buffs
        extreme_config = HasteConfig(current_time=0.0)
        for buff in ["rapid_fire", "bloodlust", "berserking", "dragonspine", "crowd_pummeler"]:
            extreme_config.add_buff(buff)
        extreme_result = calc.calculate(extreme_config)

        print(
            f"{gear_name:25} | "
            f"eWS {no_buff_result['eWS']:5.2f}s ({no_buff_result['rotation_mode'].value:12}) | "
            f"eWS {raid_result['eWS']:5.2f}s ({raid_result['rotation_mode'].value:12}) | "
            f"eWS {extreme_result['eWS']:5.2f}s ({extreme_result['rotation_mode'].value:12})"
        )


def test_haste_stacking():
    """Test how different haste buffs stack together."""
    print("\n" + "="*90)
    print("HASTE STACKING TEST - Adding buffs one at a time")
    print("="*90)

    player = PlayerStats(
        ranged_base_speed=2.0,
        ranged_haste_rating=100,
        quiver_haste=0.15,
    )
    calc = RotationCalculator(player)

    buffs_to_test = [
        ("No buffs", []),
        ("Rapid Fire", ["rapid_fire"]),
        ("RF + Bloodlust", ["rapid_fire", "bloodlust"]),
        ("RF + BL + Berserking", ["rapid_fire", "bloodlust", "berserking"]),
        ("RF + BL + Zerking + DST", ["rapid_fire", "bloodlust", "berserking", "dragonspine"]),
        ("All haste buffs", ["rapid_fire", "bloodlust", "berserking", "dragonspine",
                             "crowd_pummeler", "jackhammer", "haste_potion", "drums"]),
    ]

    print(f"\n{'Buff Combination':35} | {'eWS':8} | {'Rotation Mode':12} | {'Haste Mod':8}")
    print("-" * 75)

    for name, buffs in buffs_to_test:
        config = HasteConfig(current_time=0.0)
        for buff in buffs:
            config.add_buff(buff)

        result = calc.calculate(config)
        print(
            f"{name:35} | "
            f"{result['eWS']:7.2f}s | "
            f"{result['rotation_mode'].value:12} | "
            f"{result['haste_mod_ranged']:7.3f}x"
        )


def test_player_archetypes():
    """Test different player archetypes with typical rotations."""
    print("\n" + "="*90)
    print("PLAYER ARCHETYPE TEST - Different gear/playstyle combinations")
    print("="*90)

    archetypes = [
        ("Slow Steady (French rotation)", PlayerStats(
            ranged_base_speed=3.0,
            ranged_haste_rating=0,
            quiver_haste=0.0,
        )),
        ("Balanced (Skipping/1:1)", PlayerStats(
            ranged_base_speed=2.0,
            ranged_haste_rating=150,
            quiver_haste=0.15,
        )),
        ("Haste Stacker (1:2 or faster)", PlayerStats(
            ranged_base_speed=1.6,
            ranged_haste_rating=400,
            quiver_haste=0.20,
        )),
        ("Extreme Speedster (1:3)", PlayerStats(
            ranged_base_speed=1.3,
            ranged_haste_rating=600,
            quiver_haste=0.25,
        )),
    ]

    print(f"\n{'Archetype':30} | {'Base Speed':11} | {'No Buffs':30} | {'With BL':30}")
    print("-" * 110)

    for archetype_name, player in archetypes:
        calc = RotationCalculator(player)

        # No buffs
        no_buff_result = calc.calculate(HasteConfig(current_time=0.0))

        # Bloodlust
        bl_config = HasteConfig(current_time=0.0)
        bl_config.add_buff("bloodlust")
        bl_result = calc.calculate(bl_config)

        print(
            f"{archetype_name:30} | "
            f"{player.ranged_base_speed:6.2f}s ({player.ranged_haste_rating:3}HR) | "
            f"eWS {no_buff_result['eWS']:5.2f}s ({no_buff_result['rotation_mode'].value:12}) | "
            f"eWS {bl_result['eWS']:5.2f}s ({bl_result['rotation_mode'].value:12})"
        )


def test_trinket_procs():
    """Test how different haste trinket procs affect rotation."""
    print("\n" + "="*90)
    print("TRINKET PROC TEST - Different high-end haste trinkets")
    print("="*90)

    player = PlayerStats(
        ranged_base_speed=2.0,
        ranged_haste_rating=200,
    )
    calc = RotationCalculator(player)

    trinkets = [
        ("No trinket + BL+Drums", ["bloodlust", "drums"]),
        ("Dragonspine Trophy proc", ["bloodlust", "drums", "dragonspine"]),
        ("Abacus of Violent Odds", ["bloodlust", "drums", "abacus"]),
        ("Crowd Pummeler", ["bloodlust", "drums", "crowd_pummeler"]),
        ("Jackhammer", ["bloodlust", "drums", "jackhammer"]),
    ]

    print(f"\n{'Trinket + Raid Buffs':35} | {'eWS':8} | {'Mode':12} | {'Haste Mod':8}")
    print("-" * 75)

    for name, buffs in trinkets:
        config = HasteConfig(current_time=0.0)
        for buff in buffs:
            config.add_buff(buff)

        result = calc.calculate(config)
        print(
            f"{name:35} | "
            f"{result['eWS']:7.2f}s | "
            f"{result['rotation_mode'].value:12} | "
            f"{result['haste_mod_ranged']:7.3f}x"
        )


def main():
    """Run all example tests."""
    print("\n" + "#"*90)
    print("# FLUFFY HUNTER BARS - ROTATION CALCULATOR EXAMPLES")
    print("#"*90)
    print("\nThese examples show how to test rotation modes with different haste combinations")
    print("without being in-game or needing actual haste buffs.")

    test_raid_progression()
    test_haste_stacking()
    test_player_archetypes()
    test_trinket_procs()

    print("\n" + "#"*90)
    print("# Run 'pytest tests/ -v' for comprehensive test suite with 44 test cases")
    print("#"*90 + "\n")


if __name__ == "__main__":
    main()
