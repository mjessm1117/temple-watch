extends RefCounted
## One bounded visual motif and one synthesized sound for each common ability.

const PROFILES := {
	"rapidFire": {"shape":"triple", "sound":"rapid_fire", "spacing":0.075},
	"suppress": {"shape":"fan", "sound":"suppress", "spacing":0.10},
	"push": {"shape":"cone", "sound":"force_push", "spacing":0.12},
	"pull": {"shape":"inward", "sound":"force_pull", "spacing":0.14},
	"forceHeal": {"shape":"cross", "sound":"force_heal", "spacing":0.16},
	"barrier": {"shape":"hex", "sound":"barrier", "spacing":0.18},
	"saberThrow": {"shape":"arc", "sound":"saber_throw", "spacing":0.17},
	"grenade": {"shape":"burst", "sound":"grenade", "spacing":0.19},
}

const JEDI = ["guardian", "knight", "sage", "consular", "wayseeker"]
const SOLDIER = ["trooper", "heavy", "officer", "tech", "droid"]
const MELEE = ["duelist", "sentinel"]
const SUPPORT = ["medic"]
const RANGED = ["sniper", "scout"]
const Classes = preload("res://scripts/class_registry.gd")
static var _owners: Dictionary = {}
static var _owners_loaded := false

static func chain_ready(def: Dictionary, target: Dictionary, actor: Dictionary = {}) -> bool:
	var chain: Dictionary = def.get("chain", {})
	for entry in chain.get("consume", []):
		var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
		var recipient: Dictionary = actor if entry is Dictionary and str(entry.get("target", "target")) == "self" else target
		if tag != "" and recipient.get("combo_tags", {}).has(tag): return true
	return false

static func category(id: String, def: Dictionary = {}) -> String:
	var owner := id.get_slice("_", 0)
	if owner not in JEDI and owner not in SOLDIER and owner not in MELEE and owner not in SUPPORT and owner not in RANGED:
		if not _owners_loaded:
			_owners_loaded = true
			for class_id in Classes.classes():
				for ability_id in Classes.classes()[class_id].get("abilities", {}):
					if not _owners.has(ability_id): _owners[ability_id] = []
					_owners[ability_id].append(class_id)
		var owners: Array = _owners.get(id, [])
		if not owners.is_empty() and owners.all(func(value): return value in JEDI) or not owners.is_empty() and owners.all(func(value): return value in SOLDIER):
			owner = str(owners[0])
		elif owners.size() == 1: owner = str(owners[0])
	if owner in MELEE: return "melee"
	if owner in SUPPORT: return "support"
	if owner in RANGED: return "ranged"
	if owner in JEDI: return "jedi"
	if owner in SOLDIER: return "soldier"
	# Unprefixed legacy skills can still be resolved from their declared action form.
	if bool(def.get("melee", false)): return "melee"
	if str(def.get("target", "")) in ["ally", "ally_injured", "ally_down"]: return "support"
	if str(def.get("target", "")) == "enemy" and float(def.get("range", 0.0)) >= 5.0: return "ranged"
	return ""

static func profile(id: String, def: Dictionary = {}, target: Dictionary = {}, actor: Dictionary = {}) -> Dictionary:
	if chain_ready(def, target, actor):
		return {"shape":"rim", "color":Color("f0e020"), "radius":1.1, "pulse":0.3, "category":"chain"}
	if PROFILES.has(id): return PROFILES[id]
	var kind := category(id, def)
	match kind:
		"jedi": return {"shape":"rim", "color":Color("e8a030"), "radius":1.1, "category":kind}
		"soldier": return {"shape":"rim", "color":Color("5090c0"), "radius":1.0, "category":kind}
		"melee": return {"shape":"rim", "color":Color("e05020"), "radius":1.0, "pulse":0.3, "category":kind}
		"support": return {"shape":"rim", "color":Color("40c060"), "radius":1.0, "category":kind}
		"ranged": return {"shape":"narrow_arc", "color":Color(1.0, 1.0, 1.0, 0.7), "radius":0.8, "arc_width":0.45, "category":kind}
	return {}

static func chain_result_pulse(fx_node: Node3D, at: Vector3) -> MeshInstance3D:
	if fx_node == null or not is_instance_valid(fx_node): return null
	var pulse := MeshInstance3D.new()
	pulse.name = "W31CChainResultPulse"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.45
	mesh.outer_radius = 0.54
	pulse.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 1.0, 0.92, 0.95)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 2.4
	pulse.material_override = material
	pulse.position = at - Vector3.UP * 0.75
	fx_node.add_child(pulse)
	var tween := fx_node.create_tween().set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3.ONE * 2.4, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "transparency", 1.0, 0.25)
	tween.chain().tween_callback(pulse.queue_free)
	return pulse

static func budget() -> Dictionary:
	return {"draws_per_beat": 4, "particles_max": 12}
