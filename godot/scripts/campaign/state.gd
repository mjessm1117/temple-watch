extends RefCounted
## Persistent strategy layer. Pass battle results to apply_mission_result(), then save().
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Mentor17 = preload("res://scripts/campaign/mentor17.gd")
const Modules = preload("res://scripts/campaign/modules.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")
const Story = preload("res://scripts/story/story_engine.gd")
var story: RefCounted
var sith: RefCounted
const Integration = preload("res://scripts/campaign/integration.gd")
const SAVE_PATH = "user://campaign.json"
var state: Dictionary = {}
const Base = preload("res://scripts/campaign/strat_base.gd")
# --- wave10 gear ---
const ResearchQueue = preload("res://scripts/campaign/research_queue.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Ops = preload("res://scripts/campaign/strat_ops.gd")
const Identity = preload("res://scripts/campaign/strat_identity.gd")
const Council = preload("res://scripts/campaign/strat_council.gd")
const Events11 = preload("res://scripts/campaign/events11_engine.gd")
const Crisis11 = preload("res://scripts/campaign/crisis11_engine.gd")
signal month_advanced(month: int, snapshot: Dictionary)
signal mission_resolved(result: Dictionary, summary: Dictionary)
signal darkness_changed(segments: int, value: int)
signal rank_up(unit: Dictionary, previous: int, current: int)

func rank_advanced(unit: Dictionary, previous: int, current: int) -> void:
	rank_up.emit(unit, previous, current)
	preload("res://scripts/story/rank19_beats.gd").on_rank(state, unit, previous, current)

func ensure_strategy() -> void:
	Base.ensure(state); Roster.ensure(state); Identity.ensure(self); Ops.ensure(self)
	Events11.ensure(state)
	# --- wave10 gear ---
	ResearchQueue.ensure(state)

func darkness_segments() -> int:
	return int(sith.project_status().segments) if sith != null else 2

func squad_capacity() -> int:
	return Roster.squad_capacity(state)

func field_risk(id: String, team: Array) -> Dictionary:
	return Ops.risk(self, id, team)


func _init(difficulty: String = "normal") -> void:
	new_campaign(difficulty)

func new_campaign(difficulty: String = "normal") -> void:
	var core: Dictionary = Data.all("core")
	var wings := {"medical": 1, "training": 0, "forge": 0, "armory": 0, "comms": 0, "archives": 0, "gardens": 0, "barracks": 1}
	state = {"v": 2, "diff": difficulty, "era": 1, "month": 1, "day": 1, "elapsed_days": 0,
		"step": 0, "res": core.START_RES.duplicate(true), "orderDark": 0, "wings": wings,
		"build": "", "roster": [], "nid": 7, "research": {"done": [], "cur": "", "prog": 0.0},
		"staff": {}, "teams": [], "field": {"list": [], "log": []}, "unrest": {},
		"team_assignments": {},
		"bonds": {}, "quests": {}, "legacy": {"retired": [], "generals": {}}, "flags": {},
		"legends": [], "mentor_memorials": [], "news": [], "pending_mission": {}, "chosen": -1}
	var id := 1
	for item in core.START_ROSTER:
		var r: Dictionary = item.duplicate(true)
		r.id = "u%d" % id; id += 1
		r.rank = int(r.get("rank", 2)); r.xp = int(r.get("xp", 30))
		r.dark = 0; r.picks = r.get("picks", []); r.pick = 0
		r.classes = [Classes.class_id(str(r.cls))]; r.cross_picks = []; r.trained_padawans = []; r.legacies = []
		r.wound = 0; r.status = "active"; r.kills = 0; r.missions = 0
		r.stress = 0; r.scars = []; r.assign = ""; r.bonus = {}
		var jedi := Progression.is_jedi(r)
		r.gear = {"w": 0 if jedi else 1, "armor": "robes" if jedi else "light",
			"mods": [], "amods": [], "smods": [], "saber": 1 if jedi else 0,
			"trait": "", "util": "none", "form": "shiiCho", "mk": {"w": 1, "a": 1, "s": 1}}
		r.pick = Progression.pending_rank(r)
		state.roster.append(r)
	story = Story.new(state)
	# --- wave10 story ---
	preload("res://scripts/campaign/bond_story.gd").ensure(state)
	ensure_strategy()
	ensure_teams()
	Integration.bind(self)
	refresh_options()

func save(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"v": 2, "C": state, "at": Time.get_unix_time_from_system()}))
	return true

