extends Node3D

const Shot = preload("res://scripts/shot.gd")
var shown_tile := Vector2i(-1, -1)

func _ready() -> void:
	visible = false
	var plate := preload("res://scripts/enemy11_plate.gd").new(); plate.name = "ThreatNotes11"; plate.bind(get_parent()); get_parent().add_child.call_deferred(plate)
	var amber := StandardMaterial3D.new()
	amber.albedo_color = Color("ffbd57")
	amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amber.emission_enabled = true
	amber.emission = Color("ff7b2c")
	amber.emission_energy_multiplier = 3.0
	for side in [Vector3(-0.47, 0, 0), Vector3(0.47, 0, 0), Vector3(0, 0, -0.47), Vector3(0, 0, 0.47)]:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.1, 0.07, 0.85) if side.x != 0 else Vector3(0.85, 0.07, 0.1)
		bar.mesh = mesh
		bar.material_override = amber
		bar.position = side
		add_child(bar)
	var diamond := MeshInstance3D.new()
	var gem := SphereMesh.new()
	gem.radius = 0.17
	gem.height = 0.34
	diamond.mesh = gem
	diamond.material_override = amber
	diamond.position.y = 0.33
	add_child(diamond)
	var light := OmniLight3D.new()
	light.light_color = Color("ff8d3f")
	light.light_energy = 2.2
	light.omni_range = 2.8
	light.position.y = 0.45
	add_child(light)

func show_tile(tile: Vector2i, mission: RefCounted) -> void:
	visible = tile.x >= 0
	if not visible or tile == shown_tile: return
	shown_tile = tile
	position = Vector3(tile.x, Shot.elevation(mission, tile) * 0.7 + 0.17, tile.y)
