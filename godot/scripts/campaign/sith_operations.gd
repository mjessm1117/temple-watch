extends RefCounted
## Dark Events and the frozen web game's Intel/team alternatives.

static func find_op(layer, id: String) -> Dictionary:
	for op in layer.s.ops:
		if str(op.id) == id: return op
	return {}

static func generate(layer) -> void:
	layer.s.ops = []
	var keys: Array = layer.data.operations.keys()
	var count := 2 if int(layer.s.month) >= 3 else 1
	for i in count:
		var index: int = layer.roll(keys.size())
		var key: String = keys.pop_at(index)
		var def: Dictionary = layer.data.operations[key]
		var op := {"id": layer.next_id("op"), "key": key, "status": "open",
			"revealed": i == 0, "deadline": int(layer.s.month) * 30, "team": []}
		var m: Dictionary = layer.offer("counter", str(def.n), str(def.mission),
			{"op_id": op.id, "deadline": op.deadline})
		op.mission_id = m.id
		layer.s.ops.append(op)
	layer.emit_event("operations", {"n": "New Sith operations detected", "count": count, "deadline": int(layer.s.month) * 30})

static func visible(layer) -> Array:
	var out := []
	for op in layer.s.ops:
		var row := {"id": op.id, "mission_id": op.mission_id, "status": op.status,
			"revealed": op.revealed, "deadline": op.deadline, "team": op.team.duplicate()}
		if op.revealed:
			var def: Dictionary = layer.data.operations[op.key]
			row.merge({"key": op.key, "n": def.n, "desc": def.desc, "intel": cost(layer, op)})
		else: row.merge({"n": "Concealed operation", "desc": "Spend 1 Intel to identify the threat, or intercept it blind.", "intel": 1})
		out.append(row)
	return out

static func cost(layer, op: Dictionary) -> int:
	var discount := 1 if layer.state.get("research", {}).get("done", []).has("codebreak") else 0
	return maxi(1, int(layer.data.operations[op.key].intel) - discount)

static func reveal(layer, id: String) -> bool:
	var op := find_op(layer, id)
	if layer.s.defeated or op.is_empty() or op.status != "open" or op.revealed: return false
	if int(layer.state.get("res", {}).get("intel", 0)) < 1: return false
	layer.gain("intel", -1)
	op.revealed = true
	return true

static func counter(layer, id: String, mission_id: String) -> bool:
	var op := find_op(layer, id)
	if layer.s.defeated or op.is_empty() or op.status != "open" or op.mission_id != mission_id: return false
	if layer.s.missions[mission_id].status != "open": return false
	var month := str(int(layer.s.month))
	if layer.s.counters.has(month): return layer.s.counters[month] == mission_id
	layer.s.counters[month] = mission_id
	return true

static func stopped(layer, op: Dictionary) -> void:
	op.status = "countered"
	op.revealed = true
	var m: Dictionary = layer.s.missions[op.mission_id]
	if m.status == "open": m.status = "countered"
	layer.metric("operations_countered")
	layer.retaliation_trigger("Sith operation disrupted", 1)
	layer.emit_event("operation_countered", {"op_id": op.id, "n": layer.data.operations[op.key].n})

static func resolve_counter(layer, id: String, won: bool) -> void:
	var op := find_op(layer, id)
	if not op.is_empty() and op.status == "open" and won: stopped(layer, op)

static func with_intel(layer, id: String) -> bool:
	var op := find_op(layer, id)
	if layer.s.defeated or op.is_empty() or op.status != "open" or not op.revealed: return false
	var price := cost(layer, op)
	if int(layer.state.get("res", {}).get("intel", 0)) < price: return false
	layer.gain("intel", -price)
	stopped(layer, op)
	return true

static func send_team(layer, id: String, ids: Array) -> bool:
	var op := find_op(layer, id)
	if layer.s.defeated or op.is_empty() or op.status != "open" or ids.size() != 2 or ids[0] == ids[1]: return false
	for unit_id in ids:
		var r: Dictionary = layer.soldier(str(unit_id))
		if r.is_empty() or r.get("status", "") != "active" or int(r.get("wound", 0)) > 0 or r.get("assign", "") != "": return false
		if layer.state.get("pending_mission", {}).get("squad", []).has(unit_id): return false
	op.team = ids.duplicate()
	op.status = "team"
	for unit_id in ids: layer.soldier(str(unit_id)).assign = "sith_op:" + str(op.id)
	return true

static func resolve_teams(layer) -> void:
	for op in layer.s.ops:
		if op.status != "team": continue
		var rank := 0
		var team := []
		for id in op.team:
			var r: Dictionary = layer.soldier(str(id))
			if r.is_empty(): continue
			if r.get("assign", "") == "sith_op:" + str(op.id): r.assign = ""
			if r.get("status", "") == "active":
				team.append(r)
				rank += int(r.get("rank", 1))
		var chance := mini(int(layer.data.rules.team_max), int(layer.data.rules.team_base) + int(layer.data.rules.team_per_rank) * rank)
		var won: bool = layer.roll(100) < chance and team.size() == 2
		op.status = "open"
		if won:
			stopped(layer, op)
			for r in team:
				r.xp = int(r.get("xp", 0)) + int(layer.data.rules.team_xp)
				preload("res://scripts/campaign/progression.gd").promote(r)
		else:
			for r in team: r.stress = mini(100, int(r.get("stress", 0)) + int(layer.data.rules.team_fail_stress))
		layer.emit_event("team_result", {"op_id": op.id, "n": layer.data.operations[op.key].n, "won": won, "chance": chance})

static func month_end(layer) -> void:
	# A team still away at the deadline returns and rolls before unresolved ops land.
	resolve_teams(layer)
	for op in layer.s.ops:
		if op.status == "open": hit(layer, op)

static func hit(layer, op: Dictionary) -> void:
	op.status = "hit"
	op.revealed = true
	var def: Dictionary = layer.data.operations[op.key]
	if def.has("mod"):
		layer.s.mods.append({"key": op.key, "mod": def.mod.duplicate(true), "left": int(def.missions)})
	for key in def.get("res", {}): layer.gain(str(key), int(def.res[key]))
	if def.has("hurt") or def.has("hunt"):
		var candidates: Array = layer.state.get("roster", []).filter(func(r: Dictionary) -> bool: return r.get("status", "") == "active")
		if not candidates.is_empty():
			candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("rank", 1)) > int(b.get("rank", 1)))
			var r: Dictionary = candidates[0 if def.has("hunt") else layer.roll(candidates.size())]
			r.wound = maxi(int(r.get("wound", 0)), 14 if def.has("hunt") else 10)
			r.stress = mini(100, int(r.get("stress", 0)) + (30 if def.has("hunt") else 20))
	if def.has("jam"):
		var wings: Array = layer.state.get("wings", {}).keys().filter(func(w: String) -> bool: return int(layer.state.wings[w]) > 0)
		wings.sort()
		for i in mini(int(def.jam), wings.size()):
			var wing: String = wings.pop_at(layer.roll(wings.size()))
			layer.s.jams[wing] = 3
	layer.metric("operations_hit")
	layer.retaliation_trigger("Sith operation completed", 1)
	layer.emit_event("operation_hit", {"op_id": op.id, "n": def.n, "desc": def.desc})
