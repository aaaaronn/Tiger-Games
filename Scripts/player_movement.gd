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
	# Stylized hitman silhouette: long hair, black suit, white shirt, and tie.
	draw_circle(Vector2(0, 1), 22.0, Color("050607"))
	draw_polygon(
		PackedVector2Array([
			Vector2(-16, 2), Vector2(-12, -9), Vector2(-7, -13), Vector2(7, -13),
			Vector2(12, -9), Vector2(16, 2), Vector2(13, 18), Vector2(-13, 18)
		]),
		PackedColorArray([Color("111519")])
	)

	# Face framed by the character's shoulder-length hair.
	draw_circle(Vector2(0, -9), 9.0, Color("c98f72"))
	draw_polygon(
		PackedVector2Array([
			Vector2(-10, -12), Vector2(-7, -20), Vector2(1, -23), Vector2(9, -18),
			Vector2(11, -8), Vector2(7, -5), Vector2(6, -14), Vector2(-5, -15),
			Vector2(-7, -5), Vector2(-11, -4)
		]),
		PackedColorArray([Color("15191d")])
	)
	draw_line(Vector2(-8, -7), Vector2(-4, -6), Color("321f1d"), 1.5)
	draw_line(Vector2(4, -6), Vector2(8, -7), Color("321f1d"), 1.5)

	# Crisp shirt front and narrow black tie.
	draw_polygon(
		PackedVector2Array([Vector2(-7, 0), Vector2(0, 6), Vector2(7, 0), Vector2(5, 15), Vector2(-5, 15)]),
		PackedColorArray([Color("e7e8e2")])
	)
	draw_polygon(
		PackedVector2Array([Vector2(-2, 1), Vector2(2, 1), Vector2(3, 15), Vector2(0, 19), Vector2(-3, 15)]),
		PackedColorArray([Color("101114")])
	)
	draw_line(Vector2(-12, 4), Vector2(-18, 1), Color("252a2f"), 4.0)
	draw_line(Vector2(-18, 1), Vector2(-21, -4), Color("d4a08a"), 3.0)
	draw_line(Vector2(12, 4), Vector2(18, 1), Color("252a2f"), 4.0)
	draw_line(Vector2(18, 1), Vector2(21, -4), Color("d4a08a"), 3.0)