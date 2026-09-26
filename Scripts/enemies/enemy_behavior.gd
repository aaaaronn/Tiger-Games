extends RefCounted

var enemy: Node2D

func setup(owner: Node2D) -> void:
	enemy = owner

func before_move(_delta: float) -> bool:
	return false

func after_move(_delta: float) -> void:
	pass

func prevents_contact_damage() -> bool:
	return false

func on_zero_health() -> bool:
	return false

func on_death() -> void:
	pass

func draw_component() -> void:
	pass

func cleanup() -> void:
	pass