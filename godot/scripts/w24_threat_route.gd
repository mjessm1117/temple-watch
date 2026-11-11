extends RefCounted
## Read-only route facts shared by preview and live reaction eligibility.
const Shot = preload("res://scripts/shot.gd")
const Chains = preload("res://scripts/ability_chains.gd")

static func reaction_info(m: RefCounted, watcher: Dictionary, mover: Dictionary, q: Vector2i) -> Dictionary:
	if Chains.has_tag(watcher, "STAGGERED") or Chains.has_tag(watcher, "LIFTED"): return {}
	if str(watcher.side) == "enemy" and not bool(watcher.awake): return {}
	var pinned := int(mover.get("suppressed_by", -1)) == int(watcher.id)
	var hold: bool = bool(watcher.get("hold_line", false)) and int(mover.id) not in watcher.get("ow_hit", [])
	if not bool(watcher.overwatch) and not pinned and not hold: return {}
	if int(watcher.get("ammo", 1)) <= 0: return {}
	var probe := mover.duplicate()
	probe.x = q.x; probe.y = q.y
	var info: Dictionary = Shot.calculate(m, watcher, probe, false, -15)
	return info if bool(info.los) and bool(info.range_ok) else {}

static func segments(m: RefCounted, path: Array, start: Vector2i) -> Array:
	var out: Array = []
	var previous := start
	for step in path:
		var q: Vector2i = step
		var before := Shot.elevation(m, previous)
		var after := Shot.elevation(m, q)
		var kind := "walk"
		if m.tile(q) in ["D", "d"]: kind = "door"
		elif after > before: kind = "climb"
		elif after < before or m.tile(q) == "r": kind = "vault"
		out.append({"from":previous, "to":q, "kind":kind})
		previous = q
	return out
