extends RefCounted
## Pure, deterministic campaign extension. Owns state.sith; never advances the host clock.
## advance_day() owns monthly processing. month_end() is an idempotent boundary hook.
const Operations = preload("res://scripts/campaign/sith_operations.gd")
const Rivals = preload("res://scripts/campaign/sith_rivals.gd")
const Darkness = preload("res://scripts/campaign/sith_darkness.gd")
var state: Dictionary
var s: Dictionary
var data: Dictionary

func _init(campaign_state: Dictionary, seed_value: int = 731) -> void:
	state = campaign_state
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/sith.json"))
	if not state.has("sith"):
		var day := int(state.get("elapsed_days", 0))
		state.sith = {"version": 1, "day": day, "month": day / 30 + 1,
			"last_month": day / 30, "rng": maxi(1, seed_value & 0x7fffffff),
			"serial": 0, "segments": 2, "next_escalation": day + 30,
			"collapse_day": -1, "defeated": false, "pressure": 0,
			"retaliation_after": day, "events": [], "missions": {}, "ops": [],
			"mods": [], "rivals": {}, "reports": [], "counters": {},
			"mercy": {}, "redeem": {}, "counsel": {}, "metrics": {}, "jams": {}}
	s = state.sith
	if s.rivals.is_empty():
		Rivals.initialize(self)
		Operations.generate(self)
		_offer_cycle()

func roll(limit: int) -> int:
	s.rng = (int(s.rng) * 48271) % 2147483647
	return int(s.rng) % maxi(1, limit)

func next_id(prefix: String) -> String:
	s.serial = int(s.serial) + 1
	return "sith_%s_%d" % [prefix, s.serial]

func emit_event(kind: String, details: Dictionary = {}) -> void:
	var event := details.duplicate(true)
	event.merge({"id": next_id("event"), "kind": kind, "day": s.day}, true)
	s.events.append(event)

func pending_events() -> Array:
	return s.events.duplicate(true)

func acknowledge(event_id: String) -> bool:
	for i in s.events.size():
		if str(s.events[i].id) == event_id:
			s.events.remove_at(i)
			return true
	return false

func advance_day() -> Array:
	if s.defeated: return []
	var before: int = s.events.size()
	s.day = int(s.day) + 1
	for m in ordered_missions():
		if m.status == "open" and int(m.deadline) >= 0 and int(s.day) >= int(m.deadline):
			_expire(m)
	if int(s.day) >= int(s.next_escalation):
		change_segments(1, "Sith influence spreads")
		s.next_escalation = int(s.next_escalation) + int(data.rules.escalation_days)
	if int(s.day) % 30 == 0: month_end()
	Rivals.advance(self)
	if int(s.collapse_day) >= 0 and int(s.day) >= int(s.collapse_day):
		s.defeated = true
		emit_event("campaign_defeat", {"n": "The Order is overwhelmed", "segments": s.segments})
	return s.events.slice(before).duplicate(true)

func month_end() -> Dictionary:
	var completed := int(s.day) / 30
	if completed <= int(s.last_month):
		return {} if s.reports.is_empty() else s.reports.back().duplicate(true)
	Operations.month_end(self)
	var mentorship := Darkness.month_end(self)
	Rivals.month_end(self)
	var report := {"month": completed, "day": s.day, "segments": s.segments,
		"next_escalation": s.next_escalation, "collapse_day": s.collapse_day,
		"metrics": s.metrics.duplicate(true), "mentorship": mentorship,
		"operations": Operations.visible(self), "rivals": Rivals.visible(self),
		"assessment": "Holding the line" if int(s.metrics.get("won", 0)) > 0 else "The shadow advances"}
	s.reports.append(report)
	s.last_month = completed
	s.month = completed + 1
	s.metrics = {}
	Operations.generate(self)
	_offer_cycle()
	emit_event("council_report", {"month": completed, "n": report.assessment})
	return report.duplicate(true)

func metric(key: String, amount: int = 1) -> void:
	s.metrics[key] = int(s.metrics.get(key, 0)) + amount

func gain(key: String, amount: int) -> void:
	if key == "orderDark": state[key] = clampi(int(state.get(key, 0)) + amount, 0, 100)
	else:
		if not state.has("res"): state.res = {}
		state.res[key] = maxi(0, int(state.res.get(key, 0)) + amount)
		if key == "favor": state.res[key] = mini(100, int(state.res[key]))

