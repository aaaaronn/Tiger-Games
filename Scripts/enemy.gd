extends Area2D

signal died(enemy: Node2D)

var target: Node2D
var kind := "walker"
var speed := 60.0
var health := 2
var max_health := 2
var damage := 10
var score_value := 10
var xp_value := 1
var level := 1
var hit_flash := 0.0
var attack_clock := 1.5
var buff_clock := 0.0
var speed_multiplier := 1.0
var damage_multiplier := 1.0
var has_died := false
var boss_variant := "burst"
var boss_ability_used := false
var dash_timer := 0.0
var dash_cooldown := 2.0
var dash_direction := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = collision_radius()
	collision_shape.shape = circle_shape
	add_child(collision_shape)
	z_index = 2
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if target.get_parent().game_over or target.get_parent().in_shop:
		return
	if kind == "charger":
		if dash_timer > 0.0:
			position += dash_direction * (speed * 4.5) * delta
			dash_timer -= delta
			if position.distance_to(target.position) < collision_radius() + 18.0:
				target.take_damage(damage)
				queue_free()
				return
			queue_redraw()
			return
		dash_cooldown -= delta
		if dash_cooldown <= 0.0 and position.distance_to(target.position) < 650.0:
			dash_direction = position.direction_to(target.position)
			dash_timer = 0.5
			dash_cooldown = 3.5
			queue_redraw()
			return
	position += position.direction_to(target.position) * speed * speed_multiplier * delta
	hit_flash = max(0.0, hit_flash - delta)
	attack_clock -= delta
	if kind == "spitter":
		var distance_to_player := position.distance_to(target.position)
		if distance_to_player < 210.0:
			position += target.position.direction_to(position) * speed * delta * 1.5
		if attack_clock <= 0.0 and distance_to_player < 500.0:
			fire_spit()
			attack_clock = max(0.8, 2.2 - target.get_parent().wave * 0.03)
	elif kind == "screamer":
		if buff_clock <= 0.0:
			buff_nearby_enemies()
			buff_clock = 3.0
	elif (kind == "boss" or kind == "mini_boss") and attack_clock <= 0.0:
		use_boss_ability()
		attack_clock = max(2.0, 5.0 - target.get_parent().wave * 0.04)
	if position.distance_to(target.position) < collision_radius() + 18.0 and kind != "spitter":
		target.take_damage(int(float(damage) * damage_multiplier))
		queue_free()
	buff_clock -= delta
	queue_redraw()

func take_damage(amount: int) -> void:
	if has_died:
		return
	health -= amount
	hit_flash = 0.1
	if health <= 0:
		has_died = true
		died.emit(self)
	queue_redraw()

func fire_spit() -> void:
	var projectile: Area2D = preload("res://Scripts/enemy_projectile.gd").new()
	projectile.position = position
	projectile.direction = position.direction_to(target.position)
	projectile.damage = damage
	get_parent().add_child(projectile)

func buff_nearby_enemies() -> void:
	for other in get_tree().get_nodes_in_group("enemies"):
		if other != self and is_instance_valid(other) and position.distance_to(other.position) < 180.0:
			other.speed_multiplier = max(other.speed_multiplier, 1.22)
			other.damage_multiplier = max(other.damage_multiplier, 1.15)

func spawn_boss_runners() -> void:
	for child_index in 4:
		get_parent().spawn_enemy(child_index, 4)

func use_boss_ability() -> void:
	match boss_variant:
		"shockwave":
			if position.distance_to(target.position) < 360.0:
				target.take_damage(18 + target.get_parent().wave)
				target.apply_knockback(position.direction_to(target.position) * 360.0)
		"split":
			if health <= floori(float(max_health) / 2.0) and not boss_ability_used:
				boss_ability_used = true
				for child_index in 2:
					get_parent().spawn_enemy(child_index, 2)
			else:
				spawn_boss_runners()
		"harvest":
			health = mini(max_health, health + 18)
			spawn_boss_runners()
		_:
			spawn_boss_runners()

func collision_radius() -> float:
	match kind:
		"runner":
			return 12.0
		"dart":
			return 9.0
		"charger":
			return 15.0
		"brute":
			return 22.0
		"boss":
			return 30.0
		"mini_boss":
			return 24.0
		_:
			return 16.0

func _draw() -> void:
	var body_color := Color("e45757")
	var radius := 13.0
	if kind == "runner":
		body_color = Color("e89b45")
		radius = 10.0
	elif kind == "dart":
		body_color = Color("f4df5c")
		radius = 8.0
	elif kind == "charger":
		body_color = Color("e86a4f")
		radius = 14.0
	elif kind == "brute":
		body_color = Color("a94f75")
		radius = 19.0
	elif kind == "spitter":
		body_color = Color("57a7c9")
		radius = 14.0
	elif kind == "screamer":
		body_color = Color("9f70d4")
		radius = 15.0
	elif kind == "swarmling":
		body_color = Color("d2c44d")
		radius = 9.0
	elif kind == "boss":
		body_color = Color("d95050")
		radius = 28.0
	elif kind == "mini_boss":
		body_color = Color("d47b45")
		radius = 23.0
	if hit_flash > 0.0:
		body_color = Color.WHITE
	if kind == "charger" and is_instance_valid(target) and (dash_timer > 0.0 or dash_cooldown <= 0.0):
		var projected_direction: Vector2 = dash_direction if dash_timer > 0.0 else position.direction_to(target.position)
		var projected_dash: Vector2 = projected_direction * min(position.distance_to(target.position), 520.0)
		draw_line(Vector2.ZERO, projected_dash, Color(0.95, 0.35, 0.25, 0.5), 3.0)
		draw_circle(projected_dash, 8.0, Color(0.95, 0.35, 0.25, 0.35))
	var bar_width := radius * 2.8
	if health < max_health:
		draw_rect(Rect2(-bar_width / 2.0, -radius - 10.0, bar_width, 5.0), Color("08100e"))
		draw_rect(Rect2(-bar_width / 2.0, -radius - 10.0, bar_width * clamp(float(health) / float(max_health), 0.0, 1.0), 5.0), Color("68d391"))
	draw_circle(Vector2.ZERO, radius + 3.0, Color("08100e"))
	draw_circle(Vector2.ZERO, radius, body_color)
	if kind == "boss" or kind == "mini_boss":
		draw_circle(Vector2(-9, -5), 4.0, Color("f6c453"))
		draw_circle(Vector2(9, -5), 4.0, Color("f6c453"))
		draw_line(Vector2(-12, 12), Vector2(12, 12), Color("101a19"), 4.0)
	elif kind == "brute":
		draw_circle(Vector2(-6, -3), 3.0, Color("101a19"))
		draw_circle(Vector2(6, -3), 3.0, Color("101a19"))
		draw_line(Vector2(-7, 8), Vector2(7, 8), Color("101a19"), 3.0)
	else:
		draw_circle(Vector2(-4, -2), 2.0, Color("101a19"))
		draw_circle(Vector2(4, -2), 2.0, Color("101a19"))
		draw_line(Vector2(-5, 6), Vector2(5, 6), Color("101a19"), 2.0)
