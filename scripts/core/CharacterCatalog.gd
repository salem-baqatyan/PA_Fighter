extends RefCounted
class_name CharacterCatalog

const DATA := {
	GameState.SWORD: {
		"display_name": "Sword Fighter",
		"max_hp": 120,
		"move_speed": 330.0,
		"acceleration": 1450.0,
		"deceleration": 1750.0,
		"dash_speed": 700.0,
		"dash_energy": 100.0,
		"dash_drain": 48.0,
		"dash_regen": 30.0,
		"attack_range": 128.0,
		"attack_width": 74.0,
		"attack_damage": [22, 24, 34],
		"attack_cooldown": 0.42,
		"attack_duration": 0.20,
		"combo_timeout": 0.85,
		"color": Color(0.95, 0.92, 0.76)
	},
	GameState.BOXER: {
		"display_name": "Boxer",
		"max_hp": 135,
		"move_speed": 360.0,
		"acceleration": 1650.0,
		"deceleration": 1900.0,
		"dash_speed": 650.0,
		"dash_energy": 100.0,
		"dash_drain": 42.0,
		"dash_regen": 36.0,
		"attack_range": 82.0,
		"attack_width": 58.0,
		"attack_damage": [14, 15, 24],
		"attack_cooldown": 0.24,
		"attack_duration": 0.14,
		"combo_timeout": 0.70,
		"color": Color(0.98, 0.70, 0.48)
	}
}

static func get_config(character_id: String) -> Dictionary:
	return DATA.get(character_id, DATA[GameState.SWORD]).duplicate(true)
