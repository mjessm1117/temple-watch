extends RefCounted
## Compact unit details shared by the phone popup.
static func unit_details(g, unit: Dictionary) -> String:
	var lines: Array[String] = [str(unit.get("name", "UNIT")), str(unit.get("class_name", "Jedi"))]
	lines.append("HP %d/%d  ·  AP %d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 0)), int(unit.get("ap", 0))])
	if unit.has("will"): lines.append("WILL %d" % int(unit.will))
	lines.append("FOCUS %d  ·  MEDPACS %d" % [int(unit.get("focus_left", 0)), int(unit.get("medpacs", 0))])
	if unit.has("ammo"): lines.append("AMMO %d/%d" % [int(unit.ammo), int(unit.clip)])
	if g.mission.get("momentum") != null: lines.append("MOMENTUM %d/10" % int(g.mission.momentum))
	var cooldowns: Dictionary = unit.get("cooldowns", {})
	for ability in cooldowns:
		var remaining: int = maxi(0, int(cooldowns[ability]) - g.mission.turn)
		if remaining > 0: lines.append("%s  ·  %d TURN CD" % [str(g.mission.abilities.get(ability, {}).get("name", ability)).to_upper(), remaining])
	var partners: Array[String] = []
	for mate_id in unit.get("bondmates", {}):
		var mate: Dictionary = g.mission.unit_by_id(int(mate_id))
		if not mate.is_empty(): partners.append(str(mate.get("name", "")))
	lines.append("BOND  " + (", ".join(partners) if not partners.is_empty() else "No partner"))
	var statuses: Array[String] = []
	for key in ["hunkered", "overwatch", "concealed", "stunned", "rooted", "disarmed", "wounded"]:
		if bool(unit.get(key, false)): statuses.append(key.capitalize())
	if not statuses.is_empty(): lines.append("STATUS  " + ", ".join(statuses))
	return "\n".join(lines)
