extends Area2D

signal died(enemy: Node2D)

var target: Node2D
var speed := 60.0
var health := 2
var hit_flash := 0.0

func _ready() -> void:
	add_to_group("enemies")
	z_index = 2
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	position += position.direction_to(target.position) * speed * delta
	hit_flash = max(0.0, hit_flash - delta)
	if position.distance_to(target.position) < 27.0:
		target.get_parent().game_over = true
		target.get_parent().wave_banner.text = "OVERRUN - CLOSE THE GAME TO RESTART"
	queue_redraw()

func take_damage(amount: int) -> void:
	health -= amount
	hit_flash = 0.1
	if health <= 0:
		died.emit(self)
	queue_free()
	queue_redraw()

func _draw() -> void:
	var body_color := Color("e45757") if hit_flash <= 0.0 else Color.WHITE
	draw_circle(Vector2.ZERO, 16.0, Color("08100e"))
	draw_circle(Vector2.ZERO, 13.0, body_color)
	draw_circle(Vector2(-5, -2), 2.5, Color("101a19"))
	draw_circle(Vector2(5, -2), 2.5, Color("101a19"))
	draw_line(Vector2(-5, 6), Vector2(5, 6), Color("101a19"), 2.0)