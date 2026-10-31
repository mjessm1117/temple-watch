extends Node3D

# All collision and cover come from Mission. This node only draws its current tiles.
const Shot = preload("res://scripts/shot.gd")
const STONE_SHADER = preload("res://assets/env/stone.gdshader")

var pieces: Dictionary = {}
var meshes: Dictionary = {}
var materials: Dictionary = {}
var flames: Array[Dictionary] = []
var clock := 0.0
var lighting_ready := false

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	clock += delta
	for flame in flames:
		if not is_instance_valid(flame.mesh): continue
		var flicker := 0.90 + 0.12 * sin(clock * 13.0 + flame.phase) + 0.07 * sin(clock * 31.0 + flame.phase * 2.0)
		flame.mesh.scale.y = flicker
		flame.light.light_energy = 1.15 * flicker

func build(mission: RefCounted, _models: Dictionary = {}) -> void:
	for child in get_children(): child.queue_free()
	pieces.clear()
	flames.clear()
	_setup_resources()
	if not lighting_ready:
		_configure_lighting()
		lighting_ready = true
	var width := int(mission.spec.width)
	var height := int(mission.spec.height)
	for y in range(height):
		for x in range(width):
			var p := Vector2i(x, y)
			var tile: String = mission.tile(p)
			var elevation: int = Shot.elevation(mission, p)
			var level := elevation * 0.7
			_floor(x, y, tile, level, elevation)
			if elevation > 0: _terrace_edges(mission, x, y, level, elevation)
			if tile == "#": _wall(x, y, level, x == 0 or y == 0 or x == width - 1 or y == height - 1)
			elif tile == "c": _low_wall(x, y, level, false)
			elif tile == "h": _low_wall(x, y, level, true)
			elif tile == "k": _terminal(x, y, level)
			elif tile == "r": _rubble(x, y, level)
			elif tile != "E": _ambient_detail(x, y, level, tile)
	_backdrop(width, height)
	_floor_crest()
	_mission_markers(mission)
	_flush_instances()

func _setup_resources() -> void:
	if not meshes.is_empty(): return
	var box := BoxMesh.new(); box.size = Vector3.ONE; meshes.box = box
	var cylinder := CylinderMesh.new(); cylinder.top_radius = 0.5; cylinder.bottom_radius = 0.5; cylinder.height = 1.0; cylinder.radial_segments = 12; meshes.cylinder = cylinder
	var cone := CylinderMesh.new(); cone.top_radius = 0.0; cone.bottom_radius = 0.5; cone.height = 1.0; cone.radial_segments = 10; meshes.cone = cone
	var sphere := SphereMesh.new(); sphere.radius = 0.5; sphere.height = 1.0; sphere.radial_segments = 12; sphere.rings = 6; meshes.sphere = sphere
	materials.floor = _stone(Color("82715b"), 0.14, 0.20)
	materials.floor_alt = _stone(Color("8d7a61"), 0.15, 0.20)
	materials.floor_dark = _stone(Color("554a3d"), 0.16, 0.12)
	materials.marble = _stone(Color("88908c"), 0.05, 0.18)
	materials.marble_light = _stone(Color("a7aaa0"), 0.04, 0.19)
	materials.inlay = _stone(Color("393f46"), 0.01, 0.10)
	materials.wall = _stone(Color("a18b6b"), 0.13, 0.29)
	materials.wall_dark = _stone(Color("685946"), 0.18, 0.14)
	materials.trim = _stone(Color("d3b786"), 0.02, 0.33)
	materials.rubble = _stone(Color("766655"), 0.23, 0.25)
	materials.moss = _stone(Color("3b5134"), 0.55, 0.08)
	materials.metal = _plain(Color("3c484d"), 0.30)
	materials.bronze = _plain(Color("9c7543"), 0.34)
	materials.fabric = _fabric(Color("233b55"))
	materials.fabric_gold = _fabric(Color("b49055"))
	materials.holo = _glow(Color("5dc9da"), 2.0)
	materials.fire = _glow(Color("ff9c3c"), 3.2)
	materials.evac = _glow(Color("4fd4da"), 1.4)
	materials.skyline = _plain(Color("3d4051"), 1.0)
	materials.skyline_far = _plain(Color("57546a"), 1.0)

