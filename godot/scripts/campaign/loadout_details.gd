extends RefCounted
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const S = preload("res://scripts/campaign/loadout_style.gd")
const Phone = preload("res://scripts/phone_layout.gd")

static func fit(r: Dictionary) -> bool:
	return preload("res://scripts/campaign/strat_roster.gd").ready(r)

static func status(c, r: Dictionary) -> String:
	if int(r.get("wound", 0)) > 0:
		var days := ceili(float(r.wound) / (2 if r.get("assign", "") == "rest" else 1))
		return "WOUNDED · %d days" % days
	if r.get("status", "active") == "captured": return "CAPTURED · %d days" % int(r.get("capT", 0))
	if r.get("status", "active") != "active": return str(r.status).to_upper()
	if str(r.get("assign", "")) != "":
		for op in c.state.get("field", {}).get("list", []):
			if r.id in op.get("team", []) and op.get("st") == "team": return "ASSIGNED · %d days" % int(op.left)
		return "ASSIGNED · %s · until released" % str(r.assign).trim_prefix("staff:").capitalize()
	return "%s · fatigue %d/100" % [preload("res://scripts/campaign/strat_roster.gd").fatigue_status(r), int(r.get("fatigue", 0))]

static func nickname(r: Dictionary) -> String:
	var nick := str(r.get("nick", r.get("nickname", "")))
	return '“%s”' % nick if nick != "" else "NO CALLSIGN"

static func kit(r: Dictionary) -> Array:
	# Display the kit the battle bridge actually deploys, including fallback classes.
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var key := str(r.cls).to_lower()
	if not catalog.has(key) or catalog[key].get("side") != "player": key = "guardian" if Progression.is_jedi(r) else "soldier"
	return catalog[key].get("kit", []).duplicate()

static func gear_text(r: Dictionary) -> String:
	var jedi := Progression.is_jedi(r)
	var items: Array = Data.get_table("gear", "SABERS" if jedi else "WEAPONS")
	var tier := int(r.gear.saber if jedi else r.gear.w)
	var armor: Dictionary = Data.get_table("gear", "ARMOR").get(str(r.gear.armor), {})
	var base_mark: String = ["I", "II", "III"][clampi(int(r.gear.mk.get("s" if jedi else "w", 1)) - 1, 0, 2)]
	var armor_mark: String = ["I", "II", "III"][clampi(int(r.gear.mk.get("armor:" + str(r.gear.armor), 1)) - 1, 0, 2)]
	return "%s Mk %s · T%d\n%s Mk %s" % [items[tier].n, base_mark, tier + 1, armor.get("n", r.gear.armor), armor_mark]

static func modules_text(r: Dictionary) -> String:
	var modules: Array[String] = []
	for kind in Gear.MOD_KEY:
		for key in r.gear.get(Gear.MOD_KEY[kind], []):
			var item: Dictionary = Data.get_table("gear", Gear.POOL_KEY[kind]).get(key, {})
			modules.append("%s Mk %s" % [item.get("n", key), ["I", "II", "III"][clampi(int(r.gear.mk.get(kind + "." + key, 1)) - 1, 0, 2)]])
	return " · ".join(modules) if not modules.is_empty() else "MODULES  —"

