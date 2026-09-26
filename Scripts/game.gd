extends Node2D

const Enemy = preload("res://Scripts/enemy.gd")
const Bullet = preload("res://Scripts/bullet.gd")
const CardIcon = preload("res://Scripts/card_icon.gd")
const XpPickup = preload("res://Scripts/xp_pickup.gd")

var player: CharacterBody2D
var wave := 1
var score := 0
var experience := 0
var experience_to_next := 14
var level := 1
var pending_level_ups := 0
var elapsed := 0.0
var spawn_clock := 0.0
var wave_clock := 0.0
var wave_banner_clock := 2.5
var game_over := false
var in_shop := false
var shop_is_level_up := false
var kills := 0
var damage_upgrade := 0
var fire_rate_upgrade := 0
var move_speed_upgrade := 0
var clumps_remaining := 4
var mini_wave_index := 0
var mini_wave_total := 4
var enemies_planned := 0
var enemies_spawned := 0
var boss_variant := ""
var owned_kinds: Dictionary = {}
var bought_this_shop: Dictionary = {}
var arena_rect := Rect2(-1800.0, -1200.0, 3600.0, 2400.0)
var spawn_markers: Array[Dictionary] = []
var pending_spawn_amount := 0
var pending_spawn_positions: Array[Vector2] = []
var boss_spawned := false
var shop_options: Array[Dictionary] = []
var owned_counts: Dictionary = {}
var shop_catalog: Array[Dictionary] = [
	{"name": "Quick Hands", "tag": "SKILL", "rarity": "COMMON", "description": "Fire 8% faster", "kind": "quick", "icon": "QH"},
	{"name": "Patch Kit", "tag": "SKILL", "rarity": "COMMON", "description": "+10 max health and heal", "kind": "patch", "icon": "PK"},
	{"name": "Light Feet", "tag": "SKILL", "rarity": "COMMON", "description": "+12 movement speed", "kind": "light", "icon": "LF"},
	{"name": "Sharpened Ammo", "tag": "SKILL", "rarity": "COMMON", "description": "+1 damage per shot", "kind": "sharp", "icon": "SA"},
	{"name": "Range Finder", "tag": "SKILL", "rarity": "COMMON", "description": "+100 attack range", "kind": "range", "icon": "RF"},
	{"name": "Scattergun", "tag": "WEAPON", "rarity": "UNCOMMON", "description": "Three shots in a fan", "kind": "scatter", "icon": "SG"},
	{"name": "Railshot", "tag": "WEAPON", "rarity": "RARE", "description": "Pierces through 3 enemies", "kind": "pierce", "icon": "RS"},
	{"name": "Pulse Core", "tag": "WEAPON", "rarity": "RARE", "description": "Two extra side projectiles", "kind": "pulse", "icon": "PC"},
	{"name": "Overclock", "tag": "SKILL", "rarity": "UNCOMMON", "description": "Fire 20% faster", "kind": "rapid", "icon": "OC"},
	{"name": "Heavy Rounds", "tag": "SKILL", "rarity": "UNCOMMON", "description": "+2 damage per shot", "kind": "damage", "icon": "HR"},
	{"name": "Field Rations", "tag": "SKILL", "rarity": "UNCOMMON", "description": "+25 max health and heal", "kind": "vitality", "icon": "FR"},
	{"name": "Combat Boots", "tag": "SKILL", "rarity": "UNCOMMON", "description": "+35 movement speed", "kind": "speed", "icon": "CB"}
]