func load_save(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("v", 0)) not in [1, 2] or not parsed.get("C") is Dictionary: return false
	state = parsed.C
	_migrate()
	return true

func _migrate() -> void:
	for key in ["staff", "teams", "unrest", "bonds", "quests", "flags", "legends", "mentor_memorials", "news"]:
		if not state.has(key): state[key] = [] if key in ["teams", "legends", "mentor_memorials", "news"] else {}
	if not state.has("field"): state.field = {"list": [], "log": []}
	if not state.has("research"): state.research = {"done": [], "cur": "", "prog": 0.0}
	Modules.ensure(self)
	if not state.has("pending_mission"): state.pending_mission = {}
	if not state.has("team_assignments"): state.team_assignments = {}
	if not state.has("elapsed_days"): state.elapsed_days = (int(state.month) - 1) * 30 + int(state.day) - 1
	for r in state.roster:
		var defaults := {"rank":2, "xp":30, "pick":0, "dark":0, "wound":0, "status":"active", "kills":0, "missions":0, "bonus":{}}
		for key in defaults:
			if not r.has(key): r[key] = defaults[key]
		for key in ["picks", "scars"]:
			if not r.has(key): r[key] = []
		if not r.has("classes"): r.classes = [Classes.class_id(str(r.get("cls", "")))]
		for key in ["cross_picks", "trained_padawans", "legacies"]:
			if not r.has(key): r[key] = []
		if not r.has("tier"): r.tier = str(Classes.rank_data("jedi" if Progression.is_jedi(r) else "soldier", int(r.rank)).get("tier", r.get("title", "")))
		if not r.has("gear"): r.gear = {"w": 0 if Progression.is_jedi(r) else 1, "armor": "robes" if Progression.is_jedi(r) else "light", "mods": [], "saber": 1 if Progression.is_jedi(r) else 0, "util": "none", "form": "shiiCho", "mk": {"w": 1, "a": 1, "s": 1}}
		for key in ["mods", "amods", "smods"]:
			if not r.gear.has(key): r.gear[key] = []
		if not r.gear.has("mk"): r.gear.mk = {}
		if not r.has("assign"): r.assign = ""
		if not r.has("stress"): r.stress = 0
	story = Story.new(state)
	# --- wave10 story ---
	preload("res://scripts/campaign/bond_story.gd").ensure(state)
	ensure_strategy()
	ensure_teams()
	Integration.bind(self)
	refresh_options()

func soldier(id: String) -> Dictionary:
	for r in state.roster:
		if str(r.id) == id: return r
	return {}

func week() -> int:
	return int(state.elapsed_days) / 7 + 1

func gain(key: String, amount: int) -> void:
	if key == "orderDark":
		state.orderDark = clampi(int(state.orderDark) + amount, 0, 100)
		darkness_changed.emit(darkness_segments(), int(state.orderDark))
	else:
		state.res[key] = int(state.res.get(key, 0)) + amount
		if key == "favor": state.res.favor = clampi(int(state.res.favor), 0, 100)
		if key == "kyber": state.res.kyber = maxi(0, int(state.res.kyber))

func can_afford(cost: Dictionary) -> bool:
	for key in cost:
		if int(state.res.get(key, 0)) < int(cost[key]): return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost): return false
	for key in cost: gain(str(key), -int(cost[key]))
	return true

func build_wing(key: String) -> bool:
	var wing: Dictionary = Data.get_table("core", "WINGS").get(key, {})
	if wing.is_empty() or str(state.build) != "": return false
	var level := int(state.wings.get(key, 0)) + 1
	if level >= wing.cost.size(): return false
	if wing.has("req") and level < wing.req.size() and not researched(str(wing.req[level])): return false
	var cost := int(wing.cost[level])
	if not can_afford({"credits":cost}) or not Base.reserve(self, key): return false
	spend({"credits":cost})
	state.facility.build_left = 7.0
	state.build = key
	Base.log_room(state, key, "Construction started")
	return true

func researched(id: String) -> bool:
	return id in ["", "0", "0.0"] or state.research.done.has(id)

