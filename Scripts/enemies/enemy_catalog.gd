extends RefCounted

const EnemyArchetype = preload("res://Scripts/enemies/enemy_archetype.gd")
const ChargerBehavior = preload("res://Scripts/enemies/behaviors/charger_behavior.gd")
const SpitterBehavior = preload("res://Scripts/enemies/behaviors/spitter_behavior.gd")
const ScreamerBehavior = preload("res://Scripts/enemies/behaviors/screamer_behavior.gd")
const BossBehavior = preload("res://Scripts/enemies/behaviors/boss_behavior.gd")
const ExploderBehavior = preload("res://Scripts/enemies/behaviors/exploder_behavior.gd")
const SwarmlingBehavior = preload("res://Scripts/enemies/behaviors/swarmling_behavior.gd")

var definitions: Dictionary = {}

func _init() -> void:
	definitions = {
		&"walker": _make(&"walker", 16.0, 1, 2, 0.0, 1, 3, 68.0, 2.5, 10.0, 10, 0.0, 1, 3, 10, 1, 1, 0),
		&"runner": _make(&"runner", 12.0, 1, 2, 0.0, 1, 3, 132.0, 3.0, 12.0, 7, 0.0, 1, 4, 15, 1, 1, 0),
		&"charger": _make(&"charger", 15.0, 2, 3, 0.0, 1, 4, 76.0, 2.0, 0.0, 18, 1.0, 0, 1, 28, 1, 0, 0, [ChargerBehavior]),
		&"exploder": _make(&"exploder", 15.0, 2, 18, 4.0, 0, 1, 32.0, 1.0, 0.0, 22, 2.0, 0, 1, 24, 1, 0, 0, [ExploderBehavior]),
		&"dart": _make(&"dart", 9.0, 1, 1, 0.0, 1, 10, 178.0, 3.5, 14.0, 9, 0.0, 1, 3, 18, 1, 0, 0),
		&"brute": _make(&"brute", 22.0, 3, 9, 2.0, 0, 1, 42.0, 1.5, 5.0, 22, 1.0, 0, 1, 30, 1, 1, 2),
		&"spitter": _make(&"spitter", 16.0, 2, 5, 1.0, 0, 1, 50.0, 1.8, 0.0, 12, 1.0, 0, 1, 35, 1, 1, 0, [SpitterBehavior]),
		&"screamer": _make(&"screamer", 16.0, 3, 7, 2.0, 0, 1, 46.0, 1.2, 0.0, 8, 1.0, 0, 1, 45, 1, 1, 0, [ScreamerBehavior]),
		&"swarmling": _make(&"swarmling", 9.0, 1, 3, 0.0, 1, 2, 96.0, 2.5, 0.0, 6, 0.0, 1, 3, 12, 1, 1, 0, [SwarmlingBehavior]),
		&"boss": _make(&"boss", 30.0, 3, 100, 24.0, 0, 1, 38.0, 0.8, 0.0, 28, 2.0, 0, 1, 250, 5, 2, 0, [BossBehavior]),
		&"mini_boss": _make(&"mini_boss", 24.0, 3, 60, 12.0, 0, 1, 54.0, 1.2, 0.0, 20, 1.0, 0, 1, 100, 5, 2, 0, [BossBehavior])
	}

func get_definition(id: StringName) -> Resource:
	return definitions.get(id, definitions[&"walker"])

func choose_kind(wave: int) -> StringName:
	var roll := randf()
	if wave >= 8 and roll > 0.96:
		return &"swarmling"
	if wave >= 6 and roll > 0.91 and roll <= 0.96:
		return &"exploder"
	if wave >= 3 and roll > 0.9:
		return &"charger"
	if wave >= 2 and roll < minf(0.14 + wave * 0.018, 0.3):
		return &"dart"
	if wave >= 6 and roll > 0.84:
		return &"screamer"
	if wave >= 5 and roll > 0.72:
		return &"spitter"
	if wave >= 3 and roll > 0.78:
		return &"brute"
	return &"walker"

func _make(id: StringName, radius: float, tier: int, health_base: float, health_per_wave: float, health_step: float, health_divisor: float, speed_base: float, speed_per_wave: float, speed_variance: float, damage_base: float, damage_per_wave: float, damage_step: float, damage_divisor: float, score: int, xp_base: int, xp_per_level: int, xp_bonus: int, components: Array[Script] = []) -> Resource:
	var definition: Resource = EnemyArchetype.new()
	definition.id = id
	definition.collision_radius = radius
	definition.sprite_tier = tier
	definition.health_base = health_base
	definition.health_per_wave = health_per_wave
	definition.health_step_amount = health_step
	definition.health_step_divisor = health_divisor
	definition.speed_base = speed_base
	definition.speed_per_wave = speed_per_wave
	definition.speed_variance = speed_variance
	definition.damage_base = damage_base
	definition.damage_per_wave = damage_per_wave
	definition.damage_step_amount = damage_step
	definition.damage_step_divisor = damage_divisor
	definition.score_value = score
	definition.xp_base = xp_base
	definition.xp_per_level = xp_per_level
	definition.xp_bonus = xp_bonus
	definition.behavior_components = components
	return definition