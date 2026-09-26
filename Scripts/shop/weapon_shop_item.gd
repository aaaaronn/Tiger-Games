extends "res://Scripts/shop/shop_item.gd"

func is_available(player: CharacterBody2D, game: Node) -> bool:
	return super.is_available(player, game)