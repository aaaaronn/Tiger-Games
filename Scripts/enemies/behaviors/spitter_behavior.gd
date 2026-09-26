extends "res://Scripts/enemies/enemy_behavior.gd"

var attack_clock := 1.5

func after_move(delta: float) -> void:
	var distance_to_player := enemy.global_position.distance_to(enemy.target.global_position)
	if distance_to_player < 210.0:
		enemy.global_position += enemy.target.global_position.direction_to(enemy.global_position) * enemy.speed * delta * 1.5
	attack_clock -= delta
	if attack_clock <= 0.0 and distance_to_player < 500.0:
		enemy.call("fire_spit")
		attack_clock = maxf(0.8, 2.2 - enemy.target.get_parent().wave * 0.03)

func prevents_contact_damage() -> bool:
	return true