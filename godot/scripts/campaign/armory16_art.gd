extends RefCounted
const ROOT := "res://assets/ui/armory16/"

static func texture_for(slot: String, jedi: bool, mark: int, color: String, fallback: String) -> Texture2D:
	var key := ""
	match slot:
		"weapon": key = "saber_mk%d" % clampi(mark, 1, 3) if jedi else "blaster"
		"armor": key = ("armor_jedi" if jedi else "armor_troop") + "_mk%d" % clampi(mark, 1, 3)
		"color":
			var tint := Color(color)
			key = "armor_mod" if not jedi else "crystal_white" if tint.r > 0.8 and tint.g > 0.8 and tint.b > 0.8 else "crystal_yellow" if tint.r > 0.8 and tint.g > 0.5 and tint.b < 0.6 else "crystal_red" if tint.r > tint.g * 1.6 and tint.r > tint.b * 1.4 else "crystal_purple" if tint.b > tint.g * 1.15 and tint.r > tint.g * 1.2 else "crystal_green" if tint.g > tint.b * 1.12 else "crystal_blue"
		"base_mod": key = "module"
		"armor_mod": key = "armor_mod"
	var path := ROOT + key + ".png"
	if not key.is_empty() and ResourceLoader.exists(path): return load(path)
	return load("res://assets/loadout/icons13/%s.png" % fallback)