func soldier(id: String) -> Dictionary:
	for r in state.get("roster", []):
		if str(r.id) == id: return r
	return {}

func offer(kind: String, title: String, template: String, extra: Dictionary = {}) -> Dictionary:
	var id := next_id("mission")
	var m := {"id": id, "mission_id": id, "sith_offer_id": id, "mission": template, "kind": kind,
		"n": title, "status": "open", "deadline": -1, "created": s.day}
	m.merge(extra, true)
	s.missions[id] = m
	return m

func ordered_missions() -> Array:
	# JSON saves sort dictionary keys; iteration order must not change enemy decisions.
	var ordered: Array = s.missions.values()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.id).naturalnocasecmp_to(str(b.id)) < 0)
	return ordered

func mission_options() -> Array:
	Darkness.offer_redemption(self)
	var out := []
	for m in ordered_missions():
		if m.status != "open": continue
		if m.kind == "counter":
			var op := Operations.find_op(self, str(m.op_id))
			if op.is_empty() or op.status != "open": continue
			if s.counters.has(str(int(s.month))) and s.counters[str(int(s.month))] != m.id: continue
		var copy: Dictionary = m.duplicate(true)
		if m.kind == "counter" and not Operations.find_op(self, str(m.op_id)).revealed:
			copy.n = "Intercept a concealed operation"
		out.append(copy)
	return out

func _offer_cycle() -> void:
	offer("project", "Sever the shadow conduit", "sabotage", {"risk": "Two charges; extract under reinforcements", "reduction": 2, "deadline": int(s.month) * 30})
	if bool(s.get("crises_enabled", true)):
		var keys: Array = data.crises.keys()
		var start := (int(s.month) - 1) * 2
		for index in 2:
			var key: String = keys[(start + index) % keys.size()]
			var c: Dictionary = data.crises[key]
			offer("crisis", str(c.n), str(c.mission), {"crisis_id": key, "ignore": c.ignore.duplicate(true), "deadline": int(s.month) * 30})
	Darkness.offer_redemption(self)

func set_crisis_schedule(enabled: bool) -> void:
	## Disable when the host already schedules these crises; no invisible ignore penalties.
	## Re-enabling resumes on the next month boundary.
	s.crises_enabled = enabled
	if not enabled:
		for m in ordered_missions():
			if m.kind == "crisis" and m.status == "open": m.status = "cancelled"

func change_segments(amount: int, reason: String) -> void:
	if s.defeated: return
	var before := int(s.segments)
	s.segments = clampi(before + amount, 0, int(data.rules.segments))
	if int(s.segments) == before: return
	metric("darkness_delta", int(s.segments) - before)
	if int(s.segments) >= int(data.rules.segments) and int(s.collapse_day) < 0:
		s.collapse_day = int(s.day) + int(data.rules.collapse_days)
		emit_event("last_stand", {"n": "Break a conduit before the Order falls", "deadline": s.collapse_day})
	elif int(s.segments) < int(data.rules.segments): s.collapse_day = -1
	emit_event("darkness", {"n": reason, "delta": int(s.segments) - before, "segments": s.segments})

func project_status() -> Dictionary:
	return {"segments": s.segments, "maximum": data.rules.segments,
		"next_escalation": s.next_escalation, "collapse_day": s.collapse_day, "defeated": s.defeated}

func counter(op_id: String, mission_id: String) -> bool:
	return Operations.counter(self, op_id, mission_id)

func reveal_operation(op_id: String) -> bool:
	return Operations.reveal(self, op_id)

func counter_with_intel(op_id: String) -> bool:
	return Operations.with_intel(self, op_id)

func send_team(op_id: String, unit_ids: Array) -> bool:
	return Operations.send_team(self, op_id, unit_ids)

func operations() -> Array:
	return Operations.visible(self)

func campaign_mods() -> Dictionary:
	var result := {"enemyAim": 0, "enemyHp": 0, "extraEnemies": 0, "squadAim": 0}
	for mod in s.mods:
		for key in mod.mod: result[key] = int(result.get(key, 0)) + int(mod.mod[key])
	return result

