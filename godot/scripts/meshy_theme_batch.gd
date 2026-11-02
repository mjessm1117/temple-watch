extends "res://scripts/map_art_batch.gd"
## Spatial MultiMeshes retain batching while GeometryInstance3D handles both LODs.
const BaseBatch = preload("res://scripts/map_art_batch.gd")
const CELL := 16.0
var lod_distance := 26.0
var lod_groups: Dictionary = {}
var material_lift: Dictionary = {}

func reset_lods() -> void:
	lod_groups.clear()

func pair(path: String, at: Vector3, width: float, height: float, angle := 0.0) -> bool:
	var low := path.trim_suffix(".glb")+"_lod1.glb"
	if path.is_empty() or not ResourceLoader.exists(path) or not ResourceLoader.exists(low): return false
	prepare(path,float(material_lift.get(path,0.0)))
	prepare(low,float(material_lift.get(path,0.0)))
	var cell := Vector2i(floori(at.x/CELL),floori(at.z/CELL))
	var key := "%s:%s:%s" % [path,cell,current.get("role","cover")]
	if not lod_groups.has(key):
		lod_groups[key] = {"batches":[BaseBatch.new(),BaseBatch.new()],"bounds":AABB(),"first":true}
	var group: Dictionary = lod_groups[key]
	for i in 2:
		var target = group.batches[i]; target.models = models
		target.begin_record(current)
		var bounds: AABB = target.model(path if i == 0 else low,at,width,height,angle,true)
		target.end_record()
		group.bounds = bounds if group.first else group.bounds.merge(bounds); group.first = false
		# Both LODs are audited against the same tile and real floor height.
		if not current.is_empty():
			current.bounds = bounds if record_first else current.bounds.merge(bounds)
			current.parts.append(bounds); current["meshy_path"] = path
			record_first = false
	return true

func flush(parent: Node3D) -> void:
	super.flush(parent)
	for group in lod_groups.values():
		for i in 2:
			var holder := Node3D.new(); holder.name = "MeshyLOD%d" % i; parent.add_child(holder)
			group.batches[i].flush(holder)
			for instance: MultiMeshInstance3D in holder.get_children():
				# Identical pair bounds synchronize the range origin for every material.
				instance.custom_aabb = group.bounds
				instance.visibility_range_begin = lod_distance if i == 1 else 0.0
				instance.visibility_range_end = lod_distance if i == 0 else 0.0
				instance.visibility_range_begin_margin = 0.0
				instance.visibility_range_end_margin = 0.0
				instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	lod_groups.clear()

func prepare(path: String, lift: float) -> void:
	if models.has(path) or lift <= 0: return
	var instance: Node3D = load(path).instantiate()
	var parts: Array = []; collect(instance,Transform3D.IDENTITY,parts); instance.free()
	for part in parts:
		var mesh: ArrayMesh = part.mesh.duplicate()
		for surface in mesh.get_surface_count():
			var original: Material = part.material if part.material else mesh.surface_get_material(surface)
			if not original is StandardMaterial3D: continue
			var mat: StandardMaterial3D = original.duplicate()
			if mat.albedo_texture:
				var pixels := mat.albedo_texture.get_image()
				if pixels.is_compressed(): pixels.decompress()
				# Lift crushed texture blacks without changing geometry or asset files.
				pixels.adjust_bcs(1.0,1.0-lift*2.0,1.0)
				mat.albedo_texture = ImageTexture.create_from_image(pixels)
			else: mat.albedo_color = mat.albedo_color.lightened(lift)
			mesh.surface_set_material(surface,mat)
		part.mesh = mesh; part.material = null
	models[path] = parts
