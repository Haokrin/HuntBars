"""
Comprehensive tests for rotation calculator haste buff tracking and mode detection.

Tests cover:
- Haste modifier calculations with various buff combinations
- Effective weapon speed (eWS) calculations
- Rotation mode detection based on eWS
- Edge cases (extreme haste, no buffs, etc.)
"""

import pytest
from rotation_calculator import (
    RotationCalculator,
    PlayerStats,
    HasteConfig,
    RotationMode,
    HASTE_BUFFS,
)


class TestHasteModCalculation:
    """Test haste modifier calculations from buffs."""

    def test_no_buffs_ranged_haste_mod(self, default_player, no_buffs):
        """Haste modifier with no buffs should account for quiver and serpent swiftness."""
        calc = RotationCalculator(default_player)
        haste_mod = calc.get_haste_mod_ranged(no_buffs)

        # With quiver_haste=0.15, haste should be 1.0 / 1.15 ≈ 0.8696
        expected = 1.0 / 1.15
        assert abs(haste_mod - expected) < 0.001

    def test_no_buffs_melee_haste_mod(self, default_player, no_buffs):
        """Melee haste modifier with no buffs should be 1.0."""
        calc = RotationCalculator(default_player)
        haste_mod = calc.get_haste_mod_melee(no_buffs)
        assert abs(haste_mod - 1.0) < 0.001

    def test_rapid_fire_ranged_buff(self, default_player, rapid_fire_only):
        """Rapid Fire applies to ranged, not melee."""
        calc = RotationCalculator(default_player)
        haste_mod_ranged = calc.get_haste_mod_ranged(rapid_fire_only)
        haste_mod_melee = calc.get_haste_mod_melee(rapid_fire_only)

        # Ranged should be affected: 1/1.4 from RF, divided by quiver
        # Melee should be unchanged: 1.0
        assert haste_mod_ranged < 1.0
        assert abs(haste_mod_melee - 1.0) < 0.001

    def test_bloodlust_affects_both(self, default_player, pve_raid_buffs):
        """Bloodlust should affect both melee and ranged."""
        calc = RotationCalculator(default_player)
        haste_mod_ranged = calc.get_haste_mod_ranged(pve_raid_buffs)
        haste_mod_melee = calc.get_haste_mod_melee(pve_raid_buffs)

        # Both should be reduced from baseline
        assert haste_mod_ranged < (1.0 / 1.15)  # Less than ranged baseline
        assert haste_mod_melee < 1.0  # Less than melee baseline

    def test_stacking_multiplier_buffs(self, default_player):
        """Multiple multiplier buffs should stack multiplicatively."""
        config = HasteConfig(current_time=0.0)
        config.add_buff("rapid_fire")  # 1.4x
        config.add_buff("bloodlust")  # 1.3x

        calc = RotationCalculator(default_player)
        haste_mod = calc.get_haste_mod_ranged(config)

        # Should divide by 1.4 * 1.3 = 1.82
        expected = 1.0 / (1.4 * 1.3) / 1.15
        assert abs(haste_mod - expected) < 0.001

    def test_haste_rating_adds_correctly(self, haste_heavy_player, no_buffs):
        """Haste rating should be applied correctly."""
        calc = RotationCalculator(haste_heavy_player)
        haste_mod = calc.get_haste_mod_ranged(no_buffs)

        # With 300 haste rating and level 70
        # haste = 1.0 / 1.15 (quiver)
        # total_rating = 300
        # result = 1.0 / 1.15 / (1 + 0.01 * 300 / 15.77)
        quiver = 1.15
        level_conversion = 15.77
        total_rating = 300
        expected = (1.0 / quiver) / (1 + 0.01 * total_rating / level_conversion)
        assert abs(haste_mod - expected) < 0.01