func start_research(id: String) -> bool:
	# --- wave10 gear ---
	ResearchQueue.ensure(state)
	var project: Dictionary = Data.get_table("research", "RESEARCH").get(id, {})
	if project.is_empty() or not Base.operational(state, "archives") or str(state.research.cur) != "" or not state.research.queue.is_empty(): return false
	if researched(id) or int(project.get("era", 1)) > int(state.era): return false
	if int(state.get("elapsed_days", 0)) < int(project.get("min_day", 0)): return false
	for need in project.get("need", []):
		if not researched(str(need)): return false
	if not spend(project.get("cost", {})): return false
	state.research.cur = id; state.research.prog = 0.0
	return true

func assign(id: String, job: String) -> bool:
	var r := soldier(id)
	if r.is_empty() or str(r.status) != "active" or str(r.assign).begins_with("field:") or r.assign == "training_center" or state.pending_mission.get("squad", []).has(id): return false
	if job.begins_with("staff:"):
		var wing := job.trim_prefix("staff:")
		if not Base.operational(state, wing) or Base.staff_count(state, wing) >= mini(2, int(state.wings[wing])) or int(r.wound) > 0: return false
	elif job not in ["", "train", "rest", "calm"]: return false
	elif job == "train" and not Base.operational(state, "training"): return false
	elif job == "rest" and not Base.operational(state, "medical"): return false
	elif job == "calm" and not Base.operational(state, "gardens"): return false
	if str(r.assign).begins_with("staff:"): state.staff.erase(str(r.assign).trim_prefix("staff:"))
	if job.begins_with("staff:"): state.staff[job.trim_prefix("staff:")] = id
	r.assign = job
	return true

func heal_multiplier() -> float:
	var level := int(state.wings.medical)
	return (2.5 if level >= 3 else 2.0 if level >= 2 else 1.5 if level >= 1 else 1.0) * (1.25 if state.staff.has("medical") else 1.0)

func advance_days(days: int) -> void:
	if sith.project_status().defeated: return
	ensure_strategy()
	for _day in maxi(0, days):
		state.elapsed_days = int(state.elapsed_days) + 1; state.day = int(state.day) + 1
		Crisis11.tick(self)
		Base.tick(self); Roster.tick(self); _tick_research(1); Ops.tick(self)
		if int(state.day) > 30:
			state.day = 1; state.month = int(state.month) + 1
			_month_tick()
		sith.advance_day()
		if sith.project_status().defeated: break
	refresh_options()
	Identity.reveal(self)

func advance_mission() -> void:
	advance_days(int(Data.get_table("core", "DAYS")))
	Modules.advance_mission(self)
	state.strategy.team_deployed = []
	for r in state.roster:
		if r.status == "captured" and not r.get("covert_captive", false) and not r.has("sith_captor"):
			r.capT = int(r.get("capT", 1)) - 1
			if int(r.capT) <= 0:
				r.status = "active"; r.wound = ceili(float(Data.get_table("core", "WOUND").serious) / heal_multiplier())
	ensure_teams()

func _tick_research(days: int) -> void:
	# --- wave10 gear ---
	ResearchQueue.activate(self)
	var id := str(state.research.cur)
	if id == "" or not Base.operational(state, "archives"): return
	var speed := (1.5 if int(state.wings.archives) >= 2 else 1.0) * (1.0 + 0.5 * Base.staff_count(state, "archives"))
	if "scholarship" in state.strategy.edict: speed *= 1.5
	state.research.prog = float(state.research.prog) + days * speed
	var project: Dictionary = Data.get_table("research", "RESEARCH")[id]
	if float(state.research.prog) >= float(project.days):
		# --- wave10 gear ---
		ResearchQueue.complete(self, id)

