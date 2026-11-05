extends RefCounted
## Armor is authored in Blender, then positioned in each skeleton's rest space.
const ROOT := "res://assets/armor16/armor_mk%d_%s.glb"

static func skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := skeleton(child)
		if found: return found
	return null

static func _mesh(node: Node, prefix: String) -> Mesh:
	if node is MeshInstance3D and str(node.name).begins_with(prefix): return node.mesh
	for child in node.get_children():
		var found := _mesh(child, prefix)
		if found: return found
	return null

static func _position(sk: Skeleton3D, bone: String) -> Vector3:
	var index := sk.find_bone(bone)
	return sk.get_bone_global_rest(index).origin if index >= 0 else Vector3.ZERO

static func _piece(sk: Skeleton3D, mesh: Mesh, bone: String, name: String, center: Vector3, size: Vector3, color: Color, show: bool, low: bool) -> MeshInstance3D:
	var index := sk.find_bone(bone)
	if index < 0: return null
	var anchor := BoneAttachment3D.new()
	anchor.name = name + "Anchor"
	anchor.bone_name = bone
	sk.add_child(anchor)
	var part := MeshInstance3D.new()
	part.name = name
	part.mesh = mesh
	part.visible = show
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if low else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var finish := StandardMaterial3D.new()
	finish.albedo_color = color
	finish.metallic = 0.06 if name == "ArmorPlate" and color.r < 0.4 else 0.38
	finish.roughness = 0.78 if finish.metallic < 0.1 else 0.48
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	part.material_override = finish
	part.transform = sk.get_bone_global_rest(index).affine_inverse() * Transform3D(Basis.IDENTITY.scaled(size), center)
	anchor.add_child(part)
	return part

static func attach(model: Node3D, r: Dictionary, jedi: bool) -> void:
	var sk := skeleton(model)
	if sk == null: return
	var gear: Dictionary = r.gear
	var armor := str(gear.armor)
	var mark := clampi(int(gear.mk.get("armor:" + armor, 1)), 1, 3)
	var show := armor in ["medium", "heavy", "armoredRobes", "beskar", "masterRobes"] or mark > 1
	var low: bool = str(Engine.get_main_loop().root.get_node("Graphics").effective) == "low"
	var asset: PackedScene = load(ROOT % [mark, "low" if low else "high"])
	if asset == null: return
	var source := asset.instantiate()
	var chest: Mesh = _mesh(source, "Chest")
	var shoulder: Mesh = _mesh(source, "Pauldron")
	var bracer: Mesh = _mesh(source, "Bracer")
	var greave: Mesh = _mesh(source, "Greave")
	source.free()
	var left := _position(sk, "upperarm_l")
	var right := _position(sk, "upperarm_r")
	var spine := _position(sk, "spine_02")
	var span := absf(left.x - right.x)
	var torso_height := absf(_position(sk, "spine_01").y - _position(sk, "spine_03").y)
	var tint := Color("765d43") if mark == 1 else Color("418996") if mark == 2 else Color("c4a060")
	if not jedi: tint = tint.lerp(Color("b1c4c6"), 0.28)
	if armor == "beskar": tint = tint.lerp(Color("c9d3cb"), 0.38)
	_piece(sk, chest, "spine_03", "ArmorPlate", spine + Vector3(0, 0, span * 0.32), Vector3(span * 0.94, torso_height * 1.07, span * 0.72), tint, show, low)
	for side in ["l", "r"]:
		var arm := _position(sk, "upperarm_" + side)
		var forearm := _position(sk, "lowerarm_" + side)
		var calf := _position(sk, "calf_" + side)
		var upper: String = "upperarm_" + side
		var lower: String = "lowerarm_" + side
		_piece(sk, shoulder, upper, "ShoulderPlate" if side == "l" else "ShoulderPlateRight", arm + Vector3(0, -span * 0.07, span * 0.08), Vector3.ONE * span * 0.35, tint.lightened(0.08), show, low)
		_piece(sk, bracer, lower, "Bracer_" + side, forearm + Vector3(0, -span * 0.23, span * 0.04), Vector3(span * 0.31, span * 0.48, span * 0.31), tint.darkened(0.07), show, low)
		_piece(sk, greave, "calf_" + side, "Greave_" + side, calf + Vector3(0, -span * 0.08, span * 0.09), Vector3(span * 0.36, span * 0.55, span * 0.33), tint, show, low)
