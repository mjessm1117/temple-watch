extends RefCounted
## Campaign-owned glue for Sith intelligence and the deferred second front.
const Fronts = preload("res://scripts/mission_fronts.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func bind(c) -> void:
	c.sith = preload("res://scripts/campaign/sith_layer.gd").new(c.state)
	c.sith.set_crisis_schedule(false)

static func plan(c) -> Array:
	var era := int(c.state.era)
	return c.story.data[["data-story", "data-era2", "data-era3"][era-1]].get("PLAN" if era == 1 else "PLAN%d" % era, [])

static func default_squad(c, option: Dictionary, candidates: Array) -> Array:
	var rule := Fronts.squad_rule(c.state)
	var out := []; var jedi := 0
	var required := str(option.get("unit_id", option.get("quest", "")))
	if required != "": candidates = [required] + candidates.filter(func(id): return id != required)
	# Include reserves after excluding Front A, rather than slicing the same squad twice.
	for r in c.state.roster:
		if r.id not in candidates and preload("res://scripts/campaign/strat_roster.gd").ready(r): candidates.append(r.id)
	for id in candidates:
		if id in rule.used or option.get("hostages",[]).has(id): continue
		var r: Dictionary = c.soldier(str(id))
		if not preload("res://scripts/campaign/strat_roster.gd").ready(r): continue
		if Progression.is_jedi(r):
			if jedi >= int(rule.jmax): continue
			jedi += 1
		out.append(id)
		if out.size() >= mini(c.squad_capacity(),int(rule.max)): break
	return out

static func ignored(c, options: Array) -> void:
	for option in options:
		for key in option.get("ignore", {}): c.gain(str(key),int(option.ignore[key]))
		c.change_unrest(c.region_for_mission(str(option.mission)), int(c.Data.get_table("galaxy","UNREST").ignore))
		c.sith.retaliation_trigger("Unanswered crisis",1)

static func settle_sith(c, result: Dictionary) -> void:
	var pending: Dictionary = c.state.pending_mission
	var result_id := str(pending.get("result_id", ""))
	for event in result.get("mercy", []):
		c.sith.mercy(str(event.unit_id),result_id,str(event.action_id),int(event.points))
	if pending.has("sith_offer_id"):
		c.sith.resolve_mission(str(pending.sith_offer_id),bool(result.get("win",false)),{"deployed":pending.squad})
	c.sith.after_mission(result_id)
	if bool(result.get("win",false)): c.gain("intel",int(result.get("hack_intel",0)))

static func settle_front(c, receipt: Dictionary) -> bool:
	if not receipt.get("ok",false): return false
	if receipt.get("win",false):
		var mission: Dictionary = c.story.mission(str(receipt.mission))
		for key in mission.get("reward",{}):
			var value := int(mission.reward[key])
			if key == "credits": value = roundi(value * float(c.Data.get_table("core","MISSION_CR")) * float(c.Data.get_table("missions","DIFF")[c.state.diff].income))
			c.gain(str(key),value)
		for id in receipt.squad: Progression.promote(c.soldier(str(id)))
	c.gain("favor",int(receipt.get("favor",0)))
	if receipt.has("mission"): c.change_unrest(c.region_for_mission(str(receipt.mission)),int(c.Data.get_table("galaxy","UNREST").win if receipt.win else c.Data.get_table("galaxy","UNREST").lose))
	ignored(c,receipt.ignored)
	c.advance_mission(); c.state.step = int(c.state.step)+1; c.refresh_options()
	return true
