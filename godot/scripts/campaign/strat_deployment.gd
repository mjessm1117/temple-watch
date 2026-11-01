extends RefCounted
## Adapter for the shared battle bridge. Pure validation/selection; no campaign mutation.
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func validate(c, ids: Array, option: Dictionary = {}) -> bool:
	if ids.size() < 2 or ids.size() > c.squad_capacity(): return false
	var rule := preload("res://scripts/mission_fronts.gd").squad_rule(c.state)
	if ids.size() > int(rule.max): return false
	if option.get("kind", "") == "redemption" and option.get("unit_id", "") not in ids: return false
	var jedi := 0
	var seen := []
	for id in ids:
		if id in seen or not Roster.ready(c.soldier(str(id))): return false
		if id in rule.used: return false
		if Progression.is_jedi(c.soldier(str(id))): jedi += 1
		seen.append(id)
	if jedi > int(rule.jmax): return false
	return not option.has("quest") or ids.has(option.quest)

static func spawn_tiles(m, count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var frontier: Array[Vector2i] = []
	var visited := {}
	for row in m.spec.squad:
		var tile := Vector2i(int(row[1]), int(row[2]))
		if not m.passable(tile) or m.occupied(tile) or tile in out: continue
		out.append(tile); frontier.append(tile); visited[tile] = true
		if out.size() == count: return out
	while not frontier.is_empty() and out.size() < count:
		var tile: Vector2i = frontier.pop_front()
		for near in m._neighbors(tile, -1):
			if visited.has(near): continue
			visited[near] = true; frontier.append(near); out.append(near)
			if out.size() == count: break
	return out if out.size() == count else []

static func apply_identity(c, unit: Dictionary, r: Dictionary) -> void:
	unit.voice = r.get("voice", "")
	unit.master = c.state.pairs.get(r.id, "")
	unit.tired = int(r.get("fatigue", 0)) >= 34
	if not unit.has("kit"): unit.kit = []
	for ability in Progression.battle_abilities(r):
		if ability not in unit.kit: unit.kit.append(ability)
