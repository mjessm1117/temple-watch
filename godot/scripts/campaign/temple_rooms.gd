extends RefCounted
## Web room identities and WING_HOME arrangement; presentation only, never mutates a save.
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const ROOMS = [
	["council", "Council Chamber", "Command", "", 0.0, 11.0, "council"],
	["war", "War Room", "Galaxy", "", -2.6, 7.5, "holo"],
	["archives", "Archives", "Research", "archives", 2.6, 7.5, "holo"],
	["armory", "Armory", "Arsenal", "armory", -5.2, 4.6, "racks"],
	["comms", "Comms Hub", "Galaxy", "comms", 0.0, 4.6, "holo"],
	["gardens", "Meditation Gardens", "Roster", "gardens", 5.2, 4.6, "garden"],
	["training", "Training Salle", "Roster", "training", -7.8, 1.7, "training"],
	["barracks", "Barracks", "Roster", "barracks", -2.6, 1.7, "beds"],
	["medical", "Medical Halls", "Roster", "medical", 2.6, 1.7, "medical"],
	["forge", "Kyber Forge", "Arsenal", "forge", 7.8, 1.7, "forge"],
	["hangar", "Hangar", "Teams", "", -7.8, -1.2, "hangar"],
	["works", "Temple Works", "Build", "", -2.6, -1.2, "racks"],
	["under", "Undercity", "Arsenal", "", 7.8, -1.2, "racks"],
	["a0", "West Annex", "Build", "", -13.0, 1.7, "annex"],
	["a1", "East Annex", "Build", "", 13.0, 1.7, "annex"],
	["u0", "Kyber Vault", "Build", "", -5.2, -3.6, "vault"],
	["u1", "Holocron Vault", "Codex", "", 0.0, -3.6, "vault"],
	["u2", "Memorial Vault", "Legacy", "", 5.2, -3.6, "vault"],
	["sp0", "First Knowledge", "Research", "", -10.4, 10.0, "spire"],
	["sp1", "Reassurance", "Legacy", "", -5.2, 10.0, "spire"],
	["sp2", "Reconciliation", "Command", "", 5.2, 10.0, "spire"],
	["sp3", "Guidance", "Teams", "", 10.4, 10.0, "spire"],
]

static func describe(row: Array, state: Dictionary) -> Dictionary:
	var id: String = row[0]
	var wing: String = row[3]
	var level := int(state.wings.get(wing, 0)) if wing != "" else 1
	var status := "Operational"
	var module := ""
	var built := level > 0
	var target: String = row[2]
	var color := Color("72cedb")
	if wing != "":
		var data: Dictionary = Data.get_table("core", "WINGS")[wing]
		var action: Dictionary = Data.get_table("temple", "MOD_ACTS")[wing]
		var cooldown := int(state.get("modules", {}).get("cd", {}).get(wing, 0))
		module = str(action.n)
		status = "L%d · %s" % [level, "%d missions" % cooldown if cooldown > 0 else "NO POWER" if built and not Base.operational(state, wing) else "READY"]
		if not built: status = "Build · %d Cr" % int(data.cost[1]); target = "Build"
		if str(state.build) == wing: status = "Upgrading" if built else "Under construction"
		if wing in ["medical", "gardens"]: color = Color("86d5b3")
		if wing in ["forge", "armory"]: color = Color("e5bc7a")
	else:
		match id:
			"war": status = "%d missions waiting" % state.options.size()
			"council": status = "Council in session"
			"hangar": status = "%d strike teams" % state.teams.size()
			"works": status = "Build & upgrade wings"
			"under": status = "Equipment & contraband"
			"a0", "a1": built = false; status = "Expansion bay"
	if row[6] == "spire":
		built = bool(state.get("mods", {}).get("spire", {}).get(id, false))
		status = "Tower online" if built else "350 Cr · 2 Kyber"
		if not built: target = "Build"
	if row[6] == "vault":
		built = bool(state.get("mods", {}).get("dug", {}).get(id, false))
		status = "Vault open" if built else "Sealed · %d Cr" % {"u0":60, "u1":100, "u2":140}[id]
	var at := Vector3(float(row[4]), float(row[5]), 0.0)
	var staff := 0
	var detail := status
	if wing != "":
		var slot := Base.slot_data(Base.slot_of(state, wing))
		if not slot.is_empty(): at = Vector3(-7.8 + float(slot.x) * 5.2, 1.7 + (2 - int(slot.row)) * 2.9, 0)
		staff = Base.staff_count(state, wing)
		detail = status + " · " + Base.summary(state, wing)
	if id == "works": detail = "Power %d / %d · staff & excavation" % [Base.power(state).used, Base.power(state).capacity]
	return {"id":id, "name":row[1], "tab":target, "wing":wing, "built":built,
		"level":level, "status":status, "module":module, "color":color, "kind":row[6],
		"position":at, "staff":staff, "detail":detail}