@onready var stats: Label = $Interface/Stats
@onready var wave_banner: Label = $Interface/WaveBanner
@onready var restart_button: Button = $Interface/RestartButton
@onready var shop_panel: Panel = $Interface/ShopPanel
@onready var shop_title: Label = $Interface/ShopPanel/ShopTitle
@onready var damage_button: Button = $Interface/ShopPanel/DamageButton
@onready var fire_rate_button: Button = $Interface/ShopPanel/FireRateButton
@onready var speed_button: Button = $Interface/ShopPanel/SpeedButton
@onready var shop_status: Label = $Interface/ShopPanel/ShopStatus
@onready var owned_items_bar: HBoxContainer = $Interface/OwnedItems
@onready var xp_bar: ProgressBar = $Interface/XpBar
@onready var card_icons: Array[Control] = [
	$Interface/ShopPanel/DamageButton/CardIcon,
	$Interface/ShopPanel/FireRateButton/CardIcon,
	$Interface/ShopPanel/SpeedButton/CardIcon
]
@onready var card_labels: Array[Label] = [
	$Interface/ShopPanel/DamageButton/CardText,
	$Interface/ShopPanel/FireRateButton/CardText,
	$Interface/ShopPanel/SpeedButton/CardText
]
@onready var card_costs: Array[Label] = [
	$Interface/ShopPanel/DamageButton/CardCost,
	$Interface/ShopPanel/FireRateButton/CardCost,
	$Interface/ShopPanel/SpeedButton/CardCost
]

func _ready() -> void:
	player = $Player
	restart_button.pressed.connect(restart_game)
	damage_button.pressed.connect(func(): buy_shop_option(0))
	fire_rate_button.pressed.connect(func(): buy_shop_option(1))
	speed_button.pressed.connect(func(): buy_shop_option(2))
	shop_panel.visible = false
	setup_wave(wave)
	update_owned_icons()
	queue_redraw()

func _process(delta: float) -> void:
	if game_over or in_shop:
		return
	elapsed += delta
	spawn_clock -= delta
	wave_clock += delta
	wave_banner_clock -= delta
	for marker in spawn_markers:
		marker.time -= delta
	spawn_markers = spawn_markers.filter(func(marker: Dictionary): return marker.time > 0.0)
	if pending_spawn_amount > 0 and spawn_clock <= 0.0:
		spawn_horde_at_positions(pending_spawn_amount, pending_spawn_positions)
		pending_spawn_amount = 0
		pending_spawn_positions.clear()
		spawn_clock = max(1.0, 1.9 - wave * 0.02) if clumps_remaining > 0 else 0.0
	if spawn_clock <= 0.0:
		if clumps_remaining > 0:
			queue_mini_wave()
			clumps_remaining -= 1
	if clumps_remaining <= 0 and pending_spawn_amount <= 0 and get_tree().get_nodes_in_group("enemies").is_empty():
		wave += 1
		setup_wave(wave)
		wave_banner_clock = 2.5
	if wave_banner_clock > 0.0:
		if is_boss_wave():
			wave_banner.text = "BIG BOSS WAVE %02d  |  %s" % [wave, boss_variant.to_upper()]
		elif is_mini_boss_wave():
			wave_banner.text = "MINI BOSS WAVE %02d" % wave
		else:
			wave_banner.text = "WAVE %02d" % wave
	else:
		wave_banner.text = ""
	var alive_enemies := get_tree().get_nodes_in_group("enemies").size()
	stats.text = "LEVEL  %02d  XP %02d / %02d\nWAVE   %02d\nMINI  %02d / %02d\nHORDE  %02d / %02d" % [level, experience, experience_to_next, wave, mini_wave_index, mini_wave_total, alive_enemies, enemies_planned]
	xp_bar.max_value = experience_to_next
	xp_bar.value = experience
	queue_redraw()

func wave_duration() -> float:
	return max(14.0, 24.0 - wave * 0.12)

func open_shop() -> void:
	in_shop = true
	shop_is_level_up = true
	bought_this_shop.clear()
	shop_panel.visible = true
	shop_title.text = "LEVEL UP %02d  |  CHOOSE ONE UPGRADE" % level
	shop_status.text = "Choose one upgrade. The shop closes automatically after purchase."
	make_shop_options()
	refresh_shop_buttons()

