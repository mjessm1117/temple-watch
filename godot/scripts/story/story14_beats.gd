extends RefCounted
## One grounded squad line after the mission; presentation only.

static func debrief(s: Dictionary, result: Dictionary) -> String:
	var rows: Array = result.get("units",[])
	var roster: Dictionary = {}
	for person in s.get("roster",[]): roster[str(person.get("id",""))] = str(person.get("n",""))
	for row in rows:
		if str(row.get("status","")) == "dead":
			return "%s is missing from the return shuttle. The Temple keeps a place for them." % roster.get(str(row.get("id","")),"One of the squad")
	for row in rows:
		if bool(row.get("downed",false)) or bool(row.get("hurt",false)):
			return "%s makes it home wounded. The medics ask for the full account before anyone calls it a victory." % roster.get(str(row.get("id","")),"One of the squad")
	var best: Dictionary = {}
	for row in rows:
		if int(row.get("kills",0)) > int(best.get("kills",0)): best = row
	if not best.is_empty():
		return "%s held the line when it broke. Their squad remembers who stood beside them." % roster.get(str(best.get("id","")),"One of the squad")
	for pair in s.get("bonds",{}):
		if int(s.bonds[pair].get("lvl",0)) < 1: continue
		var ids: PackedStringArray = str(pair).split("|")
		if ids.size() == 2 and roster.has(ids[0]) and roster.has(ids[1]):
			return "%s waits for %s at the shuttle ramp. Neither says how close it was." % [roster[ids[0]],roster[ids[1]]]
	return "The squad returns together. Someone stays awake to count every name."
