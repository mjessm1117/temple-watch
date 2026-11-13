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
	var threat_name := "Threat"
	for active in c.state.get("crises11", {}).get("active", []):
		var left := int(active.deadline) - int(c.state.elapsed_days)
		if left < threat_days: threat_days = left; threat_name = str(active.get("n", active.get("name", "Crisis")))
	if c.sith != null:
		for mission in c.state.sith.get("missions", {}).values():
			if mission.status == "open" and int(mission.deadline) >= 0:
				var left := int(mission.deadline) - int(c.state.sith.day)
				if left < threat_days: threat_days = left; threat_name = str(mission.get("n", mission.get("name", "Envoy signal")))
		var escalation := int(c.state.sith.next_escalation) - int(c.state.sith.day)
		if escalation < threat_days: threat_days = escalation; threat_name = "Sith escalation"
	var items: Array = []
	if int(power.used) > int(power.capacity):
		items.append({"room_id":"works", "label":"Restore Temple power", "reason":"Rooms have lost power · 0 days left", "days_left":0, "rank":0})
	if not c.state.pending_mission.is_empty() and c.state.pending_mission.get("squad", []).is_empty():
		items.append({"room_id":"war", "label":"Choose a squad", "reason":"Deployment has no squad · 0 days left", "days_left":0, "rank":0})
	if threat_days < 9999:
		var threat_reason := "%s overdue by %d days" % [threat_name, -threat_days] if threat_days < 0 else "%s expires in %d days" % [threat_name, threat_days]
		items.append({"room_id":"war", "label":"Review the threat", "reason":threat_reason, "days_left":threat_days, "rank":0 if threat_days < 0 else 1})
	for r in c.state.roster:
		if str(r.get("status", "")) == "active" and int(r.get("pick", 0)) > 0:
			items.append({"room_id":"barracks", "label":"Promote %s" % r.n, "reason":"Rank choice ready · 0 days left", "days_left":0, "rank":2})
			break
	var finished_study := str(c.state.research.get("last", ""))
	if finished_study != "":
		items.append({"room_id":"archives", "label":"Review finished study", "reason":"New research unlock ready · 0 days left", "days_left":0, "rank":2})
	if int(c.state.wings.get("archives", 0)) == 0:
		items.append({"room_id":"works", "label":"Build Archives", "reason":"Research has no room · 0 days left", "days_left":0, "rank":3})
	if Base.operational(c.state, "forge") and c.state.strategy.project.is_empty():
		items.append({"room_id":"forge", "label":"Start a Forge project", "reason":"Forge is idle · 0 days left", "days_left":0, "rank":3})
	if Base.operational(c.state, "archives") and str(c.state.research.cur) == "" and c.state.research.get("queue", []).is_empty():
		items.append({"room_id":"archives", "label":"Choose a study", "reason":"Archives are idle · 0 days left", "days_left":0, "rank":3})
	items.sort_custom(func(a, b): return int(a.rank) < int(b.rank) or (int(a.rank) == int(b.rank) and int(a.days_left) < int(b.days_left)))
	var priority: Dictionary = items[0] if not items.is_empty() else {"room_id":"war", "label":"Review the board", "reason":"Next mission available · 0 days left", "days_left":0, "rank":3}
	return {"credits": int(c.state.res.credits), "intel": int(c.state.res.intel), "kyber": int(c.state.res.kyber),
		"favor": int(c.state.res.favor), "recruits": int(c.state.res.recruits), "power_used": int(power.used),
		"power_cap": int(power.capacity), "day": int(c.state.day), "month": int(c.state.month),
		"next_threat_days": maxi(0, threat_days), "forecast_month_credits": forecast, "top_priority": priority, "priority_items": items}

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
	var upkeep: Array = wing.up
	var monthly_delta := -int(upkeep[mini(level, upkeep.size() - 1)]) + int(upkeep[mini(level - 1, upkeep.size() - 1)])
	return {"valid": valid, "reason": "Ready" if valid else "Check bay, requirement, credits, power or active build",
		"bay_id": bay_id, "wing_id": wing_id, "level": level, "cost": cost, "power_used": int(power.used),
		"power_after": after, "power_cap": int(power.capacity), "adjacency_bonus": bonus,
		"days": days, "month_credit_delta": monthly_delta, "unlocks":str(wing.eff[level]), "finish_month": finish_month, "finish_day": finish_day}

static func confirm_build25(c, bay_id: String, wing_id: String) -> bool:
	var preview := build_preview25(c, bay_id, wing_id)
	if not bool(preview.get("valid", false)): return false
	if int(c.state.wings[wing_id]) == 0 and Base.slot_of(c.state, wing_id) == "":
		if not Base.place(c, wing_id, bay_id): return false
	return c.build_wing(wing_id)
