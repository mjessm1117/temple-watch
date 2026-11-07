extends RefCounted
## Soldier-specific rules that the shared chain engine and promotion view can call.
const Classes = preload("res://scripts/class_registry.gd")

static func module_data() -> Dictionary:
	return Classes.class_data("droid").get("modules", {})

static func selected_modules(unit: Dictionary) -> Array:
	var data := module_data()
	var chosen: Array = unit.get("droid_modules", []).duplicate()
	if chosen.size() != int(data.get("slots", 3)):
		chosen = data.get("default", []).duplicate()
	return chosen

static func module_abilities(unit: Dictionary) -> Array:
	var choices: Dictionary = module_data().get("choices", {})
	var out := []
	for key in selected_modules(unit):
		var ability := str(choices.get(str(key), {}).get("ability", ""))
		if ability != "": out.append(ability)
	return out

static func swap_module(unit: Dictionary, slot: int, module_id: String) -> bool:
	if Classes.class_id(str(unit.get("cls", ""))) != "droid": return false
	var data := module_data()
	if slot < 0 or slot >= int(data.get("slots", 3)) or not data.get("choices", {}).has(module_id): return false
	var chosen := selected_modules(unit)
	if chosen.has(module_id) and str(chosen[slot]) != module_id: return false
	if str(chosen[slot]) == module_id: return false
	chosen[slot] = module_id
	unit.droid_modules = chosen
	return true

static func damage_amount(target: Dictionary, amount: int, m: RefCounted = null, source: Dictionary = {}) -> int:
	var ability := str(source.get("active_ability", ""))
	if ability == "sniper_execution_order" and int(target.get("hp", 0)) * 2 <= int(target.get("max_hp", 0)):
		amount *= 2
	if ability == "sniper_ricochet" and not bool(source.get("ricochet_bouncing", false)):
		var nearest: Dictionary = {}
		var best := 999.0
		for other in m.living("enemy"):
			if other == target or int(other.get("hp", 0)) <= 0: continue
			var distance := Vector2i(int(other.x) - int(target.x), int(other.y) - int(target.y)).length()
			if distance < best and distance <= 4.0: nearest = other; best = distance
		if not nearest.is_empty():
			source.ricochet_bouncing = true
			m.apply_damage(nearest, maxi(1, amount / 2), source)
			source.erase("ricochet_bouncing")
	if ability == "sniper_spotter_round" and not bool(source.get("spotter_followup", false)):
		for ally in m.living("player"):
			if ally == source or int(ally.get("ammo", 0)) <= 0: continue
			source.spotter_followup = true
			ally.ammo = int(ally.ammo) - 1
			m.apply_damage(target, int(ally.get("damage", [2, 3])[0]), ally)
			source.erase("spotter_followup")
			m.message("%s follows the Spotter Round with a squadsight shot." % str(ally.get("name", "Ally")))
			break
	if ability == "tech_override" and bool(target.get("droid", false)):
		target.side = "player"
		target.ap = 0
		target.awake = true
		m.message("%s overrides %s." % [str(source.get("name", "Tech")), str(target.get("name", "Droid"))])
		return 0
	var shield := int(target.get("shield", 0))
	if str(target.get("class_name", "")).to_lower() != "droid" or amount - shield < int(target.get("hp", 0)): return amount
	# The chassis stays recoverable at one HP; Rebuild restores it in combat.
	target.wrecked = true
	target.ap = 0
	target.overwatch = false
	return shield + maxi(0, int(target.hp) - 1)