class TestEffectiveWeaponSpeed:
    """Test eWS (effective weapon speed) calculations."""

    def test_no_buffs_ews(self, default_player, no_buffs):
        """eWS with no buffs: base_speed * haste_mod."""
        calc = RotationCalculator(default_player)
        eWS = calc.get_effective_weapon_speed(no_buffs)

        haste_mod = calc.get_haste_mod_ranged(no_buffs)
        expected = default_player.ranged_base_speed * haste_mod
        assert abs(eWS - expected) < 0.001

    def test_rapid_fire_increases_attack_speed(self, default_player, rapid_fire_only):
        """Rapid Fire should decrease eWS (faster attacks)."""
        calc = RotationCalculator(default_player)
        no_buff_ews = calc.get_effective_weapon_speed(HasteConfig(current_time=0.0))
        rf_ews = calc.get_effective_weapon_speed(rapid_fire_only)

        assert rf_ews < no_buff_ews

    def test_bloodlust_extreme_haste(self, default_player, pve_raid_buffs):
        """Bloodlust + drums should significantly speed up weapon."""
        calc = RotationCalculator(default_player)
        no_buff_ews = calc.get_effective_weapon_speed(HasteConfig(current_time=0.0))
        buff_ews = calc.get_effective_weapon_speed(pve_raid_buffs)

        assert buff_ews < no_buff_ews
        # Should be noticeably faster
        assert buff_ews < no_buff_ews * 0.85

    @pytest.mark.parametrize("base_speed,expected_min_ews", [
        (1.5, 0.2),   # Fast weapon -> very fast eWS with extreme haste
        (2.0, 0.3),   # Medium weapon
        (3.0, 0.5),   # Slow weapon
    ])
    def test_ews_scales_with_base_speed(self, base_speed, expected_min_ews, all_haste_buffs):
        """eWS should scale linearly with base weapon speed."""
        player = PlayerStats(ranged_base_speed=base_speed)
        calc = RotationCalculator(player)
        eWS = calc.get_effective_weapon_speed(all_haste_buffs)

        # eWS should be proportional to base speed
        assert eWS >= expected_min_ews


class TestRotationModeDetection:
    """Test rotation mode detection based on eWS."""

    def test_mode_french_slow_weapon(self, low_haste_player, no_buffs):
        """Slow weapon with no haste -> French rotation."""
        calc = RotationCalculator(low_haste_player)
        eWS = calc.get_effective_weapon_speed(no_buffs)
        mode = calc.detect_rotation_mode(eWS)

        assert eWS >= 2.5
        assert mode == RotationMode.FRENCH

    def test_mode_one_to_one_medium_speed(self, default_player, rapid_fire_only):
        """2.0s base + Rapid Fire -> 1:1 or faster."""
        calc = RotationCalculator(default_player)
        eWS = calc.get_effective_weapon_speed(rapid_fire_only)
        mode = calc.detect_rotation_mode(eWS)

        # Rapid Fire should speed this up to 1:1 range or faster
        assert mode in (
            RotationMode.ONE_TO_ONE,
            RotationMode.TWO_TO_THREE,
            RotationMode.ONE_TO_TWO,
        )

    def test_mode_transitions_with_haste(self, default_player):
        """Test rotation mode transitions as haste increases."""
        calc = RotationCalculator(default_player)

        modes = []
        haste_levels = [
            ("no_buffs", HasteConfig(current_time=0.0)),
            ("rapid_fire", lambda: HasteConfig(current_time=0.0) or (config := HasteConfig(current_time=0.0), config.add_buff("rapid_fire"), config)[2]),
            ("rf_bl", lambda: (config := HasteConfig(current_time=0.0), config.add_buff("rapid_fire"), config.add_buff("bloodlust"), config)[2]),
        ]

        # Test with multiple haste levels
        config1 = HasteConfig(current_time=0.0)
        ews1 = calc.get_effective_weapon_speed(config1)
        mode1 = calc.detect_rotation_mode(ews1)

        config2 = HasteConfig(current_time=0.0)
        config2.add_buff("rapid_fire")
        ews2 = calc.get_effective_weapon_speed(config2)
        mode2 = calc.detect_rotation_mode(ews2)

        # Adding buffs should increase speed (decrease eWS)
        assert ews2 < ews1
        # Mode might stay same or shift faster
        assert mode2 in (mode1, RotationMode.ONE_TO_ONE, RotationMode.TWO_TO_THREE)

    @pytest.mark.parametrize("ews,expected_mode", [
        (3.0, RotationMode.FRENCH),
        (2.2, RotationMode.LONG_FRENCH),
        (1.6, RotationMode.SKIPPING),
        (1.4, RotationMode.ONE_TO_ONE),
        (1.0, RotationMode.TWO_TO_THREE),
        (0.85, RotationMode.ONE_TO_TWO),
        (0.68, RotationMode.TWO_TO_FIVE),
        (0.5, RotationMode.ONE_TO_THREE),
    ])
    def test_mode_thresholds(self, calculator, ews, expected_mode):
        """Test all rotation mode thresholds."""
        mode = calculator.detect_rotation_mode(ews)
        assert mode == expected_mode

    def test_mode_edge_cases(self, calculator):
        """Test boundary cases between rotation modes."""
        # Just above French threshold
        assert calculator.detect_rotation_mode(2.50) == RotationMode.FRENCH
        # Just below French threshold
        assert calculator.detect_rotation_mode(2.49) == RotationMode.LONG_FRENCH

        # Just above 1:1
        assert calculator.detect_rotation_mode(1.30) == RotationMode.ONE_TO_ONE
        # Just below 1:1
        assert calculator.detect_rotation_mode(1.29) == RotationMode.TWO_TO_THREE


