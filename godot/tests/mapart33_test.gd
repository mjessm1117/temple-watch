extends SceneTree
## Theme art contract. Real phone counters are checked by the W33 capture harness.
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Art = preload("res://scripts/map_presentation.gd")
const Batch = preload("res://scripts/map_art_batch.gd")
const SAMPLES := {"temple":"relay","dock":"sabotage","city":"envoy","jungle":"h_grove","plains":"shrine","ruins":"archive","snow":"ilum","caves":"r_caves"}
const AUDIT := {"relay":144,"rescue":168,"shrine":188,"archive":211,"sabotage":184}
const AUDIT_956 := {"relay":148,"rescue":185,"shrine":189,"archive":214,"sabotage":187}
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func passability(m: RefCounted) -> PackedByteArray:
	var bits := PackedByteArray()
	for y in int(m.spec.height):
		for x in int(m.spec.width): bits.append(1 if m.passable(Vector2i(x,y)) else 0)
	return bits

func triangles(mesh: Mesh) -> int:
	var count := 0
	for i in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(i)
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		count += (indices.size() if indices != null and indices.size() > 0 else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return count

func inspect_art(art: Node3D, m: RefCounted, label: String) -> void:
	var story := 0
	var flat := 0
	for record in art.batch.records:
		if not str(record.get("kind","")).begins_with("w33c "): continue
		story += 1
		check(bool(record.get("non_blocking",false)),label+": dressing has no blocking footprint")
		if record.role == "detail":
			flat += 1
			check(m.passable(record.tile) and m.tile(record.tile) == ".",label+": flat mark on open tile")
			check(record.bounds.end.y <= float(record.floor)+0.041,label+": mark stays below unit feet")
		else:
			for bounds: AABB in record.parts:
				var outside := bounds.end.x <= -0.5 or bounds.position.x >= float(m.spec.width)-0.5 or bounds.end.z <= -0.5 or bounds.position.z >= float(m.spec.height)-0.5
				check(outside,label+": tall dressing outside playable cells")
	check(story >= 2 and flat > 0,label+": story set and surface decals loaded")
	check(art.find_children("*","CollisionObject3D",true,false).is_empty(),label+": no collision nodes")
	var lamps := art.find_children("*","OmniLight3D",true,false)
	check(not lamps.is_empty(),label+": objective practical light present")
	for lamp in lamps: check(lamp.light_energy > 0.0,label+": practical survives Low")
	for instance in art.find_children("*","GeometryInstance3D",true,false):
		var mesh: Mesh = null
		if instance is MultiMeshInstance3D and instance.multimesh: mesh = instance.multimesh.mesh
		elif instance is MeshInstance3D: mesh = instance.mesh
		if mesh == null: continue
		for i in mesh.get_surface_count():
			var material: Material = instance.material_override if instance.material_override else mesh.surface_get_material(i)
			check(material != null,label+": Low has no missing surface material")

func check_captures() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--captures="): continue
		var path := arg.trim_prefix("--captures=")
		check(FileAccess.file_exists(path),"phone capture table exists")
		if not FileAccess.file_exists(path): return
		var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(rows is Array,"phone capture table parses")
		if not rows is Array: return
		for id in AUDIT:
			for size in ["956x440","844x390","390x844"]:
				var found := false
				for row in rows:
					if str(row.get("id","")) != id or str(row.get("size","")) != size: continue
					found = true
					var draws := int(row.get("draws_peak",0))
					check(draws > 0 and (size == "956x440" or draws <= 150),id+" "+size+": portrait or target draw budget")
					if size == "844x390": check(draws <= int(AUDIT[id]),id+": no 844x390 regression from audit")
					if size == "956x440": check(draws <= int(AUDIT_956[id]),id+": no 956x440 regression from audit")
				check(found,id+" "+size+": captured on real renderer")
		return

func run() -> void:
	var edge_tint := preload("res://scripts/map_art_edges.gd").route_tint(true)
	check(edge_tint.s < 0.4,"art route palette is subdued")
	var art := Art.new(); root.add_child(art)
	var signatures: Dictionary = {}
	for theme in SAMPLES:
		var id: String = SAMPLES[theme]
		var m := Mission.new(17,Maps.resolve(id))
		var before := passability(m)
		var board := m.board.duplicate()
		art.build(m)
		check(art.theme == theme,id+": correct theme")
		check(before == passability(m) and board == m.board,id+": walkability and board unchanged")
		inspect_art(art,m,id)
		var story_records: Array = art.batch.records.filter(func(record): return str(record.get("kind","")).begins_with("w33c "+theme+" story"))
		check(story_records.size() == 1,id+": own theme set loaded")
		if not story_records.is_empty(): signatures[theme] = story_records[0].parts.size()
		await process_frame
		check(art.find_children("*","OmniLight3D",true,false).any(func(lamp): return lamp.light_color.r > lamp.light_color.b*1.2),id+": warm practical active in Low")
	check(signatures.size() == 8,"eight dressing sets loaded")
	# Every authored layout gets a render pass; art must not write map rules.
	var paths: Array = []
	for entry in Maps.manifest().missions.values(): paths.append(str(entry.path))
	paths.append_array(Maps.manifest().web_variants)
	paths.append("res://data/rescue.json")
	for path in paths:
		var m := Mission.new(23,str(path))
		var before := passability(m)
		var board := m.board.duplicate()
		art.build(m)
		check(before == passability(m) and board == m.board,str(path)+": all-map walkability identical")
		await process_frame
	# All art added in this lane is procedural or from shipped imports.
	var inspector := Batch.new()
	for shape in inspector.shapes:
		check(triangles(inspector.shapes[shape]) <= 3000,"new primitive %s <=3K triangles" % shape)
	for name in ["container","barrel","airtaxi","statue","rubble"]:
		var node: Node3D = load("res://assets/maps/%s.glb" % name).instantiate()
		var parts: Array = []
		inspector.collect(node,Transform3D.IDENTITY,parts)
		for part in parts: check(triangles(part.mesh) <= 3000,name+": shipped prop <=3K triangles")
		node.free()
	var snow_path := "res://assets/maps/meshy5/cover_half_snow_v1_lod1.glb"
	inspector.model(snow_path,Vector3.ZERO,0.95,0.8)
	check(inspector.models[snow_path].size() == 1,"untextured imported material splits merge into one surface")
	check_captures()
	art.queue_free(); await process_frame
	print("MAPART33 RESULTS: %d checks, %d failures, %d maps" % [checks,failures,paths.size()])
	quit(1 if failures else 0)
