extends Area2D

var direction := Vector2.RIGHT
var speed := 155.0
var damage := 10
var lifetime := 4.0

func _ready() -> void:
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	if get_parent().game_over or get_parent().in_shop:
		return
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var player: Node2D = get_parent().player
	if is_instance_valid(player) and position.distance_to(player.position) < 20.0:
		player.take_damage(damage)
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color("08100e"))
	draw_circle(Vector2.ZERO, 5.0, Color("8fd7ec"))