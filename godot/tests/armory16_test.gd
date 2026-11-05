extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
const Armor = preload("res://scripts/campaign/armory16_armor.gd")
const Art = preload("res://scripts/campaign/armory16_art.gd")
const Jedi = preload("res://scripts/characters/jedi_models.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ARMORY16: " + reason)

func triangles(mesh: Mesh) -> int:
	var total := 0
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		total += (indices.size() if not indices.is_empty() else vertices.size()) / 3
	return total

func run() -> void:
	var campaign = Campaign.new()
	var graphics = root.get_node("Graphics")
	var old_tier: String = graphics.effective
	var names := {"kira":"Kira Venn", "tor":"Tor Saalen", "satele":"Satele Shan", "ressa":"Lord Ressa Vaun", "kell":"Kell Darrow", "sava":"Knight Sava Orrin", "tem":"Tem Ruhl"}
	var base: Dictionary = campaign.soldier("u1")
	for id in names:
		var r: Dictionary = base.duplicate(true)
		r.n = names[id]
		check(Jedi.id_for({"name": r.n}) == id, "%s maps to its Jedi scene" % id)
		var scene: PackedScene = Actor.model_scene(r)
		check(scene != null and scene.resource_path.ends_with("/%s.glb" % id), "%s hero uses its own model" % id)
		graphics.effective = "low"
		r.gear.armor = "armoredRobes"
		r.gear.mk["armor:armoredRobes"] = 2
		var actor := Actor.new()
		actor.setup(r, true)
		var plate: MeshInstance3D = actor.find_child("ArmorPlate", true, false)
		var sk := Armor.skeleton(actor)
		check(plate != null and plate.visible and sk != null, "%s has fitted armor" % id)
		if plate != null and sk != null:
			var rest_center: Vector3 = sk.get_bone_global_rest(sk.find_bone("spine_03")) * plate.transform.origin
			var span: float = absf(Armor._position(sk, "upperarm_l").x - Armor._position(sk, "upperarm_r").x)
			check(rest_center.distance_to(Armor._position(sk, "spine_02")) < span, "%s chest stays on torso" % id)
		actor.free()
	for tier in ["low", "high"]:
		graphics.effective = tier
		for mark in [1, 2, 3]:
			for soldier_id in ["u1", "u3"]:
				var r: Dictionary = campaign.soldier(soldier_id).duplicate(true)
				r.gear.armor = "armoredRobes" if soldier_id == "u1" else "heavy"
				r.gear.mk["armor:" + str(r.gear.armor)] = mark
				var actor := Actor.new()
				actor.setup(r, true)
				for piece_name in ["ArmorPlate", "ShoulderPlate", "Bracer_l", "Greave_l"]:
					var piece: MeshInstance3D = actor.find_child(piece_name, true, false)
					check(piece != null and piece.visible and piece.get_parent() is BoneAttachment3D, "%s Mk%d %s %s follows a bone" % [soldier_id, mark, tier, piece_name])
					if piece: check(triangles(piece.mesh) < 1500, "%s Mk%d %s %s stays under 1.5K tris" % [soldier_id, mark, tier, piece_name])
				actor.free()
	for mark in [1, 2, 3]:
		var low_scene: PackedScene = load("res://assets/armor16/armor_mk%d_low.glb" % mark)
		var high_scene: PackedScene = load("res://assets/armor16/armor_mk%d_high.glb" % mark)
		var low_model := low_scene.instantiate()
		var high_model := high_scene.instantiate()
		for part in ["Chest", "Pauldron", "Bracer", "Greave"]:
			var low_mesh: Mesh = Armor._mesh(low_model, part)
			var high_mesh: Mesh = Armor._mesh(high_model, part)
			check(low_mesh != null and high_mesh != null and triangles(low_mesh) < triangles(high_mesh), "Mk%d %s has a smaller Low LOD" % [mark, part])
		low_model.free()
		high_model.free()
	var trooper: Dictionary = campaign.soldier("u3")
	check(Actor.model_scene(trooper).resource_path.ends_with("/trooper.glb"), "trooper retains its own model")
	check(Jedi.scene_for_id("missing", Actor.model_scene(trooper)) == Actor.model_scene(trooper), "missing Jedi model uses fallback")
	for mark in [1, 2, 3]:
		for slot in ["weapon", "armor"]:
			var art: Texture2D = Art.texture_for(slot, true, mark, "#62b3ff", "saber")
			check(art.get_width() >= 256 and art.get_height() >= 256, "Mk%d %s art is card size" % [mark, slot])
	for color in ["#62b3ff", "#72e0a4", "#f2d36b", "#c58cff", "#e6eef6"]:
		var art: Texture2D = Art.texture_for("color", true, 1, color, "crystal")
		check(art.get_width() >= 256, "%s crystal art exists" % color)
	graphics.effective = old_tier
	print("ARMORY16 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
