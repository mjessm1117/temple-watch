extends RefCounted
## Low-cost procedural architecture; all movement is driven by TempleView.
const HUMAN = preload("res://assets/temple/human.glb")
const Data = preload("res://scripts/campaign/data.gd")
var people: Array[Dictionary] = []
var pulses: Array[MeshInstance3D] = []
var sparks: Array[Dictionary] = []
var planets: Dictionary = {}
var materials: Dictionary = {}

func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key := "%s/%s" % [color.to_html(), glow]
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = 0.74
	if glow > 0.0:
		m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = glow
	materials[key] = m
	return m

func box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = dimensions
	return shape(parent, mesh, at, color, glow)

func shape(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.mesh = mesh; node.position = at
	node.material_override = material(color, glow); parent.add_child(node)
	return node

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, top: float = -1.0, glow: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new(); mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius; mesh.height = height; mesh.radial_segments = 16
	return shape(parent, mesh, at, color, glow)

func architecture(parent: Node3D) -> void:
	var stone := Color("535c60")
	for tier in [[32.0, -1.5], [21.2, 1.4], [16.0, 4.3], [10.7, 7.2]]:
		box(parent, Vector3(0, tier[1], -0.45), Vector3(tier[0], 0.32, 5.2), stone)
		box(parent, Vector3(0, tier[1] - 0.26, 2.18), Vector3(tier[0] + 0.2, 0.18, 0.35), Color("a09275"))
		box(parent, Vector3(0, tier[1] - 0.05, 2.38), Vector3(tier[0], 0.035, 0.035), Color("5c989e"), 0.5)
	# The solid rear mass and stepped roof give the cutaway a readable ziggurat silhouette.
	for i in 4:
		box(parent, Vector3(0, 0.0 + i * 2.9, -3.6), Vector3(25.0 - i * 5.2, 2.7, 3.2), stone.darkened(0.25))
		box(parent, Vector3(0, 1.4 + i * 2.9, -2.6), Vector3(25.6 - i * 5.2, 0.2, 3.6), stone)
	# Five spires: four satellite towers around the taller Council spire.
	for x in [-10.4, -5.2, 0.0, 5.2, 10.4]:
		var center := is_zero_approx(x)
		var base_y := 11.0 if center else 10.0
		var top_y := 16.3 if center else 14.5
		box(parent, Vector3(x, base_y + 0.9, -2.4), Vector3(3.5, 3.8, 1.5), stone.darkened(0.14))
		box(parent, Vector3(x, base_y + 2.6, -0.4), Vector3(3.8, 0.22, 3.3), Color("8c8878"))
		var shaft := CylinderMesh.new(); shaft.radial_segments = 4
		shaft.bottom_radius = 1.7; shaft.top_radius = 1.05; shaft.height = top_y - base_y - 2.7
		var tower := shape(parent, shaft, Vector3(x, (top_y + base_y + 2.7) / 2.0, -0.7), stone)
		tower.rotation.y = PI / 4
		box(parent, Vector3(x, top_y + 0.12, -0.7), Vector3(1.55, 0.24, 1.55), Color("9c9c8c"))
		box(parent, Vector3(x, top_y + 0.65, -0.7), Vector3(0.18, 1.1, 0.18), Color("b5b39e"))
		for dx in [-0.85, 0.0, 0.85]:
			box(parent, Vector3(x + dx, base_y + 3.0, 0.7), Vector3(0.1, 0.5, 0.06), Color("a8dfe4"), 1.4)
	# Suspended foundation, tapering into the galaxy rather than resting on a ground plane.
	for i in 4:
		box(parent, Vector3(0, -2.0 - i * 0.38, -2.0), Vector3(29.0 - i * 2, 0.36, 6.0 - i * 0.65), stone.darkened(0.3 + i * 0.1))

func room(parent: Node3D, info: Dictionary) -> Node3D:
	var cell := Node3D.new(); cell.name = str(info.id); cell.position = info.position; parent.add_child(cell)
	var built: bool = info.built
	var color: Color = info.color
	var narrow: bool = info.kind in ["spire", "council"]
	var width := 3.5 if narrow else 4.9
	var height := 1.8 if info.kind == "vault" else 2.5
	var wall := Color("283c44") if built else Color("172329")
	box(cell, Vector3(0, height / 2, -1.55), Vector3(width, height, 0.18), wall)
	# Recessed wall and lit threshold make the open face read as a room, not a flat plate.
	box(cell, Vector3(0, height * 0.52, -1.43), Vector3(width - 0.4, height - 0.3, 0.05), Color("182a31") if built else Color("0c171c"))
	box(cell, Vector3(0, 0, 0), Vector3(width, 0.16, 3.3), Color("55616a") if built else wall)
	box(cell, Vector3(0, 0.09, 0.3), Vector3(width - 0.34, 0.025, 2.35), Color("344f55") if built else Color("1a2528"))
	for x in [-width / 2, width / 2]:
		box(cell, Vector3(x, height / 2, 0.0), Vector3(0.12, height, 3.3), Color("637177") if built else Color("3e484b"))
		box(cell, Vector3(x * 0.86, height * 0.56, -1.33), Vector3(0.1, height * 0.72, 0.08), color if built else Color("886b44"), 0.6 if built else 0.0)
	box(cell, Vector3(0, height, 0), Vector3(width, 0.13, 3.3), Color("5a6567"))
	box(cell, Vector3(0, 0.13, 1.7), Vector3(width - 0.2, 0.045, 0.04), color if built else Color("76634d"), 1.1 if built else 0.15)
	if not built:
		for x in [-width * 0.3, width * 0.3]:
			var brace := box(cell, Vector3(x, height * 0.5, -0.7), Vector3(0.07, height * 1.2, 0.07), Color("5d6058"))
			brace.rotation.z = 0.55 if x < 0 else -0.55
		for y in [0.6, 1.4]: box(cell, Vector3(0, y, -0.7), Vector3(width, 0.05, 0.05), Color("4c514b"))
		return cell
	for x in [-width * 0.34, width * 0.34]:
		box(cell, Vector3(x, height - 0.15, 0.3), Vector3(0.85, 0.04, 0.28), color, 1.4)
	for x in [-1.0, 0.0, 1.0]:
		box(cell, Vector3(x, 1.2, -1.42), Vector3(0.02, 1.7, 0.025), color.darkened(0.3), 0.4)
	var light := OmniLight3D.new(); light.position = Vector3(0, 1.6, 0.4)
	light.light_color = color; light.light_energy = 0.65; light.omni_range = 3.5; cell.add_child(light)
	furnish(cell, str(info.kind), color)
	if info.kind != "vault":
		person(cell, Vector3(-1.1, 0.1, 0.6), color, true)
		person(cell, Vector3(1.05, 0.1, -0.45), Color("e1d6b4"), false)
	for i in int(info.get("staff", 0)):
		person(cell, Vector3(-0.7 + i * 1.3, 0.1, 1.05), Color("80dfd4"), false)
	if info.kind == "vault":
		cylinder(cell, Vector3(0, 0.5, 0), 0.65, 0.9, Color("75d4df"), 0.3, 1.0)
	return cell

func furnish(cell: Node3D, kind: String, color: Color) -> void:
	match kind:
		"holo", "council", "spire":
			cylinder(cell, Vector3(0, 0.38, 0), 0.75, 0.7, Color("3a4e57"))
			cylinder(cell, Vector3(0, 0.75, 0), 0.78, 0.04, color, -1, 2.0)
			var globe := SphereMesh.new(); globe.radius = 0.36; globe.height = 0.72
			var orb := shape(cell, globe, Vector3(0, 1.25, 0), color, 1.0)
			var mat := material(color, 1.0).duplicate() as StandardMaterial3D
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a = 0.38
			orb.material_override = mat; orb.set_meta("animated", true); pulses.append(orb)
		"medical", "beds":
			for x in [-1.1, 0.4, 1.7]:
				box(cell, Vector3(x, 0.35, -0.3), Vector3(0.8, 0.5, 1.7), Color("647c7e"))
				box(cell, Vector3(x, 0.64, -0.75), Vector3(0.65, 0.1, 0.4), Color("aabcb7"))
				box(cell, Vector3(x, 0.66, -0.1), Vector3(0.62, 0.04, 0.7), color, 0.4)
		"garden":
			for x in [-1.5, 1.4]:
				cylinder(cell, Vector3(x, 0.2, -0.2), 0.45, 0.3, Color("7e8777"))
				cylinder(cell, Vector3(x, 0.8, -0.2), 0.42, 1.1, Color("559a78"), 0.08)
			cylinder(cell, Vector3(0, 0.12, 0.5), 0.6, 0.12, Color("5eafb0"), -1, 0.5)
		"forge":
			box(cell, Vector3(0.6, 0.45, 0), Vector3(1.6, 0.8, 1.15), Color("5e5550"))
			box(cell, Vector3(0.6, 0.88, 0), Vector3(1.0, 0.05, 0.65), Color("ffb357"), 3)
			for i in 12:
				var ember := box(cell, Vector3.ZERO, Vector3(0.025, 0.085, 0.025), Color("ffc77a"), 4)
				ember.set_meta("animated", true)
				sparks.append({"node":ember, "phase":float(i) / 12})
		"training":
			for x in [-1.2, 1.2]:
				cylinder(cell, Vector3(x, 0.07, 0.0), 0.7, 0.05, Color("4f797f"))
				box(cell, Vector3(x, 1.0, -0.6), Vector3(0.09, 1.5, 0.09), color, 1.3)
		"hangar":
			var hull := box(cell, Vector3(0, 0.55, -0.1), Vector3(2.2, 0.55, 1.0), Color("9da9aa"))
			hull.rotation.y = 0.2
			box(cell, Vector3(0, 0.7, -0.5), Vector3(0.6, 0.3, 0.7), color, 0.8)
			for x in [-1.5, 1.5]: box(cell, Vector3(x, 0.35, 0.1), Vector3(0.9, 0.12, 1.4), Color("6b8087"))
		_:
			for x in [-1.4, 0.0, 1.4]:
				box(cell, Vector3(x, 0.65, -0.7), Vector3(0.85, 1.2, 0.6), Color("425661"))
				box(cell, Vector3(x, 1.0, -0.36), Vector3(0.5, 0.13, 0.03), color, 1.2)

func person(cell: Node3D, at: Vector3, color: Color, walking: bool) -> void:
	var actor := Node3D.new(); actor.set_meta("animated", true); cell.add_child(actor); actor.position = at
	var model := HUMAN.instantiate() as Node3D; actor.add_child(model); model.scale = Vector3.ONE * 0.48
	var animator: AnimationPlayer = null
	for node in model.find_children("*", "AnimationPlayer", true, false): animator = node; break
	for node in model.find_children("*", "MeshInstance3D", true, false):
		node.material_override = material(color.lightened(0.1))
	if animator != null:
		var clip := "walk" if walking else "idle"
		if animator.has_animation(clip):
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			animator.play(clip); animator.seek(float(people.size()) * 0.37, true)
	# Readable Jedi/clone silhouettes and a faint saber for the patrol.
	if walking:
		var robe := cylinder(actor, Vector3(0, 0.29, 0), 0.2, 0.5, Color("a09576"), 0.12)
		robe.name = "JediRobe"
		box(actor, Vector3(0.27, 0.65, 0.06), Vector3(0.025, 0.5, 0.025), color, 2)
	else:
		box(actor, Vector3(0, 0.6, 0), Vector3(0.3, 0.28, 0.18), Color("dddeda"))
		cylinder(actor, Vector3(0, 0.92, 0), 0.11, 0.19, Color("d5dedb"))
		box(actor, Vector3(0, 0.94, 0.105), Vector3(0.17, 0.035, 0.03), Color("172b34"))
	people.append({"node":actor, "origin":at, "walk":walking, "phase":float(people.size())})

func galaxy(parent: Node3D, show_labels: bool = true) -> Node3D:
	var disk := Node3D.new(); disk.name = "Galaxy"; disk.position = Vector3(0, -6.3, -4); parent.add_child(disk)
	var plane := PlaneMesh.new(); plane.size = Vector2(64, 48)
	var cloud := MeshInstance3D.new(); cloud.mesh = plane
	var shader := ShaderMaterial.new(); shader.shader = preload("res://assets/temple/nebula.gdshader")
	cloud.material_override = shader; disk.add_child(cloud)
	var rng := RandomNumberGenerator.new(); rng.seed = 6943
	var stars := MultiMesh.new(); stars.transform_format = MultiMesh.TRANSFORM_3D; stars.use_colors = true
	var star := SphereMesh.new(); star.radius = 0.026; star.height = 0.052; star.radial_segments = 4; star.rings = 2
	star.material = material(Color("8da4c3"), 1.0); stars.mesh = star; stars.instance_count = 850
	for i in 850:
		var radius := rng.randf_range(0.8, 29.0)
		var angle := float(i % 3) * TAU / 3.0 + radius * 0.25 + rng.randfn(0, 0.22)
		var at := Vector3(cos(angle) * radius, rng.randf_range(0.0, 0.4), sin(angle) * radius * 0.72)
		stars.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.5, 1.6)), at))
		stars.set_instance_color(i, Color(0.5, 0.7, 0.85).lightened(rng.randf_range(0, 0.4)))
	var field := MultiMeshInstance3D.new(); field.multimesh = stars; disk.add_child(field)
	for key in Data.get_table("galaxy", "PLANETS"):
		var data: Dictionary = Data.get_table("galaxy", "PLANETS")[key]
		var at := Vector3((float(data.x) - 300.0) / 11.0, 0.5, (float(data.y) - 180.0) / 9.0)
		var mesh := SphereMesh.new(); mesh.radius = 0.09; mesh.height = 0.18
		var planet := shape(disk, mesh, at, Color("88c4d5"), 1.7); planet.name = str(key); planets[key] = planet
		if show_labels:
			var label := Label3D.new(); label.text = str(key); label.font_size = 20; label.pixel_size = 0.013
			label.position = at + Vector3(0, 0.25, 0); label.modulate = Color("6d939e")
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; disk.add_child(label)
	# A quiet star field beyond the temple, using one draw call.
	var distant := MultiMesh.new(); distant.transform_format = MultiMesh.TRANSFORM_3D
	distant.mesh = star; distant.instance_count = 850
	for i in 850:
		distant.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(rng.randf_range(-50, 50), rng.randf_range(-18, 35), -18)))
	var backdrop := MultiMeshInstance3D.new(); backdrop.multimesh = distant; parent.add_child(backdrop)
	return disk

