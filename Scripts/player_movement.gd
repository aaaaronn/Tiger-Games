extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 20.0
@export var friction: float = 20.0

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	if input_dir != Vector2.ZERO:
		velocity = velocity.lerp(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)

	move_and_slide()
