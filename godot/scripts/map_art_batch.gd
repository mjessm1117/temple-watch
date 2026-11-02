extends RefCounted
## Static art is batched by mesh/material, including imported GLB submeshes.
## Bounds use the same complete transform chain as the rendered instances.
var buckets: Dictionary = {}
var models: Dictionary = {}
var shapes: Dictionary = {}
var records: Array[Dictionary] = []
var current: Dictionary = {}
var record_first := true

func _init() -> void:
	var cube := BoxMesh.new(); cube.size = Vector3.ONE; shapes.box = cube
	var cylinder := CylinderMesh.new(); cylinder.height = 1; cylinder.top_radius = 0.5; cylinder.bottom_radius = 0.5; cylinder.radial_segments = 12; shapes.cylinder = cylinder
	var cone := CylinderMesh.new(); cone.height = 1; cone.top_radius = 0; cone.bottom_radius = 0.5; cone.radial_segments = 9; shapes.cone = cone
	var rock := SphereMesh.new(); rock.radius = 0.5; rock.height = 1; rock.radial_segments = 9; rock.rings = 4; shapes.rock = rock
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES); surface.set_smooth_group(-1)
	var v := [Vector3(-0.5,0,-0.5),Vector3(0.5,0,-0.5),Vector3(-0.5,1,-0.5),Vector3(0.5,1,-0.5),Vector3(-0.5,0,0.5),Vector3(0.5,0,0.5)]
	for index in [2,3,5,2,5,4,0,2,4,1,5,3,0,1,3,0,3,2,0,4,5,0,5,1]: surface.add_vertex(v[index])
	surface.generate_normals(); shapes.ramp = surface.commit()
	var stone_surface := SurfaceTool.new(); stone_surface.begin(Mesh.PRIMITIVE_TRIANGLES); stone_surface.set_smooth_group(-1)
	var rings: Array[Vector3] = []
	for level in 3:
		for j in 8:
			var a := TAU*float(j)/8.0
			var radius := (0.38 if level == 0 else 0.5 if level == 1 else 0.31)*(0.85+0.15*float(j%3)/2)
			var h := -0.5 if level == 0 else -0.08 if level == 1 else 0.22+0.28*float(j%3)/2
			rings.append(Vector3(cos(a)*radius,h,sin(a)*radius))
	for level in 2:
		for j in 8:
			var k := (j+1)%8
			for index in [level*8+j,level*8+k,(level+1)*8+k,level*8+j,(level+1)*8+k,(level+1)*8+j]: stone_surface.add_vertex(rings[index])
	for j in 8:
		for vertex in [Vector3(0,0.43,0),rings[16+j],rings[16+(j+1)%8]]: stone_surface.add_vertex(vertex)
		for vertex in [Vector3(0,-0.5,0),rings[(j+1)%8],rings[j]]: stone_surface.add_vertex(vertex)
	stone_surface.generate_normals(); shapes.boulder = stone_surface.commit()

func put(shape: String, mat: Material, at: Vector3, size: Vector3, angle := 0.0) -> AABB:
	var transform := Transform3D(Basis(Vector3.UP,angle)*Basis.from_scale(size),at)
	return add_mesh(shapes[shape],mat,transform)

func add_mesh(mesh: Mesh, mat: Material, transform: Transform3D) -> AABB:
	var role := str(current.get("role","terrain"))
	var shadows := role not in ["detail","objective"] and str(current.get("kind","")) not in ["skyline","distant landscape"]
	var key := "%d:%d:%s:%s" % [mesh.get_instance_id(),mat.get_instance_id() if mat else 0,role,shadows]
	if not buckets.has(key): buckets[key] = {"mesh":mesh,"material":mat,"transforms":[],"role":role,"shadows":shadows}
	buckets[key].transforms.append(transform)
	var bounds := transform*mesh.get_aabb()
	if not current.is_empty():
		current.bounds = bounds if record_first else current.bounds.merge(bounds)
		current.parts.append(bounds)
		record_first = false
	return bounds

func collect(node: Node3D, parent: Transform3D, out: Array) -> void:
	var transform := parent*node.transform
	if node is MeshInstance3D and node.mesh:
		out.append({"mesh":node.mesh,"material":node.material_override,"transform":transform})
	for child in node.get_children():
		if child is Node3D: collect(child,transform,out)

func model(path: String, at: Vector3, width: float, height: float, angle := 0.0) -> AABB:
	if not models.has(path):
		if not ResourceLoader.exists(path): return AABB()
		var instance: Node3D = load(path).instantiate()
		var parts: Array = []; collect(instance,Transform3D.IDENTITY,parts)
		models[path] = parts; instance.free()
	var parts: Array = models[path]
	var rotate := Transform3D(Basis(Vector3.UP,angle),Vector3.ZERO)
	var bounds := AABB(); var first := true
	for part in parts:
		var b: AABB = rotate*part.transform*part.mesh.get_aabb()
		bounds = b if first else bounds.merge(b); first = false
	if bounds.size.y < 0.001: return AABB()
	var factor := width/maxf(bounds.size.x,bounds.size.z)
	var scale_value := Vector3(factor,height/bounds.size.y,factor)
	var fit := Transform3D(Basis.from_scale(scale_value),at-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale_value)
	var actual := AABB(); first = true
	for part in parts:
		var b := add_mesh(part.mesh,part.material,fit*rotate*part.transform)
		actual = b if first else actual.merge(b); first = false
	return actual

func flush(parent: Node3D) -> void:
	for bucket in buckets.values():
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = bucket.mesh; mm.instance_count = bucket.transforms.size()
		for i in mm.instance_count: mm.set_instance_transform(i,bucket.transforms[i])
		var instance := MultiMeshInstance3D.new(); instance.multimesh = mm; instance.material_override = bucket.material
		if not bucket.shadows: instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if bucket.role == "scenery":
			instance.visibility_range_end = 95.0
			instance.visibility_range_end_margin = 8.0
		parent.add_child(instance)
	buckets.clear()

func begin_record(data: Dictionary) -> void:
	current = data.duplicate(); current.parts = []; record_first = true

func end_record() -> void:
	if not record_first: records.append(current)
	current = {}
