extends Area2D

var direction := Vector2.RIGHT
var speed := 620.0
var lifetime := 1.3
var damage := 1
var pierce := 0
var inherited_velocity := Vector2.ZERO
var hit_enemies: Array[Node] = []

func _ready() -> void:
	z_index = 1
	queue_redraw()

func _process(delta: float) -> void:
	var previous_position := global_position
	global_position += (direction * speed + inherited_velocity) * delta
	var arena: Rect2 = get_parent().arena_rect
	if not arena.has_point(global_position):
		queue_free()
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not hit_enemies.has(enemy) and Geometry2D.get_closest_point_to_segment(enemy.global_position, previous_position, global_position).distance_to(enemy.global_position) < 18.0:
			hit_enemies.append(enemy)
			enemy.take_damage(damage)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color("f6c453"))
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
