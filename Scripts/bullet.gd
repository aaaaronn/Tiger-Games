extends Area2D

var direction := Vector2.RIGHT
var speed := 620.0
var lifetime := 1.3

func _ready() -> void:
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and position.distance_to(enemy.position) < 18.0:
			enemy.take_damage(1)
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color("f6c453"))
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)