func setup_wave(next_wave: int) -> void:
	wave_clock = 0.0
	spawn_clock = 0.0
	pending_spawn_amount = 0
	pending_spawn_positions.clear()
	spawn_markers.clear()
	boss_spawned = false
	mini_wave_index = 0
	mini_wave_total = mini(4 + floori(float(next_wave) / 3.0), 8)
	clumps_remaining = mini_wave_total
	enemies_spawned = 0
	enemies_planned = 0
	boss_variant = boss_ability_for_wave(next_wave)
	for mini_index in mini_wave_total:
		enemies_planned += mini_wave_size(mini_index)
	if is_boss_wave() or is_mini_boss_wave():
		enemies_planned += 1

func mini_wave_size(index: int) -> int:
	if index == 0:
		return mini(32 + wave * 6, 80)
	return mini(14 + wave * 3 + (index % 2) * 5, 42)

func spawn_mini_wave() -> void:
	if mini_wave_index == 0 and (is_boss_wave() or is_mini_boss_wave()):
		spawn_boss(is_boss_wave())
	var amount := mini_wave_size(mini_wave_index)
	spawn_horde(amount)
	mini_wave_index += 1
	enemies_spawned += amount

func queue_mini_wave() -> void:
	var amount := mini_wave_size(mini_wave_index)
	pending_spawn_amount = amount
	pending_spawn_positions.clear()
	for index in amount:
		pending_spawn_positions.append(random_spawn_position())
	spawn_markers.append({"positions": pending_spawn_positions.duplicate(), "time": 1.25})
	spawn_clock = 1.25
	mini_wave_index += 1
	enemies_spawned += amount

func spawn_horde_at_positions(amount: int, positions: Array[Vector2]) -> void:
	spawn_markers.clear()
	if is_boss_wave() and not boss_spawned:
		spawn_boss(true)
		boss_spawned = true
	elif is_mini_boss_wave() and not boss_spawned:
		spawn_boss(false)
		boss_spawned = true
	for index in amount:
		spawn_enemy(index, amount, positions[index])

func boss_ability_for_wave(boss_wave: int) -> String:
	match (floori(float(boss_wave) / 10.0)) % 4:
		1:
			return "shockwave"
		2:
			return "split"
		3:
			return "harvest"
		_:
			return "burst"

func refresh_shop_buttons() -> void:
	var buttons := [damage_button, fire_rate_button, speed_button]
	for index in buttons.size():
		if index >= shop_options.size():
			card_labels[index].text = "SOLD OUT\nNO NEW ITEM"
			card_costs[index].text = ""
			buttons[index].disabled = true
			buttons[index].remove_theme_stylebox_override("disabled")
			buttons[index].self_modulate = Color.WHITE
			card_icons[index].visible = false
			continue
		var option := shop_options[index]
		card_icons[index].visible = true
		card_icons[index].set("item_kind", option.kind)
		card_icons[index].queue_redraw()
		card_labels[index].text = "%s\n%s  |  %s\n%s" % [option.name.to_upper(), option.tag, option.rarity, option.description]
		card_costs[index].text = "LEVEL UP REWARD"
		var already_bought := bought_this_shop.has(option.kind)
		buttons[index].disabled = already_bought
		if already_bought:
			card_labels[index].text = "PURCHASED\n%s\n%s" % [option.name.to_upper(), option.rarity]
			card_costs[index].text = "OWNED"
			set_card_disabled_style(buttons[index], Color(0.32, 0.35, 0.34, 0.82), Color(0.72, 0.75, 0.74, 0.9))
			card_icons[index].modulate = Color(0.58, 0.6, 0.59, 0.7)
		else:
			buttons[index].self_modulate = Color.WHITE
			card_icons[index].modulate = Color.WHITE
			buttons[index].remove_theme_stylebox_override("disabled")
			buttons[index].add_theme_color_override("font_color_disabled", Color("dce8df"))

func set_card_disabled_style(button: Button, background: Color, border: Color) -> void:
	button.self_modulate = Color.WHITE
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color_disabled", border)