static func card(c, r: Dictionary, action: Callable, portrait: Texture2D = null) -> PanelContainer:
	if Phone.narrow(Phone.window_size()):
		var compact := S.panel(); compact.name = "Card_" + str(r.id)
		compact.add_theme_stylebox_override("panel", S.box(S.PANEL, S.EDGE, 4))
		compact.custom_minimum_size = Vector2(180, 82)
		var content := S.column(2); compact.add_child(content)
		var select := S.button(str(r.n), action); select.alignment = HORIZONTAL_ALIGNMENT_LEFT
		select.custom_minimum_size.y = 44; select.icon = portrait; select.expand_icon = true; content.add_child(select)
		content.add_child(S.label("%s · R%d · HP %d" % [r.cls, int(r.rank), int(Gear.battle_stats(c, str(r.id)).get("hp", 0))], 10, S.GOLD))
		content.add_child(S.label(status(c, r), 10, S.GREEN if fit(r) else S.RED))
		return compact
	var p := S.panel(); p.name = "Card_" + str(r.id); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := S.column(4); p.add_child(col)
	var heading := S.button(str(r.n), action); heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.icon = portrait if portrait != null else S.icon(str(r.cls).to_lower()); heading.expand_icon = true
	heading.add_theme_font_size_override("font_size", 17)
	heading.custom_minimum_size.y = 60; col.add_child(heading)
	col.add_child(S.label("%s  ·  %s  ·  R%d" % [nickname(r), r.cls, int(r.rank)], 12, S.GOLD))
	col.add_child(S.label(status(c, r), 11, S.GREEN if fit(r) else S.RED))
	var temple: PackedStringArray = preload("res://scripts/campaign/temple_rooms.gd").active_descriptions(c.state)
	var temple_text := "Temple bonuses active: " + (", ".join(temple) if not temple.is_empty() else "none")
	var temple_label := S.label(temple_text, 11, S.CYAN)
	temple_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; temple_label.tooltip_text = temple_text; col.add_child(temple_label)
	# --- wave10 story ---
	var bond_badge := S.label("BOND  " + preload("res://scripts/campaign/bond_overlay.gd").summary(c.state,str(r.id)),11,S.CYAN)
	bond_badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bond_badge.tooltip_text = bond_badge.text; col.add_child(bond_badge)
	var stats := Gear.battle_stats(c, str(r.id))
	for key in ["hp", "aim", "will"]:
		var row := HBoxContainer.new(); col.add_child(row)
		var l := S.label(key.to_upper(), 11, S.MUTED); l.custom_minimum_size.x = 38; row.add_child(l)
		var bar := ProgressBar.new(); bar.show_percentage = false; bar.custom_minimum_size = Vector2(50, 7)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = 20 if key == "hp" else 120; bar.value = int(stats.get(key, 0))
		bar.add_theme_stylebox_override("background", S.box(Color("213238"), Color.TRANSPARENT, 0))
		bar.add_theme_stylebox_override("fill", S.box(S.GREEN if key == "hp" else S.CYAN if key == "aim" else S.GOLD, Color.TRANSPARENT, 0)); row.add_child(bar)
		var value := S.label(str(int(stats.get(key, 0))), 12); value.custom_minimum_size.x = 26; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; row.add_child(value)
	var gear_label := S.label(gear_text(r).replace("\n", "  /  "), 12)
	gear_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; gear_label.tooltip_text = gear_text(r); col.add_child(gear_label)
	var detail := modules_text(r)
	var utility: Dictionary = Data.get_table("gear", "UTIL").get(str(r.gear.get("util", "none")), {})
	if r.gear.get("util", "none") != "none": detail += " · " + str(utility.get("n", r.gear.util))
	var mods := S.label(detail, 11, S.MUTED); mods.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; mods.tooltip_text = detail; col.add_child(mods)
	var skills := HBoxContainer.new(); skills.add_theme_constant_override("separation", 3); col.add_child(skills)
	var abilities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	for key in kit(r):
		var chip := TextureRect.new(); chip.texture = S.icon(ability_icon(str(key)))
		chip.custom_minimum_size = Vector2(21, 21); chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip.tooltip_text = str(abilities.get(key, {}).get("name", str(key).capitalize())); chip.mouse_filter = Control.MOUSE_FILTER_STOP; skills.add_child(chip)
	if not fit(r): p.modulate = Color("899194")
	return p

static func ability_icon(key: String) -> String:
	return {"strike":"strike", "reviveStim":"stabilize", "forceHeal":"heal", "forceRevive":"stabilize", "rapidFire":"shoot", "deadeye":"mark", "saberThrow":"strike", "runGun":"shoot", "battleMed":"heal", "mindTrick":"panic", "hunker":"guard", "rally":"guard", "barrier":"barrier", "stun":"stunned", "sweep":"strike", "subdue":"disarm", "suppress":"shoot", "scan":"mark", "rocket":"grenade"}.get(key, key)
