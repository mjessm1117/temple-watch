extends RefCounted
## Read-only Temple prompts, computed from the same campaign save as the pages.
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Modules = preload("res://scripts/campaign/modules.gd")

static func collect(c) -> Dictionary:
	var result := {}
	var missions: int = c.state.options.size()
	if missions > 0: result["Galaxy"] = {"count":missions, "why":"%d missions available" % missions}
	if int(c.state.wings.get("archives", 0)) > 0 and str(c.state.research.cur) == "" and c.state.research.get("queue", []).is_empty():
		result["Research"] = {"count":1, "why":"Research idle: choose a project"}
	var ready := 0
	for wing in c.state.wings:
		if Modules.ready(c, str(wing)) and c.can_afford(Data.get_table("temple", "MOD_ACTS")[wing].cost): ready += 1
	var free := 0
	for slot in Data.get_table("temple", "SLOTS"):
		if int(slot.wing) == 1 and c.state.facility.clear.has(slot.id) and not c.state.slots.has(slot.id): free += 1
	if ready + free > 0:
		result["Build"] = {"count":ready + free, "why":"%d modules ready · %d free build slots" % [ready, free]}
	var wounded := 0; var exhausted := 0
	for soldier in c.state.roster:
		if str(soldier.status) != "active": continue
		if int(soldier.wound) > 0: wounded += 1
		elif int(soldier.fatigue) >= 34: exhausted += 1
	if wounded + exhausted > 0:
		result["Roster"] = {"count":wounded + exhausted, "why":"%d wounded · %d tired or exhausted soldiers" % [wounded, exhausted]}
	var votes: Dictionary = Data.get_table("temple", "VOTES")
	var keys := votes.keys()
	if not keys.is_empty():
		var id: String = keys[(int(c.state.month) - 1) % keys.size()]
		if not c.state.strategy.votes.has("%d:%s" % [c.state.month, id]):
			result["Command"] = {"count":1, "why":"Council vote pending: %s" % votes[id].n}
	return result