func _month_tick() -> void:
	var core: Dictionary = Data.all("core")
	var income := float(Data.get_table("missions", "DIFF").get(str(state.diff), {}).get("income", 1.0))
	var stipend := roundi((float(core.STIPEND[0]) + float(core.STIPEND[1]) * int(state.res.favor)) * income)
	var upkeep := 0
	for key in state.wings:
		var up: Array = core.WINGS[key].up
		upkeep += int(up[mini(int(state.wings[key]), up.size() - 1)])
	var troop_count := 0
	for r in state.roster:
		if str(r.status) == "active" and not Progression.is_jedi(r): troop_count += 1
	gain("credits", stipend - upkeep - troop_count * int(core.TROOP_PAY))
	if int(state.res.credits) < 0:
		state.res.credits = 0; gain("favor", -5)
	gain("recruits", 1 + int(state.res.favor) / 40)
	if Base.operational(state, "comms"): gain("intel", Base.staff_count(state, "comms"))
	if Base.operational(state, "barracks"): gain("recruits", Base.staff_count(state, "barracks"))
	for r in state.roster:
		if str(r.get("assign", "")) == "calm" and Progression.is_jedi(r):
			r.dark = maxi(0, int(r.dark) - int([0, 1, 2][mini(int(state.wings.gardens), 2)]))
	if Base.operational(state, "gardens"): gain("orderDark", -Base.staff_count(state, "gardens"))
	state.news.append("Month %d: stipend +%d, upkeep -%d." % [state.month, stipend, upkeep])
	Council.month(self); Ops.spawn(self)
	month_advanced.emit(int(state.month), {"day":state.day, "elapsed_days":state.elapsed_days, "darkness_segments":darkness_segments()})

func apply_mission_result(result: Dictionary) -> Dictionary:
	## Contract: {mission_id, win, units:[{id,status,hp,max_hp,downed,hurt,kills,captures,dark}],
	## rewards:{credits,intel,...}, intel, loot_credits, order_dark, story}. One call per finished mission.
	var id := str(result.get("mission_id", state.pending_mission.get("mission_id", "")))
	var before_res: Dictionary = state.res.duplicate(true)
	var before_threat: Dictionary = Events11.threat_snapshot(state)
	var mission: Dictionary = story.mission(id)
	var win := bool(result.get("win", false))
	var deployed: Array = result.get("units", [])
	var summary := {"rows": [], "promotions": [], "rewards": {}}
	if win:
		var rewards: Dictionary = result.get("rewards", mission.get("reward", {}))
		var income := float(Data.get_table("missions", "DIFF").get(str(state.diff), {}).get("income", 1.0))
		for key in rewards:
			var value := int(rewards[key])
			if key == "credits": value = roundi(value * income * float(Data.get_table("core", "MISSION_CR")))
			gain(str(key), value); summary.rewards[key] = value
	else: gain("favor", -3)
	gain("intel", int(result.get("intel", 0)))
	gain("credits", int(result.get("loot_credits", 0)))
	gain("orderDark", 4 * int(result.get("order_dark", 0)))
	var xp_data: Dictionary = Data.get_table("core", "XP")
	var wound_data: Dictionary = Data.get_table("core", "WOUND")
	for unit_result in deployed:
		var r := soldier(str(unit_result.get("id", unit_result.get("rid", ""))))
		if r.is_empty(): continue
		var fate := str(unit_result.get("status", "active"))
		var kills := int(unit_result.get("kills", 0))
		var xp := 0
		if fate == "dead":
			r.status = "dead"; r.assign = ""
			state.legends.append({"n": r.n, "cls": r.cls, "how": "Fell in battle", "where": mission.get("n", id)})
			Mentor17.on_death(self, r, str(mission.get("n", id)))
		elif fate == "captured" or (fate == "down" and not win):
			r.status = "captured"; r.capT = int(Data.get_table("core", "CAPTIVE")); r.assign = ""
		else:
			r.status = "active"
			xp = int(xp_data.survive) + kills * int(xp_data.kill) + int(unit_result.get("captures", 0)) * int(xp_data.capture)
			if win and bool(result.get("story", false)): xp += int(xp_data.story)
			var mult := (1.2 if int(state.wings.training) >= 2 else 1.1 if int(state.wings.training) >= 1 else 1.0)
			if state.staff.has("training"): mult *= 1.1
			if researched("holocron"): mult *= 1.1
			mult *= Mentor17.xp_multiplier(self, r)
			xp = roundi(xp * mult)
			var wound := 0
			if bool(unit_result.get("downed", false)): wound = int(wound_data.graveL2 if int(state.wings.medical) >= 2 else wound_data.grave)
			elif int(unit_result.get("hp", unit_result.get("max_hp", 1))) * 2 <= int(unit_result.get("max_hp", 1)): wound = int(wound_data.serious)
			elif bool(unit_result.get("hurt", false)): wound = int(wound_data.light)
			r.wound = ceili(float(wound) / heal_multiplier())
		if unit_result.has("dark"): r.dark = int(unit_result.dark)
		if kills > 0: Legacy.add_deed(self, str(r.id), "kills", kills)
		r.kills = int(r.kills) + kills; r.missions = int(r.missions) + 1; r.xp = int(r.xp) + xp
		if str(r.status) == "active" and Progression.promote(r, state.roster, self): summary.promotions.append(r.id)
		summary.rows.append({"id": r.id, "xp": xp, "status": r.status, "wound": r.wound, "rank": r.rank})
	for i in range(0 if result.get("bonds_recorded", false) else deployed.size()):
		for j in range(i + 1, deployed.size()):
			var a := soldier(str(deployed[i].get("id", deployed[i].get("rid", ""))))
			var b := soldier(str(deployed[j].get("id", deployed[j].get("rid", ""))))
			if not a.is_empty() and not b.is_empty() and str(a.status) == "active" and str(b.status) == "active":
				Legacy.bond_points(self, str(a.id), str(b.id), int(Data.get_table("temple", "BOND").together) + (int(Data.get_table("temple", "BOND").win) if win else 0))
	# --- wave10 story ---
	preload("res://scripts/campaign/bond_story.gd").settle(self,result)
	change_unrest(region_for_mission(id), int(Data.get_table("galaxy", "UNREST").win if win else Data.get_table("galaxy", "UNREST").lose))
	if win and not state.pending_mission.is_empty() and state.pending_mission.has("hostages") and not state.pending_mission.has("sith_offer_id"):
		for captive_id in state.pending_mission.hostages:
			var captive := soldier(str(captive_id))
			if not captive.is_empty() and str(captive.status) == "captured":
				captive.status = "active"; captive.capT = 0; captive.erase("covert_captive")
				captive.wound = ceili(float(wound_data.serious) / heal_multiplier())
	var selected: Dictionary = state.pending_mission.duplicate(true)
	Integration.settle_sith(self, result)
	var receipt := preload("res://scripts/mission_fronts.gd").finish(state)
	if receipt.advance:
		Integration.ignored(self, receipt.ignored)
		advance_mission()
	# --- wave10 gear ---
	if bool(result.get("win", false)) and researched("holonet"): gain("intel", 1)
	Roster.after_mission(self, result); Identity.after_mission(self, result)
	for row in summary.rows:
		var r := soldier(str(row.id))
		row.fatigue = int(r.fatigue); row.wound = int(r.wound); row.readiness = Roster.fatigue_status(r)
	if receipt.advance and not selected.is_empty() and bool(selected.get("adv", false)): state.step = int(state.step) + 1
	state.pending_mission = {}; state.chosen = -1
	if receipt.advance: refresh_options()
	Events11.after_mission(self, before_res, before_threat, bool(receipt.advance))
	mission_resolved.emit(result.duplicate(true), summary.duplicate(true))
	return summary

