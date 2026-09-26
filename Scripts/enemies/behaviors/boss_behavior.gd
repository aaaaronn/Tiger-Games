extends "res://Scripts/enemies/enemy_behavior.gd"

var attack_clock := 1.5
var ability_used := false

func after_move(delta: float) -> void:
	attack_clock -= delta
	if attack_clock > 0.0:
		return
	use_ability()
	attack_clock = maxf(2.0, 5.0 - enemy.target.get_parent().wave * 0.04)

func use_ability() -> void:
	match enemy.boss_variant:
		"shockwave":
			if enemy.global_position.distance_to(enemy.target.global_position) < 360.0:
				enemy.target.take_damage(18 + enemy.target.get_parent().wave)
				enemy.target.apply_knockback(enemy.global_position.direction_to(enemy.target.global_position) * 360.0)
		"split":
			if enemy.health <= floori(float(enemy.max_health) / 2.0) and not ability_used:
				ability_used = true
				for child_index in 2:
					enemy.get_parent().call("spawn_enemy", child_index, 2)
			else:
				enemy.call("spawn_boss_runners")
		"harvest":
			enemy.health = mini(enemy.max_health, enemy.health + 18)
			enemy.call("spawn_boss_runners")
		_:
			enemy.call("spawn_boss_runners")