extends Area2D

var value := 1
var target: Node2D
var drift_time := 0.0
var is_medkit := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 10.0
	collision_shape.shape = circle_shape
	add_child(collision_shape)
	z_index = 1
	queue_redraw()

func _process(delta: float) -> void:
	drift_time += delta
	position.y += sin(drift_time * 4.0) * delta * 3.0
	if not is_instance_valid(target):
		return
	if target.get_parent().game_over or target.get_parent().in_shop:
		return
	var distance := position.distance_to(target.position)
	if distance < target.pickup_radius:
		position = position.move_toward(target.position, 420.0 * delta)
	if distance < 18.0:
		if is_medkit:
			target.get_parent().collect_medkit()
		else:
			target.get_parent().collect_xp(value)
		queue_free()
	queue_redraw()

func _draw() -> void:
	if is_medkit:
		draw_rect(Rect2(-8, -8, 16, 16), Color("e45757"))
		draw_rect(Rect2(-2, -6, 4, 12), Color.WHITE)
		draw_rect(Rect2(-6, -2, 12, 4), Color.WHITE)
		return
	var points := PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)])
	draw_colored_polygon(points, Color("67d6c0"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("d8fff1"), 2.0)
