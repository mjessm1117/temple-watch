extends RefCounted

static func entries(s: Dictionary, callbacks: Array, arcs: Array) -> Dictionary:
	preload("res://scripts/story/arc_night1.gd").check_losses(s, arcs)
	var choices: Array = []
	for row in callbacks:
		if s.get("flags", {}).get(row.flag, false): choices.append(str(row.text))
	var active: Array = []
	for row in arcs:
		var stage := int(s.personal_arcs.get(row.id, 0))
		if stage == -1 or stage == 3: continue
		var person: Dictionary = preload("res://scripts/story/arc_night1.gd").person(s, str(row.name))
		if person.is_empty(): continue
		var done := int(s.story.get("done", 0))
		var hint := ""
		if stage == 0:
			hint = "Speak at the Temple now." if done >= 1 else "After 1 more mission: speak at the Temple."
		elif stage == 1:
			var wait := maxi(0, 3 - done)
			hint = "Bring them to the next briefing now." if wait == 0 or preload("res://scripts/story/arc_night1.gd").has_bond(s) else "After %d more mission%s or any bond level 1: bring them to a briefing." % [wait, "" if wait == 1 else "s"]
		else:
			var wait := maxi(0, 6 - done)
			hint = "Return to the Temple for their decision now." if wait == 0 or int(s.get("era", 1)) >= 2 else "After %d more mission%s or at era 2: return to the Temple." % [wait, "" if wait == 1 else "s"]
		active.append("%s — %s: %s" % [row.name, row.title, hint])
	return {"era":int(s.get("era", 1)),"choices":choices,"arcs":active,"fallen":s.get("memorials", []).duplicate()}

static func interlude(s: Dictionary, from_era: int, callbacks: Array) -> Dictionary:
	var lines: Array = []
	for row in callbacks:
		if s.get("flags", {}).get(row.flag, false): lines.append(str(row.text))
		if lines.size() == 3: break
	while lines.size() < 2:
		lines.append("The Temple kept watch while the war moved beyond its walls.")
	lines.append("The next generation inherits what you chose to protect.")
	return {"kind":"interlude","id":"era_%d_to_%d" % [from_era,from_era+1],"title":"The Years Between","eyebrow":"Era %d → Era %d" % [from_era,from_era+1],"text":"\n\n".join(lines),"choices":[{"id":"interlude:0","label":"Carry the record forward","fx":{}}]}