func wing_jammed(wing: String) -> bool:
	return int(s.jams.get(wing, 0)) > 0

func rivals() -> Array:
	return Rivals.visible(self)

func rival_for_mission(mission_id: String) -> Dictionary:
	return Rivals.for_mission(self, mission_id)

func resolve_mission(mission_id: String, won: bool, outcome: Dictionary = {}) -> bool:
	## Only registered offers resolve. Call once BEFORE host time advancement.
	var m: Dictionary = s.missions.get(mission_id, {})
	if s.defeated or m.is_empty() or m.status != "open": return false
	if m.kind == "counter" and s.counters.get(str(int(s.month)), "") != mission_id: return false
	if m.kind == "redemption" and not Darkness.can_resolve(self, m, outcome): return false
	m.status = "won" if won else "lost"
	metric("won" if won else "lost")
	if m.kind == "counter": Operations.resolve_counter(self, str(m.op_id), won)
	elif m.kind == "project":
		change_segments(-int(m.reduction) if won else 1, "Conduit destroyed" if won else "Conduit strike failed")
		if won: retaliation_trigger("Conduit destroyed", 2)
	elif m.kind == "crisis":
		if won: gain("favor", 3)
		else: _crisis_penalty(m)
	elif m.kind == "redemption": Darkness.resolve(self, m, won)
	elif m.kind == "rescue_rival": Rivals.rescue(self, m, won)
	if m.has("rival_id") and m.kind != "rescue_rival": Rivals.resolve(self, m, won, outcome)
	if m.kind == "retaliation":
		if won: s.pressure = maxi(0, int(s.pressure) - 2)
		else:
			gain("favor", -8)
			change_segments(1, "A sanctuary fell")
	emit_event("mission_result", {"n": m.n, "mission_id": mission_id, "won": won})
	return true

func after_mission(result_id: String) -> bool:
	## Every completed tactical mission, including ordinary host missions, consumes one modifier use.
	## Stable unique deployment/result ID required (a replayed map is a new result).
	if s.defeated or result_id.is_empty() or s.get("processed_results", {}).has(result_id): return false
	if not s.has("processed_results"): s.processed_results = {}
	s.processed_results[result_id] = true
	for mod in s.mods: mod.left = int(mod.left) - 1
	s.mods = s.mods.filter(func(m: Dictionary) -> bool: return int(m.left) > 0)
	for wing in s.jams.keys():
		s.jams[wing] = int(s.jams[wing]) - 1
		if int(s.jams[wing]) <= 0: s.jams.erase(wing)
	Operations.resolve_teams(self)
	return true

func _expire(m: Dictionary) -> void:
	m.status = "expired"
	if m.kind == "crisis": _crisis_penalty(m)
	elif m.kind == "ambush" or m.kind == "kidnap": Rivals.resolve(self, m, false, {})
	elif m.kind == "retaliation":
		gain("favor", -8)
		change_segments(1, "An undefended sanctuary fell")
	emit_event("mission_expired", {"n": m.n, "mission_id": m.id})

func _crisis_penalty(m: Dictionary) -> void:
	for key in m.get("ignore", {}): gain(str(key), int(m.ignore[key]))
	metric("crises_ignored")
	retaliation_trigger("Unanswered crisis", 1)

func retaliation_trigger(reason: String, pressure: int = 1) -> void:
	if s.defeated: return
	s.pressure = clampi(int(s.pressure) + maxi(0, pressure), 0, 9)
	if int(s.pressure) < int(data.rules.retaliation_pressure) or int(s.day) < int(s.retaliation_after): return
	for m in ordered_missions():
		if m.kind == "retaliation" and m.status == "open": return
	s.pressure = 0
	s.retaliation_after = int(s.day) + 30
	var m := offer("retaliation", "Defend the pilgrim sanctuary", "shrine", {"deadline": int(s.day) + 10, "trigger": reason})
	emit_event("retaliation", {"n": m.n, "mission_id": m.id, "deadline": m.deadline, "trigger": reason})
	metric("retaliations")

func mercy(unit_id: String, result_id: String, action_id: String, points: int = 1) -> int:
	return Darkness.mercy(self, unit_id, result_id, action_id, points)

func set_counsel(student_id: String, mentor_id: String) -> bool:
	return Darkness.set_counsel(self, student_id, mentor_id)
