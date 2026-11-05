extends Node3D
## One roster identity, shared by the hangar and portrait viewports.
const Progression = preload("res://scripts/campaign/progression.gd")
const Gear15 = preload("res://scripts/campaign/armory15_gear.gd")
var soldier_id := ""
var model: Node3D
var animation: AnimationPlayer
var ring: MeshInstance3D
var saber_light: OmniLight3D
var tint := Color.WHITE
var time := 0.0
var available := true
var highlighted := false
var armor_key := ""
var weapon_tier := 0
var equipment: Node3D
var jedi := false

static func model_path(r: Dictionary) -> String:
	var kind: String = "jedi" if Progression.is_jedi(r) else {"Medic":"medic", "Heavy":"heavy", "Scout":"scout", "Sniper":"scout"}.get(str(r.cls), "trooper")
	return "res://assets/loadout/models/%s.glb" % kind

func setup(r: Dictionary, portrait: bool = false) -> void:
	soldier_id = str(r.id); name = "Soldier_" + soldier_id
	jedi = Progression.is_jedi(r)
	armor_key = str(r.gear.armor); weapon_tier = int(r.gear.saber if jedi else r.gear.w)
	available = r.get("status", "active") == "active" and int(r.get("wound", 0)) == 0 and r.get("assign", "") == ""
	tint = Color(str(r.get("col", "#e0bd78"))) if available else Color("66747a")
	time = float(abs(soldier_id.hash()) % 100) / 10.0
	model = load(model_path(r)).instantiate(); add_child(model)
	model.scale = Vector3.ONE * 1.12
	# Retain the textured armor/robes, with a subtle per-soldier and gear tint.
	_tint_meshes(model, r)
	Gear15.attach(self, r, jedi)
	animation = _find_type(model, "AnimationPlayer") as AnimationPlayer
	if animation:
		var clip := "idle"
		if not animation.has_animation(clip): clip = "idle"
		if animation.has_animation(clip):
			animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			animation.play(clip); animation.seek(fmod(time, animation.get_animation(clip).length), true)
	equipment = Node3D.new(); model.add_child(equipment)
	var skeleton := _find_type(model, "Skeleton3D") as Skeleton3D
	if skeleton and skeleton.find_bone("hand_r") >= 0:
		model.remove_child(equipment)
		var hand := BoneAttachment3D.new(); hand.bone_name = "hand_r"; skeleton.add_child(hand); hand.add_child(equipment)
		# Bone-local grip: long axis follows the palm and points out of the fist.
		equipment.rotation_degrees = Vector3(90, 0, 0)
		equipment.position = Vector3(0, 0.07, 0)
		equipment.top_level = true
	else: equipment.position = Vector3(-0.55, 1.0, 0.2)
	if Progression.is_jedi(r): _saber(r)
	else: _blaster(r)
	if r.cls == "Medic": _medkit(model)
	if not portrait:
		ring = MeshInstance3D.new(); var torus := TorusMesh.new()
		torus.inner_radius = 0.55; torus.outer_radius = 0.58; torus.rings = 40; torus.ring_segments = 8
		ring.mesh = torus; ring.position.y = 0.015; ring.scale.y = 0.16; ring.material_override = material(tint, 1.5)
		add_child(ring)

func _find_type(node: Node, kind: String) -> Node:
	if node.is_class(kind): return node
	for child in node.get_children():
		var found := _find_type(child, kind)
		if found: return found
	return null

func _tint_meshes(node: Node, r: Dictionary) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var source = node.get_active_material(i)
			if source is StandardMaterial3D:
				var mat: StandardMaterial3D = source.duplicate()
				var armor_tone := Color("a6c9d6") if str(r.gear.armor) in ["medium", "heavy", "battle"] else Color.WHITE
				mat.albedo_color = Color.WHITE.lerp(tint, 0.14) * armor_tone if available else Color("5c666b")
				mat.roughness = 0.72; node.set_surface_override_material(i, mat)
	for child in node.get_children(): _tint_meshes(child, r)

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.6
	if glow > 0:
		mat.emission_enabled = true; mat.emission = color; mat.emission_energy_multiplier = glow
	return mat

