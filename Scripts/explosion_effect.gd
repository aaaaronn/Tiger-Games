extends Node2D

var max_radius := 145.0
var duration := 0.32
var elapsed := 0.0

func _ready() -> void:
	z_index = 4

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var radius := max_radius * progress
	var alpha := 1.0 - progress
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.48, 0.12, alpha * 0.25))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.82, 0.34, alpha), 8.0 * alpha)
	draw_arc(Vector2.ZERO, radius * 0.68, 0.0, TAU, 32, Color(1.0, 0.32, 0.12, alpha * 0.8), 4.0 * alpha)