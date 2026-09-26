extends RefCounted

const ShopItem = preload("res://Scripts/shop/shop_item.gd")
const WeaponShopItem = preload("res://Scripts/shop/weapon_shop_item.gd")
const PlayerStatEffect = preload("res://Scripts/shop/player_stat_effect.gd")
const WeaponLevelEffect = preload("res://Scripts/shop/weapon_level_effect.gd")

static func create_items() -> Array:
	return [
		stat_item("quick", "Quick Hands", "COMMON", "Fire 8% faster", "QH", PlayerStatEffect.Stat.FIRE_RATE, PlayerStatEffect.Operation.MULTIPLY, 0.92),
		stat_item("patch", "Patch Kit", "COMMON", "+10 max health and heal", "PK", PlayerStatEffect.Stat.MAX_HEALTH, PlayerStatEffect.Operation.ADD, 10.0, 10),
		stat_item("light", "Light Feet", "COMMON", "+12 movement speed", "LF", PlayerStatEffect.Stat.SPEED, PlayerStatEffect.Operation.ADD, 12.0),
		stat_item("sharp", "Sharpened Ammo", "COMMON", "+1 damage per shot", "SA", PlayerStatEffect.Stat.WEAPON_DAMAGE, PlayerStatEffect.Operation.ADD, 1.0),
		stat_item("range", "Range Finder", "COMMON", "+100 attack range", "RF", PlayerStatEffect.Stat.ATTACK_RANGE, PlayerStatEffect.Operation.ADD, 100.0),
		weapon_item("scatter", "Scattergun", "UNCOMMON", "Three shots in a fan", "SG"),
		weapon_item("pierce", "Railshot", "RARE", "Pierces through 3 enemies", "RS"),
		weapon_item("pulse", "Pulse Core", "RARE", "Two extra side projectiles", "PC"),
		stat_item("rapid", "Overclock", "UNCOMMON", "Fire 20% faster", "OC", PlayerStatEffect.Stat.FIRE_RATE, PlayerStatEffect.Operation.MULTIPLY, 0.8),
		stat_item("damage", "Heavy Rounds", "UNCOMMON", "+2 damage per shot", "HR", PlayerStatEffect.Stat.WEAPON_DAMAGE, PlayerStatEffect.Operation.ADD, 2.0),
		stat_item("vitality", "Field Rations", "UNCOMMON", "+25 max health and heal", "FR", PlayerStatEffect.Stat.MAX_HEALTH, PlayerStatEffect.Operation.ADD, 25.0, 25),
		stat_item("speed", "Combat Boots", "UNCOMMON", "+35 movement speed", "CB", PlayerStatEffect.Stat.SPEED, PlayerStatEffect.Operation.ADD, 35.0)
	]

static func stat_item(id: String, item_name: String, item_rarity: String, item_description: String, item_icon: String, stat: int, operation: int, amount: float, heal_amount := 0) -> Resource:
	var item: Resource = ShopItem.new()
	item.id = id
	item.display_name = item_name
	item.rarity = item_rarity
	item.description = item_description
	item.icon = item_icon
	var effect: Resource = PlayerStatEffect.new()
	effect.stat = stat
	effect.operation = operation
	effect.amount = amount
	effect.heal_amount = heal_amount
	item.effects.append(effect)
	return item

static func weapon_item(id: String, item_name: String, item_rarity: String, item_description: String, item_icon: String) -> Resource:
	var item: Resource = WeaponShopItem.new()
	item.id = id
	item.display_name = item_name
	item.tag = "WEAPON"
	item.rarity = item_rarity
	item.description = item_description
	item.icon = item_icon
	var effect: Resource = WeaponLevelEffect.new()
	effect.weapon_kind = id
	item.effects.append(effect)
	return item