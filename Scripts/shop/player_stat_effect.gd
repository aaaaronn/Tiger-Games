extends "res://Scripts/shop/shop_effect.gd"

enum Stat { FIRE_RATE, MAX_HEALTH, SPEED, WEAPON_DAMAGE, ATTACK_RANGE }
enum Operation { ADD, MULTIPLY }

@export var stat: Stat = Stat.WEAPON_DAMAGE
@export var operation: Operation = Operation.ADD
@export var amount := 0.0
@export var heal_amount := 0

func apply_to(player: CharacterBody2D, _game: Node) -> void:
	match stat:
		Stat.FIRE_RATE:
			var current_rate := float(player.get("fire_rate"))
			var value: float = current_rate * amount if operation == Operation.MULTIPLY else current_rate + amount
			player.fire_rate = maxf(0.09, value)
		Stat.MAX_HEALTH:
			player.max_health += roundi(amount)
			player.health = mini(player.max_health, player.health + heal_amount)
		Stat.SPEED:
			player.speed += amount
		Stat.WEAPON_DAMAGE:
			player.weapon_damage += roundi(amount)
		Stat.ATTACK_RANGE:
			player.increase_attack_range(amount)