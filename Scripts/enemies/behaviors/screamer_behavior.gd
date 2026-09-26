extends "res://Scripts/enemies/enemy_behavior.gd"

var buff_clock := 0.0

func after_move(delta: float) -> void:
	if buff_clock <= 0.0:
		for other in enemy.get_tree().get_nodes_in_group("enemies"):
			if other != enemy and is_instance_valid(other) and enemy.global_position.distance_to(other.global_position) < 180.0:
				other.speed_multiplier = maxf(other.speed_multiplier, 1.22)
				other.damage_multiplier = maxf(other.damage_multiplier, 1.15)
			buff_clock = 3.0
	buff_clock -= delta