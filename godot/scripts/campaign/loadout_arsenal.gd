extends VBoxContainer
const S = preload("res://scripts/campaign/loadout_style.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Preview = preload("res://scripts/campaign/armory12_preview.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var host: Control
var soldier_id := ""
var offers: Array[Dictionary] = []
var offer_cards: Array[Dictionary] = []
var active_slot := "weapon"
var picker: VBoxContainer
var slot_row: HBoxContainer
var skill_view := false

func setup(owner_screen: Control, id: String) -> void:
	host = owner_screen; soldier_id = id; active_slot = host.armory_slot
	add_theme_constant_override("separation", 7)
	var c = host.flow.session(); var r: Dictionary = c.soldier(id)
	var jedi := Progression.is_jedi(r)
	var slot_scroll := ScrollContainer.new(); slot_scroll.custom_minimum_size.y = 50 if Phone.narrow(Phone.window_size()) else 69
	slot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(slot_scroll)
	slot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	slot_row = HBoxContainer.new(); slot_row.add_theme_constant_override("separation", 6); slot_scroll.add_child(slot_row)
	_build_slots(r, jedi)
	picker = S.column(6); add_child(picker)
	var color_row := HBoxContainer.new(); picker.add_child(color_row)
	for color in (Data.get_table("gear", "CRYSTALS").values() if jedi else ["#e0bd78", "#d9a05b", "#9fc6d6", "#c9d27a", "#d6a3a3"]):
		var b := S.button("●", host.change_gear.bind("color", "", color)); b.modulate = Color(color); b.custom_minimum_size = Vector2(48, 44)
		b.tooltip_text = "Crystal color" if jedi else "Armor accent"; color_row.add_child(b); host.wire_button(b)
	offer_cards.append({"slot":"color", "node":color_row})
	var pool: Array = Data.get_table("gear", "SABERS" if jedi else "WEAPONS")
	var tier := int(r.gear.saber if jedi else r.gear.w)
	section("SABER" if jedi else "WEAPON")
	var base_kind := "s" if jedi else "w"
	var base_lv := int(r.gear.mk.get(base_kind, 1))
	var current := S.label("EQUIPPED  %s · Mk %s · T%d" % [pool[tier].n, ["I", "II", "III"][base_lv - 1], tier + 1], 13, S.CYAN)
	picker.add_child(current); offer_cards.append({"slot":"weapon", "node":current})
	if base_lv < 3:
		var base_res: String = Data.get_table("gear", "MK_RES")[base_kind][base_lv - 1]
		var base_cost := Gear.price(c, int(Data.get_table("gear", "MK_COST")[base_lv]))
		var base_reason := "Powered Forge required" if not Base.operational(c.state, "forge") else lock_reason(c, {"res":base_res}, base_cost)
		offer("base_mark", base_kind, "", "Forge to Mk " + ["I", "II", "III"][base_lv], base_reason, base_cost, 0, Gear.preview(c, id, "base_mark", base_kind))
	if tier + 1 < pool.size():
		var item: Dictionary = pool[tier + 1]
		var kyber := maxi(1, int(item.get("kyber", 0)) - (1 if c.state.staff.has("forge") else 0) - (1 if c.researched("kyberLore") else 0)) if jedi else 0
		var cost := int(item.cost) if jedi else Gear.price(c, int(item.cost))
		var action := "saber" if jedi else "weapon"
		offer(action, "", "", "Craft " + str(item.n), lock_reason(c, item, cost, kyber), cost, kyber, Gear.preview(c, id, action))
	section("ARMOR")
	for key in Data.get_table("gear", "ARMOR"):
		var item: Dictionary = Data.get_table("gear", "ARMOR")[key]
		if item.get("who", "any") not in ["any", "jedi" if jedi else "troop"]: continue
		var cost := Gear.price(c, int(item.get("cost", 0)))
		offer("armor", "", key, str(item.n), "Equipped" if r.gear.armor == key else lock_reason(c, item, cost), cost, 0, Gear.preview(c, id, "armor", "", str(key)))
	if Data.get_table("gear", "ARMOR").get(str(r.gear.armor), {}).has("mk"):
		var armor_lv := int(r.gear.mk.get("armor:" + str(r.gear.armor), 1))
		if armor_lv < 3:
			var armor_res: String = Data.get_table("gear", "MK_RES").a[armor_lv - 1]
			var armor_cost := Gear.price(c, int(Data.get_table("gear", "MK_COST")[armor_lv]))
			var armor_reason := "Powered Forge required" if not Base.operational(c.state, "forge") else lock_reason(c, {"res":armor_res}, armor_cost)
			offer("armor_mark", "", "", "Forge armor to Mk " + ["I", "II", "III"][armor_lv], armor_reason, armor_cost, 0, Gear.preview(c, id, "armor_mark"))
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
					offer("upgrade", kind, key, "Upgrade to Mk " + ["I", "II", "III"][lv], lock_reason(c, {"res":res}, cost), cost, 0, Gear.preview(c, id, "upgrade", kind, str(key)))
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
	_filter()

func _build_slots(r: Dictionary, jedi: bool) -> void:
	var primary := "SABER" if jedi else "WEAPON"
	var base_kind := "s" if jedi else "w"
	_slot("weapon", primary, "Mk " + _mark(int(r.gear.mk.get(base_kind, 1))), "strike" if jedi else "shoot")
	_slot("armor", "ARMOR", "Mk " + _mark(int(r.gear.mk.get("armor:" + str(r.gear.armor), 1))), "st_armor")
	_slot("utility", "UTILITY 1", str(Data.get_table("gear", "UTIL").get(str(r.gear.get("util", "none")), {}).get("n", "Empty")), "st_hp")
	_slot("base_mod", "SABER MOD" if jedi else "WEAPON MOD", "%d/%d fitted" % [r.gear.smods.size() if jedi else r.gear.mods.size(), Gear.slots(r, base_kind)], "kyber" if jedi else "st_power")
	_slot("armor_mod", "ARMOR MOD", "%d/%d fitted" % [r.gear.amods.size(), Gear.slots(r, "a")], "st_armor")
	if jedi: _slot("form", "SABER FORM", str(Data.get_table("gear", "FORMS").get(str(r.gear.get("form", "shiiCho")), {}).get("n", "Shii-Cho")), "strike")
	_slot("color", "CRYSTAL" if jedi else "ACCENT", "COLOR", "kyber" if jedi else "st_armor")
	_slot("evolution", "PATH", "Rank %d" % int(r.rank), "st_will")

func _slot(key: String, title: String, value: String, icon: String) -> void:
	var b := S.button(title + "\n" + value, _select_slot.bind(key))
	b.custom_minimum_size = Vector2(124 if Phone.narrow(Phone.window_size()) else 154, 44 if Phone.narrow(Phone.window_size()) else 62)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_font_size_override("font_size", 11)
	var glyph := TextureRect.new(); glyph.texture = S.icon(icon)
	glyph.position = Vector2(6, 8); glyph.size = Vector2(28, 28)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(glyph)
	slot_row.add_child(b); host.wire_button(b)

func _mark(level: int) -> String:
	return ["I", "II", "III"][clampi(level - 1, 0, 2)]

func _select_slot(slot: String) -> void:
	active_slot = slot; host.armory_slot = slot; skill_view = false; _filter()
	if Phone.narrow(Phone.window_size()) and get_parent() is ScrollContainer:
		get_parent().set_deferred("scroll_vertical", 62)

func _show_gear() -> void:
	skill_view = false; _filter()
	if get_parent() is ScrollContainer: get_parent().scroll_vertical = 0

func _show_skills() -> void:
	skill_view = true; _filter()
	if get_parent() is ScrollContainer: get_parent().scroll_vertical = 0

func _filter() -> void:
	for entry in offer_cards: entry.node.visible = not skill_view and entry.slot == active_slot
	if is_instance_valid(picker):
		for child in picker.get_children():
			if child.name == "SkillTree": child.visible = skill_view
	var existing := picker.get_node_or_null("SkillTree")
	if skill_view and existing == null: _build_skills()

func _build_skills() -> void:
	var tree := S.column(5); tree.name = "SkillTree"; picker.add_child(tree)
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	var rank_now := Progression.pending_rank(r)
	tree.add_child(S.label("PROMOTION  /  %s  /  RANK %d" % [str(r.cls).to_upper(), int(r.rank)], 13, S.GOLD))
	var perks: Dictionary = Data.get_table("temple", "PERKS")
	var abilities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	for rank in range(1, maxi(3, int(r.rank) + 1)):
		var options: Array = Progression.tree_options(r, rank)
		if options.is_empty(): continue
		var row := HBoxContainer.new(); tree.add_child(row)
		row.add_child(S.label("R%d" % rank, 12, S.CYAN))
		for key in options:
			var info: Dictionary = perks.get(str(key), abilities.get(str(key), {}))
			var picked: bool = str(key) in r.get("picks", [])
			var label := str(info.get("name", str(key).capitalize()))
			var b := S.button(("✓ " if picked else "") + label, _choose_skill.bind(str(key)), rank == rank_now)
			b.custom_minimum_size.y = 44; b.size_flags_horizontal = SIZE_EXPAND_FILL
			b.tooltip_text = str(info.get("desc", "")); row.add_child(b); host.wire_button(b)
	if rank_now == 0: tree.add_child(S.label("Next choices unlock when this soldier earns a rank.", 12, S.MUTED))

func _choose_skill(key: String) -> void:
	if Progression.choose(host.flow.session().soldier(soldier_id), key):
		host.flow.save(); host._refresh(); host.arsenal._show_skills()

func section(title: String) -> void:
	# Slot tiles carry the section names; the picker shows one group at a time.
	pass

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
	var slot := _offer_slot(action, kind)
	var compact := Phone.narrow(Phone.window_size())
	var card := S.panel(); card.add_theme_stylebox_override("panel", S.box(Color("14232a"), S.EDGE, 4 if compact else 7))
	picker.add_child(card); offer_cards.append({"slot":slot, "node":card})
	var column := S.column(3); card.add_child(column)
	var heading := HBoxContainer.new(); column.add_child(heading)
	var icon := TextureRect.new(); icon.texture = S.icon(_offer_icon(action, kind))
	icon.custom_minimum_size = Vector2(26, 26) if compact else Vector2(34, 34); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; heading.add_child(icon)
	var label := title + ("  ·  %d Cr" % cost if cost > 0 else "") + (" + %d Ky" % kyber if kyber > 0 else "")
	var tier := "Mk %s  ·  " % _mark(_offer_mark(action, kind, key))
	var callback: Callable = armor_upgrade if action == "armor_mark" else base_upgrade.bind(kind) if action == "base_mark" else host.change_gear.bind(action, kind, key)
	var b := S.button(tier + label, callback, reason == "")
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = SIZE_EXPAND_FILL; b.custom_minimum_size.y = 44
	b.tooltip_text = tip; heading.add_child(b); host.wire_button(b)
	var delta: Array = Preview.changes(host.flow.session(), soldier_id, action, kind, key)
	if not delta.is_empty():
		var stats := HBoxContainer.new(); stats.add_theme_constant_override("separation", 9); column.add_child(stats)
		for change in delta:
			var gain := int(change.value) >= 0 and int(change.get("high", change.value)) >= 0
			stats.add_child(S.label(Preview.text_for(change), 11, S.GREEN if gain else S.RED))
	elif tip != "":
		var detail := S.label(tip, 11, S.MUTED); detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(detail)
	if reason != "":
		var why := S.label("LOCKED  ·  " + reason, 11, S.RED); why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(why)
	offers.append({"action":action, "kind":kind, "key":key, "slot":slot, "enabled":reason == "", "button":b, "card":card})

func _offer_slot(action: String, kind: String) -> String:
	if action in ["weapon", "saber", "base_mark"]: return "weapon"
	if action in ["armor", "armor_mark"]: return "armor"
	if action == "utility": return "utility"
	if action == "form": return "form"
	if action == "evolve": return "evolution"
	return "armor_mod" if kind == "a" else "base_mod"

func _offer_icon(action: String, kind: String) -> String:
	if action in ["weapon", "saber", "base_mark"]: return "strike" if kind == "s" or action == "saber" else "shoot"
	if action in ["armor", "armor_mark"] or kind == "a": return "st_armor"
	if action == "utility": return "st_hp"
	if action == "form": return "strike"
	return "kyber" if kind == "s" else "st_power"

func _offer_mark(action: String, kind: String, key: String) -> int:
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	if action == "upgrade": return int(r.gear.mk.get(kind + "." + key, 1)) + 1
	if action == "base_mark": return int(r.gear.mk.get(kind, 1)) + 1
	if action == "armor_mark": return int(r.gear.mk.get("armor:" + str(r.gear.armor), 1)) + 1
	if action == "remove": return int(r.gear.mk.get(kind + "." + key, 1))
	if action == "armor": return int(r.gear.mk.get("armor:" + key, 1))
	return 1

func armor_upgrade() -> void:
	var c = host.flow.session()
	if Gear.upgrade_armor(c, soldier_id):
		host.flow.save()
		host._refresh()

func base_upgrade(kind: String) -> void:
	var c = host.flow.session()
	if Gear.upgrade_base(c, soldier_id, kind):
		host.flow.save()
		host._refresh()
