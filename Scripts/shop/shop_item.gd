extends Resource

@export var id: StringName
@export var display_name := ""
@export var tag := "SKILL"
@export var rarity := "COMMON"
@export_multiline var description := ""
@export var icon := ""
@export var effects: Array[Resource] = []

func is_available(player: CharacterBody2D, game: Node) -> bool:
	for effect in effects:
		if effect.has_method("is_available") and not effect.is_available(player, game):
			return false
	return true

func apply_to(player: CharacterBody2D, game: Node) -> void:
	for effect in effects:
		if effect.has_method("apply_to"):
			effect.apply_to(player, game)