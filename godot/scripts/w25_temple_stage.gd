extends RefCounted
## Reuse the existing room figures for focal workers and corridor life.
const Data = preload("res://scripts/campaign/data.gd")
var workers: Array[Dictionary] = []
var walkers: Array[Dictionary] = []

func setup(art: RefCounted, cells: Dictionary, rooms: Dictionary, state: Dictionary, _jedi: Array[Node3D]) -> void:
	for room_id in rooms:
		var info: Dictionary = rooms[room_id]
		if not info.built or (int(info.staff) <= 0 and room_id != "archives"): continue
		var figure: Node3D
		for entry in art.people:
			if entry.node.get_parent() == cells[room_id] and not entry.walk:
				figure = entry.node
				break
		if figure == null: continue
		figure.name = "FocalWorker_" + str(room_id)
		figure.scale = Vector3.ONE * 1.55
		figure.position = Vector3(-0.5, 0.13, 1.05)
		figure.rotation.z = -0.12
		var project := MeshInstance3D.new(); project.name = "WorkerProject"; project.mesh = _project_mesh(_progress(str(room_id), state))
		project.position = Vector3(0.24, 0.95, 1.16)
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color("72e4df")
		mat.emission_enabled = true; mat.emission = Color("72e4df"); mat.emission_energy_multiplier = 2.0
		project.material_override = mat; cells[room_id].add_child(project)
		var ring := Node3D.new(); ring.name = "ProjectProgress"; cells[room_id].add_child(ring)
		workers.append({"figure":figure, "project":project, "phase":float(workers.size())})
	# Patrols use existing human instances. They cross only neighboring built rooms on the same floor.
	for entry in art.people:
		if not entry.walk or walkers.size() >= 3: continue
		var origin_room := str(entry.node.get_parent().name)
		if not rooms.has(origin_room): continue
		var origin: Vector3 = rooms[origin_room].position
		var destination := origin
		for other in rooms:
			if other == origin_room or not rooms[other].built: continue
			var at: Vector3 = rooms[other].position
			if absf(at.y - origin.y) < 0.2 and absf(at.x - origin.x) <= 5.3 and absf(at.x - origin.x) > 0.2:
				destination = at; break
		if destination == origin: continue
		var figure: Node3D = entry.node
		figure.reparent(cells[origin_room].get_parent())
		walkers.append({"figure":figure, "from":origin, "to":destination, "phase":float(walkers.size()) * 1.7})

func _progress(room_id: String, state: Dictionary) -> float:
	if room_id == "archives" and str(state.research.cur) != "":
		var project: Dictionary = Data.get_table("research", "RESEARCH").get(str(state.research.cur), {})
		return clampf(float(state.research.prog) / maxf(1.0, float(project.get("days", 15))), 0.05, 1.0)
	if room_id == "forge" and not state.strategy.project.is_empty():
		var project: Dictionary = state.strategy.project
		var definition: Dictionary = Data.get_table("temple", "PROJECTS").get(str(project.id), {})
		return clampf(float(project.progress) / maxf(1.0, float(definition.get("days", 15))), 0.05, 1.0)
	return 0.22

func _project_mesh(progress: float) -> ArrayMesh:
	var points := PackedVector3Array()
	var steps := maxi(3, int(28.0 * progress))
	for i in steps:
		var a := -PI / 2.0 + TAU * float(i) / 28.0
		var b := -PI / 2.0 + TAU * float(i + 1) / 28.0
		var ai := Vector3(cos(a) * 0.27, sin(a) * 0.27, 0)
		var ao := Vector3(cos(a) * 0.31, sin(a) * 0.31, 0)
		var bi := Vector3(cos(b) * 0.27, sin(b) * 0.27, 0)
		var bo := Vector3(cos(b) * 0.31, sin(b) * 0.31, 0)
		points.append_array(PackedVector3Array([ai, ao, bo, ai, bo, bi]))
	points.append_array(PackedVector3Array([
		Vector3(0, 0.16, 0), Vector3(0.13, 0, 0), Vector3(0, -0.16, 0),
		Vector3(0, 0.16, 0), Vector3(0, -0.16, 0), Vector3(-0.13, 0, 0)]))
	var mesh := ArrayMesh.new(); var arrays := []
	arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX] = points
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func animate(time: float) -> void:
	for entry in workers:
		entry.figure.rotation.z = -0.12 + sin(time * 2.0 + entry.phase) * 0.07
		entry.project.position.y = 0.95 + sin(time * 2.0 + entry.phase) * 0.04
	for entry in walkers:
		var p := (sin(time * 0.42 + entry.phase) + 1.0) * 0.5
		entry.figure.position = entry.from.lerp(entry.to, p) + Vector3(0, 0.1, 2.0)
		entry.figure.rotation.y = PI / 2.0 if cos(time * 0.42 + entry.phase) >= 0 else -PI / 2.0