static func block(parent: Node3D, at: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	m.mesh = mesh; m.position = at; m.material_override = material(color, glow); parent.add_child(m); return m

func _saber(r: Dictionary) -> void:
	var mark := int(r.gear.mk.get("s", 1))
	block(equipment, Vector3.ZERO, Vector3(0.06 + mark * 0.008, 0.06 + mark * 0.008, 0.22 + mark * 0.035), Color("d1cba7") if mark >= 2 else Color("a8b7bc"))
	var blade := MeshInstance3D.new(); var mesh := CylinderMesh.new()
	mesh.top_radius = 0.016; mesh.bottom_radius = 0.023; mesh.height = 1.03
	blade.mesh = mesh; blade.rotation.x = PI / 2; blade.position.z = 0.62
	blade.material_override = material(tint, 1.4); equipment.add_child(blade)
	var halo := MeshInstance3D.new(); var halo_mesh := CylinderMesh.new()
	halo_mesh.top_radius = 0.04; halo_mesh.bottom_radius = 0.055; halo_mesh.height = 1.04
	halo.mesh = halo_mesh; halo.rotation.x = PI / 2; halo.position.z = 0.62
	var halo_mat := material(Color(tint.r, tint.g, tint.b, 0.18), 0.8)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material_override = halo_mat; equipment.add_child(halo)
	blade.set_meta("saber_color", str(r.get("col", "#79d3e2")))
	saber_light = OmniLight3D.new(); saber_light.light_color = tint
	saber_light.light_energy = 1.2; saber_light.omni_range = 2.0; saber_light.position.z = 0.5; equipment.add_child(saber_light)

func _blaster(r: Dictionary) -> void:
	var tier := int(r.gear.w)
	block(equipment, Vector3(0, 0, 0.1), Vector3(0.10, 0.12, 0.55 + tier * 0.07), Color("202b32"))
	block(equipment, Vector3(0, -0.10, -0.04), Vector3(0.07, 0.18, 0.10), Color("3e4e54"))
	block(equipment, Vector3(0, 0.075, 0.10), Vector3(0.035, 0.025, 0.24), tint, 0.7)
	if tier >= 2 or "scope" in r.gear.get("mods", []):
		block(equipment, Vector3(0, 0.13, 0.02), Vector3(0.07, 0.09, 0.2), Color("70838b"))

func _medkit(parent: Node3D) -> void:
	var kit := Node3D.new(); kit.name = "Medkit"; kit.position = Vector3(0.38, 0.75, 0.13); parent.add_child(kit)
	block(kit, Vector3.ZERO, Vector3(0.28, 0.26, 0.16), Color("d1ddd8"))
	block(kit, Vector3(0, 0, 0.085), Vector3(0.18, 0.055, 0.018), Color("74e1b0"), 0.6)
	block(kit, Vector3(0, 0, 0.085), Vector3(0.055, 0.18, 0.018), Color("74e1b0"), 0.6)
	block(kit, Vector3(0, 0.17, 0), Vector3(0.15, 0.045, 0.07), Color("7c999a"))

func _process(delta: float) -> void:
	time += delta
	if model:
		model.rotation.y = sin(time * 0.6) * 0.025
		model.position.y = sin(time * 1.6) * 0.007
	if ring:
		ring.scale.x = lerpf(ring.scale.x, 1.16 if highlighted else 1.0, delta * 8)
		ring.scale.z = ring.scale.x
	if equipment:
		if equipment.top_level: equipment.global_position = equipment.get_parent().global_position + Vector3(0, 0, 0.14)
		equipment.global_rotation = Vector3(PI / 2, 0, -0.48) if jedi else Vector3(PI / 2, 0, 0.2)
	if saber_light: saber_light.light_energy = 1.1 + sin(time * 5.5) * 0.09
