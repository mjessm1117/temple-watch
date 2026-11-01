extends RefCounted
## Remaining darkness.js rules. Gardens remain owned by the existing campaign tick.
const Progression = preload("res://scripts/campaign/progression.gd")

static func mercy(layer, unit_id: String, result_id: String, action_id: String, points: int) -> int:
	var unit: Dictionary = layer.soldier(unit_id)
	if layer.s.defeated or unit.is_empty() or not Progression.is_jedi(unit) or unit.get("status", "") != "active": return 0
	if result_id.is_empty() or action_id.is_empty() or points <= 0 or layer.s.get("processed_results", {}).has(result_id): return 0
	if not layer.s.mercy.has(result_id): layer.s.mercy[result_id] = {}
	var mission: Dictionary = layer.s.mercy[result_id]
	if not mission.has(unit_id): mission[unit_id] = {"points": 0, "reduced": 0, "actions": {}}
	var ledger: Dictionary = mission[unit_id]
	if ledger.actions.has(action_id): return 0
	ledger.actions[action_id] = true
	ledger.points = int(ledger.points) + mini(2, points)
	var reduction := mini(mini(int(ledger.points) / 2, 2 - int(ledger.reduced)), int(unit.get("dark", 0)))
	unit.dark = maxi(0, int(unit.get("dark", 0)) - reduction)
	ledger.points = int(ledger.points) - 2 * reduction
	ledger.reduced = int(ledger.reduced) + reduction
	if reduction > 0: layer.metric("mercy", reduction)
	return reduction

static func set_counsel(layer, student_id: String, mentor_id: String) -> bool:
	var student: Dictionary = layer.soldier(student_id)
	if layer.s.defeated or student.is_empty() or not Progression.is_jedi(student) or student.get("status", "") != "active" or student.get("title", "") == "Padawan": return false
	if mentor_id == "":
		layer.s.counsel.erase(student_id)
		return true
	var mentor: Dictionary = layer.soldier(mentor_id)
	if mentor.is_empty() or student_id == mentor_id or not Progression.is_jedi(mentor): return false
	if mentor.get("status", "") != "active" or int(mentor.get("rank", 0)) < 4 or mentor.get("title", "") not in ["Knight", "Master"]: return false
	layer.s.counsel[student_id] = mentor_id
	return true

static func month_end(layer) -> Array:
	var changes := []
	# Compute from a snapshot: roster ordering must not affect a mentor chain.
	for unit in layer.state.get("roster", []):
		if unit.get("status", "") != "active" or not Progression.is_jedi(unit): continue
		var mentor_id: String = str(layer.state.get("pairs", {}).get(unit.id, "")) if unit.get("title", "") == "Padawan" else str(layer.s.counsel.get(unit.id, ""))
		var mentor: Dictionary = layer.soldier(mentor_id)
		if mentor.is_empty() or mentor == unit or mentor.get("status", "") != "active" or not Progression.is_jedi(mentor): continue
		if unit.get("title", "") != "Padawan" and (int(mentor.get("rank", 0)) < 4 or mentor.get("title", "") not in ["Knight", "Master"]): continue
		var current := int(unit.get("dark", 0))
		var shadow := int(mentor.get("dark", 0))
		var delta := -1 if shadow <= 2 and current > shadow else 1 if shadow >= 7 and current < shadow else 0
		if delta != 0: changes.append({"id": unit.id, "n": unit.get("n", unit.id), "delta": delta, "mentor": mentor.get("n", mentor.id)})
	for change in changes:
		var unit: Dictionary = layer.soldier(str(change.id))
		unit.dark = clampi(int(unit.get("dark", 0)) + int(change.delta), 0, 10)
	return changes

static func offer_redemption(layer) -> void:
	if layer.s.defeated: return
	var era := int(layer.state.get("era", 1))
	for m in layer.ordered_missions():
		if m.kind == "redemption" and m.status == "open":
			var unit: Dictionary = layer.soldier(str(m.unit_id))
			if int(m.era) != era or unit.get("status", "") != "active" or int(unit.get("dark", 0)) < 6: m.status = "cancelled"
	for unit in layer.state.get("roster", []):
		if unit.get("status", "") != "active" or not Progression.is_jedi(unit) or int(unit.get("dark", 0)) < 6: continue
		var key := "%d:%s" % [era, unit.id]
		if layer.s.redeem.has(key): continue
		var exists := false
		for m in layer.ordered_missions():
			if m.kind == "redemption" and m.status == "open" and m.get("unit_id", "") == unit.id: exists = true
		if not exists:
			layer.offer("redemption", "The way back · " + str(unit.get("n", unit.id)), "r_hospital" if era == 2 else "h_prisoners" if era == 3 else "shrine",
				{"unit_id": unit.id, "era": era, "reward": "Darkness −4; stress −20. Failure: Darkness +1."})

static func can_resolve(layer, m: Dictionary, outcome: Dictionary) -> bool:
	var unit: Dictionary = layer.soldier(str(m.unit_id))
	return int(m.era) == int(layer.state.get("era", 1)) and unit.get("status", "") == "active" and outcome.get("deployed", []).has(m.unit_id) and not layer.s.redeem.has("%d:%s" % [int(m.era), m.unit_id])

static func resolve(layer, m: Dictionary, won: bool) -> void:
	var unit: Dictionary = layer.soldier(str(m.unit_id))
	layer.s.redeem["%d:%s" % [int(m.era), m.unit_id]] = {"won": won, "day": layer.s.day}
	unit.dark = clampi(int(unit.get("dark", 0)) + (-4 if won else 1), 0, 10)
	if won: unit.stress = maxi(0, int(unit.get("stress", 0)) - 20)
	layer.metric("redemptions" if won else "redemption_failures")
