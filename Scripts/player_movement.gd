extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 20.0
@export var friction: float = 20.0
@export var fire_rate: float = 0.24

var fire_clock := 0.0

func _ready() -> void:
	z_index = 2
	queue_redraw()

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
	fire_clock -= delta
	if fire_clock <= 0.0:
		var closest := get_closest_enemy()
		if closest:
			get_parent().fire_at(closest)
			fire_clock = fire_rate
	queue_redraw()

func get_closest_enemy() -> Node2D:
	var closest: Node2D
	var closest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var distance := global_position.distance_squared_to(enemy.global_position)
			if distance < closest_distance:
				closest = enemy
				closest_distance = distance
	return closest

func _draw() -> void:
	draw_circle(Vector2.ZERO, 22.0, Color("08100e"))
	draw_circle(Vector2.ZERO, 18.0, Color("53c7a1"))
	draw_circle(Vector2(0, -3), 9.0, Color("b5f2ce"))
	draw_circle(Vector2(-4, -5), 2.0, Color("16322b"))
	draw_circle(Vector2(4, -5), 2.0, Color("16322b"))
	draw_line(Vector2(-7, 8), Vector2(7, 8), Color("16322b"), 2.0)