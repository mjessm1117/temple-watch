extends RefCounted
## Wave 10 scenes share the campaign Dictionary and the original story choice contract.

const Data = preload("res://scripts/campaign/data.gd")

static func debrief_choices(rows: Dictionary, won: bool) -> Array:
	var out: Array = []
	for i in rows.get("win" if won else "lose", []).size():
		var row: Dictionary = rows["win" if won else "lose"][i]
		out.append({"id":"after:%d" % i,"label":row.label,"fx":row.fx})
	return out

static func mid_scene(s: Dictionary, mission_id: String, turn: int, family: String, rows: Array) -> Dictionary:
	if rows.is_empty(): return {}
	var candidates: Array = rows.filter(func(row): return row.family == family)
	if candidates.is_empty(): candidates = rows.filter(func(row): return row.family == "investigate")
	var row: Dictionary = candidates[int(s.story.get("done", 0)) % candidates.size()]
	var choices: Array = []
	for i in row.choices.size():
		var c: Dictionary = row.choices[i]
		choices.append({"id":"beat:%d" % i,"label":c.label,"text":c.get("text", ""),"fx":c.fx,"battle":c.battle})
	return {"kind":"beat","id":row.id,"mission_id":mission_id,"title":row.title,"eyebrow":"Comms · Turn %d" % turn,"text":row.text,"choices":choices}

static func pair_talk(s: Dictionary, rows: Array) -> Dictionary:
	if rows.is_empty() or s.bonds.is_empty(): return {}
	var visit := "%d|%d" % [int(s.step),int(s.story.done)]
	if s.saga.get("talked", "") == visit: return {}
	for pair in s.bonds:
		var ids: PackedStringArray = str(pair).split("|")
		if ids.size() != 2: continue
		var a := _person(s,ids[0]); var b := _person(s,ids[1])
		if not _active_jedi(a) or not _active_jedi(b): continue
		var level := int(s.bonds[pair].get("lvl",0))
		for row in rows:
			if level < int(row.min_level) or s.saga.seen.has("pair:" + str(pair) + ":" + str(row.id)): continue
			var choices: Array = []
			for i in row.choices.size():
				var c: Dictionary = row.choices[i]
				choices.append({"id":"talk:%d" % i,"label":c.label,"fx":c.fx})
			var scene := {"kind":"talk","id":row.id,"pair":str(pair),"who":"","name":str(a.n) + " & " + str(b.n),"title":row.title,"eyebrow":"Temple conversation · Bond %d" % mini(level,3),"text":row.text,"choices":choices}
			s.pending = scene
			return scene
	return {}

static func temple_talk(s: Dictionary, rows: Array) -> Dictionary:
	var visit := "%d|%d" % [int(s.step),int(s.story.done)]
	if s.saga.get("talked", "") == visit: return {}
	for row in rows:
		if s.saga.seen.has(row.id): continue
		var choices: Array = []
		for i in row.choices.size():
			var c: Dictionary = row.choices[i]
			choices.append({"id":"talk:%d" % i,"label":c.label,"fx":c.fx})
		var scene := {"kind":"talk","id":row.id,"who":"","name":"Jedi Council","title":row.title,"eyebrow":"Temple conversation","text":row.text,"choices":choices}
		s.pending = scene
		return scene
	return {}

static func grief(s: Dictionary, data: Dictionary) -> Dictionary:
	var queue: Array = s.get("story_grief", [])
	if queue.is_empty() or data.is_empty(): return {}
	var row: Dictionary = queue[0]
	var choices: Array = []
	for i in data.choices.size():
		var c: Dictionary = data.choices[i]
		choices.append({"id":"event:%d" % i,"label":c.label,"fx":c.fx})
	var scene := {"kind":"event","id":"grief:" + str(row.id),"title":data.title,"eyebrow":data.eyebrow,"text":row.text,"choices":choices}
	s.pending = scene
	return scene

static func apply(s: Dictionary, scene: Dictionary, choice: Dictionary) -> void:
	if str(scene.get("id", "")).begins_with("grief:") and not s.get("story_grief", []).is_empty(): s.story_grief.pop_front()
	if scene.has("pair"):
		var pair := str(scene.pair)
		s.saga.seen.append("pair:" + pair + ":" + str(scene.id))
		var bond: Dictionary = s.bonds.get(pair,{})
		if not bond.is_empty():
			bond.n = int(bond.get("n",0)) + int(choice.get("fx",{}).get("bond_points",0))
			var need: Array = Data.get_table("temple", "BOND").need
			while int(bond.lvl) < 8 and int(bond.n) >= int(need[int(bond.lvl)]):
				bond.n = int(bond.n) - int(need[int(bond.lvl)])
				bond.lvl = int(bond.lvl) + 1

static func _person(s: Dictionary, id: String) -> Dictionary:
	for r in s.roster:
		if str(r.get("id", "")) == id: return r
	return {}

static func _active_jedi(r: Dictionary) -> bool:
	return r.get("status") == "active" and str(r.get("cls", "")) in ["Guardian","Consular","Sentinel","Wayseeker","Defender"]
