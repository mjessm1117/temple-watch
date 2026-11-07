extends RefCounted
## Shared contract for class data. Class files own their abilities and tactical kits.
const ROOT = "res://data/classes/"
const IDS = {
	"jedi": ["guardian", "knight", "duelist", "sage", "consular", "sentinel", "wayseeker"],
	"soldier": ["trooper", "heavy", "sniper", "scout", "medic", "tech", "droid", "officer"]
}
static var cache: Dictionary = {}
static var rank_cache: Dictionary = {}

static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func classes() -> Dictionary:
	if cache.is_empty():
		for side in IDS:
			for id in IDS[side]:
				var row := _read(ROOT + side + "/" + id + ".json")
				if not row.is_empty(): cache[id] = row
	return cache

static func class_id(name: String) -> String:
	var id := name.to_lower()
	return "trooper" if id == "soldier" else id

static func class_data(name: String) -> Dictionary:
	return classes().get(class_id(name), {})

static func side(name: String) -> String:
	return str(class_data(name).get("side", ""))

static func ranks(side_name: String) -> Array:
	if rank_cache.is_empty(): rank_cache = _read(ROOT + "ranks.json")
	return rank_cache.get(side_name, [])

static func rank_data(side_name: String, level: int) -> Dictionary:
	var rows := ranks(side_name)
	return rows[clampi(level - 1, 0, rows.size() - 1)] if not rows.is_empty() else {}

static func power(side_name: String, level: int) -> int:
	return int(rank_data(side_name, level).get("power", 0))

static func blend_slots(side_name: String, level: int) -> int:
	if side_name == "jedi": return 3 if level >= 5 else 2 if level >= 3 else 1
	return 3 if level >= 6 else 2 if level >= 4 else 1

static func can_blend(unit: Dictionary, new_class: String) -> bool:
	var primary := str(unit.get("cls", ""))
	var desired := class_id(new_class)
	var origin := side(primary)
	if origin == "" or side(desired) != origin: return false
	var current: Array = unit.get("classes", [class_id(primary)])
	if current.has(desired) or current.size() >= 3: return false
	return current.size() < blend_slots(origin, int(unit.get("rank", 1)))

static func cross_train(unit: Dictionary, new_class: String) -> bool:
	if not can_blend(unit, new_class): return false
	if not unit.has("classes"): unit.classes = [class_id(str(unit.cls))]
	unit.classes.append(class_id(new_class))
	return true

static func ability_cap(unit: Dictionary, path_name: String) -> int:
	if class_id(path_name) == class_id(str(unit.get("cls", ""))): return int(unit.get("rank", 1))
	return 5 if class_id(str(unit.get("cls", ""))) == "knight" else 4

static func ability_catalog() -> Dictionary:
	var out: Dictionary = _read("res://data/abilities.json")
	for row in classes().values():
		for id in row.get("abilities", {}): out[id] = row.abilities[id].duplicate(true)
	return out

static func apply_to_units(catalog: Dictionary) -> void:
	for row in classes().values():
		var kind := str(row.get("unit_kind", ""))
		if kind == "" or row.get("unit_stats", {}).is_empty(): continue
		if not catalog.has(kind): catalog[kind] = {"name":str(row.name), "class_name":str(row.name), "side":"player"}
		if str(catalog[kind].get("side", "")) != "player": continue
		for key in row.unit_stats: catalog[kind][key] = row.unit_stats[key]
		catalog[kind].kit = row.get("kit", []).duplicate()
		catalog[kind].passives = row.get("passives", []).duplicate()

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for side_name in IDS:
		for id in IDS[side_name]:
			var row := class_data(id)
			if row.is_empty(): errors.append("Missing " + id); continue
			if row.get("schema") != 1 or row.get("id") != id or row.get("side") != side_name: errors.append("Identity " + id)
			for key in ["name", "role", "signature", "branches", "implemented", "unit_kind", "base_stats", "unit_stats", "kit", "passives", "bonus_kit", "bonus_passives", "tree", "abilities"]:
				if not row.has(key): errors.append("%s lacks %s" % [id, key])
			if not row.get("base_stats", {}) is Dictionary or not row.get("unit_stats", {}) is Dictionary: errors.append("Invalid stats " + id)
			if not row.get("kit", []) is Array or not row.get("abilities", {}) is Dictionary: errors.append("Invalid kit/abilities " + id); continue
			for ability in row.get("kit", []) + row.get("bonus_kit", []):
				if not row.get("abilities", {}).has(ability): errors.append("%s lacks ability %s" % [id, ability])
			for ability in row.abilities:
				var def: Dictionary = row.abilities[ability]
				if not def.has("name") or not def.has("effect") or not def.has("cost") or (not def.has("target") and not bool(def.get("passive", false))): errors.append("Bad ability %s/%s" % [id, ability])
				if seen.has(ability) and seen[ability] != def: errors.append("Conflicting ability " + ability)
				seen[ability] = def
	return errors