func _stone(color: Color, moss: float, edge_wear: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = STONE_SHADER
	mat.set_shader_parameter("stone_color", color)
	mat.set_shader_parameter("moss_amount", moss)
	mat.set_shader_parameter("wear", edge_wear)
	return mat

func _plain(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.35 if roughness < 0.7 else 0.0
	return mat

func _fabric(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.96
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var mat := _plain(color, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

func _put(shape: String, material: String, at: Vector3, size: Vector3, rotation := 0.0) -> void:
	var key := shape + ":" + material
	if not pieces.has(key): pieces[key] = []
	var basis := Basis(Vector3.UP, rotation).scaled(size)
	pieces[key].append(Transform3D(basis, at))

func _flush_instances() -> void:
	for key in pieces:
		var transforms: Array = pieces[key]
		if transforms.is_empty(): continue
		var parts: PackedStringArray = str(key).split(":")
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[parts[0]]
		mm.instance_count = transforms.size()
		for i in range(transforms.size()): mm.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = materials[parts[1]]
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if parts[1] in ["wall", "wall_dark", "metal"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func _floor(x: int, y: int, tile: String, level: float, elevation: int) -> void:
	var material := "marble" if tile == "M" else "floor_alt" if (x * 17 + y * 31) % 7 < 3 else "floor"
	if tile == "^": material = "marble_light" if (x + y) % 3 == 0 else "marble"
	if tile == "r": material = "rubble"
	_put("box", "floor_dark", Vector3(x, level * 0.5 - 0.07, y), Vector3(0.995, level + 0.14, 0.995))
	_put("box", material, Vector3(x, level + 0.015, y), Vector3(0.92, 0.035, 0.92))
	if tile in ["^", "M"]:
		var inlay := "bronze" if tile == "M" else "inlay"
		_put("box", inlay, Vector3(x, level + 0.037, y - 0.38), Vector3(0.72, 0.008, 0.013))
		_put("box", inlay, Vector3(x - 0.38, level + 0.037, y), Vector3(0.013, 0.008, 0.72))
	if (x + y) % 5 == 0 and tile not in ["#", "r", "E"]:
		_put("box", "trim", Vector3(x, level + 0.035, y + 0.37), Vector3(0.83, 0.006, 0.012))
	if tile == "E":
		_put("box", "evac", Vector3(x, level + 0.037, y), Vector3(0.80, 0.009, 0.045))
		_put("box", "evac", Vector3(x, level + 0.037, y - 0.34), Vector3(0.80, 0.009, 0.045))
	if elevation == 2:
		_put("box", "trim", Vector3(x, level + 0.038, y - 0.43), Vector3(0.84, 0.01, 0.025))

func _terrace_edges(mission: RefCounted, x: int, y: int, level: float, elevation: int) -> void:
	for dir in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var next: Vector2i = Vector2i(x, y) + dir
		if Shot.elevation(mission, next) >= elevation: continue
		var side := Vector3(dir.x, 0, dir.y)
		var sideways: bool = dir.x != 0
		var size := Vector3(0.08, 0.11, 0.92) if sideways else Vector3(0.92, 0.11, 0.08)
		_put("box", "trim", Vector3(x, level - 0.06, y) + side * 0.46, size)
		_put("box", "bronze", Vector3(x, level - 0.13, y) + side * 0.488, Vector3(0.015, 0.035, 0.84) if sideways else Vector3(0.84, 0.035, 0.015))
		_put("box", "wall", Vector3(x, level * 0.5, y) + side * 0.46, Vector3(0.045, level - 0.12, 0.88) if sideways else Vector3(0.88, level - 0.12, 0.045))
		for step in range(elevation * 2):
			var band_y := 0.18 + step * 0.31
			if band_y < level - 0.12:
				_put("box", "wall_dark", Vector3(x, band_y, y) + side * 0.486, Vector3(0.025, 0.035, 0.84) if sideways else Vector3(0.84, 0.035, 0.025))

func _wall(x: int, y: int, level: float, boundary: bool) -> void:
	var tall := 1.70 if not boundary else 1.50
	if not boundary and x == 12 and y in [5, 12, 16, 19]:
		_statue(Vector3(x, level, y), 1.0)
		return
	# Every third block reads as a broken column; all # cells still rise above a person.
	var column := not boundary and (x * 13 + y * 7) % 5 == 0
	if column:
		_put("box", "wall_dark", Vector3(x, level + 0.14, y), Vector3(0.94, 0.28, 0.94))
		_put("cylinder", "wall", Vector3(x, level + 0.89, y), Vector3(0.70, 1.38, 0.70))
		_put("box", "trim", Vector3(x, level + 1.57, y), Vector3(0.94, 0.13, 0.94))
		for offset in [-0.22, 0.22]:
			_put("box", "wall_dark", Vector3(x, level + 0.89, y + offset), Vector3(0.04, 1.28, 0.045))
	else:
		_put("box", "wall", Vector3(x, level + tall * 0.5, y), Vector3(0.88, tall, 0.88))
		_put("box", "wall_dark", Vector3(x, level + 0.23, y), Vector3(0.94, 0.09, 0.94))
		_put("box", "trim", Vector3(x, level + tall - 0.08, y), Vector3(0.95, 0.16, 0.95))
		if not boundary and (x + y) % 3 == 0:
			_put("box", "wall_dark", Vector3(x, level + 1.0, y + 0.448), Vector3(0.62, 0.045, 0.025))
	if boundary and (x + y) % 6 == 0:
		_put("box", "trim", Vector3(x, level + tall + 0.03, y), Vector3(0.97, 0.07, 0.97))
	if not boundary and (x * 5 + y * 11) % 7 == 0:
		for i in range(3):
			_put("box", "moss", Vector3(x - 0.28 + i * 0.23, level + 1.21 - i * 0.13, y + 0.453), Vector3(0.065, 0.75 + i * 0.16, 0.035))

func _low_wall(x: int, y: int, level: float, reinforced: bool) -> void:
	var height := 0.84 if reinforced else 0.63
	var angle := PI * 0.5 if (x * 7 + y * 3) % 4 == 0 else 0.0
	_put("box", "wall_dark", Vector3(x, level + 0.12, y), Vector3(0.91, 0.24, 0.56), angle)
	_put("box", "wall", Vector3(x, level + height * 0.5, y), Vector3(0.86, height - 0.08, 0.51), angle)
	_put("box", "trim", Vector3(x, level + height - 0.01, y), Vector3(0.98, 0.09, 0.61), angle)
	if reinforced:
		_put("box", "metal", Vector3(x, level + height + 0.046, y), Vector3(0.93, 0.035, 0.55), angle)
		for offset in [-0.35, 0.35]:
			var local := Vector3(offset, level + height * 0.45, 0).rotated(Vector3.UP, angle)
			_put("box", "bronze", Vector3(x, 0, y) + local, Vector3(0.035, height * 0.7, 0.54), angle)
	else:
		_put("box", "wall_dark", Vector3(x, level + height * 0.50, y + 0.265), Vector3(0.74, 0.022, 0.025), angle)

func _terminal(x: int, y: int, level: float) -> void:
	_put("box", "wall_dark", Vector3(x, level + 0.14, y), Vector3(0.75, 0.28, 0.62))
	_put("box", "metal", Vector3(x, level + 0.49, y), Vector3(0.56, 0.46, 0.42))
	_put("box", "bronze", Vector3(x, level + 0.75, y - 0.08), Vector3(0.69, 0.07, 0.62))
	_put("box", "holo", Vector3(x, level + 0.91, y - 0.16), Vector3(0.45, 0.24, 0.025))
	_put("box", "holo", Vector3(x, level + 0.66, y - 0.321), Vector3(0.33, 0.025, 0.015))

func _rubble(x: int, y: int, level: float) -> void:
	for i in range(7):
		var seed := x * 31 + y * 47 + i * 29
		var px := float(seed % 17 - 8) * 0.045
		var pz := float((seed * 7) % 19 - 9) * 0.04
		var size := 0.13 + float(seed % 5) * 0.045
		_put("box", "rubble" if i % 3 else "wall", Vector3(x + px, level + 0.055, y + pz), Vector3(size, 0.11, size * 0.78), float(seed % 8) * 0.18)

func _ambient_detail(x: int, y: int, level: float, tile: String) -> void:
	if tile not in [".", "^", "M"]: return
	var hash_value := (x * 41 + y * 71 + x * y * 13) % 101
	if hash_value < 8:
		_put("box", "rubble", Vector3(x + 0.27, level + 0.035, y - 0.26), Vector3(0.18, 0.07, 0.12), 0.3)
	if hash_value >= 83 and hash_value <= 89:
		for i in range(3):
			_put("cone", "moss", Vector3(x - 0.36 + i * 0.10, level + 0.12, y + 0.33), Vector3(0.08, 0.24 + i * 0.06, 0.08), float(i) * 0.7)

func _backdrop(width: int, height: int) -> void:
	# Perimeter architecture and a distant Coruscant skyline sit outside the rule grid.
	_temple_gate(width)
	_arcade(width)
	for x in range(-3, width + 4):
		if x % 4 == 0:
			_ruined_pillar(Vector3(x, 0, height + 1.8), 1.8 + float(x % 4) * 0.33)
	for y in range(-2, height + 3):
		if y % 5 == 0:
			_ruined_pillar(Vector3(-2.8, 0, y), 2.0 + float(y % 3) * 0.4)
			_ruined_pillar(Vector3(width + 1.8, 0, y), 2.2 + float(y % 3) * 0.4)
	for i in range(32):
		var x := float(i) * 2.7 - 28.0
		var h := 3.0 + float((i * 17) % 9)
		var far := "skyline_far" if i % 3 == 0 else "skyline"
		_put("box", far, Vector3(x, h * 0.5 - 0.6, -17.0 - float(i % 4) * 2.0), Vector3(1.2 + float(i % 3) * 0.5, h, 1.8))
		if i % 4 == 0:
			_put("cone", far, Vector3(x, h + 0.35, -17.0 - float(i % 4) * 2.0), Vector3(1.1, 1.5, 1.1))
	# Fallen colonnade and planted courtyards are fully outside the playable tiles.
	for i in range(7):
		_put("cylinder", "wall", Vector3(-2.3, 0.34, i * 3.4 + 1.0), Vector3(0.45, 1.7, 0.45), PI * 0.5)
		_put("box", "moss", Vector3(width + 2.3, 0.06, i * 3.4), Vector3(1.3, 0.13, 1.4))
		for j in range(4):
			_put("cone", "moss", Vector3(width + 1.9 + j * 0.25, 0.35, i * 3.4 + (j % 2) * 0.2), Vector3(0.32, 0.7, 0.32))
	for p in [Vector3(2, 0, -1.2), Vector3(10, 0, -1.2), Vector3(20, 0, -1.2), Vector3(3, 0, height + 0.8), Vector3(13, 0, height + 0.8), Vector3(22, 0, height + 0.8)]:
		_brazier(p)
	for p in [Vector3(12, 1.62, 7), Vector3(12, 1.62, 16)]:
		_brazier(p)

func _arcade(width: int) -> void:
	# Windows and arches stay behind the playable north edge; no scenery crosses a tile.
	for x in range(0, width + 1, 4):
		var base := Vector3(x, 0, -2.7)
		_ruined_pillar(base, 2.2)
		_put("box", "bronze", base + Vector3(0, 2.43, 0.57), Vector3(0.75, 0.035, 0.035))
	for x in range(2, width, 4):
		for i in range(9):
			var angle := PI * float(i) / 8.0
			var pos := Vector3(x + cos(angle) * 1.78, 2.0 + sin(angle) * 1.60, -2.7)
			_put("box", "wall", pos, Vector3(0.48, 0.32, 0.48), -angle)
		_put("box", "trim", Vector3(x, 3.70, -2.7), Vector3(4.0, 0.16, 0.72))
		_put("box", "bronze", Vector3(x, 3.79, -2.34), Vector3(3.82, 0.035, 0.025))
		if x % 8 == 2:
			_banner(Vector3(x, 3.56, -2.34))
		else:
			# An open window catches the sun through the arcade.
			_put("box", "trim", Vector3(x, 0.50, -2.78), Vector3(1.75, 0.12, 0.36))

func _banner(at: Vector3) -> void:
	_put("box", "bronze", at + Vector3(0, 0.06, 0), Vector3(1.22, 0.08, 0.10))
	_put("box", "fabric", at + Vector3(0, -0.83, 0.02), Vector3(1.02, 1.72, 0.035))
	_put("box", "fabric_gold", at + Vector3(0, -0.53, 0.045), Vector3(0.075, 0.88, 0.008))
	_put("box", "fabric_gold", at + Vector3(0, -0.27, 0.05), Vector3(0.58, 0.055, 0.009))
	_put("box", "fabric_gold", at + Vector3(0, -1.56, 0.04), Vector3(0.83, 0.05, 0.01))

func _temple_gate(width: int) -> void:
	var center := float(width - 1) * 0.5
	_put("box", "wall_dark", Vector3(center, 0.14, -5.0), Vector3(11.5, 0.28, 5.2))
	for step in range(4):
		_put("box", "wall", Vector3(center, 0.20 + step * 0.18, -3.2 - step * 0.42), Vector3(8.8 - step * 0.8, 0.18, 0.47))
	for side in [-1.0, 1.0]:
		var x: float = center + float(side) * 3.7
		_put("box", "wall", Vector3(x, 2.7, -6.2), Vector3(1.5, 5.4, 1.5))
		_put("box", "trim", Vector3(x, 5.46, -6.2), Vector3(1.78, 0.25, 1.78))
		_put("cone", "wall", Vector3(x, 7.25, -6.2), Vector3(1.25, 3.4, 1.25))
		_put("box", "bronze", Vector3(x, 8.86, -6.2), Vector3(0.12, 0.7, 0.12))
		_statue(Vector3(center + side * 5.2, 0.4, -3.7), 1.25)
	_put("box", "wall", Vector3(center, 4.9, -6.2), Vector3(7.5, 1.2, 1.6))
	_put("box", "trim", Vector3(center, 5.65, -6.2), Vector3(8.6, 0.25, 2.0))
	_put("box", "wall_dark", Vector3(center, 2.1, -6.4), Vector3(4.4, 4.2, 0.2))
	_put("box", "bronze", Vector3(center, 3.4, -6.23), Vector3(2.3, 0.055, 0.10))
	for i in range(5):
		var sx := center + float(i - 2) * 2.15
		_put("cone", "wall", Vector3(sx, 7.25 + abs(i - 2) * -0.35, -8.0), Vector3(0.92, 4.2 - abs(i - 2) * 0.6, 0.92))
		_put("box", "trim", Vector3(sx, 4.95, -8.0), Vector3(1.12, 0.18, 1.12))

func _statue(at: Vector3, size: float) -> void:
	_put("box", "wall_dark", at + Vector3(0, 0.18 * size, 0), Vector3(0.85, 0.36, 0.85) * size)
	_put("box", "trim", at + Vector3(0, 0.40 * size, 0), Vector3(0.74, 0.09, 0.74) * size)
	_put("cone", "wall", at + Vector3(0, 1.10 * size, 0), Vector3(0.68, 1.36, 0.58) * size)
	_put("sphere", "marble_light", at + Vector3(0, 1.92 * size, 0), Vector3(0.37, 0.43, 0.37) * size)
	_put("cone", "wall_dark", at + Vector3(0, 2.07 * size, 0.06 * size), Vector3(0.52, 0.52, 0.50) * size)
	_put("box", "bronze", at + Vector3(0.34 * size, 1.08 * size, 0.16 * size), Vector3(0.07, 1.43, 0.07) * size)

func _floor_crest() -> void:
	var center := Vector3(13.0, 0.045, 22.0)
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		var at := center + Vector3(sin(angle) * 1.55, 0, cos(angle) * 1.55)
		_put("box", "bronze", at, Vector3(0.07, 0.012, 0.40), angle)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var at := center + Vector3(sin(angle) * 0.72, 0, cos(angle) * 0.72)
		_put("box", "trim", at, Vector3(0.13, 0.014, 1.26), angle)
	_put("cylinder", "bronze", center, Vector3(0.48, 0.017, 0.48))

func _ruined_pillar(at: Vector3, height: float) -> void:
	_put("box", "wall_dark", at + Vector3(0, 0.17, 0), Vector3(1.25, 0.34, 1.25))
	_put("box", "trim", at + Vector3(0, 0.40, 0), Vector3(1.08, 0.12, 1.08))
	_put("cylinder", "wall", at + Vector3(0, height * 0.5 + 0.4, 0), Vector3(0.84, height, 0.84))
	_put("box", "trim", at + Vector3(0, height + 0.43, 0), Vector3(1.10, 0.17, 1.10))
	for offset in [-0.27, 0.27]:
		_put("box", "wall_dark", at + Vector3(offset, height * 0.5 + 0.4, 0.34), Vector3(0.04, height * 0.82, 0.04))

func _brazier(at: Vector3) -> void:
	_put("box", "wall_dark", at + Vector3(0, 0.35, 0), Vector3(0.55, 0.7, 0.55))
	_put("cylinder", "bronze", at + Vector3(0, 0.78, 0), Vector3(0.68, 0.20, 0.68))
	var flame_mesh := MeshInstance3D.new()
	flame_mesh.mesh = meshes.cone
	flame_mesh.material_override = materials.fire
	flame_mesh.position = at + Vector3(0, 1.10, 0)
	flame_mesh.scale = Vector3(0.37, 0.58, 0.37)
	add_child(flame_mesh)
	var light := OmniLight3D.new()
	light.light_color = Color("ffac5b")
	light.light_energy = 1.15
	light.omni_range = 5.0
	light.shadow_enabled = false
	light.position = at + Vector3(0, 1.2, 0)
	add_child(light)
	flames.append({"mesh": flame_mesh, "light": light, "phase": at.x * 0.7 + at.z})

func _mission_markers(mission: RefCounted) -> void:
	var x := int(mission.prisoner.x)
	var y := int(mission.prisoner.y)
	_put("box", "trim", Vector3(x, 0.047, y), Vector3(0.83, 0.016, 0.83))
	_put("box", "wall_dark", Vector3(x, 0.053, y), Vector3(0.67, 0.02, 0.67))
	for dx in [-0.29, 0.29]:
		_put("box", "holo", Vector3(x + dx, 0.068, y), Vector3(0.025, 0.009, 0.55))

func _configure_lighting() -> void:
	var root := get_parent().get_parent()
	for node in root.get_children():
		if node is WorldEnvironment:
			var env: Environment = node.environment
			env.background_mode = Environment.BG_SKY
			var sky := Sky.new()
			var sky_material := ProceduralSkyMaterial.new()
			sky_material.sky_top_color = Color("303d59")
			sky_material.sky_horizon_color = Color("c99671")
			sky_material.ground_bottom_color = Color("39302a")
			sky_material.ground_horizon_color = Color("9e7862")
			sky.sky_material = sky_material
			env.sky = sky
			env.ambient_light_color = Color("aebfd0")
			env.ambient_light_energy = 0.42
			env.tonemap_mode = Environment.TONE_MAPPER_ACES
			env.adjustment_enabled = true
			env.adjustment_contrast = 1.12
			env.adjustment_saturation = 0.94
			env.glow_enabled = true
			env.glow_intensity = 0.22
			env.ssao_enabled = true
			env.ssao_intensity = 0.75
			env.ssao_radius = 1.3
			env.fog_light_color = Color("aa8d79")
			env.fog_density = 0.002
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.003
			env.volumetric_fog_albedo = Color("d3bba0")
			env.volumetric_fog_length = 40.0
		elif node is DirectionalLight3D:
			if node.shadow_enabled:
				node.rotation_degrees = Vector3(-35, -48, 0)
				node.light_color = Color("ffd09a")
				node.light_energy = 1.75
				node.light_angular_distance = 1.4
				node.light_volumetric_fog_energy = 1.2
			else:
				node.light_color = Color("88acd2")
				node.light_energy = 0.44
