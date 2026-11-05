extends RefCounted
## A small instanced room. Repeated ribs, crates and lamps share materials and draw calls.
const Actor = preload("res://scripts/campaign/loadout_actor.gd")

static func _box(parts: Array, pos: Vector3, size: Vector3) -> void:
	parts.append(Transform3D(Basis().scaled(size), pos))

static func _group(parent: Node3D, name: String, parts: Array, color: Color, glow: float = 0.0, metallic: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = parts.size()
	for i in parts.size(): mm.set_instance_transform(i, parts[i])
	var node := MultiMeshInstance3D.new()
	node.name = name; node.multimesh = mm
	var mat := Actor.material(color, glow)
	mat.metallic = metallic; mat.roughness = 0.2 if metallic > 0.0 else 0.72
	node.material_override = mat
	parent.add_child(node)

static func build(parent: Node3D, low: bool) -> Node3D:
	var room := Node3D.new(); room.name = "Armory15Hangar"; parent.add_child(room)
	var shell: Array = []; var steel: Array = []; var trim: Array = []; var warm: Array = []; var cool: Array = []
	# Floor, rear wall, recessed gate, side walls and overhead lintel establish depth.
	_box(shell, Vector3(0, -0.16, -0.5), Vector3(20, 0.26, 16))
	_box(shell, Vector3(0, 3.3, -5.0), Vector3(20, 7, 0.45))
	_box(shell, Vector3(-8.1, 2.6, -0.5), Vector3(0.5, 5.4, 10))
	_box(shell, Vector3(8.1, 2.6, -0.5), Vector3(0.5, 5.4, 10))
	_box(shell, Vector3(0, 3.1, -4.6), Vector3(3.0, 5.8, 0.12))
	_box(steel, Vector3(0, 5.1, -3.8), Vector3(10, 0.35, 2.2))
	for side in [-1, 1]:
		for x in [1.75, 2.7, 3.65, 5.0, 6.3]:
			_box(steel, Vector3(side * x, 2.6, -4.65), Vector3(0.16, 5.1, 0.32))
			_box(trim, Vector3(side * x, 2.55, -4.42), Vector3(0.025, 4.5, 0.04))
		# Two weapon racks set forward from the rear wall; barrels and hilt rails read in profile.
		_box(steel, Vector3(side * 2.8, 1.2, -3.2), Vector3(1.65, 2.15, 0.28))
		for row in 3:
			_box(trim, Vector3(side * 2.8, 0.48 + row * 0.58, -3.0), Vector3(1.5, 0.065, 0.12))
			for dx in [-0.48, 0, 0.48]:
				_box(warm, Vector3(side * 2.8 + dx, 0.7 + row * 0.58, -2.94), Vector3(0.055, 0.38, 0.06))
		# Staggered cargo crates in front of each rack.
		for crate in [[3.7, -1.8, 0.65], [4.55, -2.3, 0.83]]:
			var x: float = crate[0]; var z: float = crate[1]; var scale: float = crate[2]
			_box(steel, Vector3(side * x, scale * 0.5, z), Vector3(scale, scale, scale))
			_box(trim, Vector3(side * x, scale + 0.015, z), Vector3(scale + 0.04, 0.035, scale + 0.04))
	# Workbench sits deeper than the hero and carries a luminous instrument strip.
	_box(steel, Vector3(0, 1.0, -3.4), Vector3(1.5, 0.13, 0.55))
	for x in [-0.62, 0.62]: _box(steel, Vector3(x, 0.48, -3.4), Vector3(0.1, 0.96, 0.1))
	_box(cool, Vector3(0, 1.09, -3.4), Vector3(0.95, 0.035, 0.24))
	for x in [-4.8, -2.4, 0.0, 2.4, 4.8]:
		_box(cool, Vector3(x, 4.75, -2.3), Vector3(1.0, 0.06, 0.25))
		_box(cool, Vector3(x, -0.005, -1.3), Vector3(0.7, 0.012, 1.2))
	for z in [-3.8, -1.1, 1.6]: _box(trim, Vector3(0, 0.005, z), Vector3(13, 0.015, 0.025))
	_group(room, "Shell", shell, Color("13242d"), 0.0, 0.45 if not low else 0.0)
	_group(room, "RibsRacksCrates", steel, Color("354952"), 0.0, 0.35)
	_group(room, "MetalEdges", trim, Color("69818a"), 0.0, 0.55)
	_group(room, "RackWeapons", warm, Color("b58e64"), 0.12)
	_group(room, "LightPools", cool, Color("79c6da"), 1.6)
	if not low:
		for x in [-2.4, 2.4]:
			var light := SpotLight3D.new(); light.name = "CeilingPool"
			light.position = Vector3(x, 4.55, -2.3)
			light.light_color = Color("9bd9ee"); light.light_energy = 2.4
			light.spot_range = 6; light.spot_angle = 34; room.add_child(light)
			light.look_at(Vector3(x, 0, -1.3))
	return room
