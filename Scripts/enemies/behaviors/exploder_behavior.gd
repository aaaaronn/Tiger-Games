extends "res://Scripts/enemies/enemy_behavior.gd"

func after_move(_delta: float) -> void:
	if enemy.global_position.distance_to(enemy.target.global_position) < enemy.collision_radius() + 20.0:
		enemy.call("detonate")

func on_zero_health() -> bool:
	enemy.call("detonate")
	return true

func draw_component() -> void:
	enemy.draw_arc(Vector2.ZERO, enemy.collision_radius() + 6.0, 0.0, TAU, 24, Color("ffd166"), 2.0)
	enemy.draw_circle(Vector2.ZERO, 4.0, Color("ffcf5c"))