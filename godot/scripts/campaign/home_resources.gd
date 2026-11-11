extends RefCounted
const UI = preload("res://scripts/campaign/ui.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const ITEMS = [
	["Credits", "credits", "Pay for construction, research and equipment. Earn stipends and mission rewards."],
	["Intel", "intel", "Fund research and reveal or counter Sith operations. Earn mission intel and staff the Comms Hub."],
	["Kyber", "kyber", "Craft sabers and spires. Earn it from missions, vaults and Kyber research."],
	["Senate Favor", "favor", "Raises the monthly stipend and political standing. Earn it through successful missions and council decisions."],
	["Recruits", "recruits", "Hire troops and Temple staff. Gain recruits each month and from a staffed Barracks."]
]

static func projected_balance(c) -> int:
	return int(c.state.res.credits) + int(c.monthly_credits25().net)

static func forecast_label(c) -> Label:
	var amount := int(c.strategic_snapshot25().forecast_month_credits)
	var label := UI.label("%s%d Cr at month end" % ["+" if amount >= 0 else "", amount], 14, UI.ACCENT if amount >= 0 else UI.DANGER)
	label.name = "MonthCreditForecast"
	var breakdown: Dictionary = c.monthly_credits25()
	label.tooltip_text = "Stipend +%d · wing upkeep -%d · troop pay -%d; Council and room effects included." % [breakdown.stipend, breakdown.upkeep, breakdown.troop_pay]
	return label

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
	row.add_child(forecast_label(c))
	if not row.visible and row.get_parent() != null:
		var title := row.get_parent().get_child(0) as HBoxContainer
		if title != null and title.get_child_count() > 0 and title.get_child(0) is Label:
			var brand := title.get_child(0) as Label
			var stack := VBoxContainer.new()
			stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			stack.add_theme_constant_override("separation", 0)
			title.remove_child(brand)
			title.add_child(stack); title.move_child(stack, 0)
			stack.add_child(brand)
			stack.add_child(forecast_label(c))

static func power_label(c) -> Label:
	var power := Base.power(c.state)
	var label := UI.label("POWER %d / %d" % [power.used, power.capacity], 13, UI.ACCENT)
	label.name = "PowerStatus"
	label.tooltip_text = "Each built wing and current construction consumes power; relays add 4 capacity."
	if int(power.used) > int(power.capacity) or int(power.used) < 0 or int(power.capacity) < 0:
		label.add_theme_color_override("font_color", UI.DANGER)
		label.tooltip_text += " Over capacity: built wings stop operating, including their production and bonuses. Build a power relay in Temple Works."
	return label
