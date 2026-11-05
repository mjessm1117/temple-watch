extends RefCounted
## Armor follows the imported skeleton; rounded, shallow plates sit on the cloth surface.
const Actor = preload("res://scripts/campaign/loadout_actor.gd")

static func _skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := _skeleton(child)
		if found: return found
	return null

static func _armor_mesh() -> ArrayMesh:
	var outline := [Vector2(-0.32, 0.5), Vector2(0.32, 0.5), Vector2(0.5, 0.32), Vector2(0.5, -0.3), Vector2(0.25, -0.5), Vector2(-0.25, -0.5), Vector2(-0.5, -0.3), Vector2(-0.5, 0.32)]
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var next: int = (i + 1) % outline.size()
		for p in [Vector3(0, 0, 0.5), Vector3(outline[next].x, outline[next].y, 0.5), Vector3(outline[i].x, outline[i].y, 0.5)]: surface.add_vertex(p)
		for p in [Vector3(outline[i].x, outline[i].y, 0.5), Vector3(outline[i].x, outline[i].y, -0.5), Vector3(outline[next].x, outline[next].y, -0.5), Vector3(outline[i].x, outline[i].y, 0.5), Vector3(outline[next].x, outline[next].y, -0.5), Vector3(outline[next].x, outline[next].y, 0.5)]: surface.add_vertex(p)
	surface.generate_normals()
	return surface.commit()

static func _plate(skeleton: Skeleton3D, bone: String, name: String, center: Vector3, size: Vector3, tone: Color) -> MeshInstance3D:
	var index := skeleton.find_bone(bone)
	if index < 0: return null
	var anchor := BoneAttachment3D.new(); anchor.bone_name = bone; skeleton.add_child(anchor)
	# Author the fit in skeleton space, then convert to the moving bone's rest space.
	var rest := skeleton.get_bone_global_rest(index)
	var mesh := MeshInstance3D.new(); mesh.name = name
	mesh.mesh = _armor_mesh()
	var finish := Actor.material(tone); finish.metallic = 0.25; finish.roughness = 0.52
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = finish
	var side := signf(center.x)
	var facing := Basis(Vector3.UP, -side * deg_to_rad(18.0))
	facing = facing.rotated(Vector3.FORWARD, side * deg_to_rad(10.0))
	mesh.transform = rest.affine_inverse() * Transform3D(facing.scaled(size), center)
	anchor.add_child(mesh)
	return mesh

static func attach(model: Node3D, r: Dictionary, jedi: bool) -> void:
	var gear: Dictionary = r.gear
	var mark := int(gear.mk.get("armor:" + str(gear.armor), 1))
	var armor := str(gear.armor)
	var armored := armor in ["medium", "heavy", "armoredRobes", "beskar", "masterRobes"] or mark > 1
	var heavy := armor in ["heavy", "armoredRobes", "beskar"]
	var tone := Color("596760") if jedi else Color("7293a0")
	if armor == "beskar": tone = Color("a7b8ae")
	if mark >= 2: tone = tone.lerp(Color("a7aaa0") if jedi else Color("d3dfdc"), 0.22 * (mark - 1))
	var skeleton := _skeleton(model)
	if skeleton == null: return
	var width := 0.145 if heavy else 0.12
	if jedi:
		var chest := _plate(skeleton, "spine_03", "ArmorPlate", Vector3(0, 1.42, 0.20), Vector3(0.25, 0.14, 0.022), tone)
		chest.visible = armored
	for side in [-1, 1]:
		if not jedi:
			var chest := _plate(skeleton, "spine_03", "ArmorPlate" if side < 0 else "ArmorPlateRight",
				Vector3(side * 0.078, 1.25, 0.12), Vector3(width, 0.19, 0.038), tone)
			chest.visible = armored
		var shoulder := _plate(skeleton, "upperarm_l" if side < 0 else "upperarm_r", "ShoulderPlate",
			Vector3(side * (0.145 if jedi else 0.14), 1.36 if jedi else 1.38, 0.055 if jedi else 0.02), Vector3(0.11 if jedi else 0.10, 0.06, 0.05), tone.darkened(0.1))
		shoulder.visible = heavy
	var mount := Node3D.new(); mount.name = "Armory15Gear"; model.add_child(mount)
	if not jedi:
		var holster := Actor.block(mount, Vector3(0.37, 0.8, 0.14), Vector3(0.15, 0.44, 0.18), Color("25343a"))
		holster.name = "HipBlaster"
		Actor.block(mount, Vector3(0.37, 0.99, 0.24), Vector3(0.13, 0.09, 0.36), Color("506875"))
	var mods: Array = gear.smods if jedi else gear.mods
	if not mods.is_empty() or not gear.amods.is_empty():
		var glow := Actor.block(mount, Vector3(0, 1.29, 0.19), Vector3(0.08, 0.08, 0.025), Color(str(r.get("col", "#79d3e2"))), 2.2)
		glow.name = "ModGlow"
