extends RefCounted
## Camera framing stays on the playable board without changing tile or unit geometry.

static func _phone_view() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and preload("res://scripts/phone_layout.gd").narrow(tree.root.size)

static func start_zoom(m: RefCounted) -> float:
	if _phone_view():
		return clampf(maxf(float(m.spec.width), float(m.spec.height)) * 1.1, 26.0, 32.0)
	return clampf(maxf(float(m.spec.width), float(m.spec.height)) * 0.66, 11.0, 26.0) if m.modern else 12.0

static func selected_zoom(m: RefCounted) -> float:
	if _phone_view():
		return clampf(start_zoom(m) / 2.2, 13.0, 20.0)
	return clampf(start_zoom(m) / 2.5, 6.0, 13.0)

static func target_zoom(m: RefCounted, separation: float) -> float:
	return clampf(maxf(selected_zoom(m), separation * 1.25), 6.0, 22.0)

static func clamp_zoom(value: float) -> float:
	return clampf(value, 9.0, 65.0)

static func clamp_pivot(m: RefCounted, point: Vector3) -> Vector3:
	var edge := 1.0
	return Vector3(clampf(point.x, edge, maxf(edge, float(m.spec.width) - 1.0 - edge)), 0.0, clampf(point.z, edge, maxf(edge, float(m.spec.height) - 1.0 - edge)))

static func safe_position(m: RefCounted, point: Vector3) -> Vector3:
	if _phone_view():
		return Vector3(clampf(point.x, -8.0, float(m.spec.width) + 7.0), maxf(5.0, point.y), clampf(point.z, -8.0, float(m.spec.height) + 7.0))
	return Vector3(clampf(point.x, 0.5, float(m.spec.width) - 1.5), maxf(5.0, point.y), clampf(point.z, 0.5, float(m.spec.height) - 1.5))

static func aim_position(m: RefCounted, point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, -18.0, float(m.spec.width) + 17.0), maxf(1.7, point.y), clampf(point.z, -18.0, float(m.spec.height) + 17.0))
