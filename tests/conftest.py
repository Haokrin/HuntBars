"""
Pytest configuration and fixtures for rotation calculator tests.
"""

import sys
import pytest
from pathlib import Path

# Add parent directory to path so we can import rotation_calculator
sys.path.insert(0, str(Path(__file__).parent.parent))

from rotation_calculator import (
    RotationCalculator,
    PlayerStats,
    HasteConfig,
    RotationMode,
)


@pytest.fixture
def default_player():
    """Standard player with baseline stats."""
    return PlayerStats(
        level=70,
        ranged_base_speed=2.0,
        ranged_dps=100.0,
        quiver_haste=0.15,
        serpent_swiftness=1.0,
        ranged_haste_rating=0,
        melee_haste_rating=0,
        latency=0.05,
    )


@pytest.fixture
def haste_heavy_player():
    """Player with significant haste rating gear."""
    return PlayerStats(
        level=70,
        ranged_base_speed=2.0,
        ranged_dps=100.0,
        quiver_haste=0.15,
        serpent_swiftness=1.0,
        ranged_haste_rating=300,  # ~30% haste rating
        melee_haste_rating=300,
        latency=0.05,
    )


@pytest.fixture
def low_haste_player():
    """Player with minimal haste, using slow weapons."""
    return PlayerStats(
        level=70,
        ranged_base_speed=3.0,  # Slow weapon
        ranged_dps=120.0,
        quiver_haste=0.0,  # No quiver
        serpent_swiftness=1.0,
        ranged_haste_rating=0,
        melee_haste_rating=0,
        latency=0.05,
    )


@pytest.fixture
def fast_weapon_player():
    """Player using fast-attack stat stacking."""
    return PlayerStats(
        level=70,
        ranged_base_speed=1.5,  # Fast weapon
        ranged_dps=80.0,
        quiver_haste=0.20,
        serpent_swiftness=1.0,
        ranged_haste_rating=400,
        melee_haste_rating=400,
        latency=0.05,
    )


@pytest.fixture
def no_buffs():
    """Empty haste configuration (no buffs)."""
    return HasteConfig(current_time=0.0)


@pytest.fixture
def pve_raid_buffs():
    """Typical raid buff combination (Bloodlust + drums + shaman auras)."""
    config = HasteConfig(current_time=0.0)
    config.add_buff("bloodlust")
    config.add_buff("drums")
    return config


@pytest.fixture
def raid_buffs_with_trinket():
    """Raid buffs plus high-end haste trinket proc."""
    config = HasteConfig(current_time=0.0)
    config.add_buff("bloodlust")
    config.add_buff("drums")
    config.add_buff("dragonspine")
    return config


@pytest.fixture
def rapid_fire_only():
    """Just Rapid Fire (common solo buff)."""
    config = HasteConfig(current_time=0.0)
    config.add_buff("rapid_fire")
    return config


@pytest.fixture
def all_haste_buffs():
    """Every haste buff at once (stress test)."""
    config = HasteConfig(current_time=0.0)
    for buff_key in [
        "rapid_fire",
        "bloodlust",
        "berserking",
        "haste_potion",
        "abacus",
        "dragonspine",
        "crowd_pummeler",
        "jackhammer",
        "hammer_haste",
        "drums",
    ]:
        config.add_buff(buff_key)
    return config


@pytest.fixture
def calculator():
    """Default rotation calculator."""
    return RotationCalculator()


@pytest.fixture
def calculator_custom(default_player):
    """Rotation calculator with custom player stats."""
    return RotationCalculator(player_stats=default_player)
