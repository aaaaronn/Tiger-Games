extends Node2D

const Enemy = preload("res://Scripts/enemy.gd")
const Bullet = preload("res://Scripts/bullet.gd")

var player: CharacterBody2D
var wave := 1
var score := 0
var elapsed := 0.0
var spawn_clock := 0.0
var wave_clock := 0.0
var wave_banner_clock := 2.5
var game_over := false

@onready var stats: Label = $Interface/Stats
@onready var wave_banner: Label = $Interface/WaveBanner

func _ready() -> void:
	player = $Player
	queue_redraw()

func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	spawn_clock -= delta
	wave_clock += delta
	wave_banner_clock -= delta
	if spawn_clock <= 0.0:
		spawn_enemy()
		spawn_clock = max(0.22, 0.82 - wave * 0.035)
	if wave_clock >= 24.0:
		wave += 1
		wave_clock = 0.0
		wave_banner_clock = 2.5
	if wave_banner_clock > 0.0:
		wave_banner.text = "WAVE %02d" % wave
	else:
		wave_banner.text = ""
	stats.text = "SCORE  %05d\nWAVE   %02d\nTHREATS  %02d" % [score, wave, get_tree().get_nodes_in_group("enemies").size()]
	queue_redraw()

func spawn_enemy() -> void:
	var enemy := Enemy.new()
	enemy.position = random_spawn_position()
	enemy.target = player
	enemy.health = 2 + floori(float(wave) / 3.0)
	enemy.speed = 52.0 + wave * 2.0 + randf_range(-8.0, 8.0)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func random_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(430.0, 590.0)
	return player.position + Vector2(cos(angle), sin(angle)) * distance

func fire_at(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var bullet := Bullet.new()
	bullet.position = player.position
	bullet.direction = player.position.direction_to(target.position)
	add_child(bullet)

func _on_enemy_died(enemy: Node2D) -> void:
	score += 10
	if is_instance_valid(enemy):
		enemy.queue_free()

func _draw() -> void:
	# A simple patterned floor keeps the arena readable while the camera follows the player.
	draw_rect(Rect2(-2400, -1800, 4800, 3600), Color("101a19"))
	for x in range(-2400, 2401, 64):
		draw_line(Vector2(x, -1800), Vector2(x, 1800), Color("172623"), 1.0)
	for y in range(-1800, 1801, 64):
		draw_line(Vector2(-2400, y), Vector2(2400, y), Color("172623"), 1.0)