extends RefCounted
const UI = preload("res://scripts/campaign/ui.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const ITEMS = [
	["Credits", "credits", "Pay for construction, research and equipment. Earn stipends and mission rewards."],
	["Intel", "intel", "Fund research and reveal or counter Sith operations. Earn mission intel and staff the Comms Hub."],
	["Kyber", "kyber", "Craft sabers and spires. Earn it from missions, vaults and Kyber research."],
	["Senate Favor", "favor", "Raises the monthly stipend and political standing. Earn it through successful missions and council decisions."],
	["Recruits", "recruits", "Hire troops and Temple staff. Gain recruits each month and from a staffed Barracks."]
]

static func projected_balance(c) -> int:
	var core := Data.all("core")
	var income := float(Data.get_table("missions", "DIFF").get(str(c.state.diff), {}).get("income", 1.0))
	var stipend := roundi((float(core.STIPEND[0]) + float(core.STIPEND[1]) * int(c.state.res.favor)) * income)
	var upkeep := 0
	for wing in c.state.wings:
		var costs: Array = core.WINGS[wing].up
		upkeep += int(costs[mini(int(c.state.wings[wing]), costs.size() - 1)])
	var troops := 0
	for soldier in c.state.roster:
		if str(soldier.status) == "active" and not Progression.is_jedi(soldier): troops += 1
	return int(c.state.res.credits) + stipend - upkeep - troops * int(core.TROOP_PAY)

static func add_row(row: HBoxContainer, c) -> void:
	for item in ITEMS:
		var key: String = item[1]
		var label := UI.label("%s  %d" % [item[0], int(c.state.res[key])], 13, UI.ACCENT)
		label.name = "Resource_" + key
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.tooltip_text = item[2]
		if int(c.state.res[key]) < 0: label.add_theme_color_override("font_color", UI.DANGER)
		if key == "credits" and projected_balance(c) < 0:
			label.add_theme_color_override("font_color", UI.DANGER)
			label.tooltip_text += " Next monthly stipend will not cover upkeep and troop pay; unpaid costs reduce Senate Favor."
		row.add_child(label)

static func power_label(c) -> Label:
	var power := Base.power(c.state)
	var label := UI.label("POWER %d / %d" % [power.used, power.capacity], 13, UI.ACCENT)
	label.name = "PowerStatus"
	label.tooltip_text = "Each built wing and current construction consumes power; relays add 4 capacity."
	if int(power.used) > int(power.capacity) or int(power.used) < 0 or int(power.capacity) < 0:
		label.add_theme_color_override("font_color", UI.DANGER)
		label.tooltip_text += " Over capacity: built wings stop operating, including their production and bonuses. Build a power relay in Temple Works."
	return label