func refresh_options() -> Array:
	if state.get("twin",{}).get("stage", "") == "b": return state.options
	var era := int(state.era)
	var plan: Array = story.data[["data-story", "data-era2", "data-era3"][era - 1]].get("PLAN" if era == 1 else "PLAN%d" % era, [])
	while int(state.step) < plan.size() and plan[int(state.step)].has("years"):
		state.story.bby = int(state.story.bby) - int(plan[int(state.step)].years)
		state.step = int(state.step) + 1
	var step := int(state.step)
	var options := []
	if step < plan.size():
		var part: Dictionary = plan[step]
		if part.has("story"):
			options.append({"mission": str(part.story), "story": true, "adv": true, "kind": "Story"})
		for crisis_id in part.get("crises", []):
			var crisis: Dictionary = story.table("BASE_CRISES").get(str(crisis_id), story.table("CRISES").get(str(crisis_id), {})).duplicate(true)
			crisis.crisis = str(crisis_id); crisis.adv = true
			options.append(crisis)
		var captives := []
		for r in state.roster:
			if str(r.status) == "captured" and not r.has("sith_captor"): captives.append(r.id)
		if not captives.is_empty():
			var rescue := false
			for option in options:
				if str(option.get("mission", "")) == "rescue":
					option.hostages = captives; rescue = true
			if not rescue:
				options.append({"mission": "rescue", "crisis": "rescue", "kind": "Rescue", "hostages": captives, "adv": false})
	var stranded := []
	for r in state.roster:
		if r.status == "captured" and not r.has("sith_captor"): stranded.append(r.id)
	if not stranded.is_empty() and not options.any(func(o): return o.has("hostages")):
		options.append({"mission":"rescue","kind":"Rescue","hostages":stranded,"adv":false})
	options.append_array(Identity.quest_options(self))
	if sith != null: options.append_array(sith.mission_options())
	state.options = options
	return options

