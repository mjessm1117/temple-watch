extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")

static func ensure(state: Dictionary) -> void:
	if not state.has("research"): state.research = {"done":[], "cur":"", "prog":0.0}
	if not state.research.has("done"): state.research.done = []
	if not state.research.has("cur"): state.research.cur = ""
	if not state.research.has("prog"): state.research.prog = 0.0
	if not state.research.has("queue"): state.research.queue = []
	if not state.research.has("last"): state.research.last = ""
	var valid: Dictionary = Data.get_table("research", "RESEARCH")
	var seen: Array = state.research.done.duplicate()
	if state.research.cur != "": seen.append(state.research.cur)
	var clean := []
	for id in state.research.queue:
		if valid.has(id) and id not in seen:
			clean.append(id); seen.append(id)
	state.research.queue = clean

static func can_queue(c, id: String) -> bool:
	ensure(c.state)
	var project: Dictionary = Data.get_table("research", "RESEARCH").get(id, {})
	if project.is_empty() or c.researched(id) or str(c.state.research.cur) == id or id in c.state.research.queue: return false
	if int(project.get("era", 1)) > int(c.state.era): return false
	var ahead: Array = c.state.research.done.duplicate()
	if c.state.research.cur != "": ahead.append(c.state.research.cur)
	ahead.append_array(c.state.research.queue)
	for need in project.get("need", []):
		if need not in ahead: return false
	return true

static func enqueue(c, id: String) -> bool:
	if not can_queue(c, id): return false
	c.state.research.queue.append(id)
	activate(c)
	return true

static func dequeue(c, id: String) -> bool:
	ensure(c.state)
	if id not in c.state.research.queue: return false
	c.state.research.queue.erase(id)
	var ahead: Array = c.state.research.done.duplicate()
	if c.state.research.cur != "": ahead.append(c.state.research.cur)
	var kept := []
	for queued in c.state.research.queue:
		var valid := true
		for need in Data.get_table("research", "RESEARCH")[queued].get("need", []):
			if need not in ahead: valid = false
		if valid: kept.append(queued); ahead.append(queued)
	c.state.research.queue = kept
	return true

static func activate(c) -> void:
	ensure(c.state)
	if c.state.research.cur != "" or not Base.operational(c.state, "archives"): return
	if c.state.research.queue.is_empty(): return
	var id: String = c.state.research.queue[0]
	var p: Dictionary = Data.get_table("research", "RESEARCH")[id]
	if int(c.state.get("elapsed_days", 0)) < int(p.get("min_day", 0)): return
	for need in p.get("need", []):
		if not c.researched(str(need)): return
	if not c.can_afford(p.cost): return
	c.spend(p.cost)
	c.state.research.queue.pop_front()
	c.state.research.cur = id; c.state.research.prog = 0.0

static func complete(c, id: String) -> void:
	var p: Dictionary = Data.get_table("research", "RESEARCH")[id]
	c.state.research.done.append(id)
	c.state.research.cur = ""; c.state.research.prog = 0.0
	c.state.research.last = id
	c.state.news.append("Unlocked: %s — %s" % [p.n, p.desc])
	if id == "kyberLore": c.gain("kyber", 1)
	if p.has("dark"): c.gain("orderDark", int(p.dark))
	activate(c)
