extends RefCounted
## Guarded bridge to lane D; the standalone C branch has no threat API yet.
const PRESSURE_PATH = "res://scripts/mission_pressure.gd"

static func summary(m: RefCounted) -> Dictionary:
	var pressure: Script = load(PRESSURE_PATH)
	if pressure == null or not pressure.has_method("threat_summary"): return {}
	return pressure.call("threat_summary", m)

static func reveal(m: RefCounted, group: Array) -> Dictionary:
	var pressure: Script = load(PRESSURE_PATH)
	if pressure == null or not pressure.has_method("reveal_info"): return {}
	return pressure.call("reveal_info", m, group)

static func chip(data: Dictionary) -> String:
	if data.is_empty(): return ""
	var exposed: int = data.get("exposed_units", []).size()
	var risk: int = int(data.get("objective_risk", 0))
	var pending: int = data.get("pending_groups", []).size()
	var rows: Array[String] = []
	if exposed > 0: rows.append("%d in enemy sight" % exposed)
	if risk > 0: rows.append("ZONE -%d" % risk)
	if pending > 0: rows.append("%d INBOUND" % pending)
	if not data.get("villain", {}).is_empty(): rows.append("VILLAIN")
	if rows.is_empty(): return "No allies in enemy sight"
	return "  |  ".join(rows)

static func phone_chip(data: Dictionary) -> String:
	if data.is_empty(): return ""
	var risk := int(data.get("objective_risk", 0))
	if risk > 0: return "ZONE -%d" % risk
	var exposed: int = data.get("exposed_units", []).size()
	if exposed > 0: return "%d in sight" % exposed
	var pending: int = data.get("pending_groups", []).size()
	if pending > 0: return "%d IN" % pending
	return "VILLAIN" if not data.get("villain", {}).is_empty() else "SAFE"

static func sight_text(data: Dictionary) -> String:
	return "%d in enemy sight" % data.get("exposed_units", []).size()

static func zone_text(data: Dictionary) -> String:
	var pieces: Array[String] = []
	var risk := int(data.get("objective_risk", 0))
	if risk > 0: pieces.append("ZONE -%d" % risk)
	var next: Dictionary = data.get("next_wave26", {})
	if not next.is_empty():
		pieces.append("%d IN %dT" % [int(next.get("count", 0)), int(next.get("turns", 0))])
		return "  ".join(pieces)
	var pending: Array = data.get("pending_groups", [])
	if not pending.is_empty():
		var first: Dictionary = pending[0]
		pieces.append("%d IN %dT" % [int(first.get("count", pending.size())), int(first.get("turns", 1))])
	return "  ".join(pieces)
