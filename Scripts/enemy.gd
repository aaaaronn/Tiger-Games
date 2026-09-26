extends Area2D

const ENEMY_SPRITES: Array[Texture2D] = [
	preload("res://Assets/Godot.png"),
	preload("res://Assets/Godot (1).png"),
	preload("res://Assets/Godot (2).png")
]

signal died(enemy: Node2D)

const EXPLOSION_RADIUS := 145.0
const ExplosionEffect = preload("res://Scripts/explosion_effect.gd")

var target: Node2D
var kind := "walker"
var speed := 60.0
var health := 2
var max_health := 2
var damage := 10
var score_value := 10
var xp_value := 1
var level := 1
var body_radius := 16.0
var sprite_tier := 1
var generated_sprites: Array[Texture2D] = []
var hit_flash := 0.0
var speed_multiplier := 1.0
var damage_multiplier := 1.0
var has_died := false
var boss_variant := "burst"
var behaviors: Array = []

func configure(archetype: Resource, wave: int, player_target: Node2D, variant := "burst", tier_sprites: Array[Texture2D] = []) -> void:
	kind = String(archetype.id)
	target = player_target
	level = maxi(1, 1 + floori(float(wave - 1) / 5.0))
	body_radius = archetype.collision_radius
	sprite_tier = archetype.sprite_tier
	generated_sprites = tier_sprites
	boss_variant = variant
	var stats: Dictionary = archetype.stats_for_wave(wave, level)
	max_health = stats.health
	health = max_health
	speed = stats.speed
	damage = stats.damage
	score_value = stats.score
	xp_value = stats.xp
	for behavior_script in archetype.behavior_components:
		var behavior = behavior_script.new()
		behavior.setup(self)
		behaviors.append(behavior)

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

func _exit_tree() -> void:
	for behavior in behaviors:
		behavior.cleanup()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if target.get_parent().game_over or target.get_parent().in_shop:
		return
	for behavior in behaviors:
		if behavior.before_move(delta):
			return
	position += position.direction_to(target.position) * speed * speed_multiplier * delta
	hit_flash = max(0.0, hit_flash - delta)
	for behavior in behaviors:
		behavior.after_move(delta)
	if has_died:
		return
	var distance_to_target := global_position.distance_to(target.global_position)
	var prevents_contact_damage := false
	for behavior in behaviors:
		prevents_contact_damage = prevents_contact_damage or behavior.prevents_contact_damage()
	if distance_to_target < collision_radius() + 18.0 and not prevents_contact_damage:
		target.take_damage(int(float(damage) * damage_multiplier))
		queue_free()
	queue_redraw()

func detonate() -> void:
	if has_died:
		return
	has_died = true
	var effect = ExplosionEffect.new()
	effect.max_radius = EXPLOSION_RADIUS
	get_parent().add_child(effect)
	effect.global_position = global_position
	var explosion_damage := damage
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= EXPLOSION_RADIUS:
		target.take_damage(explosion_damage)
	for other in get_tree().get_nodes_in_group("enemies"):
		if other != self and is_instance_valid(other) and global_position.distance_to(other.global_position) <= EXPLOSION_RADIUS:
			other.take_damage(explosion_damage)
	died.emit(self)
	queue_free()

func take_damage(amount: int) -> void:
	if has_died:
		return
	health -= amount
	hit_flash = 0.1
	if health <= 0:
		for behavior in behaviors:
			if behavior.on_zero_health():
				return
		has_died = true
		for behavior in behaviors:
			behavior.on_death()
		died.emit(self)
	queue_redraw()

func fire_spit() -> void:
	var projectile: Area2D = preload("res://Scripts/enemy_projectile.gd").new()
	projectile.position = position
	projectile.direction = position.direction_to(target.position)
	projectile.damage = damage
	get_parent().add_child(projectile)

func spawn_boss_runners() -> void:
	for child_index in 4:
		get_parent().spawn_enemy(child_index, 4)

func collision_radius() -> float:
	return body_radius

func enemy_sprite() -> Texture2D:
	var tier := mini(sprite_tier + level - 1, ENEMY_SPRITES.size())
	if generated_sprites.size() == ENEMY_SPRITES.size():
		return generated_sprites[tier - 1]
	return ENEMY_SPRITES[tier - 1]

func _draw() -> void:
	var radius := body_radius
	var bar_width := radius * 2.8
	if health < max_health:
		draw_rect(Rect2(-bar_width / 2.0, -radius - 10.0, bar_width, 5.0), Color("08100e"))
		draw_rect(Rect2(-bar_width / 2.0, -radius - 10.0, bar_width * clamp(float(health) / float(max_health), 0.0, 1.0), 5.0), Color("68d391"))
	draw_circle(Vector2.ZERO, radius + 3.0, Color("08100e"))
	var sprite_size := radius * 2.2
	draw_texture_rect(enemy_sprite(), Rect2(-sprite_size / 2.0, -sprite_size / 2.0, sprite_size, sprite_size), false)
	for behavior in behaviors:
		behavior.draw_component()