class TestBuffCombinations:
    """Test realistic buff combinations from raids."""

    def test_mc_raid_buffs(self, default_player):
        """Typical MC raid: Mark of the Wild, Bloodlust, Drums."""
        config = HasteConfig(current_time=0.0)
        config.add_buff("bloodlust")
        config.add_buff("drums")

        calc = RotationCalculator(default_player)
        result = calc.calculate(config)

        assert result["eWS"] < 2.0  # Should be significantly faster
        assert "bloodlust" in result["active_buffs"]
        assert "drums" in result["active_buffs"]

    def test_t4_gear_with_haste(self, haste_heavy_player):
        """T4 geared player with baseline buffs."""
        config = HasteConfig(current_time=0.0)
        config.add_buff("bloodlust")

        calc = RotationCalculator(haste_heavy_player)
        result = calc.calculate(config)

        assert result["rotation_mode"] in (
            RotationMode.ONE_TO_ONE,
            RotationMode.TWO_TO_THREE,
        )

    def test_extreme_haste_stack(self, fast_weapon_player, all_haste_buffs):
        """Extreme haste from max buffs + gear."""
        calc = RotationCalculator(fast_weapon_player)
        result = calc.calculate(all_haste_buffs)

        # Should be extremely fast
        assert result["eWS"] < 0.7
        assert result["rotation_mode"] == RotationMode.ONE_TO_THREE

    def test_no_haste_slow_rotation(self, low_haste_player, no_buffs):
        """Slow gear with no buffs -> French rotation."""
        calc = RotationCalculator(low_haste_player)
        result = calc.calculate(no_buffs)

        assert result["rotation_mode"] == RotationMode.FRENCH
        assert result["eWS"] >= 2.5


class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_zero_haste_rating(self, default_player, no_buffs):
        """Player with no haste rating should still calculate correctly."""
        assert default_player.ranged_haste_rating == 0
        calc = RotationCalculator(default_player)
        result = calc.calculate(no_buffs)

        assert result["eWS"] > 0
        assert result["rotation_mode"] is not None

    def test_extremely_high_haste(self, fast_weapon_player):
        """Stack all haste buffs with haste-heavy gear."""
        config = HasteConfig(current_time=0.0)
        for buff_key in HASTE_BUFFS:
            config.add_buff(buff_key)

        calc = RotationCalculator(fast_weapon_player)
        result = calc.calculate(config)

        # Should still be > 0
        assert result["eWS"] > 0.1
        assert result["rotation_mode"] is not None

    def test_no_quiver(self, default_player, no_buffs):
        """Player without quiver should have different haste calculation."""
        player_no_quiver = PlayerStats(
            level=70,
            ranged_base_speed=2.0,
            quiver_haste=0.0,  # No quiver
        )
        calc = RotationCalculator(player_no_quiver)
        haste_mod = calc.get_haste_mod_ranged(no_buffs)

        # Without quiver: haste = 1.0 / 1.0 = 1.0
        expected = 1.0
        assert abs(haste_mod - expected) < 0.001

    def test_different_player_levels(self):
        """Test haste calculations at different player levels."""
        for level in [60, 65, 70]:
            player = PlayerStats(level=level, ranged_base_speed=2.0)
            calc = RotationCalculator(player)
            config = HasteConfig(current_time=0.0)
            config.add_buff("bloodlust")

            result = calc.calculate(config)
            assert result["eWS"] > 0
            assert result["rotation_mode"] is not None


