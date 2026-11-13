extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")

static func patient_actions25(c, soldier_id: String) -> Array:
	return load("res://scripts/w25_roster_people.gd").patient_actions(c, soldier_id)

static func open_from_temple(tree: SceneTree, room: String, soldier_id: String) -> void:
	preload("res://scripts/campaign/squad.gd").open_from_temple(tree, room, soldier_id)

static func ensure(s: Dictionary) -> void:
	if not s.has("strategy"): s.strategy = {}
	var defaults := {"squad_upgrades":0, "team_deployed":[], "projects":[], "project":{}, "training":{}, "edict":[], "edict_month":0, "votes":{}, "support":[], "support_used":{}, "loyalty":60}
	for key in defaults:
		if not s.strategy.has(key): s.strategy[key] = defaults[key]
	for r in s.roster:
		if not r.has("fatigue"): r.fatigue = 0
		if not r.has("extra_picks"): r.extra_picks = []
		if not r.has("ability_slots"): r.ability_slots = 0
	if not s.has("cands"): refresh_recruits(s)

static func ready(r: Dictionary) -> bool:
	return not r.is_empty() and r.get("status", "") == "active" and int(r.get("wound", 0)) == 0 and r.get("assign", "") == "" and int(r.get("fatigue", 0)) < 67

static func fatigue_status(r: Dictionary) -> String:
	var value := int(r.get("fatigue", 0))
	return "EXHAUSTED" if value >= 67 else "TIRED" if value >= 34 else "READY"

static func rank_tier_label(r: Dictionary) -> String:
	var explicit := str(r.get("rank_tier", ""))
	if explicit != "": return explicit
	var side_name := Classes.side(str(r.get("cls", "")))
	var rank := int(r.get("rank", 1))
	if side_name == "jedi": return str(Classes.rank_data(side_name, rank).get("tier", "Padawan"))
	return ["Recruit", "Specialist", "Expert", "Expert", "Elite", "Elite", "Legend"][clampi(rank - 1, 0, 6)]

static func chain_tag_label(r: Dictionary) -> String:
	var explicit := str(r.get("combo_tag", ""))
	if explicit != "": return explicit
	var abilities: Dictionary = Classes.class_data(str(r.get("cls", ""))).get("abilities", {})
	var candidates: Array = r.get("picks", []).duplicate()
	var signature := str(Classes.class_data(str(r.get("cls", ""))).get("signature", ""))
	if signature != "": candidates.append(signature)
	for id in candidates:
		var chain: Dictionary = abilities.get(str(id), {}).get("chain", {})
		for action in ["consume", "apply"]:
			for entry in chain.get(action, []):
				var tag := str(entry.get("tag", ""))
				if tag != "": return tag
	return ""

static func refresh_recruits(s: Dictionary) -> void:
	s.cands = []
	var names: Array = Data.get_table("core", "RECRUIT_NAMES")
	for i in 3:
		var jedi := i == 0 and int(s.month) % 2 == 1
		var cls: String = ["Guardian", "Consular", "Sentinel"][(int(s.month) + i) % 3] if jedi else ["Trooper", "Scout", "Medic", "Heavy", "Sniper", "Tech", "Droid", "Officer"][(int(s.month) + i) % 8]
		s.cands.append({"id":"candidate-%d-%d" % [s.month, i], "n":names[(int(s.month) * 3 + i) % names.size()], "cls":cls, "jedi":jedi})

static func capacity(s: Dictionary) -> int:
	var caps: Array = Data.get_table("core", "WINGS").barracks.cap
	return int(caps[mini(int(s.wings.barracks), caps.size() - 1)])

static func hire(c, id: String) -> bool:
	var active := 0
	for r in c.state.roster:
		if r.status in ["active", "captured"]: active += 1
	if active >= capacity(c.state): return false
	for candidate in c.state.cands:
		if str(candidate.id) != id: continue
		var jedi := bool(candidate.jedi)
		if not c.spend({"credits":0 if jedi else int(Data.get_table("core", "HIRE_COST")), "recruits":0 if jedi else 1}): return false
		var next_id := int(c.state.nid)
		while not c.soldier("u%d" % next_id).is_empty(): next_id += 1
		c.state.nid = next_id + 1
		var r := {"id":"u%d" % next_id, "n":candidate.n, "cls":candidate.cls, "title":"Padawan" if jedi else "Recruit", "tier":"Padawan" if jedi else "Recruit", "rank":1, "xp":0, "dark":0, "picks":[], "pick":1, "classes":[Classes.class_id(str(candidate.cls))], "cross_picks":[], "trained_padawans":[], "legacies":[], "wound":0, "status":"active", "kills":0, "missions":0, "stress":0, "scars":[], "assign":"", "bonus":{}, "fatigue":0, "extra_picks":[], "ability_slots":0,
			"col":"#72e0a4" if jedi else "#d9a05b", "gear":{"w":0 if jedi else 1,"armor":"robes" if jedi else "light","mods":[],"amods":[],"smods":[],"saber":1 if jedi else 0,"trait":"","util":"none","form":"shiiCho","mk":{"w":1,"a":1,"s":1}}}
		c.state.roster.append(r); c.state.cands.erase(candidate); c.ensure_teams(); c.Identity.ensure(c)
		c.state.news.append("%s joined the Order." % r.n)
		return true
	return false

static func squad_capacity(s: Dictionary) -> int:
	return 5 + clampi(int(s.get("strategy", {}).get("squad_upgrades", 0)), 0, 2)

