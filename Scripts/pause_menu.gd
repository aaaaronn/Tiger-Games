extends Control

var game: Node

@onready var resume_button: Button = $Panel/ResumeButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = get_parent().get_parent()
	resume_button.pressed.connect(resume_game)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game") or event.is_echo():
		return
	if game.game_over or game.in_shop:
		return
	get_viewport().set_input_as_handled()
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused

func resume_game() -> void:
	get_tree().paused = false
	visible = false