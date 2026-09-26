extends Area2D

var direction := Vector2.RIGHT
var speed := 155.0
var max_speed := 430.0
var acceleration_radius := 360.0
var damage := 10
var lifetime := 4.0

func _ready() -> void:
	z_index = 1
	queue_redraw()

func _process(delta: float) -> void:
	if get_parent().game_over or get_parent().in_shop:
		return
	var player: Node2D = get_parent().player
	if not is_instance_valid(player):
		queue_free()
		return
	var to_player := global_position.direction_to(player.global_position)
	direction = direction.lerp(to_player, minf(1.0, delta * 2.5)).normalized()
	var distance_to_player := global_position.distance_to(player.global_position)
	var proximity := 1.0 - clampf(distance_to_player / acceleration_radius, 0.0, 1.0)
	var current_speed := lerpf(speed, max_speed, proximity)
	var previous_position := global_position
	global_position += direction * current_speed * delta
	var arena: Rect2 = get_parent().arena_rect
	if not arena.has_point(global_position):
		queue_free()
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if Geometry2D.get_closest_point_to_segment(player.global_position, previous_position, global_position).distance_to(player.global_position) < 20.0:
		player.take_damage(damage)
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color("08100e"))
	draw_circle(Vector2.ZERO, 5.0, Color("8fd7ec"))