func make_shop_options() -> void:
	shop_options.clear()
	var pool: Array[Dictionary] = []
	for item in shop_catalog:
		var weight := rarity_weight(item.rarity)
		for copy in weight:
			pool.append(item)
	for index in mini(3, pool.size()):
		var pick := randi() % pool.size()
		var selected: Dictionary = pool[pick]
		shop_options.append(selected)
		pool = pool.filter(func(item: Dictionary): return item.kind != selected.kind)

func rarity_weight(rarity: String) -> int:
	match rarity:
		"COMMON":
			return 8
		"UNCOMMON":
			return 4
		"RARE":
			return 2
		_:
			return 1

func buy_shop_option(index: int) -> void:
	if index >= shop_options.size():
		return
	var option := shop_options[index]
	if bought_this_shop.has(option.kind):
		return
	apply_shop_option(option.kind)
	owned_kinds[option.kind] = option
	owned_counts[option.kind] = int(owned_counts.get(option.kind, 0)) + 1
	bought_this_shop[option.kind] = true
	update_owned_icons()
	shop_status.text = "%s acquired." % option.name
	close_level_up_shop()

func apply_shop_option(kind: String) -> void:
	match kind:
		"quick":
			player.fire_rate = max(0.09, player.fire_rate * 0.92)
		"patch":
			player.max_health += 10
			player.health = mini(player.max_health, player.health + 10)
		"light":
			player.speed += 12.0
		"sharp":
			player.weapon_damage += 1
		"range":
			player.increase_attack_range(100.0)
		"scatter", "pierce", "pulse":
			player.weapon_type = kind
			player.weapon_levels[kind] = int(player.weapon_levels.get(kind, 0)) + 1
			player.weapon_level = player.weapon_levels[kind]
		"rapid":
			player.fire_rate = max(0.09, player.fire_rate * 0.8)
			fire_rate_upgrade += 1
		"damage":
			player.weapon_damage += 1
			damage_upgrade += 1
		"vitality":
			player.max_health += 25
			player.health = mini(player.max_health, player.health + 25)
		"speed":
			player.speed += 35.0
			move_speed_upgrade += 1

func close_level_up_shop() -> void:
	in_shop = false
	shop_panel.visible = false
	shop_is_level_up = false
	pending_level_ups = maxi(0, pending_level_ups - 1)
	if pending_level_ups > 0:
		call_deferred("open_shop")

func spawn_horde(amount: int = -1) -> void:
	var horde_size := amount if amount > 0 else mini(24 + wave * 5, 80)
	for index in horde_size:
		spawn_enemy(index, horde_size, random_spawn_position())

