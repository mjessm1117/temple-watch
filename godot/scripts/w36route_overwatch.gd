extends RefCounted
## Visualize the approach toward the closest opponent that can trigger armed fire.
const Shot = preload("res://scripts/shot.gd")
const Threat = preload("res://scripts/w24_threat_route.gd")
const Facing = preload("res://scripts/w34b_facing.gd")

static func lane(m: RefCounted, watcher: Dictionary) -> Dictionary:
	var source: Vector2i = Shot.pos(watcher)
	var opponents: Array = m.living("enemy" if str(watcher.side) == "player" else "player")
	if opponents.is_empty(): return {}
	var target: Vector2i = Facing.target(m, watcher, [])
	var nearest: Dictionary = opponents[0]
	for unit in opponents:
		if Shot.pos(unit) == target: nearest = unit; break
	var delta: Vector2 = Vector2(target - source)
	if delta.length_squared() < 0.1: return {}
	var direction := delta.normalized()
	var far := Vector2i(-1, -1)
	for angle in [0.0, -0.35, 0.35, -0.7, 0.7]:
		var ray: Vector2 = direction.rotated(angle)
		for step in range(1, mini(9, int(ceilf(float(watcher.range))) + 1)):
			var tile := source + Vector2i(roundi(ray.x * step), roundi(ray.y * step))
			if not m.in_bounds(tile): break
			if not Threat.reaction_info(m, watcher, nearest, tile).is_empty(): far = tile
		if far.x >= 0: break
	if far.x < 0: return {}
	return {"from": source, "to": far, "side": str(watcher.side), "watcher": watcher}

static func mesh(m: RefCounted) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for watcher in m.living("player") + m.living("enemy"):
		if not bool(watcher.get("overwatch", false)) or int(watcher.get("ammo", 1)) <= 0: continue
		if str(watcher.side) == "enemy" and not bool(watcher.get("spotted", false)): continue
		var data := lane(m, watcher)
		if data.is_empty(): continue
		var start: Vector2i = data["from"]
		var finish: Vector2i = data["to"]
		var a := Vector3(start.x, Shot.elevation(m, start) * 0.7 + 0.19, start.y)
		var b := Vector3(finish.x, Shot.elevation(m, finish) * 0.7 + 0.19, finish.y)
		var direction := Vector2(finish - start).normalized()
		var side: Vector3 = Vector3(-direction.y, 0.0, direction.x)
		var wide := 0.95
		var tint := Color("70d3ee") if data.side == "player" else Color("ef8e72")
		triangle(vertices, colors, a, b - side * wide, b + side * wide, Color(tint.r, tint.g, tint.b, 0.28))
		for edge in [-1.0, 1.0]:
			var tip: Vector3 = b + side * wide * edge
			var inner: Vector3 = b + side * (wide - 0.12) * edge
			triangle(vertices, colors, a, tip, inner, Color(tint.r, tint.g, tint.b, 0.88))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var result := ArrayMesh.new()
	if not vertices.is_empty(): result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

static func triangle(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	for point in [a, b, c]:
		vertices.append(point)
		colors.append(tint)
