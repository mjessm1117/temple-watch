extends RefCounted

static func threat(data: Dictionary) -> String:
	var next: Dictionary = data.get("next_wave26", {})
	var pending: Array = data.get("pending_groups", [])
	if next.is_empty() and not pending.is_empty(): next = pending[0]
	if not next.is_empty():
		var turns := int(next.get("turns", 1))
		return "Reinforcements in %d turn%s" % [turns, "" if turns == 1 else "s"]
	var risk := int(data.get("objective_risk", 0))
	if risk > 0: return "Zone threatened"
	var exposed: Array = data.get("exposed_units", [])
	if not exposed.is_empty(): return "%d allies in sight" % exposed.size()
	return ""

static func detail(data: Dictionary) -> String:
	var lines: Array[String] = []
	var wave: Dictionary = data.get("next_wave26", {})
	if not wave.is_empty(): lines.append("%d reinforcements in %d turns" % [int(wave.get("count", 0)), int(wave.get("turns", 0))])
	elif not data.get("pending_groups", []).is_empty(): lines.append("Enemy reinforcements are inbound")
	var risk := int(data.get("objective_risk", 0))
	if risk > 0: lines.append("Hold zone threatened: %d damage at risk" % risk)
	var exposed: Array = data.get("exposed_units", [])
	if not exposed.is_empty(): lines.append("%d allies in enemy sight" % exposed.size())
	return "\n".join(lines) if not lines.is_empty() else "No immediate threats"
