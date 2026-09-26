extends Control

@export var item_kind := "scatter"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var accent := Color("f6c453")
	draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color("0b1715"), true)
	draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), accent, false, 2.0)
	var center := size / 2.0
	match item_kind:
		"scatter":
			draw_rect(Rect2(center.x - 5, center.y - 15, 10, 30), accent, true)
			draw_line(Vector2(center.x - 16, center.y - 10), Vector2(center.x - 6, center.y - 20), Color.WHITE, 4.0)
			draw_line(Vector2(center.x + 16, center.y - 10), Vector2(center.x + 6, center.y - 20), Color.WHITE, 4.0)
			draw_circle(Vector2(center.x - 14, center.y + 14), 3.0, accent)
			draw_circle(Vector2(center.x, center.y + 18), 3.0, accent)
			draw_circle(Vector2(center.x + 14, center.y + 14), 3.0, accent)
		"pierce":
			draw_colored_polygon(PackedVector2Array([Vector2(center.x, 7), Vector2(center.x + 15, center.y), Vector2(center.x, size.y - 7), Vector2(center.x - 15, center.y)]), accent)
			draw_line(Vector2(center.x - 18, center.y), Vector2(center.x + 18, center.y), Color.WHITE, 3.0)
		"pulse":
			draw_circle(center, 8.0, accent, false, 3.0)
			draw_arc(center, 16.0, -1.0, 1.0, 18, accent, 2.0)
			draw_arc(center, 16.0, 2.1, 4.1, 18, accent, 2.0)
		"rapid":
			draw_colored_polygon(PackedVector2Array([Vector2(center.x + 5, 6), Vector2(center.x - 10, center.y - 1), Vector2(center.x - 1, center.y - 1), Vector2(center.x - 7, size.y - 6), Vector2(center.x + 12, center.y + 3), Vector2(center.x + 3, center.y + 3)]), Color("72d6b0"))
		"damage":
			draw_circle(center, 10.0, Color("e45757"))
			draw_line(Vector2(center.x - 14, center.y + 14), Vector2(center.x + 14, center.y - 14), Color.WHITE, 4.0)
		"vitality":
			draw_rect(Rect2(center.x - 6, center.y - 17, 12, 34), Color("e88989"), true)
			draw_rect(Rect2(center.x - 17, center.y - 6, 34, 12), Color("e88989"), true)
		"speed":
			draw_colored_polygon(PackedVector2Array([Vector2(center.x - 14, center.y - 15), Vector2(center.x + 8, center.y - 15), Vector2(center.x + 17, center.y - 5), Vector2(center.x + 10, center.y + 14), Vector2(center.x - 15, center.y + 14)]), Color("72a8e8"))
			draw_line(Vector2(center.x - 10, center.y - 5), Vector2(center.x + 9, center.y - 5), Color.WHITE, 2.0)
		_:
			draw_circle(center, 12.0, accent)
