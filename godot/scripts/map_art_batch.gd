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
	var cube := BoxMesh.new(); cube.size = Vector3.ONE; shapes.box = cube; shapes.bevel = _bevel_mesh()
	var ground := PlaneMesh.new(); ground.size = Vector2.ONE; shapes.terrain = ground
	shapes.crag = _crag_mesh()
	var cylinder := CylinderMesh.new(); cylinder.height = 1; cylinder.top_radius = 0.5; cylinder.bottom_radius = 0.5; cylinder.radial_segments = 12; shapes.cylinder = cylinder
	var cone := CylinderMesh.new(); cone.height = 1; cone.top_radius = 0; cone.bottom_radius = 0.5; cone.radial_segments = 9; shapes.cone = cone
	var rock := SphereMesh.new(); rock.radius = 0.5; rock.height = 1; rock.radial_segments = 12; rock.rings = 6; shapes.rock = rock
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES); surface.set_smooth_group(-1)
	var v := [Vector3(-0.5,0,-0.5),Vector3(0.5,0,-0.5),Vector3(-0.5,1,-0.5),Vector3(0.5,1,-0.5),Vector3(-0.5,0,0.5),Vector3(0.5,0,0.5)]
	for index in [2,3,5,2,5,4,0,2,4,1,5,3,0,1,3,0,3,2,0,4,5,0,5,1]: surface.add_vertex(v[index])
	surface.generate_normals(); shapes.ramp = surface.commit()
	var stone_surface := SurfaceTool.new(); stone_surface.begin(Mesh.PRIMITIVE_TRIANGLES); stone_surface.set_smooth_group(-1)
	var rings: Array[Vector3] = []
	var sides := 8
	for level in 3:
		for j in sides:
			var a := TAU*float(j)/float(sides)
			var radius := (0.38 if level == 0 else 0.5 if level == 1 else 0.31)*(0.85+0.15*float(j%3)/2)
			var h := -0.5 if level == 0 else -0.08 if level == 1 else 0.22+0.28*float(j%3)/2
			rings.append(Vector3(cos(a)*radius,h,sin(a)*radius))
	for level in 2:
		for j in sides:
			var k := (j+1)%sides
			for index in [level*sides+j,level*sides+k,(level+1)*sides+k,level*sides+j,(level+1)*sides+k,(level+1)*sides+j]: stone_surface.add_vertex(rings[index])
	for j in sides:
		for vertex in [Vector3(0,0.43,0),rings[2*sides+j],rings[2*sides+(j+1)%sides]]: stone_surface.add_vertex(vertex)
		for vertex in [Vector3(0,-0.5,0),rings[(j+1)%sides],rings[j]]: stone_surface.add_vertex(vertex)
	stone_surface.generate_normals(); shapes.boulder = stone_surface.commit()

func _bevel_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner := 0.43; var outer := 0.5
	for axis in 3:
		var a := (axis+1)%3; var b := (axis+2)%3
		for sign_value in [-1.0,1.0]:
			var corners: Array[Vector3] = []
			for pair in [[-1.0,-1.0],[1.0,-1.0],[1.0,1.0],[-1.0,1.0]]:
				var v := Vector3.ZERO; v[axis] = sign_value*outer; v[a] = pair[0]*inner; v[b] = pair[1]*inner; corners.append(v)
			_add_quad(surface,corners[0],corners[1],corners[2],corners[3])
	for free_axis in 3:
		var a := (free_axis+1)%3; var b := (free_axis+2)%3
		for sa in [-1.0,1.0]:
			for sb in [-1.0,1.0]:
				var points: Array[Vector3] = []
				for end in [-1.0,1.0]:
					for side in [0,1]:
						var v := Vector3.ZERO; v[free_axis] = end*inner
						v[a] = sa*(outer if side == 0 else inner)
						v[b] = sb*(inner if side == 0 else outer)
						points.append(v)
				_add_quad(surface,points[0],points[2],points[3],points[1])
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var x := Vector3(sx*outer,sy*inner,sz*inner)
				var y := Vector3(sx*inner,sy*outer,sz*inner)
				var z := Vector3(sx*inner,sy*inner,sz*outer)
				_add_triangle(surface,x,y,z)
	surface.generate_normals(); return surface.commit()

func _crag_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs := [-0.5,-0.26,0.02,0.27,0.5]
	var tops := [0.43,0.50,0.46,0.49,0.42]
	var fronts := [0.38,0.50,0.39,0.48,0.42]
	for i in 4:
		var a := Vector3(xs[i],-0.5,fronts[i])
		var b := Vector3(xs[i+1],-0.5,fronts[i+1])
		var c := Vector3(xs[i+1],tops[i+1],fronts[i+1])
		var d := Vector3(xs[i],tops[i],fronts[i])
		_add_quad(surface,a,b,c,d)
		_add_quad(surface,Vector3(xs[i+1],-0.5,-0.5),Vector3(xs[i],-0.5,-0.5),Vector3(xs[i],tops[i],-0.5),Vector3(xs[i+1],tops[i+1],-0.5))
		_add_quad(surface,d,c,Vector3(xs[i+1],tops[i+1],-0.5),Vector3(xs[i],tops[i],-0.5))
	for i in [0,4]:
		_add_quad(surface,Vector3(xs[i],-0.5,-0.5),Vector3(xs[i],-0.5,fronts[i]),Vector3(xs[i],tops[i],fronts[i]),Vector3(xs[i],tops[i],-0.5))
	surface.generate_normals(); return surface.commit()

func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_triangle(surface,a,b,c); _add_triangle(surface,a,c,d)

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (b-a).cross(c-a).dot((a+b+c)/3.0) < 0.0:
		var swap := b; b = c; c = swap
	for v in [a,b,c]: surface.add_vertex(v)

func put(shape: String, mat: Material, at: Vector3, size: Vector3, angle := 0.0) -> AABB:
	var transform := Transform3D(Basis(Vector3.UP,angle)*Basis.from_scale(size),at)
	return add_mesh(shapes[shape],mat,transform)

func add_mesh(mesh: Mesh, mat: Material, transform: Transform3D) -> AABB:
	var role := str(current.get("role","terrain"))
	var shadows := role not in ["detail","objective"] and str(current.get("kind","")) not in ["skyline","distant landscape"]
	# The mesh and material already define a compatible static batch. Only the
	# visibility/shadow policy needs to split it; cover and terrain can share.
	var visibility := "scenery" if role == "scenery" else "board"
	var key := "%d:%d:%s:%s" % [mesh.get_instance_id(),mat.get_instance_id() if mat else 0,visibility,shadows]
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

func model(path: String, at: Vector3, width: float, height: float, angle := 0.0, uniform := false) -> AABB:
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
	var scale_value := Vector3.ONE*minf(factor,height/bounds.size.y) if uniform else Vector3(factor,height/bounds.size.y,factor)
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
