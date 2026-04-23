"""
Hunter rotation calculator - replicates core Lua logic for testing.

Handles haste buff tracking, effective weapon speed calculation,
rotation mode detection, and ability timing windows.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, Optional


class RotationMode(Enum):
    FRENCH = "French"
    LONG_FRENCH = "LongFrench"
    SKIPPING = "Skipping"
    ONE_TO_ONE = "1:1"
    TWO_TO_THREE = "2:3"
    ONE_TO_TWO = "1:2"
    TWO_TO_FIVE = "2:5"
    ONE_TO_THREE = "1:3"


class HasteBuffType(Enum):
    MELEE = 1
    RANGED = 2
    BOTH = 3


@dataclass
class HasteBuff:
    """Represents a haste buff with its properties."""
    name: str
    value: float
    is_rating: bool  # False = multiplier (e.g., 1.3x), True = rating (e.g., 400)
    buff_type: HasteBuffType
    expiration_time: float = float('inf')  # When buff expires


# Predefined haste buffs
HASTE_BUFFS = {
    "rapid_fire": HasteBuff("Rapid Fire", 1.4, False, HasteBuffType.RANGED),
    "bloodlust": HasteBuff("Bloodlust", 1.3, False, HasteBuffType.BOTH),
    "heroism": HasteBuff("Heroism", 1.3, False, HasteBuffType.BOTH),
    "berserking": HasteBuff("Berserking", 1.1, False, HasteBuffType.BOTH),
    # Quick Shots (Improved Aspect of the Hawk) is a dynamic proc. Values vary
    # based on rank but typically 1.10 (10% haste) is a reasonable middle ground.
    # Customize by changing this value or pass manually via config.
    "quick_shots": HasteBuff("Quick Shots", 1.10, False, HasteBuffType.RANGED),
    "haste_potion": HasteBuff("Haste Potion", 400, True, HasteBuffType.BOTH),
    "abacus": HasteBuff("Abacus of Violent Odds", 260, True, HasteBuffType.BOTH),
    "dragonspine": HasteBuff("Dragonspine Trophy", 325, True, HasteBuffType.BOTH),
    "crowd_pummeler": HasteBuff("Crowd Pummeler", 500, True, HasteBuffType.BOTH),
    "jackhammer": HasteBuff("Jackhammer", 300, True, HasteBuffType.BOTH),
    "hammer_haste": HasteBuff("Hammer Haste", 212, True, HasteBuffType.BOTH),
    "drums": HasteBuff("Drums of Battle", 80, True, HasteBuffType.BOTH),
}

# Hit conversion table (WoW TBC, indexed by player level - 10)
HIT_CONVERSION_TABLE = {
    1: 0.38, 2: 0.38, 3: 0.38, 4: 0.38, 5: 0.38, 6: 0.38, 7: 0.38, 8: 0.38,
    9: 0.38, 10: 0.38, 11: 0.58, 12: 0.77, 13: 0.96, 14: 1.15, 15: 1.35,
    16: 1.54, 17: 1.73, 18: 1.92, 19: 2.12, 20: 2.31, 21: 2.50, 22: 2.69,
    23: 2.88, 24: 3.08, 25: 3.27, 26: 3.46, 27: 3.65, 28: 3.85, 29: 4.04,
    30: 4.23, 31: 4.42, 32: 4.62, 33: 4.81, 34: 5.00, 35: 5.19, 36: 5.38,
    37: 5.58, 38: 5.77, 39: 5.96, 40: 6.15, 41: 6.35, 42: 6.54, 43: 6.73,
    44: 6.92, 45: 7.12, 46: 7.31, 47: 7.50, 48: 7.69, 49: 7.88, 50: 8.08,
    51: 8.27, 52: 8.46, 53: 8.65, 54: 8.85, 55: 9.04, 56: 9.23, 57: 9.42,
    58: 9.62, 59: 9.81, 60: 10.00, 61: 10.38, 62: 10.79, 63: 11.23, 64: 11.71,
    65: 12.24, 66: 12.81, 67: 13.44, 68: 14.14, 69: 14.91, 70: 15.77,
}


@dataclass
class PlayerStats:
    """Player statistics relevant to rotation calculation."""
    level: int = 70
    ranged_base_speed: float = 2.0  # Weapon base speed
    ranged_dps: float = 100.0  # DPS of ranged weapon
    quiver_haste: float = 0.15  # Quiver haste bonus (e.g., 0.15 for 15%)
    serpent_swiftness: float = 1.0  # Serpent Swiftness talent (1.0 = not talented)
    ranged_haste_rating: int = 0  # Ranged haste rating
    melee_haste_rating: int = 0  # Melee haste rating
    latency: float = 0.05  # Network latency in seconds (one-way)


@dataclass
class HasteConfig:
    """Configuration for active haste buffs."""
    active_buffs: Dict[str, HasteBuff] = field(default_factory=dict)
    current_time: float = 0.0

    def add_buff(self, buff_key: str, duration: Optional[float] = None):
        """Add a haste buff. If duration is None, it's permanent."""
        if buff_key not in HASTE_BUFFS:
            raise ValueError(f"Unknown buff: {buff_key}")
        buff = HASTE_BUFFS[buff_key]
        if duration is not None:
            buff = HasteBuff(buff.name, buff.value, buff.is_rating, buff.buff_type,
                            self.current_time + duration)
        else:
            buff = HasteBuff(buff.name, buff.value, buff.is_rating, buff.buff_type)
        self.active_buffs[buff_key] = buff

    def remove_buff(self, buff_key: str):
        """Remove a haste buff."""
        if buff_key in self.active_buffs:
            del self.active_buffs[buff_key]

    def clear_buffs(self):
        """Clear all active buffs."""
        self.active_buffs.clear()