func animate(time: float) -> void:
	for key in materials:
		if str(key).ends_with("/1.4"):
			materials[key].emission_energy_multiplier = 1.3 + sin(time * 1.5) * 0.18
	for person_data in people:
		var actor: Node3D = person_data.node
		if person_data.walk:
			var phase: float = time * 0.35 + person_data.phase
			actor.position.x = sin(phase) * 1.3
			actor.rotation.y = PI / 2 if cos(phase) > 0 else -PI / 2
	for orb in pulses: orb.scale = Vector3.ONE * (1.0 + sin(time * 1.8) * 0.07); orb.rotation.y = time * 0.3
	for spark in sparks:
		var age := fmod(time * 0.9 + float(spark.phase), 1.0)
		var node: Node3D = spark.node
		node.position = Vector3(0.6 + sin(float(spark.phase) * 43) * age, 0.9 + sin(age * PI) * 1.1, age * 0.5)
		node.visible = age < 0.72

func batch_static(temple: Node3D) -> void:
	# Merge stationary surfaces by material. Animated actors, holograms and sparks stay independent.
	var batches: Dictionary = {}
	for node in temple.find_children("*", "MeshInstance3D", true, false):
		var ancestor: Node = node
		var animated := false
		while ancestor != temple:
			if ancestor.has_meta("animated"): animated = true; break
			ancestor = ancestor.get_parent()
		if animated: continue
		var mat: Material = node.material_override
		if mat == null: continue
		var key := mat.get_instance_id()
		if not batches.has(key):
			var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[key] = {"surface":surface, "material":mat}
		batches[key].surface.append_from(node.mesh, 0, temple.global_transform.affine_inverse() * node.global_transform)
		node.hide(); node.queue_free()
	for batch in batches.values():
		var merged := MeshInstance3D.new(); merged.mesh = batch.surface.commit()
		merged.material_override = batch.material; temple.add_child(merged)
