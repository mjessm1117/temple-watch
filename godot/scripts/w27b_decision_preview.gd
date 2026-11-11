extends RefCounted
## One route calculation shared by the board, destination card, and phone HUD.
const Shot = preload("res://scripts/shot.gd")

static func _flank_count(m: RefCounted, actor: Dictionary, at: Vector2i) -> int:
	var probe: Dictionary = actor.duplicate()
	probe.x = at.x; probe.y = at.y
	var count := 0
	for enemy in m.living("enemy" if str(actor.side) == "player" else "player"):
		if str(enemy.side) == "enemy" and not bool(enemy.awake): continue
		var info: Dictionary = Shot.calculate(m, enemy, probe)
		if bool(info.los) and bool(info.range_ok) and bool(info.flanked): count += 1
	return count

static func _entry_tiles(m: RefCounted) -> Array:
	if not m.has_method("wave_entry27"): return []
	var wave: Variant = m.call("wave_entry27", m)
	if not wave is Dictionary: return []
	var out: Array = wave.get("entry_tiles", wave.get("tiles", []))
	if wave.get("entry_tile") is Vector2i and wave.entry_tile not in out: out.append(wave.entry_tile)
	return out

static func build(m: RefCounted, actor_id: int, tile: Vector2i) -> Dictionary:
	var empty := {"path": [], "events": [], "cover": "none", "cover_value": 0, "height": 0, "flank": 0, "flank_exposed": false, "odds_delta": 0, "ap": 0}
	if not m.in_bounds(tile): return empty
	var actor: Dictionary = m.unit_by_id(actor_id)
	if actor.is_empty() or tile == Shot.pos(actor): return empty
	var reach: Dictionary = m.paths(actor, int(actor.mob) * 2)
	if not reach.costs.has(tile): return empty
	var ap_cost := 1 if int(reach.costs[tile]) <= int(actor.mob) else 2
	if int(actor.ap) < ap_cost: return empty
	var path: Array = []
	var cursor := tile
	while cursor != Shot.pos(actor) and reach.prev.has(cursor):
		path.push_front(cursor)
		cursor = reach.prev[cursor]
	if cursor != Shot.pos(actor): return empty
	var events: Array = []
	var risk: Dictionary = m.route_threat24(path, actor_id)
	var revealed: Dictionary = {}
	for entry in risk.get("reveal_tiles", []):
		var group := int(entry.get("group", -1))
		if not revealed.has(group):
			revealed[group] = entry.tile
	var entry_tiles: Array = _entry_tiles(m)
	var last_flanks := _flank_count(m, actor, Shot.pos(actor))
	for q in path:
		# The risk list preserves the real watcher order at each step.
		for entry in risk.get("overwatch_tiles", []):
			if entry.tile != q: continue
			for watcher_id in entry.watchers:
				var watcher: Dictionary = m.unit_by_id(int(watcher_id))
				events.append({"kind":"overwatch", "tile":q, "source":Shot.pos(watcher), "source_id":int(watcher_id), "source_name":str(watcher.name)})
		for group in revealed:
			if revealed[group] == q: events.append({"kind":"reveal", "tile":q, "source":group})
		if q in entry_tiles: events.append({"kind":"wave_entry", "tile":q, "source":q})
		var flanks := _flank_count(m, actor, q)
		if flanks > last_flanks: events.append({"kind":"flank", "tile":q, "source":flanks})
		last_flanks = flanks
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for enemy in m.living("enemy" if str(actor.side) == "player" else "player"):
		if str(enemy.side) == "enemy" and not bool(enemy.awake): continue
		var distance := Shot.distance(tile, Shot.pos(enemy))
		if distance < nearest_distance: nearest_distance = distance; nearest = enemy
	var cover_value := 0
	var odds_delta := 0
	if not nearest.is_empty():
		cover_value = Shot.cover(m, tile, Shot.pos(nearest))
		var before: Dictionary = Shot.calculate(m, actor, nearest)
		var probe: Dictionary = actor.duplicate()
		probe.x = tile.x; probe.y = tile.y
		var after: Dictionary = Shot.calculate(m, probe, nearest)
		if bool(after.los) and bool(after.range_ok): odds_delta = int(after.hit) - (int(before.hit) if bool(before.los) and bool(before.range_ok) else 0)
	else:
		for direction in Shot.DIRS: cover_value = maxi(cover_value, Shot.cover(m, tile, tile + direction * 2))
	var flank_delta := _flank_count(m, actor, tile) - _flank_count(m, actor, Shot.pos(actor))
	return {"path":path, "events":events, "cover":"full" if cover_value >= 40 else "half" if cover_value >= 20 else "none", "cover_value":cover_value, "height":Shot.elevation(m, tile) - Shot.elevation(m, Shot.pos(actor)), "flank":flank_delta, "flank_exposed":_flank_count(m, actor, tile) > 0, "odds_delta":odds_delta, "ap":ap_cost}
