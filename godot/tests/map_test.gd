extends RefCounted

const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const ENTRY := Vector2i(5, 22)
const GOAL := Vector2i(10, 6)
const LANES := [Vector2i(4, 14), Vector2i(10, 14), Vector2i(16, 14)]

static func _wide(m: RefCounted, p: Vector2i) -> bool:
	for y in range(p.y - 1, p.y + 2):
		for x in range(p.x - 1, p.x + 2):
			if not m.passable(Vector2i(x, y)): return false
	return true

static func _path(m: RefCounted, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not _wide(m, start) or not _wide(m, goal): return []
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == goal: break
		for d in Shot.DIRS:
			var q: Vector2i = p + d
			if previous.has(q) or not _wide(m, q): continue
			previous[q] = p
			queue.append(q)
	if not previous.has(goal): return []
	var path: Array[Vector2i] = []
	var p: Vector2i = goal
	while p != start:
		path.push_front(p)
		p = previous[p]
	path.push_front(start)
	return path

static func _cover_stop(m: RefCounted, p: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q: Vector2i = p + offset
		for d in Shot.DIRS:
			if m.tile(q + d) in ["c", "h", "k", "#"]: return true
	return false

static func _longest_cover_gap(m: RefCounted, path: Array[Vector2i]) -> int:
	var gap := 0
	var longest := 0
	for p in path:
		if _cover_stop(m, p): gap = 0
		else: gap += 1
		longest = max(longest, gap)
	return longest

static func run_checks(_runner: SceneTree, check: Callable) -> void:
	var m = Mission.new(1)
	var walk := _path(m, ENTRY, GOAL)
	check.call(not walk.is_empty() and walk.size() - 1 <= 22, "map entry-to-prisoner wide path <=22 steps (got %d)" % (walk.size() - 1))
	var route_count := 0
	for lane in LANES:
		var clear_span := true
		for y in range(14, 21):
			if not _wide(m, Vector2i(lane.x, y)): clear_span = false
		if not clear_span: continue
		var approach := _path(m, ENTRY, lane)
		var finish := _path(m, lane, GOAL)
		var route: Array[Vector2i] = approach.duplicate()
		if not finish.is_empty():
			finish.remove_at(0)
			route.append_array(finish)
		if route.is_empty() or finish.is_empty(): continue
		route_count += 1
		check.call(_longest_cover_gap(m, route) <= 4, "map lane %d cover gap <=4 (got %d)" % [lane.x, _longest_cover_gap(m, route)])
	check.call(route_count >= 3, "map has three distinct three-tile-wide routes (got %d)" % route_count)
	var ramps := 0
	for y in range(int(m.spec.height)):
		for x in range(int(m.spec.width)):
			var p := Vector2i(x, y)
			if m.tile(p) != "^": continue
			for d in Shot.DIRS:
				if m.tile(p + d) == "M": ramps += 1; break
	check.call(ramps >= 2, "eastern high ground has two ramps (got %d)" % ramps)
	print("map: %d wide routes, shortest %d steps, %d high-ground ramps" % [route_count, walk.size() - 1, ramps])
