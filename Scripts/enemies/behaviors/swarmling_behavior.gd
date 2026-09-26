extends "res://Scripts/enemies/enemy_behavior.gd"

func on_death() -> void:
	if enemy.get_parent().wave < 8:
		return
	for child_index in 3:
		enemy.get_parent().call("spawn_enemy", child_index, 1)