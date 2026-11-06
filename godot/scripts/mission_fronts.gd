extends RefCounted
## Stateful two-front contract. Campaign owner calls before ignoring crises or advancing time.
const Progression = preload("res://scripts/campaign/progression.gd")

static func fit(r: Dictionary) -> bool:
	return r.get("status","active") == "active" and int(r.get("wound",0)) == 0 and str(r.get("assign","")) == "" and int(r.get("fatigue",0)) < 67

static func free_roster(state: Dictionary) -> Array:
	var used: Array = state.get("twin",{}).get("used",[])
	return state.roster.filter(func(r): return fit(r) and r.id not in used)

static func late_steps(plan: Array) -> Array:
	var out: Array = []
	for i in plan.size():
		if plan[i].get("crises",[]).size() >= 2: out.append(i)
	return out.slice(maxi(0,out.size()-2))

static func available(state: Dictionary, plan: Array) -> bool:
	if not state.get("twin",{}).is_empty(): return false
	if int(state.get("era",1)) < 2 and int(state.get("wings",{}).get("barracks",0)) < 2: return false
	return int(state.step) in late_steps(plan) and free_roster(state).size() >= 8 and state.options.filter(func(o): return bool(o.get("adv",false)) and o.has("crisis")).size() >= 2

static func squad_rule(state: Dictionary) -> Dictionary:
	var second: bool = state.get("twin",{}).get("stage","") == "b"
	return {"max":4 if second else 7,"jmin":0,"jmax":2 if second else 7,"used":state.get("twin",{}).get("used",[])}

static func launch(state: Dictionary, option: Dictionary, ids: Array, plan: Array) -> Dictionary:
	if not state.options.has(option): return {"ok":false,"reason":"Unknown crisis"}
	var rule := squad_rule(state); var found := {}; var jedi := 0
	if ids.size() < 2 or ids.size() > int(rule.max): return {"ok":false,"reason":"Squad size"}
	for id in ids:
		var rows: Array = state.roster.filter(func(r): return r.id == id and fit(r))
		if rows.is_empty() or found.has(id) or id in rule.used: return {"ok":false,"reason":"Soldier unavailable or already deployed"}
		found[id] = true
		if Progression.is_jedi(rows[0]): jedi += 1
	if jedi > int(rule.jmax): return {"ok":false,"reason":"Front B allows at most two Jedi"}
	if state.get("twin",{}).get("stage","") == "b":
		if not state.options.has(option) or not bool(option.get("adv",false)): return {"ok":false,"reason":"Not a remaining crisis"}
		state.twin.stage = "b2"; state.twin.b = option.duplicate(true)
		return {"ok":true,"defer_ignored":true,"fewer":1}
	if available(state,plan) and option.has("crisis") and bool(option.get("adv",false)):
		var rest: Array = state.options.filter(func(o): return o != option and bool(o.get("adv",false)))
		state.twin = {"stage":"a","used":ids.duplicate(),"a":option.get("n",option.mission),"remaining":rest.duplicate(true)}
		return {"ok":true,"defer_ignored":true,"fewer":0}
	return {"ok":true,"defer_ignored":false,"fewer":0}

## Called after per-soldier results/rewards, before advance_mission/step/refresh_options.
static func finish(state: Dictionary) -> Dictionary:
	var twin: Dictionary = state.get("twin",{})
	if twin.is_empty(): return {"advance":true,"ignored":[]}
	if twin.stage == "b": return {"advance":false,"ignored":[],"front":"b"}
	if twin.stage == "a" and free_roster(state).size() >= 2 and not twin.remaining.is_empty():
		twin.stage = "b"; state.options = twin.remaining.duplicate(true)
		for option in state.options: option.fewer = 1
		state.pending_mission = {}; state.chosen = -1
		return {"advance":false,"ignored":[],"front":"b"}
	var ignored: Array = twin.remaining.filter(func(o): return o.get("mission","") != twin.get("b",{}).get("mission",""))
	state.erase("twin")
	return {"advance":true,"ignored":ignored}

static func auto_odds(state: Dictionary, ids: Array) -> int:
	var ranks := 0
	for r in free_roster(state):
		if r.id in ids: ranks += int(r.get("rank",1))
	return mini(70,25+6*ranks)

## Produces a one-use settlement receipt; owner applies rewards/unrest and advances once.
static func auto_resolve(state: Dictionary, index: int, ids: Array, rng: RandomNumberGenerator) -> Dictionary:
	if state.get("twin",{}).get("stage","") != "b" or index < 0 or index >= state.options.size(): return {"ok":false}
	var option: Dictionary = state.options[index]
	if option.has("hostages"): return {"ok":false,"reason":"Captive rescue must be played"}
	var launch_result := launch(state,option,ids,[])
	if not launch_result.ok: return launch_result
	var odds := auto_odds(state,ids); var won := rng.randi_range(1,100) <= odds
	var units: Array = state.roster.filter(func(r): return r.id in ids)
	if won:
		for r in units: r.xp = int(r.get("xp",0))+10; r.missions = int(r.get("missions",0))+1
	else:
		for r in units: r.stress = int(r.get("stress",0))+15
		var injured: Dictionary = units[rng.randi_range(0,units.size()-1)]
		injured.wound = maxi(int(injured.get("wound",0)),10)
	var receipt := finish(state)
	receipt.merge({"ok":true,"win":won,"odds":odds,"mission":option.mission,"favor":0 if won else -3,"reward_mission":option.mission if won else "","squad":ids.duplicate()})
	return receipt

static func stand_down(state: Dictionary) -> Dictionary:
	if state.get("twin",{}).get("stage","") != "b": return {"ok":false}
	var ignored: Array = state.twin.remaining.duplicate(true)
	state.erase("twin")
	return {"ok":true,"advance":true,"ignored":ignored}
