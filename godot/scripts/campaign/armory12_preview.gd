extends RefCounted
const Gear = preload("res://scripts/campaign/gear.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func changes(c, id: String, action: String, kind: String = "", key: String = "") -> Array:
	var r: Dictionary = c.soldier(id)
	if r.is_empty(): return []
	var before: Dictionary = Gear.battle_stats(c, id)
	var saved: Dictionary = r.gear.duplicate(true)
	var had_evo := r.has("evo")
	var old_evo: bool = bool(r.get("evo", false))
	match action:
		"weapon": r.gear.w = int(r.gear.w) + 1
		"saber": r.gear.saber = int(r.gear.saber) + 1
		"armor": r.gear.armor = key
		"utility": r.gear.util = key
		"form": r.gear.form = key
		"fit":
			if Gear.MOD_KEY.has(kind):
				r.gear[Gear.MOD_KEY[kind]].append(key)
				r.gear.mk[kind + "." + key] = 1
		"remove":
			if Gear.MOD_KEY.has(kind): r.gear[Gear.MOD_KEY[kind]].erase(key)
		"upgrade": r.gear.mk[kind + "." + key] = int(r.gear.mk.get(kind + "." + key, 1)) + 1
		"base_mark": r.gear.mk[kind] = int(r.gear.mk.get(kind, 1)) + 1
		"armor_mark":
			var armor_key := "armor:" + str(r.gear.armor)
			r.gear.mk[armor_key] = int(r.gear.mk.get(armor_key, 1)) + 1
		"evolve": r.evo = true
	var after: Dictionary = Gear.battle_stats(c, id)
	r.gear = saved
	if had_evo: r.evo = old_evo
	else: r.erase("evo")
	var out := []
	for field in ["aim", "mob", "hp", "armor", "crit", "dodge", "will", "deflect", "range", "maxF", "kits", "nades"]:
		var delta := int(after.get(field, 0)) - int(before.get(field, 0))
		if delta != 0: out.append({"name": _name(field), "value": delta})
	var first: Array = before.get("dmg", [0, 0]); var second: Array = after.get("dmg", [0, 0])
	if int(second[0]) != int(first[0]) or int(second[1]) != int(first[1]):
		out.append({"name": "damage", "value": int(second[0]) - int(first[0]), "high": int(second[1]) - int(first[1])})
	return out

static func _name(field: String) -> String:
	return {"mob":"move", "hp":"HP", "maxF":"max Focus", "kits":"medpacs", "nades":"grenades"}.get(field, field)

static func text_for(change: Dictionary) -> String:
	var value := int(change.value)
	if change.has("high") and int(change.high) != value:
		return "%+d/%+d %s" % [value, int(change.high), str(change.name)]
	return "%+d %s" % [value, str(change.name)]