func spawn_enemy(_index: int = 0, _horde_size: int = 1, spawn_position: Vector2 = Vector2.ZERO) -> void:
	var enemy := Enemy.new()
	var kind := choose_enemy_type()
	enemy.position = spawn_position if spawn_position != Vector2.ZERO else random_spawn_position()
	enemy.target = player
	enemy.kind = kind
	match kind:
		"runner":
			enemy.max_health = 2 + floori(float(wave) / 3.0)
			enemy.speed = 132.0 + wave * 3.0 + randf_range(-12.0, 12.0)
			enemy.damage = 7 + floori(float(wave) / 4.0)
			enemy.score_value = 15
		"charger":
			enemy.max_health = 3 + floori(float(wave) / 4.0)
			enemy.speed = 76.0 + wave * 2.0
			enemy.damage = 18 + wave
			enemy.score_value = 28
		"dart":
			enemy.max_health = 1 + floori(float(wave) / 10.0)
			enemy.speed = 178.0 + wave * 3.5 + randf_range(-14.0, 14.0)
			enemy.damage = 9 + floori(float(wave) / 3.0)
			enemy.score_value = 18
		"brute":
			enemy.max_health = 9 + wave * 2
			enemy.speed = 42.0 + wave * 1.5 + randf_range(-5.0, 5.0)
			enemy.damage = 22 + wave
			enemy.score_value = 30
		"spitter":
			enemy.max_health = 5 + wave
			enemy.speed = 50.0 + wave * 1.8
			enemy.damage = 12 + wave
			enemy.score_value = 35
		"screamer":
			enemy.max_health = 7 + wave * 2
			enemy.speed = 46.0 + wave * 1.2
			enemy.damage = 8 + wave
			enemy.score_value = 45
		"swarmling":
			enemy.max_health = 3 + floori(float(wave) / 2.0)
			enemy.speed = 96.0 + wave * 2.5
			enemy.damage = 6 + floori(float(wave) / 3.0)
			enemy.score_value = 12
		_:
			enemy.max_health = 2 + floori(float(wave) / 3.0)
			enemy.speed = 68.0 + wave * 2.5 + randf_range(-10.0, 10.0)
			enemy.damage = 10 + floori(float(wave) / 3.0)
			enemy.score_value = 10
	enemy.health = enemy.max_health
	enemy.level = max(1, 1 + floori(float(wave - 1) / 5.0))
	enemy.xp_value = 1 if kind == "dart" else 1 + enemy.level + (2 if kind == "brute" or kind == "boss" else 0)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func spawn_boss(is_big: bool = true) -> void:
	var boss := Enemy.new()
	boss.position = random_spawn_position(randf() * TAU)
	boss.target = player
	boss.kind = "boss" if is_big else "mini_boss"
	boss.max_health = (100 + wave * 24) if is_big else (60 + wave * 12)
	boss.health = boss.max_health
	boss.speed = (38.0 + wave * 0.8) if is_big else (54.0 + wave * 1.2)
	boss.damage = (28 + wave * 2) if is_big else (20 + wave)
	boss.score_value = (250 + wave * 10) if is_big else (100 + wave * 5)
	boss.level = max(1, 1 + floori(float(wave - 1) / 5.0))
	boss.xp_value = 5 + boss.level * 2
	boss.boss_variant = boss_variant
	boss.died.connect(_on_enemy_died)
	add_child(boss)

func is_boss_wave() -> bool:
	return wave % 10 == 0

func is_mini_boss_wave() -> bool:
	return wave % 5 == 0 and not is_boss_wave()

func choose_enemy_type() -> String:
	var roll := randf()
	if wave >= 8 and roll > 0.96:
		return "swarmling"
	if wave >= 3 and roll > 0.9:
		return "charger"
	if wave >= 2 and roll < min(0.14 + wave * 0.018, 0.3):
		return "dart"
	if wave >= 6 and roll > 0.84:
		return "screamer"
	if wave >= 5 and roll > 0.72:
		return "spitter"
	if wave >= 3 and roll > 0.78:
		return "brute"
	return "walker"

func random_spawn_position(_angle: float = -1.0) -> Vector2:
	var edge := randi() % 4
	match edge:
		0:
			return Vector2(randf_range(arena_rect.position.x, arena_rect.end.x), arena_rect.position.y + 18.0)
		1:
			return Vector2(arena_rect.end.x - 18.0, randf_range(arena_rect.position.y, arena_rect.end.y))
		2:
			return Vector2(randf_range(arena_rect.position.x, arena_rect.end.x), arena_rect.end.y - 18.0)
		_:
			return Vector2(arena_rect.position.x + 18.0, randf_range(arena_rect.position.y, arena_rect.end.y))

