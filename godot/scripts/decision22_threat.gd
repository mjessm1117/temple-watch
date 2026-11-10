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
	if exposed > 0: rows.append("%d EXPOSED" % exposed)
	if risk > 0: rows.append("OBJ −%d" % risk)
	if pending > 0: rows.append("%d INBOUND" % pending)
	if not data.get("villain", {}).is_empty(): rows.append("VILLAIN")
	if rows.is_empty(): return "NO KNOWN\nTHREAT"
	if rows.size() > 2:
		rows[1] += " +%d IN" % pending if pending > 0 else " +V"
	return "\n".join(rows.slice(0, 2))

static func phone_chip(data: Dictionary) -> String:
	if data.is_empty(): return ""
	var risk := int(data.get("objective_risk", 0))
	if risk > 0: return "OBJ\n−%d" % risk
	var exposed: int = data.get("exposed_units", []).size()
	if exposed > 0: return "%d\nEXPOSED" % exposed
	var pending: int = data.get("pending_groups", []).size()
	if pending > 0: return "%d\nINBOUND" % pending
	return "VILLAIN" if not data.get("villain", {}).is_empty() else "SAFE"
