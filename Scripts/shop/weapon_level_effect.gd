extends "res://Scripts/shop/shop_effect.gd"

@export var weapon_kind: StringName

func apply_to(player: CharacterBody2D, _game: Node) -> void:
	var kind := String(weapon_kind)
	player.weapon_type = kind
	player.weapon_levels[kind] = int(player.weapon_levels.get(kind, 0)) + 1
	player.weapon_level = player.weapon_levels[kind]

func is_available(_player: CharacterBody2D, game: Node) -> bool:
	return game.can_add_weapon(String(weapon_kind))