func fire_at(target: Node2D) -> void:
	if not is_instance_valid(target) or player.global_position.distance_to(target.global_position) > player.max_attack_range:
		return
	var direction := player.position.direction_to(target.position)
	player.aim_direction = direction
	var selected_weapon_level: int = player.weapon_levels.get(player.weapon_type, 0)
	var spread_count := 1
	if player.weapon_type == "scatter":
		spread_count = mini(3 + selected_weapon_level - 1, 6)
	elif player.weapon_type == "pulse":
		spread_count = mini(3 + selected_weapon_level - 1, 5)
	for shot_index in spread_count:
		var bullet := Bullet.new()
		bullet.position = player.position
		var spread := 0.0
		if player.weapon_type == "scatter":
			spread = float(shot_index - 1) * 0.2
		elif player.weapon_type == "pulse":
			spread = float(shot_index - 1) * 0.32
		bullet.direction = direction.rotated(spread)
		bullet.damage = player.weapon_damage + (selected_weapon_level - 1 if player.weapon_type == "pierce" else 0)
		bullet.pierce = mini(selected_weapon_level, 6) if player.weapon_type == "pierce" else 0
		add_child(bullet)

func _on_enemy_died(enemy: Node2D) -> void:
	score += enemy.score_value if "score_value" in enemy else 10
	kills += 1
	spawn_xp_drop(enemy.position, enemy.xp_value if "xp_value" in enemy else 1)
	if enemy.kind == "swarmling" and wave >= 8:
		for child_index in 3:
			spawn_enemy(0, 1)
	if is_instance_valid(enemy):
		enemy.queue_free()

func spawn_xp_drop(drop_position: Vector2, value: int) -> void:
	var pickup := XpPickup.new()
	pickup.position = drop_position
	pickup.value = value
	pickup.target = player
	add_child(pickup)

func collect_xp(value: int) -> void:
	experience += value
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next = experience_required_for_level(level)
		pending_level_ups += 1
	if not in_shop and pending_level_ups > 0:
		open_shop()

func experience_required_for_level(target_level: int) -> int:
	if target_level <= 1:
		return 14
	var level_float := float(target_level)
	return 14 + floori(level_float * 10.0) + floori(pow(level_float, 1.5) * 2.0)

func trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	wave_banner.text = "OVERRUN"
	restart_button.visible = true
	shop_panel.visible = false

func restart_game() -> void:
	get_tree().reload_current_scene()

func update_owned_icons() -> void:
	if not is_instance_valid(owned_items_bar):
		return
	for child in owned_items_bar.get_children():
		child.queue_free()
	for item in owned_kinds.values():
		var icon := CardIcon.new()
		icon.item_kind = item.kind
		icon.custom_minimum_size = Vector2(42.0, 42.0)
		var count: int = owned_counts.get(item.kind, 1)
		icon.tooltip_text = item.name + " x" + str(count) + " - " + item.description
		if count > 1:
			var stack_label := Label.new()
			stack_label.text = "x" + str(count)
			stack_label.position = Vector2(24.0, 23.0)
			stack_label.add_theme_font_size_override("font_size", 12)
			stack_label.add_theme_color_override("font_color", Color("f6c453"))
			icon.add_child(stack_label)
		owned_items_bar.add_child(icon)

func _draw() -> void:
	# A simple patterned floor keeps the arena readable while the camera follows the player.
	draw_rect(Rect2(-2400, -1800, 4800, 3600), Color("101a19"))
	for x in range(-2400, 2401, 64):
		draw_line(Vector2(x, -1800), Vector2(x, 1800), Color("172623"), 1.0)
	for y in range(-1800, 1801, 64):
		draw_line(Vector2(-2400, y), Vector2(2400, y), Color("172623"), 1.0)
	draw_rect(arena_rect, Color("4f806d"), false, 4.0)
	for marker in spawn_markers:
		for spawn_position in marker.positions:
			draw_circle(spawn_position, 15.0, Color(0.94, 0.34, 0.28, 0.22))
			draw_arc(spawn_position, 15.0, 0.0, TAU, 16, Color("f06a5e"), 2.0)
			draw_line(spawn_position - Vector2(6, 6), spawn_position + Vector2(6, 6), Color("ffd0a8"), 2.0)
			draw_line(spawn_position + Vector2(6, -6), spawn_position - Vector2(6, 6), Color("ffd0a8"), 2.0)