class TestCalculateMethod:
    """Test the main calculate() method that returns rotation recommendations."""

    def test_calculate_returns_all_fields(self, default_player, pve_raid_buffs):
        """calculate() should return eWS, rotation_mode, and haste mods."""
        calc = RotationCalculator(default_player)
        result = calc.calculate(pve_raid_buffs)

        assert "eWS" in result
        assert "rotation_mode" in result
        assert "haste_mod_ranged" in result
        assert "haste_mod_melee" in result
        assert "active_buffs" in result

    def test_calculate_with_no_buffs(self, default_player):
        """calculate() with no buffs should return a valid rotation mode."""
        calc = RotationCalculator(default_player)
        config = HasteConfig(current_time=0.0)
        result = calc.calculate(config)

        # Default player with 2.0s weapon and quiver should be in LONG_FRENCH or FRENCH
        assert result["rotation_mode"] in (RotationMode.FRENCH, RotationMode.LONG_FRENCH)
        assert len(result["active_buffs"]) == 0

    @pytest.mark.parametrize("buff_key", [
        "rapid_fire",
        "bloodlust",
        "heroism",
        "berserking",
        "dragonspine",
    ])
    def test_calculate_with_individual_buffs(self, default_player, buff_key):
        """Test calculate() with each individual buff type."""
        config = HasteConfig(current_time=0.0)
        config.add_buff(buff_key)

        calc = RotationCalculator(default_player)
        result = calc.calculate(config)

        assert buff_key in result["active_buffs"]
        assert result["rotation_mode"] is not None
        assert result["eWS"] > 0


class TestHasteConfigManagement:
    """Test HasteConfig buff management."""

    def test_add_buff(self):
        """Adding a buff should update active_buffs."""
        config = HasteConfig(current_time=0.0)
        assert len(config.active_buffs) == 0

        config.add_buff("bloodlust")
        assert len(config.active_buffs) == 1
        assert "bloodlust" in config.active_buffs

    def test_remove_buff(self):
        """Removing a buff should update active_buffs."""
        config = HasteConfig(current_time=0.0)
        config.add_buff("bloodlust")
        assert "bloodlust" in config.active_buffs

        config.remove_buff("bloodlust")
        assert "bloodlust" not in config.active_buffs

    def test_clear_buffs(self):
        """clear_buffs() should remove all buffs."""
        config = HasteConfig(current_time=0.0)
        config.add_buff("bloodlust")
        config.add_buff("drums")
        assert len(config.active_buffs) == 2

        config.clear_buffs()
        assert len(config.active_buffs) == 0

    def test_invalid_buff_raises_error(self):
        """Adding an unknown buff should raise ValueError."""
        config = HasteConfig(current_time=0.0)
        with pytest.raises(ValueError):
            config.add_buff("nonexistent_buff")

    def test_buff_expiration(self):
        """Buffs should expire based on expiration_time."""
        config = HasteConfig(current_time=0.0)
        config.add_buff("bloodlust", duration=5.0)

        # At t=0.0, buff is active
        assert config.current_time < config.active_buffs["bloodlust"].expiration_time

        # At t=6.0, buff has expired
        config.current_time = 6.0
        assert config.current_time >= config.active_buffs["bloodlust"].expiration_time
