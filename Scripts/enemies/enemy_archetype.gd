extends Resource

@export var id: StringName
@export var collision_radius := 16.0
@export var sprite_tier := 1
@export var health_base := 2.0
@export var health_per_wave := 0.0
@export var health_step_amount := 0.0
@export var health_step_divisor := 1.0
@export var speed_base := 60.0
@export var speed_per_wave := 0.0
@export var speed_variance := 0.0
@export var damage_base := 10.0
@export var damage_per_wave := 0.0
@export var damage_step_amount := 0.0
@export var damage_step_divisor := 1.0
@export var score_value := 10
@export var xp_base := 1
@export var xp_per_level := 1
@export var xp_bonus := 0
@export var behavior_components: Array[Script] = []

func stats_for_wave(wave: int, level: int) -> Dictionary:
	return {
		"health": roundi(health_base + wave * health_per_wave + floor(wave / health_step_divisor) * health_step_amount),
		"speed": speed_base + wave * speed_per_wave + randf_range(-speed_variance, speed_variance),
		"damage": roundi(damage_base + wave * damage_per_wave + floor(wave / damage_step_divisor) * damage_step_amount),
		"score": score_value,
		"xp": xp_base + level * xp_per_level + xp_bonus
	}
