extends RefCounted
## First matching ending wins. Conditions follow the ordered design-history endings.csv.

const PATH := "res://data/story/endings.json"

static func endings() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed.get("endings", []) if parsed is Dictionary else []

static func resolve(s: Dictionary) -> Dictionary:
	var flags: Dictionary = s.get("flags", {})
	var shadow := int(s.get("story", {}).get("shadow", 6))
	var dark := int(s.get("orderDark", 0))
	var arrested := bool(flags.get("sith_arrested", false))
	var chips := bool(flags.get("chips_all", false))
	var bane_dead := bool(flags.get("e2_bane_dead", false))
	var selected := "the_fire"
	if dark >= 20: selected = "dark_council"
	elif arrested and chips and shadow <= 3: selected = "dawn_unbroken"
	elif bane_dead and shadow <= 4: selected = "vision_fades"
	elif not arrested and shadow <= 6: selected = "long_exile"
	elif arrested and not chips: selected = "grey_peace"
	for row in endings():
		if str(row.get("id", "")) == selected: return row.duplicate(true)
	return {}

static func scene(s: Dictionary) -> Dictionary:
	var ending := resolve(s)
	if ending.is_empty(): return {}
	return {"kind":"ending", "id":ending.id, "title":ending.title,
		"eyebrow":"The vision resolves", "text":ending.text, "choices":[]}
