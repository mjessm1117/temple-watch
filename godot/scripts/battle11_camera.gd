extends RefCounted
## Camera framing stays on the playable board without changing tile or unit geometry.

static func _phone_view() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and preload("res://scripts/phone_layout.gd").narrow(tree.root.size)

static func battle_heading(m: RefCounted) -> float:
	var allies: Array = m.living("player")
	if allies.is_empty(): return 0.0
	var squad := Vector2.ZERO
	for unit in allies: squad += Vector2(float(unit.x), float(unit.y))
	squad /= float(allies.size())
	var target := Vector2.ZERO
	var count := 0
	var points: Array = []
	var objective: Dictionary = m.spec.get("objective", {})
	for point in objective.get("points", []): points.append(Vector2i(int(point[0]), int(point[1])))
	if points.is_empty() and bool(m.prisoner.get("active", false)):
		points.append(Vector2i(int(m.prisoner.x), int(m.prisoner.y)))
	for point in points:
		target += Vector2(point); count += 1
	var threats: Array = m.living("enemy")
	if not threats.is_empty():
		var enemy_center := Vector2.ZERO
		for enemy in threats: enemy_center += Vector2(float(enemy.x), float(enemy.y))
		target += enemy_center / float(threats.size()); count += 1
	if count == 0: return 0.0
	var toward: Vector2 = target / float(count) - squad
	if toward.length_squared() < 0.01: return 0.0
	var behind := -toward
	return snappedf(atan2(behind.x, behind.y), PI / 4.0)

static func start_zoom(m: RefCounted) -> float:
	if _phone_view():
		return clampf(maxf(float(m.spec.width), float(m.spec.height)) * 1.1, 26.0, 32.0)
	return clampf(maxf(float(m.spec.width), float(m.spec.height)) * 0.66, 11.0, 26.0) if m.modern else 12.0

static func selected_zoom(m: RefCounted) -> float:
	if _phone_view():
		return clampf(start_zoom(m) / 2.3, 11.0, 13.0)
	return clampf(start_zoom(m) / 2.35, 8.0, 12.0)

static func target_zoom(m: RefCounted, separation: float) -> float:
	return clampf(maxf(selected_zoom(m), separation * 1.25), 6.0, 22.0)

static func phone_focus(point: Vector3, yaw: float, distance: float = 0.8) -> Vector3:
	if not _phone_view(): return point
	return point - Vector3(sin(yaw),0.0,cos(yaw)) * distance

static func clamp_zoom(value: float) -> float:
	return clampf(value, 9.0, 65.0)

static func clamp_pivot(m: RefCounted, point: Vector3) -> Vector3:
	var edge := 1.0
	return Vector3(clampf(point.x, edge, maxf(edge, float(m.spec.width) - 1.0 - edge)), 0.0, clampf(point.z, edge, maxf(edge, float(m.spec.height) - 1.0 - edge)))

static func safe_position(m: RefCounted, point: Vector3) -> Vector3:
	var minimum_height := 2.3 if bool(m.get("presentation_active")) else 5.0
	if _phone_view():
		return Vector3(point.x, maxf(minimum_height, point.y), point.z)
	return Vector3(clampf(point.x, 0.5, float(m.spec.width) - 1.5), maxf(minimum_height, point.y), clampf(point.z, 0.5, float(m.spec.height) - 1.5))

static func aim_position(m: RefCounted, point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, -18.0, float(m.spec.width) + 17.0), maxf(1.7, point.y), clampf(point.z, -18.0, float(m.spec.height) + 17.0))
