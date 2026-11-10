extends RefCounted
## Short result summary and event radio lines. Rate limiting belongs to comms.

const BARKS_PATH := "res://data/story/story14-barks.json"
const NAMES := {"kira":"Kira Venn", "tor":"Tor Saalen", "satele":"Satele Shan", "ressa":"Lord Ressa Vaun", "kell":"Kell Darrow", "sava":"Knight Sava Orrin", "tem":"Tem Ruhl", "jace":"Jace Malcom", "ilsa":"Ilsa Myr"}

static func pick_bark(kind: String, actor_id: String, target_id: String, context: Dictionary) -> Dictionary:
	if kind in ["villain_reveal", "villain_retreat", "villain_taunt"]:
		var villain := str(context.get("villain_name", context.get("name", actor_id)))
		villain = str({"kaan":"Lord Kaan", "bane":"Darth Bane", "malgus":"Darth Malgus"}.get(villain, villain))
		if villain.is_empty(): return {}
		var villain_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/wave11-villain.json"))
		var key := "intro" if kind == "villain_reveal" else "retreat" if kind == "villain_retreat" else "taunt"
		var fallback: Dictionary = villain_data.get("records", {}).get("W11_BATTLE_LINES", {}).get(villain, {}) if villain_data is Dictionary else {}
		var line := str(context.get(key, fallback.get(key, "")))
		if kind == "villain_reveal" and not line.is_empty():
			var taunt := str(context.get("taunt", fallback.get("taunt", "")))
			if not taunt.is_empty(): line += "\n" + taunt
		if line.is_empty(): return {}
		return {"speaker":villain,"portrait_key":villain,"text":line,"priority":3}
	if not kind in ["kill", "hurt", "flank", "crit", "miss", "reveal"]: return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BARKS_PATH))
	if not parsed is Dictionary: return {}
	var data: Dictionary = parsed
	var affected := target_id if kind == "hurt" else actor_id
	var candidates: Array = [affected]
	var bondmate := str(context.get("bondmate_id", ""))
	if bondmate.is_empty():
		var bonds: Dictionary = context.get("bonds", {})
		bondmate = str(bonds.get(affected, ""))
	if not bondmate.is_empty() and not candidates.has(bondmate): candidates.append(bondmate)
	for advisor in context.get("advisors", ["jace", "ilsa"]):
		if not candidates.has(str(advisor)): candidates.append(str(advisor))
	for candidate in candidates:
		var id := str(candidate)
		var name := str(NAMES.get(id, id))
		var lines: Array = data.get("heroes", {}).get(name, {}).get(kind, [])
		if lines.is_empty(): lines = data.get("advisors", {}).get(name, {}).get(kind, [])
		if not lines.is_empty(): return {"speaker":name,"portrait_key":name,"text":str(lines[0]),"priority":2 if id == affected else 1}
	return {}

static func debrief(s: Dictionary, result: Dictionary, mission: Dictionary = {}) -> String:
	var rows: Array = result.get("units", [])
	var roster: Dictionary = {}
	for person in s.get("roster", []): roster[str(person.get("id", ""))] = str(person.get("n", ""))
	var named := "the squad"
	var cost := "returned safely"
	var best_kills := -1
	for row in rows:
		var id := str(row.get("id", ""))
		if not roster.has(id): continue
		if named == "the squad": named = roster[id]
		if str(row.get("status", "")) == "dead":
			named = roster[id]; cost = "did not return"; break
		if bool(row.get("downed", false)) or bool(row.get("hurt", false)) or int(row.get("hp", 1)) < int(row.get("max_hp", 1)):
			named = roster[id]; cost = "returned wounded"
		elif cost == "returned safely" and int(row.get("kills", 0)) > best_kills:
			best_kills = int(row.get("kills", 0)); named = roster[id]
	if named == "the squad":
		for id in result.get("squad", []):
			if roster.has(str(id)): named = roster[str(id)]; break
	var mission_type := str(mission.get("type", ""))
	var objective_default := "Prisoner" if mission_type == "rescue" else "Data" if mission_type == "investigate" else "Convoy" if mission_type == "escort" else str(mission.get("n", "the objective"))
	var objective := str(result.get("objective", mission.get("objName", objective_default)))
	var outcome := ("evacuated" if mission_type == "rescue" else "recovered" if mission_type == "investigate" else "held" if mission_type == "defend" else "secured") if bool(result.get("won", false)) else "lost"
	var decision := str(s.get("beat_decision", ""))
	var line := "%s %s; casualty report pending." % [objective, outcome] if rows.is_empty() else "%s %s; %s %s." % [objective, outcome, named, cost]
	if not decision.is_empty(): line += " Field choice: %s." % decision.trim_suffix(".")
	return line
