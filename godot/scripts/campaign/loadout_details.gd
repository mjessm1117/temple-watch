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

static func visible_name(full_name: String, available: float) -> String:
	var font := ThemeDB.fallback_font
	var first := full_name.get_slice(" ", 0)
	for candidate in [full_name, first]:
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x <= available:
			return candidate
	var shortened := first
	while shortened.length() > 1 and font.get_string_size(shortened + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > available:
		shortened = shortened.left(shortened.length() - 1)
	return shortened + "…"

static func card(c, r: Dictionary, action: Callable, portrait: Texture2D = null) -> PanelContainer:
	var compact := S.panel(); compact.name = "Card_" + str(r.id)
	compact.add_theme_stylebox_override("panel", S.box(S.PANEL, S.EDGE, 4))
	var phone := Phone.narrow(Phone.window_size())
	compact.custom_minimum_size = Vector2(90 if phone else 166, 62); compact.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := S.column(2); compact.add_child(content)
	var select := S.button("", action); select.alignment = HORIZONTAL_ALIGNMENT_LEFT
	select.custom_minimum_size.y = 44; content.add_child(select)
	var name := S.label("", 14 if phone else 11); name.name = "SoldierName"
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name.offset_left = 43 if portrait != null else 4
	name.offset_right = -2; name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	select.add_child(name)
	var update_name := func() -> void:
		name.text = visible_name(str(r.n), name.size.x) if phone else str(r.n)
	select.resized.connect(update_name)
	name.text = str(r.n)
	if portrait != null:
		var face := Sprite2D.new(); face.texture = portrait; face.position = Vector2(21, 21)
		face.scale = Vector2(0.26, 0.26); select.add_child(face)
	content.add_child(S.label("T%d · HP %d" % [Progression.skill_rank(r), int(Gear.battle_stats(c, str(r.id)).get("hp", 0))] if phone else "%s · R%d / T%d · HP %d" % [r.cls, int(r.rank), Progression.skill_rank(r), int(Gear.battle_stats(c, str(r.id)).get("hp", 0))], 9 if phone else 10, S.GOLD))
	if not fit(r): compact.modulate = Color("899194")
	return compact

static func ability_icon(key: String) -> String:
	return {"strike":"strike", "reviveStim":"stabilize", "forceHeal":"heal", "forceRevive":"stabilize", "rapidFire":"shoot", "deadeye":"mark", "saberThrow":"strike", "runGun":"shoot", "battleMed":"heal", "mindTrick":"panic", "hunker":"guard", "rally":"guard", "barrier":"barrier", "stun":"stunned", "sweep":"strike", "subdue":"disarm", "suppress":"shoot", "scan":"mark", "rocket":"grenade"}.get(key, key)
