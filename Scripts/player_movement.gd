extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 20.0
@export var friction: float = 20.0
@export var fire_rate: float = 0.24
@export var max_health: int = 100
@export var pickup_radius: float = 110.0
@export var max_attack_range: float = 300.0

@onready var targeting_area: Area2D = $TargetingArea

var fire_clock := 0.0
var weapon_damage := 1
var weapon_type := "pistol"
var weapon_level := 1
var weapon_levels: Dictionary = {}
var aim_direction := Vector2.RIGHT
var health := 100
var invulnerability_clock := 0.0
var hit_flash := 0.0

func _ready() -> void:
	z_index = 2
	queue_redraw()

func _physics_process(delta: float) -> void:
	invulnerability_clock = max(0.0, invulnerability_clock - delta)
	hit_flash = max(0.0, hit_flash - delta)
	if get_parent().game_over or get_parent().in_shop:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	if input_dir != Vector2.ZERO:
		velocity = velocity.lerp(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)

	move_and_slide()
	var arena: Rect2 = get_parent().arena_rect
	global_position.x = clamp(global_position.x, arena.position.x + 25.0, arena.end.x - 25.0)
	global_position.y = clamp(global_position.y, arena.position.y + 25.0, arena.end.y - 25.0)
	fire_clock -= delta
	if fire_clock <= 0.0:
		var closest := get_closest_enemy()
		if closest:
			aim_direction = global_position.direction_to(closest.global_position)
			get_parent().fire_at(closest)
			fire_clock = fire_rate
	queue_redraw()

func take_damage(amount: int) -> void:
	if invulnerability_clock > 0.0 or get_parent().game_over:
		return
	health = maxi(0, health - amount)
	invulnerability_clock = 0.45
	hit_flash = 0.15
	if health <= 0:
		get_parent().trigger_game_over()
	queue_redraw()

func apply_knockback(force: Vector2) -> void:
	velocity += force

func increase_attack_range(amount: float) -> void:
	max_attack_range += amount
	var shape := targeting_area.get_node("CollisionShape2D").shape as CircleShape2D
	shape.radius = max_attack_range
	queue_redraw()

func get_closest_enemy() -> Node2D:
	var closest: Node2D
	var closest_distance := max_attack_range * max_attack_range
	var nearby_enemies := targeting_area.get_overlapping_areas()
	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance := global_position.distance_squared_to(enemy.global_position)
			if distance <= closest_distance:
				closest = enemy
				closest_distance = distance
	if closest:
		return closest
	# Physics overlaps update on the server tick; use the group as a brief spawn-time fallback.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var distance := global_position.distance_squared_to(enemy.global_position)
			if distance <= closest_distance:
				closest = enemy
				closest_distance = distance
	return closest

func _draw() -> void:
	draw_arc(Vector2.ZERO, max_attack_range, 0.0, TAU, 96, Color(0.35, 0.82, 0.68, 0.16), 2.0)
	if health < max_health:
		draw_rect(Rect2(-28, -38, 56, 6), Color("08100e"))
		draw_rect(Rect2(-28, -38, 56.0 * clamp(float(health) / float(max_health), 0.0, 1.0), 6), Color("53c7a1"))
	var player_color := Color("53c7a1") if hit_flash <= 0.0 else Color.WHITE
	var gun_color := Color("d5e4db")
	var gun_length := 30.0
	draw_line(Vector2.ZERO + aim_direction * 10.0, aim_direction * gun_length, Color("08100e"), 9.0)
	draw_line(Vector2.ZERO + aim_direction * 10.0, aim_direction * gun_length, gun_color, 5.0)
	draw_circle(Vector2.ZERO, 22.0, Color("08100e"))
	draw_circle(Vector2.ZERO, 18.0, player_color)
	draw_circle(Vector2(0, -3), 9.0, Color("b5f2ce"))
	draw_circle(Vector2(-4, -5), 2.0, Color("16322b"))
	draw_circle(Vector2(4, -5), 2.0, Color("16322b"))
	draw_line(Vector2(-7, 8), Vector2(7, 8), Color("16322b"), 2.0)
