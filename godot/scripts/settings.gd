extends RefCounted
class_name RescueSettings

static var difficulty: String = "normal"

static func all() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/difficulty.json"))
	return parsed if parsed is Dictionary else {}

static func selected() -> Dictionary:
	return all().get(difficulty, all().get("normal", {}))
