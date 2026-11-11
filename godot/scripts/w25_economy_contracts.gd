extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func monthly_credits25(c) -> Dictionary:
	var core: Dictionary = Data.all("core")
	var income := float(Data.get_table("missions", "DIFF").get(str(c.state.diff), {}).get("income", 1.0))
	var stipend := roundi((float(core.STIPEND[0]) + float(core.STIPEND[1]) * int(c.state.res.favor)) * income)
	var upkeep := 0
	for key in c.state.wings:
		var costs: Array = core.WINGS[key].up
		upkeep += int(costs[mini(int(c.state.wings[key]), costs.size() - 1)])
	var troops := 0
	for r in c.state.roster:
		if str(r.status) == "active" and not Progression.is_jedi(r): troops += 1
	var pay: int = troops * int(core.TROOP_PAY)
	return {"stipend": stipend, "upkeep": upkeep, "troop_pay": pay, "net": stipend - upkeep - pay}

static func strategic_snapshot25(c) -> Dictionary:
	c.ensure_strategy()
	var power: Dictionary = Base.power(c.state)
	var effects: Dictionary = Base.effects(c.state)
	var balance := maxi(0, int(c.state.res.credits) + int(monthly_credits25(c).net)) + int(effects.get("credits", 0))
	var intel := int(c.state.res.intel) + int(effects.get("intel", 0))
	if Base.operational(c.state, "comms"): intel += Base.staff_count(c.state, "comms")
	for id in c.state.strategy.edict:
		var cost := int(Data.get_table("temple", "EDICTS")[id].cost)
		if balance >= cost and (id != "scholarship" or intel >= 2):
			balance -= cost
			if id == "scholarship": intel -= 2
	var forecast := balance - int(c.state.res.credits)
	var threat_days := 9999
	for active in c.state.get("crises11", {}).get("active", []):
		threat_days = mini(threat_days, maxi(0, int(active.deadline) - int(c.state.elapsed_days)))
	if c.sith != null:
		for mission in c.state.sith.get("missions", {}).values():
			if mission.status == "open" and int(mission.deadline) >= 0:
				threat_days = mini(threat_days, maxi(0, int(mission.deadline) - int(c.state.sith.day)))
		threat_days = mini(threat_days, maxi(0, int(c.state.sith.next_escalation) - int(c.state.sith.day)))
	var priority := {"room_id": "war", "label": "Review the threat", "reason": "Threat pressure is approaching"}
	if int(c.state.wings.get("archives", 0)) == 0:
		priority = {"room_id": "works", "label": "Build Archives", "reason": "Research needs a working room"}
	if int(power.used) > int(power.capacity):
		priority = {"room_id": "works", "label": "Restore Temple power", "reason": "Rooms are over capacity"}
	if Base.operational(c.state, "forge") and c.state.strategy.project.is_empty():
		priority = {"room_id": "forge", "label": "Start a Forge project", "reason": "The Forge is idle"}
	if Base.operational(c.state, "archives") and str(c.state.research.cur) == "":
		priority = {"room_id": "archives", "label": "Choose a study", "reason": "The Archives are idle"}
	return {"credits": int(c.state.res.credits), "intel": int(c.state.res.intel), "kyber": int(c.state.res.kyber),
		"favor": int(c.state.res.favor), "recruits": int(c.state.res.recruits), "power_used": int(power.used),
		"power_cap": int(power.capacity), "day": int(c.state.day), "month": int(c.state.month),
		"next_threat_days": threat_days, "forecast_month_credits": forecast, "top_priority": priority}

static func build_preview25(c, bay_id: String, wing_id: String) -> Dictionary:
	c.ensure_strategy()
	var slot: Dictionary = Base.slot_data(bay_id)
	var wing: Dictionary = Data.get_table("core", "WINGS").get(wing_id, {})
	if slot.is_empty() or wing.is_empty(): return {"valid": false, "reason": "Unknown bay or room"}
	var level := int(c.state.wings.get(wing_id, 0)) + 1
	if level >= wing.cost.size(): return {"valid": false, "reason": "Room is fully built"}
	var placed: String = Base.slot_of(c.state, wing_id)
	var first_build := level == 1
	var available := bool(c.state.facility.clear.has(bay_id)) and int(slot.wing) == 1 and (str(c.state.slots.get(bay_id, "")) in ["", wing_id])
	var valid := available and (placed == "" or placed == bay_id) and str(c.state.build) == ""
	var req := str(wing.get("req", [])[level]) if level < wing.get("req", []).size() else ""
	valid = valid and c.researched(req)
	var cost := int(wing.cost[level])
	var power: Dictionary = Base.power(c.state)
	var after: int = int(power.used) + (int(Base.POWER[wing_id]) if first_build else 0)
	valid = valid and after <= int(power.capacity) and int(c.state.res.credits) >= cost
	var bonus := []
	for pair in Data.get_table("temple", "ADJ"):
		var other := str(pair.b) if str(pair.a) == wing_id else str(pair.a) if str(pair.b) == wing_id else ""
		if other != "" and Base.adjacent(bay_id, Base.slot_of(c.state, other)):
			bonus.append(str(pair.n))
	var artisans := 0
	for worker in c.state.facility.workers:
		if worker.role == "artisan" and worker.wing == "": artisans += 1
	var days := ceili(7.0 / (1.0 + 0.5 * artisans))
	var finish_day := int(c.state.day) + days
	var finish_month := int(c.state.month) + (finish_day - 1) / 30
	finish_day = (finish_day - 1) % 30 + 1
	return {"valid": valid, "reason": "Ready" if valid else "Check bay, requirement, credits, power or active build",
		"bay_id": bay_id, "wing_id": wing_id, "level": level, "cost": cost, "power_used": int(power.used),
		"power_after": after, "power_cap": int(power.capacity), "adjacency_bonus": bonus,
		"days": days, "finish_month": finish_month, "finish_day": finish_day}

static func confirm_build25(c, bay_id: String, wing_id: String) -> bool:
	var preview := build_preview25(c, bay_id, wing_id)
	if not bool(preview.get("valid", false)): return false
	if int(c.state.wings[wing_id]) == 0 and Base.slot_of(c.state, wing_id) == "":
		if not Base.place(c, wing_id, bay_id): return false
	return c.build_wing(wing_id)
