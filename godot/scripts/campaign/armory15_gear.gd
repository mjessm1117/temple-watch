extends RefCounted
## Armory gear follows the selected model and its fitted armor.
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
const Armor16 = preload("res://scripts/campaign/armory16_armor.gd")

static func attach(model: Node3D, r: Dictionary, jedi: bool) -> void:
	Armor16.attach(model, r, jedi)
	var gear: Dictionary = r.gear
	var mount := Node3D.new(); mount.name = "Armory15Gear"; model.add_child(mount)
	if not jedi:
		var holster := Actor.block(mount, Vector3(0.37, 0.8, 0.14), Vector3(0.15, 0.44, 0.18), Color("25343a"))
		holster.name = "HipBlaster"
		Actor.block(mount, Vector3(0.37, 0.99, 0.24), Vector3(0.13, 0.09, 0.36), Color("506875"))
	var mods: Array = gear.smods if jedi else gear.mods
	if not mods.is_empty() or not gear.amods.is_empty():
		var glow := Actor.block(mount, Vector3(0, 1.29, 0.19), Vector3(0.08, 0.08, 0.025), Color(str(r.get("col", "#79d3e2"))), 2.2)
		glow.name = "ModGlow"
