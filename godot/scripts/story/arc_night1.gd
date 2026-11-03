extends RefCounted
## Six starting roster personal arcs. The cast retains its existing roles.

static func ensure(s: Dictionary) -> void:
	if not s.has("personal_arcs"): s.personal_arcs = {}
	if not s.has("memorials"): s.memorials = []

static func person(s: Dictionary, name: String) -> Dictionary:
	for r in s.get("roster", []):
		if r.get("n", "") == name: return r
	return {}

static func check_losses(s: Dictionary, rows: Array) -> void:
	ensure(s)
	for row in rows:
		var r := person(s, str(row.name))
		if r.is_empty(): continue
		if r.get("status", "") != "dead": continue
		if int(s.personal_arcs.get(row.id, 0)) == -1: continue
		if int(s.personal_arcs.get(row.id, 0)) >= 3: continue
		s.personal_arcs[row.id] = -1
		var line := "%s died before %s could be finished. Their watch is remembered at the Temple." % [row.name, row.title]
		if not s.memorials.has(line): s.memorials.append(line)

static func next_talk(s: Dictionary, rows: Array) -> Dictionary:
	check_losses(s, rows)
	if int(s.get("era", 1)) != 1: return {}
	for row in rows:
		var r := person(s, str(row.name))
		if r.is_empty() or r.get("status", "") != "active": continue
		var step := int(s.personal_arcs.get(row.id, 0))
		if step == 0 and int(s.story.get("done", 0)) >= 1:
			var scene := {"kind":"arc_talk","id":row.id,"name":row.name,"title":row.title,"eyebrow":"Temple conversation","text":row.talk,"choices":[{"id":"arc:0","label":"Listen","fx":{}}]}
			s.pending = scene
			return scene
		if step == 2 and int(s.story.get("done", 0)) >= 2:
			var choices: Array = []
			for i in row.choices.size(): choices.append({"id":"arc:%d" % i,"label":row.choices[i].label,"fx":{}})
			var scene := {"kind":"arc_resolution","id":row.id,"name":row.name,"title":row.title,"eyebrow":"A choice that stays","text":row.resolution,"choices":choices}
			s.pending = scene
			return scene
	return {}

static func briefing(s: Dictionary, scene: Dictionary, rows: Array) -> void:
	check_losses(s, rows)
	for row in rows:
		if int(s.personal_arcs.get(row.id, 0)) != 1: continue
		var r := person(s, str(row.name))
		if r.is_empty() or r.get("status", "") != "active": continue
		scene.text = str(scene.text) + "\n\n" + str(row.brief)
		s.personal_arcs[row.id] = 2

static func chosen(s: Dictionary, scene: Dictionary, choice_id: String, rows: Array) -> void:
	if not str(scene.get("kind", "")).begins_with("arc_"): return
	for row in rows:
		if row.id != scene.get("id", ""): continue
		if scene.kind == "arc_talk": s.personal_arcs[row.id] = 1; return
		var index := int(choice_id.trim_prefix("arc:"))
		if index < 0 or index >= row.choices.size(): return
		var r := person(s, str(row.name))
		if r.is_empty() or r.get("status", "") != "active": return
		var outcome: Dictionary = row.choices[index]
		if not r.has("bonus"): r.bonus = {}
		for key in outcome.get("bonus", {}): r.bonus[key] = int(r.bonus.get(key, 0)) + int(outcome.bonus[key])
		r.dark = int(r.get("dark", 0)) + int(outcome.get("dark", 0))
		s.personal_arcs[row.id] = 3
		return
