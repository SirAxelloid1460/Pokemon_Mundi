extends Node
# Formulae.gd — Core math: stats, battle damage, XP curves, tier-based level system.
# Accumulative-stats mechanic: stats NEVER reset on evolution; only the level resets.

# ---------------------------------------------------------------------------
# TIER / LEVEL-CAP SYSTEM (validated via Python simulation)
# Worst case (evolving at 3/4 of tier cap) => ~12-15% power loss vs best case. Acceptable.
# ---------------------------------------------------------------------------
# T0 baby      cap 30   no reset on evolution
# T1           cap 60   x1.0   reset on evolution
# T2           cap 40   x1.5   reset on evolution
# T3 final     cap 30   x2.0   final stage
# T1 no-evo    cap 150  x1.0   (single-stage line, no multiplier)
# T2 method    cap 40   x3.0   (found already in phase 2: Haunter, Kadabra, Graveler)
# T4 legendary cap 200
# T5 mythical  cap 250

const TIER_CAPS: Dictionary = {
	"T0": 30, "T1": 60, "T2": 40, "T3": 30,
	"T1_NOEVO": 150, "T2_METHOD": 40, "T4": 200, "T5": 250,
}
const TIER_MULTIPLIERS: Dictionary = {
	"T0": 1.0, "T1": 1.0, "T2": 1.5, "T3": 2.0,
	"T1_NOEVO": 1.0, "T2_METHOD": 3.0, "T4": 1.0, "T5": 1.0,
}

# Offset applied to in-game (Mundi) levels when transferring between scaling systems.
const TRANSFER_OFFSET: int = 0

func tier_cap(tier: String) -> int:
	return TIER_CAPS.get(tier, 100)

func tier_multiplier(tier: String) -> float:
	return TIER_MULTIPLIERS.get(tier, 1.0)

# Level after evolution: stats carry forward, ONLY the level resets.
# T0 is the exception — it does NOT reset on evolution.
func level_after_evolution(current_tier: String) -> int:
	if current_tier == "T0":
		return -1  # sentinel: no reset, keep current level
	return 1

# Threshold level = cap + 1. Reaching it triggers evolution availability / blocks further XP gain.
func threshold_level(tier: String) -> int:
	return tier_cap(tier) + 1

# Convert an original main-series level to a Mundi-scaled level for a given tier cap.
func scale_encounter_level(original_level: int, cap_tier: int) -> int:
	return int(round(float(original_level) / 100.0 * float(cap_tier)))

# ---------------------------------------------------------------------------
# STAT CALCULATION
# ---------------------------------------------------------------------------
func calc_hp(base: int, iv: int, ev: int, level: int) -> int:
	return int(floor((2 * base + iv + floor(ev / 4.0)) * level / 100.0)) + level + 10

func calc_stat(base: int, iv: int, ev: int, level: int, nature: float = 1.0) -> int:
	var val: float = (floor((2 * base + iv + floor(ev / 4.0)) * level / 100.0)) + 5
	return int(floor(val * nature))

# Apply in-battle stage modifier (-6..+6) to a stat.
func stage_modifier(stat: int, stage: int) -> int:
	stage = clamp(stage, -6, 6)
	if stage >= 0:
		return int(stat * (2.0 + stage) / 2.0)
	return int(stat * 2.0 / (2.0 - stage))

# ---------------------------------------------------------------------------
# BATTLE DAMAGE
# ---------------------------------------------------------------------------
# STAB = Same-Type Attack Bonus. effectiveness comes from Type.calculate_effectiveness().
func calc_damage(level: int, power: int, attack: int, defense: int, modifiers: Dictionary = {}) -> int:
	if power <= 0 or defense <= 0:
		return 0
	var base: float = (((2.0 * level / 5.0 + 2.0) * power * (float(attack) / float(defense))) / 50.0) + 2.0

	var stab: float = modifiers.get("stab", 1.0)
	var effectiveness: float = modifiers.get("effectiveness", 1.0)
	var critical: float = modifiers.get("critical", 1.0)
	var weather: float = modifiers.get("weather", 1.0)
	var burn: float = modifiers.get("burn", 1.0)
	var random_factor: float = modifiers.get("random", randf_range(0.85, 1.0))

	var total: float = base * stab * effectiveness * critical * weather * burn * random_factor
	return max(1, int(floor(total)))

func stab_multiplier(move_type: String, attacker_types: Array) -> float:
	return 1.5 if move_type in attacker_types else 1.0

func critical_multiplier(is_critical: bool) -> float:
	return 1.5 if is_critical else 1.0

# ---------------------------------------------------------------------------
# XP GROWTH CURVES — total XP required to REACH a given level (1..100 classic; capped per tier)
# ---------------------------------------------------------------------------
func xp_for_level(level: int, growth_type: String) -> int:
	if level <= 1:
		return 0
	var n: float = float(level)
	match growth_type:
		"Fast":
			return int(floor(0.8 * n * n * n))
		"Medium Fast":
			return int(floor(n * n * n))
		"Medium Slow":
			return int(floor(1.2 * n * n * n - 15.0 * n * n + 100.0 * n - 140.0))
		"Slow":
			return int(floor(1.25 * n * n * n))
		"Erratic":
			return _xp_erratic(int(level))
		"Fluctuating":
			return _xp_fluctuating(int(level))
		_:
			return int(floor(n * n * n))

func _xp_erratic(level: int) -> int:
	var n: float = float(level)
	if level < 50:
		return int(floor(n * n * n * (100.0 - n) / 50.0))
	elif level < 68:
		return int(floor(n * n * n * (150.0 - n) / 100.0))
	elif level < 98:
		return int(floor(n * n * n * floor((1911.0 - 10.0 * n) / 3.0) / 500.0))
	else:
		return int(floor(n * n * n * (160.0 - n) / 100.0))

func _xp_fluctuating(level: int) -> int:
	var n: float = float(level)
	if level < 15:
		return int(floor(n * n * n * (floor((n + 1.0) / 3.0) + 24.0) / 50.0))
	elif level < 36:
		return int(floor(n * n * n * (n + 14.0) / 50.0))
	else:
		return int(floor(n * n * n * (floor(n / 2.0) + 32.0) / 50.0))

# XP needed to go from current level to the next.
func xp_to_next_level(level: int, growth_type: String) -> int:
	return xp_for_level(level + 1, growth_type) - xp_for_level(level, growth_type)
