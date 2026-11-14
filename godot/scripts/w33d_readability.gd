extends RefCounted
## Cheap, depth-independent tactical marks shared by range and preview.
const Shot = preload("res://scripts/shot.gd")
const FULL := Color("e9fbff")
const HALF := Color("ffde81")
const INK := Color("10202d")

static func shield_mesh(full: bool, scale_value: float = 1.0) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var points := [Vector2(-0.20, -0.17), Vector2(0.20, -0.17), Vector2(0.17, 0.08), Vector2(0, 0.25), Vector2(-0.17, 0.08)]
	for i in range(1, 4):
		for j in [0, i, i + 1]:
			vertices.append(Vector3(points[j].x * 1.65 * scale_value, -points[j].y * 1.65 * scale_value, 0))
			colors.append(INK)
	var inner := [Vector2(-0.24, -0.20), Vector2(0.24, -0.20), Vector2(0.20, 0.10), Vector2(0, 0.30), Vector2(-0.20, 0.10)]
	if not full:
		inner = [Vector2(-0.24, -0.20), Vector2(0, -0.20), Vector2(0, 0.30), Vector2(-0.20, 0.10), Vector2(-0.24, 0.10)]
	for i in range(1, 4):
		for j in [0, i, i + 1]:
			vertices.append(Vector3(inner[j].x * scale_value, -inner[j].y * scale_value, 0))
			colors.append(FULL if full else HALF)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func shield_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	return mat

static func silhouette_mesh() -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var body := [Vector2(-0.25, -0.06), Vector2(0.25, -0.06), Vector2(0.20, 0.20), Vector2(0.12, 0.22), Vector2(0.13, 0.59), Vector2(-0.13, 0.59), Vector2(-0.12, 0.22), Vector2(-0.20, 0.20)]
	_add_silhouette_part(vertices, colors, body, INK, 1.25)
	_add_silhouette_part(vertices, colors, body, FULL, 0.83)
	var head := []
	for i in 10:
		var angle := TAU * float(i) / 10.0
		head.append(Vector2(cos(angle) * 0.13, sin(angle) * 0.13 - 0.22))
	_add_silhouette_part(vertices, colors, head, INK, 1.25)
	_add_silhouette_part(vertices, colors, head, FULL, 0.82)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices); arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func _add_silhouette_part(vertices: Array[Vector3], colors: Array[Color], polygon: Array, tint: Color, scale_value: float) -> void:
	for i in range(1, polygon.size() - 1):
		for j in [0, i, i + 1]:
			vertices.append(Vector3(polygon[j].x * scale_value, -polygon[j].y * scale_value, 0))
			colors.append(tint)

static func cover_marks(m: RefCounted, tiles: Dictionary) -> Dictionary:
	var result := {"full": [], "half": []}
	for tile in tiles:
		var best := 0
		for direction in Shot.DIRS:
			best = maxi(best, Shot.cover(m, tile, tile + direction * 2))
		if best == 0: continue
		var at := Vector3(tile.x, Shot.elevation(m, tile) * 0.7 + 0.50, tile.y)
		result["full" if best == 40 else "half"].append(at)
	return result

static func tile_threat(m: RefCounted, tile: Vector2i, fallback: Dictionary) -> Dictionary:
	var data: Dictionary = m.w33b_tile_tactics(tile) if m.has_method("w33b_tile_tactics") else fallback
	var watch: Variant = data.get("overwatch", data.get("overwatch_threat", fallback.get("overwatch", 0)))
	var flank: Variant = data.get("flanked_by", data.get("flank_count", fallback.get("flanked_by", 0)))
	return {"overwatch": watch.size() if watch is Array else int(watch), "flanked_by": flank.size() if flank is Array else int(flank)}

static func fallback_threat(m: RefCounted, actor: Dictionary, tile: Vector2i) -> Dictionary:
	var projected := actor.duplicate()
	projected.x = tile.x; projected.y = tile.y
	var watch := 0
	var flank := 0
	for enemy in m.living("enemy"):
		if int(enemy.hp) <= 0 or not bool(enemy.get("spotted", true)): continue
		var shot: Dictionary = Shot.calculate(m, enemy, projected)
		if not bool(shot.get("los", false)) or not bool(shot.get("range_ok", false)): continue
		if bool(enemy.get("overwatch", false)): watch += 1
		if bool(shot.get("flanked", false)): flank += 1
	return {"overwatch": watch, "flanked_by": flank}

static func warning_text(threat: Dictionary) -> String:
	var warnings: Array[String] = []
	if int(threat.get("overwatch", 0)) > 0: warnings.append("OVERWATCH %d" % int(threat.overwatch))
	if int(threat.get("flanked_by", 0)) > 0: warnings.append("WOULD BE FLANKED BY %d" % int(threat.flanked_by))
	return "  ·  ".join(warnings)

static func occluded(m: RefCounted, camera_position: Vector3, unit_position: Vector3, records: Array = []) -> bool:
	for record in records:
		if str(record.get("role", "")) != "cover" or not record.get("bounds") is AABB: continue
		var bounds: AABB = record.bounds
		if not bounds.has_point(unit_position) and bounds.intersects_segment(camera_position, unit_position + Vector3.UP * 0.9): return true
	var start := Vector2i(roundi(camera_position.x), roundi(camera_position.z))
	var finish := Vector2i(roundi(unit_position.x), roundi(unit_position.z))
	var line := Shot.line(start, finish)
	for i in range(1, line.size() - 1):
		var tile: Vector2i = line[i]
		if not m.in_bounds(tile): continue
		var top := Shot.elevation(m, tile) * 0.7 + (1.9 if Shot.full(m.tile(tile)) else 0.8 if Shot.half(m.tile(tile)) else 0.0)
		var sight := lerpf(camera_position.y, unit_position.y + 0.9, float(i) / float(line.size() - 1))
		if top > sight: return true
	return false
