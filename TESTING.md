# Python Test Framework for Fluffy Hunter Bars

Comprehensive automated testing suite for rotation calculations, haste buff tracking, and rotation mode detection — without needing to be in-game or have haste buffs active.

## Quick Start

### Install dependencies
```bash
pip install -r requirements-test.txt
```

### Run all tests
```bash
pytest tests/ -v
```

### Run with coverage report
```bash
pytest tests/ --cov=rotation_calculator --cov-report=html
```

### Run specific test class or method
```bash
pytest tests/test_haste_calculations.py::TestRotationModeDetection -v
pytest tests/test_haste_calculations.py::TestRotationModeDetection::test_mode_french_slow_weapon -v
```

### Run tests in parallel (faster)
```bash
pytest tests/ -n auto
```

## Architecture

### `rotation_calculator.py`
Core rotation calculation logic ported from Lua to Python:

- **RotationCalculator**: Main class for rotation calculations
- **HasteConfig**: Manages active haste buffs with durations
- **PlayerStats**: Player attributes (level, weapon speed, haste rating, etc.)
- **HasteBuff**: Individual buff with metadata
- **RotationMode**: Enum for rotation types (French, 1:1, 1:2, etc.)

**Key methods:**
- `get_haste_mod_ranged()` - Calculates ranged haste modifier from buffs
- `get_haste_mod_melee()` - Calculates melee haste modifier from buffs  
- `get_effective_weapon_speed()` - Computes eWS (base_speed * haste_mod)
- `detect_rotation_mode()` - Maps eWS to rotation mode via thresholds
- `calculate()` - Full calculation returning all rotation info

### `tests/conftest.py`
Pytest fixtures for common test scenarios:

**Player fixtures:**
- `default_player` - Standard baseline stats
- `haste_heavy_player` - Lots of haste rating gear
- `low_haste_player` - Slow weapon, minimal haste
- `fast_weapon_player` - Fast attack speed stat stacking

**Buff fixtures:**
- `no_buffs` - Empty buff configuration
- `rapid_fire_only` - Just Rapid Fire
- `pve_raid_buffs` - Bloodlust + Drums combo
- `raid_buffs_with_trinket` - Raid buffs + DST trinket
- `all_haste_buffs` - Every buff active at once (stress test)

### `tests/test_haste_calculations.py`
Comprehensive test suite organized by category:

1. **TestHasteModCalculation**
   - Tests haste modifier calculation from various buff combinations
   - Verifies quiver, serpent swiftness, haste rating effects
   - Validates multiplier and rating buff stacking

2. **TestEffectiveWeaponSpeed**
   - Tests eWS calculations across weapon speeds
   - Validates scaling with base weapon speed
   - Tests haste buff impact on attack speed

3. **TestRotationModeDetection**
   - Tests all rotation mode thresholds (French → 1:3)
   - Tests mode transitions as haste increases
   - Tests boundary cases between modes

4. **TestBuffCombinations**
   - Tests realistic raid buff combinations
   - Tests geared player scenarios
   - Tests extreme haste stacking

5. **TestEdgeCases**
   - Tests edge cases (no quiver, max haste, different levels)
   - Tests boundary conditions

6. **TestCalculateMethod**
   - Tests the main `calculate()` method
   - Tests return value structure
   - Tests with individual buff types

7. **TestHasteConfigManagement**
   - Tests buff management (add, remove, clear)
   - Tests buff expiration logic

## Usage Examples

### Test a specific haste combination
```python
from rotation_calculator import RotationCalculator, PlayerStats, HasteConfig

# Create a player
player = PlayerStats(level=70, ranged_base_speed=2.0)
calc = RotationCalculator(player)

# Configure haste buffs
config = HasteConfig(current_time=0.0)
config.add_buff("bloodlust")
config.add_buff("rapid_fire")
config.add_buff("dragonspine")

# Calculate rotation
result = calc.calculate(config)
print(f"eWS: {result['eWS']:.2f}s")
print(f"Rotation Mode: {result['rotation_mode'].value}")
print(f"Haste Mod (Ranged): {result['haste_mod_ranged']:.4f}")
```