static func upgrade_squad(c) -> bool:
	var level := int(c.state.strategy.squad_upgrades)
	if level >= 2 or not Base.operational(c.state, "training") or int(c.state.wings.barracks) < level + 1: return false
	var veteran := false
	for r in c.state.roster:
		if r.status == "active" and int(r.rank) >= level + 3: veteran = true
	if not veteran or not c.spend({"credits":100 + level * 75}): return false
	c.state.strategy.squad_upgrades = level + 1
	return true

static func train(c, id: String, mode: String, perk: String = "") -> bool:
	var r: Dictionary = c.soldier(id)
	if not ready(r) or not Base.operational(c.state, "training") or not c.state.strategy.training.is_empty(): return false
	var cost := 40
	match mode:
		"retrain":
			if r.picks.is_empty(): return false
		"slot":
			if int(r.ability_slots) >= 2 or int(c.state.wings.training) < 2: return false
			cost = 75
		"ability":
			if r.extra_picks.size() >= int(r.ability_slots) or perk in r.picks or perk in r.extra_picks or not extra_options(r).has(perk): return false
			cost = 50
		_: return false
	if not c.spend({"credits":cost}): return false
	c.state.strategy.training = {"id":id,"mode":mode,"perk":perk,"left":5.0}; r.assign = "training_center"
	return true

static func extra_options(r: Dictionary) -> Array:
	var out := []
	for rank in range(1, mini(2, int(r.rank)) + 1):
		for perk in Progression.tree_options(r, rank):
			if perk not in r.picks and perk not in r.extra_picks: out.append(perk)
	return out

static func start_project(c, id: String) -> bool:
	var p: Dictionary = Data.get_table("temple", "PROJECTS").get(id, {})
	if p.is_empty() or not Base.operational(c.state, "forge") or not c.state.strategy.project.is_empty() or id in c.state.strategy.projects: return false
	if not c.researched(str(p.research)) or not c.spend(p.cost): return false
	c.state.strategy.project = {"id":id,"progress":0.0}
	Base.log_room(c.state, "forge", "Started " + str(p.n))
	return true

static func tick(c) -> void:
	var s: Dictionary = c.state
	var healing := 1 + (Base.staff_count(s, "medical") if Base.operational(s, "medical") and int(s.elapsed_days) % 3 == 0 else 0)
	if "bacta" in s.strategy.projects: healing += 1
	if "relief" in s.strategy.edict: healing += 2
	for r in s.roster:
		if r.status != "active" or str(r.assign).begins_with("field:") or s.pending_mission.get("squad", []).has(r.id) or r.id in s.strategy.team_deployed: continue
		r.wound = maxi(0, int(r.wound) - healing * (2 if r.assign == "rest" else 1))
		r.fatigue = maxi(0, int(r.fatigue) - (4 + healing if r.assign in ["", "rest", "calm"] else 2))
		r.stress = maxi(0, int(r.stress) - 1)
		if r.assign == "rest" and int(r.wound) == 0 and int(r.fatigue) == 0: r.assign = ""
		if r.assign == "train" and Base.operational(s, "training"):
			r.xp = int(r.xp) + 1 + Base.staff_count(s, "training"); Progression.promote(r, s.roster, c)
	preload("res://scripts/campaign/mentor17.gd").tick(c)
	var training: Dictionary = s.strategy.training
	if not training.is_empty() and Base.operational(s, "training"):
		training.left = float(training.left) - 1.0 - 0.5 * Base.staff_count(s, "training")
		if float(training.left) <= 0:
			var r: Dictionary = c.soldier(training.id)
			if not r.is_empty():
				match str(training.mode):
					"retrain": r.picks = []; r.extra_picks = []; r.erase("spec"); r.pick = Progression.pending_rank(r)
					"slot": r.ability_slots = int(r.ability_slots) + 1
					"ability": r.extra_picks.append(training.perk)
				r.assign = ""
			s.strategy.training = {}; Base.log_room(s, "training", "Training complete")
	var project: Dictionary = s.strategy.project
	if not project.is_empty() and Base.operational(s, "forge"):
		project.progress = float(project.progress) + 1.0 + 0.5 * Base.staff_count(s, "forge")
		if float(project.progress) >= float(Data.get_table("temple", "PROJECTS")[project.id].days):
			s.strategy.projects.append(project.id); s.news.append("Project complete: " + str(Data.get_table("temple", "PROJECTS")[project.id].n))
			Base.log_room(s, "forge", "Project ready: " + str(project.id)); s.strategy.project = {}

static func after_mission(c, result: Dictionary) -> void:
	var s: Dictionary = c.state
	var effects := Base.effects(s)
	var deployed := []
	for entry in result.get("units", []):
		var r: Dictionary = c.soldier(str(entry.get("id", entry.get("rid", ""))))
		if r.is_empty(): continue
		deployed.append(r.id)
		if r.status == "active":
			r.fatigue = mini(100, int(r.fatigue) + 38 + (15 if bool(entry.get("downed", false)) else 0))
			r.xp = int(r.xp) + int(effects.get("xp", 0)); Progression.promote(r, s.roster, c)
	for r in s.roster:
		if r.status != "active": continue
		r.wound = maxi(0, int(r.wound) - int(effects.get("heal", 0)))
		r.stress = maxi(0, int(r.stress) - int(effects.get("stress", 0)))
		if not deployed.has(r.id): r.xp = int(r.xp) + int(effects.get("bench", 0)); Progression.promote(r, s.roster, c)
	if bool(result.get("win", false)):
		c.gain("credits", int(effects.get("winCr", 0)) + (20 if "reclamation" in s.strategy.edict else 0))
	if s.research.cur != "": s.research.prog = float(s.research.prog) + int(effects.get("research", 0)); c._tick_research(0)