class RotationCalculator:
    """Calculates rotation recommendations based on player state and haste buffs."""

    def __init__(self, player_stats: Optional[PlayerStats] = None):
        self.player_stats = player_stats or PlayerStats()

    def get_haste_mod_ranged(self, haste_config: HasteConfig) -> float:
        """
        Calculate ranged haste modifier from buffs and haste rating.
        Replicates Lua: get_haste_mod_ranged()
        """
        quiver_mult = 1 + self.player_stats.quiver_haste
        haste = 1.0 / quiver_mult / self.player_stats.serpent_swiftness
        haste_rating = 0

        hit_conversion = HIT_CONVERSION_TABLE.get(
            self.player_stats.level, 15.77
        )

        # Process haste buffs
        for buff_key, buff in haste_config.active_buffs.items():
            is_ranged = buff.buff_type in (HasteBuffType.RANGED, HasteBuffType.BOTH)

            if is_ranged and haste_config.current_time < buff.expiration_time:
                if buff.is_rating:
                    haste_rating += buff.value
                else:
                    haste = haste / buff.value

        total_haste_rating = self.player_stats.ranged_haste_rating + haste_rating
        return haste / (1 + 0.01 * total_haste_rating / hit_conversion)

    def get_haste_mod_melee(self, haste_config: HasteConfig) -> float:
        """
        Calculate melee haste modifier from buffs and haste rating.
        Replicates Lua: get_haste_mod_melee()
        """
        haste = 1.0
        haste_rating = 0

        hit_conversion = HIT_CONVERSION_TABLE.get(
            self.player_stats.level, 15.77
        )

        # Process haste buffs
        for buff_key, buff in haste_config.active_buffs.items():
            is_melee = buff.buff_type in (HasteBuffType.MELEE, HasteBuffType.BOTH)

            if is_melee and haste_config.current_time < buff.expiration_time:
                if buff.is_rating:
                    haste_rating += buff.value
                else:
                    haste = haste / buff.value

        total_haste_rating = self.player_stats.melee_haste_rating + haste_rating
        return haste / (1 + 0.01 * total_haste_rating / hit_conversion)

    def get_effective_weapon_speed(self, haste_config: HasteConfig) -> float:
        """
        Calculate effective weapon speed (eWS).
        eWS = base_speed * haste_mod
        """
        haste_mod = self.get_haste_mod_ranged(haste_config)
        return self.player_stats.ranged_base_speed * haste_mod

    def detect_rotation_mode(self, eWS: float) -> RotationMode:
        """
        Detect rotation mode based on effective weapon speed.
        Thresholds from diziet559.github.io/rotationtools
        """
        if eWS >= 2.5:
            return RotationMode.FRENCH
        elif eWS >= 1.7:
            return RotationMode.LONG_FRENCH
        elif eWS >= 1.5:
            return RotationMode.SKIPPING
        elif eWS >= 1.3:
            return RotationMode.ONE_TO_ONE
        elif eWS >= 0.94:
            return RotationMode.TWO_TO_THREE
        elif eWS >= 0.75:
            return RotationMode.ONE_TO_TWO
        elif eWS >= 0.62:
            return RotationMode.TWO_TO_FIVE
        else:
            return RotationMode.ONE_TO_THREE

    def calculate(self, haste_config: HasteConfig) -> Dict:
        """
        Calculate rotation information for given haste configuration.

        Returns:
            Dict with keys: eWS, rotation_mode, haste_mod_ranged, haste_mod_melee
        """
        haste_mod_ranged = self.get_haste_mod_ranged(haste_config)
        haste_mod_melee = self.get_haste_mod_melee(haste_config)
        eWS = self.player_stats.ranged_base_speed * haste_mod_ranged
        rotation_mode = self.detect_rotation_mode(eWS)

        return {
            "eWS": eWS,
            "rotation_mode": rotation_mode,
            "haste_mod_ranged": haste_mod_ranged,
            "haste_mod_melee": haste_mod_melee,
            "active_buffs": list(haste_config.active_buffs.keys()),
        }
