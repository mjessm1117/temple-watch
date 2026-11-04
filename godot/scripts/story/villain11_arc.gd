extends RefCounted
## Kaan's campaign and Bane's surviving doctrine, carried in the archive across eras.

static func ensure(s: Dictionary) -> void:
	if not s.has("villain11_seen"): s.villain11_seen = []
	if not s.has("villain11_answers"): s.villain11_answers = {"light":0,"dark":0}

static func next(s: Dictionary, rows: Array) -> Dictionary:
	ensure(s)
	for row in rows:
		if s.villain11_seen.has(row.id) or int(s.era) != int(row.era): continue
		if int(s.story.get("done",0)) < int(row.get("done",0)): continue
		if row.has("flag") and not s.flags.get(row.flag,false): continue
		if row.has("flags_any") and not row.flags_any.any(func(flag): return s.flags.get(flag,false)): continue
		var text_line: String = str(row.text)
		if row.has("outcome"): text_line += "\n\n" + str(row.outcome.get("win" if s.flags.get("boss_ru_won",false) else "lose",""))
		if row.has("react"):
			var react: Dictionary = row.react
			var key := "dark" if int(s.get("orderDark",0)) >= 20 or int(s.story.get("shadow",0)) >= 8 else "light"
			if react.has("death") and _fallen_name(s) != "": key = "death"
			if react.has("arc") and s.get("personal_arcs",{}).values().has(3): key = "arc"
			text_line += "\n\n" + str(react.get(key,react.get("light",""))).replace("{fallen}",_fallen_name(s))
		var choices := [{"id":"villain:light","label":"Answer with resolve","fx":{"orderDark":-2}}, {"id":"villain:dark","label":"Answer with fear","fx":{"orderDark":2}}]
		var eyebrow := "Force vision" if int(row.era) == 1 else "Intercepted transmission" if int(row.era) == 2 else "Archive vision"
		var scene := {"kind":"villain11","id":row.id,"name":row.speaker,"title":row.title,"eyebrow":eyebrow,"text":text_line,"choices":choices}
		s.pending = scene
		return scene
	return {}

static func chosen(s: Dictionary, scene: Dictionary, choice: Dictionary) -> void:
	if scene.get("kind","") != "villain11": return
	ensure(s)
	if not s.villain11_seen.has(scene.id): s.villain11_seen.append(scene.id)
	var side := "dark" if str(choice.get("id","")).ends_with("dark") else "light"
	s.villain11_answers[side] = int(s.villain11_answers.get(side,0)) + 1

static func briefing(s: Dictionary, scene: Dictionary) -> void:
	var id := str(scene.get("id",""))
	var rival := "Lord Kaan" if id in ["r_seventh","r_bomb"] else "Darth Bane"
	if id not in ["r_caves","r_seventh","r_bomb"]: return
	var start := "%s: You have come far enough to hear us." % rival
	var end := "%s: The field remembers who walked away." % rival
	scene.villain_present = true
	scene.villain_name = rival
	scene.villain_start_bark = start
	scene.villain_end_bark = end

static func attach_battle(s: Dictionary, pending: Dictionary) -> void:
	var briefing: Dictionary = s.get("last_villain_briefing",{})
	if briefing.get("id","") != pending.get("mission_id",""): return
	for key in ["villain_present","villain_name","villain_start_bark","villain_end_bark"]:
		pending[key] = briefing.get(key)

static func debrief(s: Dictionary, scene: Dictionary) -> void:
	if int(s.get("era",1)) != 3 or scene.get("id","") != "h_beacon": return
	ensure(s)
	var dark := int(s.get("orderDark",0)) >= 20 or int(s.story.get("shadow",0)) >= 8
	var answers: Dictionary = s.villain11_answers
	var response := "The archive records your answers to Kaan and Bane: %d in the light, %d in the dark." % [int(answers.light),int(answers.dark)]
	var ending := "The Order carries the old warning into another age." if not dark else "The old fear has found a home inside the Order."
	if int(answers.dark) > int(answers.light): ending += " Bane's argument still finds listeners."
	else: ending += " The Rule of Two remains a warning, not a creed."
	scene.text = str(scene.text) + "\n\n" + response + "\n" + ending

static func journal(s: Dictionary, record: Dictionary, rows: Array) -> void:
	ensure(s)
	var lines: Array = []
	for row in rows:
		if s.villain11_seen.has(row.id): lines.append("%s — %s" % [row.speaker,row.title])
	for encounter in s.get("villain11_encounters", []):
		var summary := preload("res://scripts/villain11_battle.gd").outcome_text(str(encounter.get("name", "Sith Lord")), str(encounter.get("outcome", "absent")))
		if not summary.is_empty(): lines.append(summary)
	record.villain = lines

static func _fallen_name(s: Dictionary) -> String:
	for person in s.get("roster",[]):
		if person.get("status","") == "dead": return str(person.get("n","a squad member"))
	if not s.get("memorials",[]).is_empty(): return str(s.memorials[0]).get_slice(" died",0)
	return ""
