extends VBoxContainer
const S = preload("res://scripts/campaign/loadout_style.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
var host: Control
var soldier_id := ""
var offers: Array[Dictionary] = []

func setup(owner_screen: Control, id: String) -> void:
	host = owner_screen; soldier_id = id; add_theme_constant_override("separation", 7)
	var c = host.flow.session(); var r: Dictionary = c.soldier(id)
	var jedi := Progression.is_jedi(r)
	add_child(S.label("ARSENAL", 18, S.CYAN))
	add_child(S.label("%d Credits  /  %d Kyber" % [c.state.res.credits, c.state.res.kyber], 13, S.GOLD))
	var help := S.label("Purchases equip immediately. Research, wing levels and module slots apply.", 12, S.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(help)
	var color_row := HBoxContainer.new(); add_child(color_row)
	for color in (Data.get_table("gear", "CRYSTALS").values() if jedi else ["#e0bd78", "#d9a05b", "#9fc6d6", "#c9d27a", "#d6a3a3"]):
		var b := S.button("●", host.change_gear.bind("color", "", color)); b.modulate = Color(color)
		b.tooltip_text = "Crystal color" if jedi else "Armor accent"; color_row.add_child(b); host.wire_button(b)
	var pool: Array = Data.get_table("gear", "SABERS" if jedi else "WEAPONS")
	var tier := int(r.gear.saber if jedi else r.gear.w)
	section("SABER" if jedi else "WEAPON")
	add_child(S.label(str(pool[tier].n) + " · T%d" % (tier + 1), 14))
	if tier + 1 < pool.size():
		var item: Dictionary = pool[tier + 1]
		var kyber := maxi(1, int(item.get("kyber", 0)) - (1 if c.state.staff.has("forge") else 0) - (1 if c.researched("kyberLore") else 0)) if jedi else 0
		var cost := int(item.cost) if jedi else Gear.price(c, int(item.cost))
		offer("saber" if jedi else "weapon", "", "", "Craft " + str(item.n), lock_reason(c, item, cost, kyber), cost, kyber)
	section("ARMOR")
	for key in Data.get_table("gear", "ARMOR"):
		var item: Dictionary = Data.get_table("gear", "ARMOR")[key]
		if item.get("who", "any") not in ["any", "jedi" if jedi else "troop"]: continue
		var cost := Gear.price(c, int(item.get("cost", 0)))
		offer("armor", "", key, str(item.n), "Equipped" if r.gear.armor == key else lock_reason(c, item, cost), cost, 0, str(item.get("desc", "")))
	section("UTILITY")
	for key in Data.get_table("gear", "UTIL"):
		var item: Dictionary = Data.get_table("gear", "UTIL")[key]; var cost := Gear.price(c, int(item.get("cost", 0)))
		offer("utility", "", key, str(item.n), "Equipped" if r.gear.get("util", "none") == key else lock_reason(c, item, cost), cost, 0, str(item.get("desc", "")))
	if jedi:
		section("SABER FORM")
		for key in Data.get_table("gear", "FORMS"):
			var item: Dictionary = Data.get_table("gear", "FORMS")[key]
			offer("form", "", key, str(item.n), "Equipped" if r.gear.get("form", "shiiCho") == key else lock_reason(c, item, 0), 0, 0, str(item.get("desc", "")))
	for kind in (["s", "a"] if jedi else ["w", "a"]):
		var installed: Array = r.gear.get(Gear.MOD_KEY[kind], [])
		var slots := Gear.slots(r, kind)
		section("%s MODULES · %d/%d" % [{"w":"WEAPON", "s":"SABER", "a":"ARMOR"}[kind], installed.size(), slots])
		for key in Data.get_table("gear", Gear.POOL_KEY[kind]):
			var item: Dictionary = Data.get_table("gear", Gear.POOL_KEY[kind])[key]
			if item.get("who", "any") not in ["any", "jedi" if jedi else "troop"]: continue
			if key in installed:
				var lv := int(r.gear.mk.get(kind + "." + key, 1))
				offer("remove", kind, key, "%s · Mk %s · remove" % [item.n, ["I", "II", "III"][lv - 1]], "", 0, 0, "Remove module; no refund.")
				if lv < 3:
					var res: String = Data.get_table("gear", "MK_RES")[kind][lv - 1]
					var cost := Gear.price(c, int(Data.get_table("gear", "MK_COST")[lv]))
					offer("upgrade", kind, key, "Upgrade to Mk " + ["I", "II", "III"][lv], lock_reason(c, {"res":res}, cost), cost)
			else:
				var cost := Gear.price(c, int(item.cost))
				var reason := lock_reason(c, item, cost)
				if slots <= installed.size(): reason = "No free slots"
				offer("fit", kind, key, str(item.n), reason, cost, 0, str(item.get("tip", "")))

	var evolution: Dictionary = Data.get_table("gear", "EVO").get(str(r.cls), {})
	if not evolution.is_empty():
		section("EVOLUTION")
		var reason := "Evolved" if r.get("evo", false) else lock_reason(c, {"res":"mastery" if jedi else "eliteProgram"}, int(Data.get_table("gear", "EVO_COST").credits))
		if not r.get("evo", false) and int(r.rank) < int(Data.get_table("gear", "EVO_RANK")): reason = "Rank %d required" % int(Data.get_table("gear", "EVO_RANK"))
		if not r.get("evo", false) and int(c.state.res.intel) < int(Data.get_table("gear", "EVO_COST").intel): reason = "Requires %d Intel" % int(Data.get_table("gear", "EVO_COST").intel)
		offer("evolve", "", "", str(evolution.n), reason, int(Data.get_table("gear", "EVO_COST").credits), 0, str(evolution.get("desc", "")))

func section(title: String) -> void:
	add_child(HSeparator.new()); add_child(S.label(title, 12, S.GOLD))

func lock_reason(c, item: Dictionary, cost: int, kyber: int = 0) -> String:
	if not c.researched(str(item.get("res", ""))):
		var research: Dictionary = Data.get_table("research", "RESEARCH").get(str(item.res), {})
		return "Research: " + str(research.get("n", item.res))
	var need: Array = item.get("need", [])
	if not need.is_empty() and int(c.state.wings.get(need[0], 0)) < int(need[1]): return "%s level %d required" % [str(need[0]).capitalize(), int(need[1])]
	if int(c.state.res.credits) < cost: return "Insufficient credits"
	if int(c.state.res.kyber) < kyber: return "Insufficient Kyber"
	return ""

func offer(action: String, kind: String, key: String, title: String, reason: String, cost: int, kyber: int = 0, tip: String = "") -> void:
	var label := title + (" · %d Cr" % cost if cost > 0 else "") + (" + %d Ky" % kyber if kyber > 0 else "")
	var b := S.button(label, host.change_gear.bind(action, kind, key), reason == "")
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.tooltip_text = tip; add_child(b); host.wire_button(b)
	if reason != "":
		var why := S.label(reason, 11, S.MUTED); why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(why)
	offers.append({"action":action, "kind":kind, "key":key, "enabled":reason == "", "button":b})
