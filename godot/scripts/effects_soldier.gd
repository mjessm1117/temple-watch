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

static func damage_amount(target: Dictionary, amount: int) -> int:
	var shield := int(target.get("shield", 0))
	if str(target.get("class_name", "")).to_lower() != "droid" or amount - shield < int(target.get("hp", 0)): return amount
	# The chassis stays recoverable at one HP; Rebuild restores it in combat.
	target.wrecked = true
	target.ap = 0
	target.overwatch = false
	return shield + maxi(0, int(target.hp) - 1)
