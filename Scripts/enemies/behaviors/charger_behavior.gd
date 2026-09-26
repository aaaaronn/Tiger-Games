extends "res://Scripts/enemies/enemy_behavior.gd"

const DASH_DURATION := 0.35

var dash_timer := 0.0
var windup := 0.0
var cooldown := 2.0
var direction := Vector2.ZERO
var origin := Vector2.ZERO
var distance := 0.0
var travelled := 0.0
var hit_player := false
var indicator: Node2D

func before_move(delta: float) -> bool:
	if dash_timer > 0.0:
		var step_time := minf(delta, dash_timer)
		var dash_start := enemy.global_position
		var dash_speed := distance / DASH_DURATION
		travelled = minf(distance, travelled + dash_speed * step_time)
		var dash_end := origin + direction * travelled
		var closest_point := Geometry2D.get_closest_point_to_segment(enemy.target.global_position, dash_start, dash_end)
		enemy.global_position = dash_end
		dash_timer = maxf(0.0, dash_timer - step_time)
		if not hit_player and closest_point.distance_to(enemy.target.global_position) < enemy.collision_radius() + 18.0:
			enemy.target.take_damage(enemy.damage)
			hit_player = true
		if dash_timer <= 0.0:
			enemy.global_position = origin + direction * distance
			clear_indicator()
		enemy.queue_redraw()
		return true
	if windup > 0.0:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			dash_timer = DASH_DURATION
			origin = enemy.global_position
			travelled = 0.0
			hit_player = false
		enemy.queue_redraw()
		return true
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown == 0.0 and enemy.global_position.distance_to(enemy.target.global_position) < 650.0:
		direction = enemy.global_position.direction_to(enemy.target.global_position)
		distance = float(enemy.target.get("max_attack_range"))
		windup = 0.45
		cooldown = 3.5
		create_indicator()
		enemy.queue_redraw()
		return true
	return false

func after_move(_delta: float) -> void:
	if hit_player and enemy.global_position.distance_to(enemy.target.global_position) >= enemy.collision_radius() + 18.0:
		hit_player = false

func prevents_contact_damage() -> bool:
	return hit_player

func cleanup() -> void:
	clear_indicator()

func create_indicator() -> void:
	clear_indicator()
	indicator = Node2D.new()
	indicator.z_index = 1
	enemy.get_parent().add_child(indicator)
	indicator.global_position = enemy.global_position
	var indicator_color := Color(0.94, 0.28, 0.24, 0.82)
	var shaft := Line2D.new()
	shaft.points = PackedVector2Array([Vector2.ZERO, direction * distance])
	shaft.width = 3.0
	shaft.default_color = indicator_color
	indicator.add_child(shaft)
	for side in [-1.0, 1.0]:
		var arrowhead := Line2D.new()
		arrowhead.points = PackedVector2Array([
			direction * distance,
			direction * distance - direction.rotated(side * 0.55) * 18.0
		])
		arrowhead.width = 4.0
		arrowhead.default_color = indicator_color
		indicator.add_child(arrowhead)

func clear_indicator() -> void:
	if is_instance_valid(indicator):
		indicator.queue_free()
	indicator = null