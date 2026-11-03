extends RefCounted
const PATH = "res://data/campaign/events11.json"

static func definitions() -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data.get("CRISES", []) if data is Dictionary else []

static func ensure(s: Dictionary) -> void:
	if not s.has("crises11"): s.crises11 = {"active":[],"done":[]}

static func definition(id: String) -> Dictionary:
	for row in definitions():
		if row.id == id: return row
	return {}

static func after_mission(c) -> void:
	ensure(c.state)
	for row in definitions():
		if int(c.state.events11.missions) < int(row.open_at) or c.state.crises11.done.has(row.id): continue
		var exists := false
		for active in c.state.crises11.active:
			if active.id == row.id: exists = true
		if exists: continue
		c.state.crises11.active.append({"id":row.id,"stage":0,"deadline":int(c.state.elapsed_days)+int(row.days),"ready_day":int(c.state.elapsed_days)})
		c.state.news.append("Crisis: %s — %d days remain." % [row.title, row.days])

static func tick(c) -> void:
	ensure(c.state)
	for active in c.state.crises11.active.duplicate():
		if int(c.state.elapsed_days) >= int(active.deadline): resolve(c, active, false)

static func choose(c, id: String, index: int) -> bool:
	for active in c.state.crises11.active:
		if active.id != id: continue
		var row := definition(id)
		if row.is_empty() or int(c.state.elapsed_days) < int(active.ready_day) or int(c.state.elapsed_days) >= int(active.deadline): return false
		var choices: Array = row.steps[int(active.stage)]
		if index < 0 or index >= choices.size(): return false
		if not preload("res://scripts/campaign/events11_engine.gd").apply(c, str(row.planet), choices[index][1]): return false
		active.stage = int(active.stage) + 1; active.ready_day = int(c.state.elapsed_days) + 1
		c.state.news.append("%s: %s" % [row.title, choices[index][0]])
		if int(active.stage) >= row.steps.size(): resolve(c, active, true)
		return true
	return false

static func resolve(c, active: Dictionary, win: bool) -> void:
	var row := definition(str(active.id))
	if row.is_empty(): return
	preload("res://scripts/campaign/events11_engine.gd").apply(c, str(row.planet), row.win if win else row.loss, false)
	c.state.crises11.active.erase(active)
	c.state.crises11.done.append(str(active.id))
	c.state.news.append("%s %s. Lasting effects remain on %s." % [row.title, "resolved" if win else "failed", row.planet])

static func deadlines(s: Dictionary) -> Array:
	var rows := []
	for active in s.get("crises11", {}).get("active", []):
		var row := definition(str(active.id))
		rows.append("%s: %d days" % [row.get("title", active.id), maxi(0, int(active.deadline) - int(s.elapsed_days))])
	return rows
