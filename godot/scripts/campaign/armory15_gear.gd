extends RefCounted
## Visible loadout markers fitted around existing soldier GLBs.
const Actor = preload("res://scripts/campaign/loadout_actor.gd")

static func attach(model: Node3D, r: Dictionary, jedi: bool) -> void:
	var gear: Dictionary = r.gear
	var mark := int(gear.mk.get("armor:" + str(gear.armor), 1))
	var armor := str(gear.armor)
	var heavy := armor in ["heavy", "battle", "armoredRobes"]
	var tone := Color("46616d") if heavy else Color("667d86")
	if mark >= 2: tone = tone.lerp(Color("c7d7d7"), 0.28)
	var mount := Node3D.new(); mount.name = "Armory15Gear"; model.add_child(mount)
	var chest := Actor.block(mount, Vector3(-0.13, 1.29, 0.17), Vector3(0.12, 0.22, 0.08), tone)
	chest.name = "ArmorPlate"; chest.visible = heavy or mark > 1
	var second := Actor.block(mount, Vector3(0.13, 1.29, 0.17), Vector3(0.12, 0.22, 0.08), tone)
	second.name = "ArmorPlateRight"; second.visible = chest.visible
	for side in [-1, 1]:
		var shoulder := Actor.block(mount, Vector3(side * 0.27, 1.37, 0.02), Vector3(0.13, 0.09, 0.19), tone)
		shoulder.name = "ShoulderPlate"; shoulder.visible = heavy
	if not jedi:
		var holster := Actor.block(mount, Vector3(0.37, 0.8, 0.14), Vector3(0.15, 0.44, 0.18), Color("25343a"))
		holster.name = "HipBlaster"
		Actor.block(mount, Vector3(0.37, 0.99, 0.24), Vector3(0.13, 0.09, 0.36), Color("506875"))
	var mods: Array = gear.smods if jedi else gear.mods
	if not mods.is_empty() or not gear.amods.is_empty():
		var glow := Actor.block(mount, Vector3(0, 1.29, 0.245), Vector3(0.08, 0.08, 0.025), Color(str(r.get("col", "#79d3e2"))), 2.2)
		glow.name = "ModGlow"
		glow.visible = true