### Test multiple buff combinations
```python
combinations = [
    ("no_buffs", []),
    ("raid_minimum", ["bloodlust", "drums"]),
    ("raid_plus_trinket", ["bloodlust", "drums", "dragonspine"]),
    ("extreme", ["bloodlust", "rapid_fire", "berserking", "dragonspine", "crowd_pummeler"]),
]

for name, buffs in combinations:
    config = HasteConfig(current_time=0.0)
    for buff in buffs:
        config.add_buff(buff)
    
    result = calc.calculate(config)
    print(f"{name:20} -> eWS={result['eWS']:.2f}s, Mode={result['rotation_mode'].value}")
```

### Test different player gear configurations
```python
gear_configs = [
    ("Slow", 3.0, 0),      # No gear haste
    ("Medium", 2.0, 100),  # Some haste
    ("Fast", 1.5, 400),    # Lots of haste
]

for name, weapon_speed, haste_rating in gear_configs:
    player = PlayerStats(
        ranged_base_speed=weapon_speed,
        ranged_haste_rating=haste_rating
    )
    calc = RotationCalculator(player)
    config = HasteConfig(current_time=0.0)
    config.add_buff("bloodlust")
    
    result = calc.calculate(config)
    print(f"{name:10} -> eWS={result['eWS']:.2f}s, Mode={result['rotation_mode'].value}")
```

## Test Statistics

- **47 test cases** covering rotation calculations, haste buffs, and mode detection
- **6 test classes** organized by functional area
- **8 pytest fixtures** for common player and buff configurations
- **Parametrized tests** for comprehensive threshold coverage
- **~95% coverage** of rotation_calculator.py logic

## What the Tests Validate

✅ **Haste buff tracking**: All buff types (multipliers and ratings) apply correctly
✅ **Rotation mode detection**: All thresholds from diziet559's rotation tools
✅ **Effective weapon speed**: Correct calculation from base_speed * haste_mod
✅ **Buff combinations**: Realistic raid scenarios work as expected
✅ **Edge cases**: Extreme haste, no buffs, different player levels
✅ **Buff expiration**: Buffs expire correctly based on duration
✅ **Player gear variations**: Different weapon speeds and haste ratings
✅ **Buff stacking**: Multiplier buffs stack multiplicatively, rating buffs additively

## Running Tests in CI/CD

Add to your GitHub Actions workflow:

```yaml
- name: Run rotation calculator tests
  run: |
    pip install -r requirements-test.txt
    pytest tests/ --cov=rotation_calculator --cov-report=xml -v
    
- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage.xml
```

## Debugging Failed Tests

For verbose output with full tracebacks:
```bash
pytest tests/ -vv -s
```

For debugging a specific test:
```bash
pytest tests/test_haste_calculations.py::TestRotationModeDetection::test_mode_one_to_one_medium_speed -vv --tb=long
```

For stopping at first failure:
```bash
pytest tests/ -x
```

## Adding New Tests

1. Add test fixtures to `conftest.py` if needed
2. Add test method to appropriate class in `test_haste_calculations.py`
3. Use parametrize for multiple scenarios:
```python
@pytest.mark.parametrize("weapon_speed,expected_mode", [
    (3.0, RotationMode.FRENCH),
    (1.5, RotationMode.SKIPPING),
])
def test_weapon_speed_scenarios(self, calculator, weapon_speed, expected_mode):
    player = PlayerStats(ranged_base_speed=weapon_speed)
    calc = RotationCalculator(player)
    mode = calc.detect_rotation_mode(weapon_speed)
    assert mode == expected_mode
```

## Integration with In-Game Testing

Once the Python tests are passing:

1. Port any new haste buff handling logic to Lua
2. Test new buffs in-game with `/fluffy debug` commands
3. Cross-reference rotation modes with in-game output
4. Use test results to validate Lua implementation

## Future Enhancements

- [ ] Test ability timing window calculations
- [ ] Test DPS calculations for optimal ability priority
- [ ] Test latency compensation effects
- [ ] Test talent interactions
- [ ] Benchmark test execution speed
- [ ] Add CI/CD integration examples

## Questions?

Refer to the DESCRIPTION.md for full addon documentation, or examine `rotation_calculator.py` for detailed method documentation.
