extends RefCounted
## Camera framing stays on the playable board without changing tile or unit geometry.

static func start_zoom(m: RefCounted) -> float:
	return clampf(maxf(float(m.spec.width), float(m.spec.height)) * 0.66, 11.0, 26.0) if m.modern else 12.0

static func clamp_pivot(m: RefCounted, point: Vector3) -> Vector3:
	var edge := 1.0
	return Vector3(clampf(point.x, edge, maxf(edge, float(m.spec.width) - 1.0 - edge)), 0.0, clampf(point.z, edge, maxf(edge, float(m.spec.height) - 1.0 - edge)))

static func safe_position(m: RefCounted, point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, 0.5, float(m.spec.width) - 1.5), maxf(5.0, point.y), clampf(point.z, 0.5, float(m.spec.height) - 1.5))
