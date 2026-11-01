extends RefCounted
## Recurring rivals learn, launch attacks, retreat, and can be pursued permanently.

static func initialize(layer) -> void:
	var index := 0
	for def in layer.data.rivals:
		layer.s.rivals[def.id] = {"id": def.id, "knowledge": 0, "defeats": 0,
			"phase": "hunting", "revealed": [], "next_action": int(layer.s.day) + 14 + index * 7}
		index += 1

static func definition(layer, id: String) -> Dictionary:
	for def in layer.data.rivals:
		if str(def.id) == id: return def
	return {}

static func visible(layer) -> Array:
	var out := []
	for template in layer.data.rivals:
		var rival: Dictionary = layer.s.rivals[template.id]
		var def := definition(layer, str(rival.id)).duplicate(true)
		def.erase("countermeasures")
		def.merge(rival.duplicate(true), true)
		out.append(def)
	return out

static func month_end(layer) -> void:
	for template in layer.data.rivals:
		var r: Dictionary = layer.s.rivals[template.id]
		if r.phase != "eliminated": r.knowledge = mini(100, int(r.knowledge) + int(layer.data.rules.knowledge_month))

static func advance(layer) -> void:
	for template in layer.data.rivals:
		var r: Dictionary = layer.s.rivals[template.id]
		if r.phase != "hunting" or int(layer.s.day) < int(r.next_action): continue
		r.next_action = int(layer.s.day) + 28
		var existing := false
		for m in layer.ordered_missions():
			if m.get("rival_id", "") == r.id and m.status == "open" and m.kind in ["ambush", "kidnap"]: existing = true
		if existing: continue
		var kind := "kidnap" if int(r.knowledge) >= 24 else "ambush"
		var def := definition(layer, str(r.id))
		var m: Dictionary = layer.offer(kind, ("Foil an abduction · " if kind == "kidnap" else "Break the ambush · ") + str(def.n), "rescue" if kind == "kidnap" else "archive",
			{"rival_id": r.id, "deadline": int(layer.s.day) + 10})
		layer.emit_event(kind, {"n": m.n, "rival_id": r.id, "mission_id": m.id, "deadline": m.deadline})
		if int(r.knowledge) >= 74: layer.retaliation_trigger("A Sith rival located the sanctuary", 3)

static func for_mission(layer, mission_id: String) -> Dictionary:
	var m: Dictionary = layer.s.missions.get(mission_id, {})
	if m.is_empty() or m.status != "open" or not m.has("rival_id") or m.kind == "rescue_rival": return {}
	var r: Dictionary = layer.s.rivals.get(m.rival_id, {})
	if r.is_empty() or r.phase == "eliminated": return {}
	var def := definition(layer, str(r.id))
	var spawn: Dictionary = def.spawn.duplicate(true)
	spawn.merge({"id": r.id, "n": def.n, "title": def.title, "phase": r.phase,
		"knowledge": r.knowledge, "strengths": def.strengths.duplicate(),
		"weaknesses": def.weaknesses.duplicate(), "countermeasures": r.revealed.duplicate(true),
		"mission_id": mission_id, "final": m.kind == "pursuit"})
	spawn.hp = int(spawn.hp) + 2 * (int(r.knowledge) / 24)
	return spawn

static func resolve(layer, m: Dictionary, won: bool, outcome: Dictionary) -> void:
	var r: Dictionary = layer.s.rivals[m.rival_id]
	if r.phase == "eliminated": return
	r.knowledge = mini(100, int(r.knowledge) + (4 if won else 8))
	if won:
		r.defeats = int(r.defeats) + 1
		var def := definition(layer, str(r.id))
		var index: int = r.revealed.size()
		if index < def.countermeasures.size():
			var counter: Dictionary = def.countermeasures[index].duplicate(true)
			r.revealed.append(counter)
			layer.emit_event("countermeasure", {"rival_id": r.id, "n": counter.n, "text": counter.text})
		layer.metric("rivals_defeated")
		if m.kind == "pursuit":
			r.phase = "eliminated"
			layer.change_segments(-2, str(def.n) + " defeated for good")
			for captive in layer.state.get("roster", []):
				if captive.get("sith_captor", "") == r.id: release(captive)
			for open in layer.ordered_missions():
				if open.status == "open" and open.get("rival_id", "") == r.id: open.status = "cancelled"
		elif m.kind == "stronghold":
			r.phase = "pursuit"
			layer.change_segments(-1, "Sith stronghold destroyed")
			layer.offer("pursuit", "Final pursuit · " + str(def.n), "sabotage", {"rival_id": r.id, "risk": "Defeat the rival before extraction"})
		elif int(r.defeats) >= 2 and r.phase == "hunting":
			r.phase = "stronghold"
			layer.offer("stronghold", "Breach the stronghold · " + str(def.n), "sabotage", {"rival_id": r.id, "risk": "Destroy the focus and defeat its guardian"})
		layer.retaliation_trigger("A Sith rival was defeated", 1)
	else:
		if m.kind == "kidnap": kidnap(layer, r, str(outcome.get("captive_id", "")))
		if m.kind in ["stronghold", "pursuit"]:
			layer.offer(str(m.kind), str(m.n), str(m.mission), {"rival_id": r.id, "risk": m.get("risk", "")})
		layer.metric("rival_setbacks")

static func kidnap(layer, r: Dictionary, preferred: String) -> void:
	var candidates: Array = layer.state.get("roster", []).filter(func(unit: Dictionary) -> bool:
		return unit.get("status", "") == "active" and unit.get("assign", "") == "" and not layer.state.get("pending_mission", {}).get("squad", []).has(unit.id))
	if candidates.is_empty():
		layer.change_segments(1, "The abduction network gained ground")
		return
	var captive: Dictionary = candidates[layer.roll(candidates.size())]
	for unit in candidates:
		if str(unit.id) == preferred: captive = unit
	captive.status = "captured"
	captive.sith_captor = r.id
	captive.assign = ""
	var rescue_offer: Dictionary = layer.offer("rescue_rival", "Recover " + str(captive.get("n", captive.id)), "rescue", {"rival_id": r.id, "hostages": [captive.id]})
	layer.emit_event("kidnapped", {"n": rescue_offer.n, "unit_id": captive.id, "rival_id": r.id, "mission_id": rescue_offer.id})
	layer.metric("kidnapped")

static func release(unit: Dictionary) -> void:
	unit.status = "active"
	unit.erase("sith_captor")
	unit.capT = 0
	unit.stress = mini(100, int(unit.get("stress", 0)) + 10)

static func rescue(layer, m: Dictionary, won: bool) -> void:
	if won:
		for id in m.hostages:
			var unit: Dictionary = layer.soldier(str(id))
			if unit.get("status", "") == "captured" and unit.get("sith_captor", "") == m.rival_id: release(unit)
		layer.metric("rescued")
	else: layer.offer("rescue_rival", str(m.n), "rescue", {"rival_id": m.rival_id, "hostages": m.hostages.duplicate()})
