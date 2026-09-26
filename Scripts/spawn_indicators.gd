extends Control

const EDGE_MARGIN := 30.0

var game: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	game = get_parent().get_parent()
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or game.in_shop or game.game_over or game.spawn_markers.is_empty() or visible_enemy_count() > 10:
		return
	var viewport_size := get_viewport_rect().size
	var center := viewport_size * 0.5
	var average_direction := Vector2.ZERO
	var spawn_count := 0
	for marker in game.spawn_markers:
		for spawn_position in marker.positions:
			var direction: Vector2 = game.player.global_position.direction_to(spawn_position)
			if direction == Vector2.ZERO:
				continue
			average_direction += direction
			spawn_count += 1
	if spawn_count > 0:
		draw_indicator(center, viewport_size, average_direction.normalized())

func visible_enemy_count() -> int:
	var viewport_size := get_viewport_rect().size
	var half_size := viewport_size * 0.5
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var offset: Vector2 = enemy.global_position - game.player.global_position
			if abs(offset.x) <= half_size.x and abs(offset.y) <= half_size.y:
				count += 1
	return count

func draw_indicator(center: Vector2, viewport_size: Vector2, direction: Vector2) -> void:
	var half_size := viewport_size * 0.5 - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var scale_to_edge: float = min(half_size.x / max(abs(direction.x), 0.001), half_size.y / max(abs(direction.y), 0.001))
	var edge_position: Vector2 = center + direction * scale_to_edge
	var angle: float = direction.angle()
	var tip: Vector2 = edge_position + direction * 16.0
	var left: Vector2 = edge_position + Vector2.from_angle(angle + 2.35) * 10.0
	var right: Vector2 = edge_position + Vector2.from_angle(angle - 2.35) * 10.0
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color(0.94, 0.28, 0.24, 0.92))
	draw_circle(edge_position, 14.0, Color(0.12, 0.04, 0.04, 0.72))
	draw_arc(edge_position, 14.0, 0.0, TAU, 20, Color("f06a5e"), 2.0)
