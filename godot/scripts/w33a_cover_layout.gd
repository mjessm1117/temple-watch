extends RefCounted
## Adds spaced cover to the authored pockets while preserving the plot's three-wide routes.
const Validator = preload("res://scripts/map_validator.gd")
const COVER_IDS = ["relay", "rescue", "shrine", "archive", "sabotage", "envoy", "dock", "vault", "ilum", "adraasHunt"]

static func apply(rows: Array[String], data: Dictionary, seed_value: int) -> void:
	if str(data.get("id", "")) not in COVER_IDS: return
	var full := 0
	var half := 0
	for y in range(1, rows.size() - 1):
		for x in range(1, rows[y].length() - 1):
			if rows[y][x] == "#": full += 1
			elif rows[y][x] in ["c", "h", "k"]: half += 1
	var anchors := {}
	for at in data.objective.points + data.entries + data.evac:
		anchors[Vector2i(int(at[0]), int(at[1]))] = true
	for unit in data.squad:
		anchors[Vector2i(int(unit[1]), int(unit[2]))] = true
	for group in data.groups:
		for unit in group: anchors[Vector2i(int(unit[1]), int(unit[2]))] = true
	anchors[Vector2i(int(data.prisoner.x), int(data.prisoner.y))] = true
	if str(data.id) == "relay":
		for at in [Vector2i(12,16), Vector2i(13,16), Vector2i(14,16), Vector2i(9,18), Vector2i(10,18)]: anchors[at] = true
	var candidates: Array[Vector2i] = []
	for y in range(2, rows.size() - 2):
		for x in range(2, rows[y].length() - 2):
			var p := Vector2i(x, y)
			if rows[y][x] != "." or _route(data.plot, p) or _near_anchor(anchors, p): continue
			candidates.append(p)
	var salt: int = seed_value if bool(data.get("procedural", false)) else 0
	var lean := str(data.id) in ["rescue", "shrine"]
	var target_full := 14 if lean else 18
	var target_half := 20 if lean else 28
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _rank(a, str(data.id).hash() + salt) < _rank(b, str(data.id).hash() + salt))
	for tile in ["#", "c"]:
		var target := target_full if tile == "#" else target_half
		var count := full if tile == "#" else half
		for p in candidates:
			if count >= target: break
			if rows[p.y][p.x] != "." or not _safe_neighbors(rows, p): continue
			var old: String = rows[p.y]
			rows[p.y] = old.substr(0, p.x) + tile + old.substr(p.x + 1)
			var topology := Validator.topology(rows)
			if int(topology.components) != 1 or not topology.cuts.is_empty(): rows[p.y] = old
			else: count += 1
		if tile == "#": full = count
		else: half = count
	# Fill any uncovered stretch of a plot approach after the broad distribution.
	for lane in data.plot.lanes:
		for y in range(3, rows.size() - 3):
			if _cover_within(rows, Vector2i(int(lane), y), 4): continue
			for p in candidates:
				if absi(p.x - int(lane)) > 3 or absi(p.y - y) > 2: continue
				if rows[p.y][p.x] != "." or not _safe_neighbors(rows, p): continue
				var tile := "#" if full < 22 else "c"
				if tile == "c" and half >= 35: break
				var old: String = rows[p.y]
				rows[p.y] = old.substr(0, p.x) + tile + old.substr(p.x + 1)
				var topology := Validator.topology(rows)
				if int(topology.components) != 1 or not topology.cuts.is_empty(): rows[p.y] = old
				else:
					if tile == "#": full += 1
					else: half += 1
					break
	# Balance spawn pockets after the approach chains are complete.
	for attempt in range(35 - half):
		var tilt := _local_cover(rows, data.groups) - _local_cover(rows, [data.squad])
		if tilt <= 1.0: break
		var placed := false
		for p in candidates:
			if rows[p.y][p.x] != "." or not _near_team(data.squad, p): continue
			var old: String = rows[p.y]
			rows[p.y] = old.substr(0, p.x) + "c" + old.substr(p.x + 1)
			var topology := Validator.topology(rows)
			var next_tilt := _local_cover(rows, data.groups) - _local_cover(rows, [data.squad])
			if int(topology.components) == 1 and topology.cuts.is_empty() and next_tilt < tilt:
				half += 1; placed = true; break
			rows[p.y] = old
		if not placed: break

static func _route(plot: Dictionary, p: Vector2i) -> bool:
	for x in plot.lanes:
		if absi(p.x - int(x)) <= 1: return true
	for y in plot.crossings:
		if absi(p.y - int(y)) <= 1: return true
	return false

static func _near_anchor(anchors: Dictionary, p: Vector2i) -> bool:
	for at in anchors:
		if maxi(absi(p.x - at.x), absi(p.y - at.y)) <= 1: return true
	return false

static func _safe_neighbors(rows: Array[String], p: Vector2i) -> bool:
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q: Vector2i = p + d
		if rows[q.y][q.x] in ["#", "c", "h", "k", "w"]: return false
	return true

static func _rank(p: Vector2i, salt: int) -> int:
	return posmod((p.x * 73856093) ^ (p.y * 19349663) ^ salt, 2147483647)

static func _cover_within(rows: Array[String], at: Vector2i, radius: int) -> bool:
	for y in range(maxi(1, at.y - radius), mini(rows.size() - 1, at.y + radius + 1)):
		for x in range(maxi(1, at.x - radius), mini(rows[y].length() - 1, at.x + radius + 1)):
			if rows[y][x] in ["#", "c", "h", "k"]: return true
	return false

static func _near_team(team: Array, p: Vector2i) -> bool:
	for u in team:
		if absi(p.x - int(u[1])) + absi(p.y - int(u[2])) <= 5: return true
	return false

static func _near_groups(groups: Array, p: Vector2i) -> bool:
	for group in groups:
		if _near_team(group, p): return true
	return false

static func _local_cover(rows: Array[String], groups: Array) -> float:
	var total := 0.0
	var units := 0
	for group in groups:
		for u in group:
			units += 1
			var at := Vector2i(int(u[1]), int(u[2]))
			for y in range(maxi(1, at.y - 5), mini(rows.size() - 1, at.y + 6)):
				for x in range(maxi(1, at.x - 5), mini(rows[y].length() - 1, at.x + 6)):
					if absi(x - at.x) + absi(y - at.y) <= 5 and rows[y][x] in ["#", "c", "h", "k"]: total += 1.0
	return total / maxf(1.0, float(units))
