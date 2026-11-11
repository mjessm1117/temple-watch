extends RefCounted
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Preview = preload("res://scripts/campaign/armory12_preview.gd")

static func healing_per_day(c, offset: int = 0, extra_healers: int = 0) -> int:
	var s: Dictionary = c.state
	var value := 1 + (Base.staff_count(s, "medical") + extra_healers if Base.operational(s, "medical") and (int(s.get("elapsed_days", 0)) + offset) % 3 == 0 else 0)
	if "bacta" in s.strategy.projects: value += 1
	if "relief" in s.strategy.edict: value += 2
	return value

static func eta(c, r: Dictionary, extra_healers: int = 0) -> int:
	if int(r.get("wound", 0)) > 0:
		var remaining := int(r.wound)
		for day in range(1, 366):
			remaining -= healing_per_day(c, day, extra_healers) * (2 if r.get("assign", "") == "rest" else 1)
			if remaining <= 0: return day
	if int(r.get("fatigue", 0)) >= 34:
		var remaining := int(r.fatigue)
		for day in range(1, 366):
			remaining -= 4 + healing_per_day(c, day, extra_healers) if r.get("assign", "") in ["", "rest", "calm"] else 2
			if remaining <= 33: return day
	return 0

static func group(r: Dictionary) -> String:
	if int(r.get("wound", 0)) > 0: return "Wounded"
	if int(r.get("fatigue", 0)) >= 34: return "Tired"
	if not Roster.ready(r): return "Tired"
	return "Ready"

static func groups(c) -> Dictionary:
	var result := {"Ready":[], "Tired":[], "Wounded":[]}
	for r in c.state.roster:
		if str(r.get("status", "active")) == "active": result[group(r)].append({"id":str(r.id), "name":str(r.n), "eta":eta(c, r)})
	return result

static func best_ready(c, capacity: int) -> Array:
	var ready: Array = groups(c).Ready
	ready.sort_custom(func(a, b): return int(c.soldier(a.id).get("fatigue", 0)) < int(c.soldier(b.id).get("fatigue", 0)))
	return ready.slice(0, capacity).map(func(entry): return entry.id)

static func patient_actions(c, soldier_id: String) -> Array:
	var r: Dictionary = c.soldier(soldier_id)
	if r.is_empty() or str(r.get("status", "")) != "active" or int(r.get("wound", 0)) <= 0: return []
	var assignable: bool = str(r.get("status", "")) == "active" and not str(r.get("assign", "")).begins_with("field:") and str(r.get("assign", "")) != "training_center" and not c.state.pending_mission.get("squad", []).has(soldier_id)
	var rest_days := eta(c, {"wound":r.wound, "assign":"rest", "fatigue":r.get("fatigue", 0)})
	var result := [{"id":"rest", "label":"Full rest", "days":rest_days, "effect":"Twice daily recovery", "enabled":assignable and Base.operational(c.state, "medical")},
		{"id":"standard", "label":"Standard care", "days":eta(c, {"wound":r.wound, "assign":"", "fatigue":r.get("fatigue", 0)}), "effect":"Normal recovery. Room duty resumes after healing.", "enabled":assignable}]
	var free_healer := ""
	for worker in c.state.facility.workers:
		if worker.role == "healer" and worker.wing == "": free_healer = str(worker.id); break
	var staffed := Base.staff_count(c.state, "medical") >= mini(2, int(c.state.wings.medical))
	result.append({"id":"healer", "label":"Assign healer", "days":eta(c, r, 1), "effect":"Recovery boost every third day · %s" % ("use free healer" if free_healer != "" else "75 Cr + 1 recruit"), "enabled":Base.operational(c.state, "medical") and not staffed and (free_healer != "" or c.state.res.credits >= 75 and c.state.res.recruits >= 1)})
	return result

static func apply_patient(c, soldier_id: String, action: String) -> bool:
	var available := false
	for choice in patient_actions(c, soldier_id):
		if choice.id == action: available = bool(choice.enabled)
	if not available: return false
	if action == "rest": return c.assign(soldier_id, "rest")
	if action == "standard": return c.assign(soldier_id, "")
	if action == "healer":
		for worker in c.state.facility.workers:
			if worker.role == "healer" and worker.wing == "": return Base.assign_worker(c, str(worker.id), "medical")
		if Base.hire_staff(c, "healer"):
			return Base.assign_worker(c, str(c.state.facility.workers.back().id), "medical")
	return false

static func delta(c, soldier_id: String, item_id: Variant) -> Array:
	var choice: Dictionary = item_id if item_id is Dictionary else {}
	if item_id is String:
		var id := str(item_id)
		if Data.get_table("gear", "ARMOR").has(id): choice = {"action":"armor", "key":id}
		elif Data.get_table("gear", "UTIL").has(id): choice = {"action":"utility", "key":id}
		elif Data.get_table("gear", "FORMS").has(id): choice = {"action":"form", "key":id}
	var action := str(choice.get("action", ""))
	var kind := str(choice.get("kind", ""))
	var key := str(choice.get("key", ""))
	var r: Dictionary = c.soldier(soldier_id)
	if r.is_empty(): return []
	var before: Dictionary = Gear.battle_stats(c, soldier_id)
	var changes: Array = Preview.changes(c, soldier_id, action, kind, key)
	var out := []
	for change in changes:
		var stat := str(change.name)
		var field: String = str({"move":"mob", "HP":"hp", "max Focus":"maxF", "medpacs":"kits", "grenades":"nades", "damage":"dmg"}.get(stat, stat))
		var prior = before.get(field, 0)
		if stat == "damage":
			out.append({"stat":stat, "before":prior, "after":[int(prior[0]) + int(change.value), int(prior[1]) + int(change.get("high", change.value))]})
		else: out.append({"stat":stat, "before":int(prior), "after":int(prior) + int(change.value)})
	return out