func select_mission(index: int, squad: Array = []) -> Dictionary:
	if sith.project_status().defeated: return {}
	if index < 0 or index >= state.options.size() or not state.pending_mission.is_empty(): return {}
	var option: Dictionary = state.options[index]
	var selected := squad.duplicate()
	if selected.is_empty(): selected = default_squad(option)
	if selected.is_empty() or selected.size() > squad_capacity(): return {}
	var unique := []
	for id in selected:
		if id in unique: return {}
		unique.append(id)
	if option.has("quest") and not selected.has(option.quest): return {}
	for id in selected:
		var r := soldier(str(id))
		if not Roster.ready(r): return {}
	if not preload("res://scripts/campaign/strat_deployment.gd").validate(self,selected,option): return {}
	var front := preload("res://scripts/mission_fronts.gd").launch(state,option,selected,Integration.plan(self))
	if not front.ok: return {}
	if option.get("kind", "") == "counter" and not sith.counter(str(option.op_id),str(option.sith_offer_id)): return {}
	if bool(option.get("adv", false)) and not front.defer_ignored:
		for other in state.options:
			if other != option and bool(other.get("adv", false)):
				var assigned := str(state.team_assignments.get(str(other.get("crisis", "")), ""))
				if assigned == "" or not _resolve_team(other, assigned, selected):
					sith.retaliation_trigger("Unanswered crisis",1)
					for key in other.get("ignore", {}): gain(str(key), int(other.ignore[key]))
					change_unrest(region_for_mission(str(other.mission)), int(Data.get_table("galaxy", "UNREST").ignore))
		state.team_assignments.clear()
	state.chosen = index
	state.pending_mission = option.duplicate(true)
	state.pending_mission.mission_id = str(option.mission)
	state.pending_mission.squad = selected
	state.pending_mission.fewer = int(front.fewer)
	state.deployment_serial = int(state.get("deployment_serial",0)) + 1
	state.pending_mission.result_id = "deployment_%d" % state.deployment_serial
	return state.pending_mission

func default_squad(option: Dictionary = {}) -> Array:
	var jedi := []; var troops := []
	for r in state.roster:
		if not Roster.ready(r) or option.get("hostages", []).has(r.id): continue
		if Progression.is_jedi(r): jedi.append(r.id)
		else: troops.append(r.id)
	var out := []
	for id in jedi.slice(0, 3): out.append(id)
	for id in troops:
		if out.size() >= squad_capacity(): break
		out.append(id)
	return Integration.default_squad(self, option, out)

func region_for_mission(id: String) -> String:
	var mission: Dictionary = story.mission(id)
	var where := str(mission.get("where", ""))
	var planet := where.split("·")[-1].strip_edges()
	return str(Data.get_table("galaxy", "PLANETS").get(planet, {}).get("reg", ""))

func change_unrest(region: String, delta: int) -> void:
	if region == "": return
	state.unrest[region] = clampi(int(state.unrest.get(region, 0)) + delta, 0, int(Data.get_table("galaxy", "UNREST").max))

