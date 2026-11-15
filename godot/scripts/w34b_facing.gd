extends RefCounted
## Threat selection and idle model turns. Imported combat meshes face local +Z.
const Shot = preload("res://scripts/shot.gd")
const TURN_SECONDS := 0.20
static var enabled := true

static func position_of(unit: Dictionary) -> Vector2i:
	return Vector2i(int(unit.get("x", 0)), int(unit.get("y", 0)))

static func nearest(origin: Vector2i, positions: Array[Vector2i]) -> Vector2i:
	var best := Vector2i(-1, -1)
	var distance := INF
	for point in positions:
		var candidate := origin.distance_squared_to(point)
		if candidate < distance:
			distance = candidate
			best = point
	return best

static func visible_enemies(mission: RefCounted) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for enemy in mission.units:
		if str(enemy.get("side", "")) != "enemy" or int(enemy.get("hp", 0)) <= 0: continue
		if not bool(enemy.get("spotted", false)): continue
		if mission.modern and not bool(enemy.get("detected", false)): continue
		result.append(position_of(enemy))
	return result

static func spawn_side(mission: RefCounted, origin: Vector2i) -> Vector2i:
	var positions: Array[Vector2i] = []
	for group in mission.spec.get("groups", []):
		for entry in group:
			if entry is Array and entry.size() >= 3: positions.append(Vector2i(int(entry[1]), int(entry[2])))
	if positions.is_empty():
		for enemy in mission.units:
			if str(enemy.get("side", "")) == "enemy": positions.append(position_of(enemy))
	var target := nearest(origin, positions)
	if target != Vector2i(-1, -1): return target
	for objective in mission.objective_tiles():
		if objective is Vector2i and objective != origin: return objective
	return Vector2i(int(mission.spec.width / 2), int(mission.spec.height / 2))

static func target(mission: RefCounted, unit: Dictionary, last_known: Array[Vector2i]) -> Vector2i:
	var origin := position_of(unit)
	if str(unit.get("side", "")) == "enemy":
		var players: Array[Vector2i] = []
		for player in mission.units:
			if str(player.get("side", "")) == "player" and int(player.get("hp", 0)) > 0: players.append(position_of(player))
		return nearest(origin, players)
	var visible := visible_enemies(mission)
	if not visible.is_empty(): return nearest(origin, visible)
	if not last_known.is_empty(): return nearest(origin, last_known)
	return spawn_side(mission, origin)

static func yaw_to(from: Vector3, to: Vector3) -> float:
	var direction := to - from
	return atan2(direction.x, direction.z)

static func idle_ready(view: Node3D) -> bool:
	if not view.alive or view.downed or view.aim_ready or view.model == null: return false
	if Time.get_ticks_msec() < view.idle_lock_until_w34b: return false
	if view.motion != null and view.motion.is_running(): return false
	if view.animation != null and view.animation.current_animation not in [view.base_clip, "idle", "gunIdle", "saberIdle"]: return false
	return true

static func turn_model(view: Node3D, point: Vector3, duration: float = TURN_SECONDS) -> void:
	var direction := point - view.global_position
	if Vector2(direction.x, direction.z).length_squared() < 0.01: return
	var goal := yaw_to(view.global_position, point) - view.rotation.y
	if absf(wrapf(goal - view.model.rotation.y, -PI, PI)) < 0.01: return
	if view.turn_motion != null and view.turn_motion.is_running(): view.turn_motion.kill()
	view.turn_motion = view.create_tween()
	view.turn_motion.tween_property(view.model, "rotation:y", view.model.rotation.y + wrapf(goal - view.model.rotation.y, -PI, PI), duration).set_trans(Tween.TRANS_SINE)

static func update(view: Node3D) -> void:
	if not enabled or not idle_ready(view): return
	var game := view.get_parent().get_parent() if view.get_parent() != null else null
	if game == null or game.get("mission") == null: return
	var mission: RefCounted = game.mission
	var unit: Dictionary = mission.unit_by_id(view.unit_id)
	if unit.is_empty(): return
	var visible := visible_enemies(mission)
	if not visible.is_empty(): view.last_known_w34b = visible.duplicate()
	var wanted := target(mission, unit, view.last_known_w34b)
	if wanted == Vector2i(-1, -1): return
	var origin := position_of(unit)
	if wanted == view.last_idle_target_w34b and origin == view.last_idle_origin_w34b: return
	view.last_idle_target_w34b = wanted
	view.last_idle_origin_w34b = origin
	var at := Vector3(wanted.x, view.global_position.y, wanted.y)
	turn_model(view, at)
