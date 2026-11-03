extends RefCounted
class_name RescueSettings

static var difficulty: String = "normal"

static func all() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/difficulty.json"))
	return parsed if parsed is Dictionary else {}

static func selected() -> Dictionary:
	return all().get(difficulty, all().get("normal", {}))

const BATTLE_PATH := "user://battle11-settings.cfg"

static func battle_value(key: String) -> Variant:
	var config := ConfigFile.new()
	config.load(BATTLE_PATH)
	return config.get_value("battle", key, true if key == "fast_enemy" or key == "auto_select" else false)

static func set_battle_value(key: String, value: bool) -> bool:
	if key not in ["fast_enemy", "auto_select"]: return false
	var config := ConfigFile.new()
	config.load(BATTLE_PATH)
	config.set_value("battle", key, value)
	return config.save(BATTLE_PATH) == OK

static func enemy_speed() -> float:
	return 2.0 if battle_value("fast_enemy") else 1.0
