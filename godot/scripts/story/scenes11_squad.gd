extends RefCounted
## Named squad conversations preserve their own record across era roster changes.

static func ensure(s: Dictionary) -> void:
	if not s.has("scenes11_seen"): s.scenes11_seen = []
	if not s.has("scenes11_log"): s.scenes11_log = []

static func next(s: Dictionary, rows: Array) -> Dictionary:
	ensure(s)
	var visit := "%d|%d|%d" % [int(s.era),int(s.get("step",0)),int(s.story.get("done",0))]
	if s.get("scenes11_visit","") == visit: return {}
	for row in rows:
		if int(row.era) != int(s.era) or s.scenes11_seen.has(row.id): continue
		if int(s.story.get("done",0)) < int(row.get("done",0)): continue
		var people: Array = []
		for index in row.members:
			if int(index) >= s.roster.size(): break
			var person: Dictionary = s.roster[int(index)]
			if person.get("status","") != "active": break
			people.append(person)
		if people.size() != row.members.size(): continue
		if int(row.get("bond",0)) > 0:
			var pair := _pair(str(people[0].id),str(people[1].id))
			if int(s.bonds.get(pair,{}).get("lvl",0)) < int(row.bond): continue
		var names: Array = people.map(func(p): return str(p.n))
		var choices: Array = []
		for i in row.choices.size():
			var c: Dictionary = row.choices[i]
			choices.append({"id":"scene11:%d" % i,"label":c.label,"fx":{"orderDark":int(c.get("dark",0))},"bond_points":int(c.get("bond",0))})
		var scene := {"kind":"scene11","id":row.id,"name":" & ".join(names),"title":row.title,"eyebrow":"Temple conversation","text":"\n".join(row.lines),"choices":choices,"members":people.map(func(p): return str(p.id)),"pair":_pair(str(people[0].id),str(people[1].id))}
		s.pending = scene
		return scene
	return {}

static func chosen(s: Dictionary, scene: Dictionary, choice: Dictionary, engine: RefCounted) -> void:
	if scene.get("kind","") != "scene11": return
	ensure(s)
	s.scenes11_seen.append(scene.id)
	s.scenes11_log.append("%s — %s" % [scene.name,scene.title])
	s.scenes11_visit = "%d|%d|%d" % [int(s.era),int(s.get("step",0)),int(s.story.get("done",0))]
	var members: Array = scene.get("members",[])
	if members.size() >= 2 and int(choice.get("bond_points",0)) != 0:
		engine.bond_points(s,str(members[0]),str(members[1]),int(choice.bond_points))

static func journal(s: Dictionary, record: Dictionary, _rows: Array) -> void:
	ensure(s)
	record.squad = s.scenes11_log.duplicate()

static func _pair(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a