func ensure_teams() -> void:
	var rules: Dictionary = Data.get_table("galaxy", "TEAMS")
	var cap := int(rules.base)
	for level in rules.barracks:
		if int(state.wings.barracks) >= int(level): cap += 1
	cap = mini(cap, int(rules.max))
	while state.teams.size() < cap:
		var index: int = state.teams.size()
		state.teams.append({"id": "t%d" % (index + 1), "n": "%s Team" % rules.names[index], "lead": "", "mem": []})
	for team in state.teams:
		if soldier(str(team.lead)).get("status", "dead") in ["dead", "retired"]: team.lead = ""
		team.mem = team.mem.filter(func(id): return soldier(str(id)).get("status", "dead") not in ["dead", "retired"])
	var free_jedi := []; var free_troops := []
	for r in state.roster:
		if str(r.status) != "active": continue
		var assigned := false
		for team in state.teams:
			if str(team.lead) == str(r.id) or team.mem.has(r.id): assigned = true
		if not assigned:
			if Progression.is_jedi(r): free_jedi.append(r.id)
			else: free_troops.append(r.id)
	for team in state.teams:
		if str(team.lead) == "" and not free_jedi.is_empty(): team.lead = free_jedi.pop_front()
	for team in state.teams:
		while team.mem.size() < int(rules.size) - 1 and not free_troops.is_empty(): team.mem.append(free_troops.pop_front())

func team_capacity() -> int:
	ensure_teams()
	return state.teams.size()

func assign_team_to_crisis(crisis: String, team_id: String) -> bool:
	var found := false
	for option in state.options:
		if str(option.get("crisis", "")) == crisis and bool(option.get("adv", false)): found = true
	if not found: return false
	for team in state.teams:
		if str(team.id) == team_id:
			for other in state.team_assignments.keys():
				if str(state.team_assignments[other]) == team_id: state.team_assignments.erase(other)
			state.team_assignments[crisis] = team_id
			return true
	return false

func _resolve_team(option: Dictionary, team_id: String, player_squad: Array) -> bool:
	var team: Dictionary = {}
	for candidate in state.teams:
		if str(candidate.id) == team_id: team = candidate
	if team.is_empty(): return false
	var forecast := Ops.team_risk(self, team, option, player_squad)
	var members: Array = forecast.members
	if members.size() < 2: return false
	var auto: Dictionary = Data.get_table("galaxy", "TAUTO")
	var odds := int(forecast.success)
	for r in members:
		r.fatigue = mini(100, int(r.fatigue) + 38)
		state.strategy.team_deployed.append(r.id)
	var win := randi_range(0, 99) < odds
	if win:
		var mission: Dictionary = Data.get_table("missions", "MISSIONS").get(str(option.mission), {})
		for key in mission.get("reward", {}):
			var amount := int(mission.reward[key])
			if key == "credits": amount = roundi(amount * float(Data.get_table("core", "MISSION_CR")) * float(Data.get_table("missions", "DIFF")[str(state.diff)].income))
			gain(str(key), amount)
		for r in members:
			r.xp = int(r.xp) + int(auto.xp); r.missions = int(r.missions) + 1
			Progression.promote(r, state.roster, self)
			if randi_range(0, 99) < int(auto.winWound): r.wound = maxi(int(r.wound), ceili(float(Data.get_table("core", "WOUND").light) / heal_multiplier()))
		for i in members.size():
			for j in range(i + 1, members.size()): Legacy.bond_points(self, members[i].id, members[j].id, 1)
		change_unrest(region_for_mission(str(option.mission)), int(Data.get_table("galaxy", "UNREST").win))
	else:
		gain("favor", int(auto.loseFavor))
		for r in members: r.stress = mini(100, int(r.stress) + int(auto.loseStress))
		members[0].wound = ceili(float(Data.get_table("core", "WOUND").serious) / heal_multiplier())
		change_unrest(region_for_mission(str(option.mission)), int(Data.get_table("galaxy", "UNREST").lose))
	if not win:
		var fate := randi_range(0, 99)
		if fate < int(auto.death):
			members[-1].status = "dead"
			state.legends.append({"n":members[-1].n,"cls":members[-1].cls,"how":"Fell on a strike team mission","where":option.get("n", option.mission)})
			Mentor17.on_death(self, members[-1], str(option.get("n", option.mission)))
		elif fate < int(auto.death) + int(auto.capture):
			members[-1].status = "captured"; members[-1].capT = int(Data.get_table("core", "CAPTIVE"))
	state.news.append("%s %s %s (auto, %d%%)." % [team.n, "won" if win else "lost", option.get("n", option.mission), odds])
	return true

func field_odds(op_id: String, team: Array) -> int:
	return int(Ops.risk(self, op_id, team).success)

func send_field_op(op_id: String, team: Array) -> bool:
	return Ops.send(self, op_id, team)

func _tick_field(days: int) -> void:
	for _day in maxi(0, days): Ops.tick(self)
