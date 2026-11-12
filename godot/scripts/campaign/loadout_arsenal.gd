extends VBoxContainer
const S = preload("res://scripts/campaign/loadout_style.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Preview = preload("res://scripts/campaign/armory12_preview.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Preview15 = preload("res://scripts/campaign/armory15_preview.gd")
const Art16 = preload("res://scripts/campaign/armory16_art.gd")
const SkillTree = preload("res://scripts/campaign/loadout_skill_tree.gd")
var host: Control
var soldier_id := ""
var offers: Array[Dictionary] = []
var offer_cards: Array[Dictionary] = []
var active_slot := ""
var picker: VBoxContainer
var slot_row: GridContainer
var slot_prompt: Label
var preview_card: PanelContainer
var hangar_sign: Label
var feature_row: BoxContainer
var skill_view := false
var jedi_actor := false
var actor_color := "#62b3ff"
var secondary_open := false
var secondary_button: Button

func setup(owner_screen: Control, id: String) -> void:
	host = owner_screen; soldier_id = id; active_slot = host.armory_slot
	if active_slot == "" and host.from_temple: active_slot = "weapon"; host.armory_slot = active_slot
	add_theme_constant_override("separation", 7)
	var c = host.flow.session(); var r: Dictionary = c.soldier(id)
	var jedi := Progression.is_jedi(r)
	jedi_actor = jedi; actor_color = str(r.get("col", actor_color))
	feature_row = VBoxContainer.new() if host.size.x < 600 else HBoxContainer.new()
	feature_row.add_theme_constant_override("separation", 6); add_child(feature_row)
	slot_row = GridContainer.new(); slot_row.columns = 2 if host.size.x < 500 else 3 if host.size.x < 720 else 4
	slot_row.size_flags_horizontal = SIZE_EXPAND_FILL
	slot_row.add_theme_constant_override("h_separation", 8 if Phone.narrow(Phone.window_size()) else 5)
	slot_row.add_theme_constant_override("v_separation", 8 if Phone.narrow(Phone.window_size()) else 4)
	feature_row.add_child(slot_row)
	_build_slots(r, jedi)
	secondary_button = S.button("MORE SLOTS  ▾", _toggle_secondary)
	secondary_button.name = "SecondarySlots"; secondary_button.custom_minimum_size.y = 44
	secondary_button.add_theme_color_override("font_disabled_color", Color("e5eff1"))
	add_child(secondary_button)
	secondary_button.visible = Phone.narrow(Phone.window_size())
	_apply_secondary()
	_update_preview()
	hangar_sign = UI.label("HANGAR 07", 14, S.CYAN)
	hangar_sign.add_theme_color_override("font_shadow_color", Color("00131b"))
	hangar_sign.add_theme_constant_override("shadow_offset_x", 1)
	hangar_sign.add_theme_constant_override("shadow_offset_y", 2)
	hangar_sign.position = Vector2(10 if Phone.narrow(get_tree().root.size) else host.size.x - 676, 8)
	hangar_sign.size = Vector2(148, 24)
	hangar_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.stage_container.add_child(hangar_sign)
	picker = S.column(6); add_child(picker)
	slot_prompt = UI.label("SELECT A GEAR SLOT TO COMPARE EQUIPMENT", 14, S.CYAN); picker.add_child(slot_prompt)
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
	var armor_keys: Array = Data.get_table("gear", "ARMOR").keys()
	if str(r.gear.armor) in armor_keys:
		armor_keys.erase(str(r.gear.armor))
		armor_keys.push_front(str(r.gear.armor))
	for key in armor_keys:
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
			var form_reason := Gear.form_lock_reason(c, r, key)
			var reason := form_reason if form_reason == "Knight rank 3 required" else lock_reason(c, item, 0)
			offer("form", "", key, str(item.n), "Equipped" if r.gear.get("form", "shiiCho") == key else reason, 0, 0, str(item.get("desc", "")))
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

func _toggle_secondary() -> void:
	secondary_open = not secondary_open
	_apply_secondary()

func _apply_secondary() -> void:
	if slot_row == null: return
	for slot in slot_row.get_children():
		if slot is Control: slot.visible = not Phone.narrow(Phone.window_size()) or secondary_open or slot.name in ["Slot_weapon", "Slot_armor", "Slot_utility"]

func _build_slots(r: Dictionary, jedi: bool) -> void:
	var primary := "SABER" if jedi else "WEAPON"
	var base_kind := "s" if jedi else "w"
	var pool: Array = Data.get_table("gear", "SABERS" if jedi else "WEAPONS")
	var tier := int(r.gear.saber if jedi else r.gear.w)
	_slot("weapon", primary, str(pool[tier].n), int(r.gear.mk.get(base_kind, 1)), "strike" if jedi else "shoot")
	var armor: Dictionary = Data.get_table("gear", "ARMOR").get(str(r.gear.armor), {})
	_slot("armor", "ARMOR", str(armor.get("n", "Empty")), int(r.gear.mk.get("armor:" + str(r.gear.armor), 1)), "armor_jedi" if jedi else "armor_troop")
	_slot("utility", "UTILITY", str(Data.get_table("gear", "UTIL").get(str(r.gear.get("util", "none")), {}).get("n", "Empty")), 1, "st_hp")
	var mods: Array = r.gear.smods if jedi else r.gear.mods
	var mod_name := "Empty"
	var mod_mark := 1
	if not mods.is_empty():
		mod_name = str(Data.get_table("gear", Gear.POOL_KEY[base_kind]).get(str(mods[0]), {}).get("n", mods[0]))
		mod_mark = int(r.gear.mk.get(base_kind + "." + str(mods[0]), 1))
	_slot("base_mod", "SABER MOD" if jedi else "WEAPON MOD", mod_name, mod_mark, "kyber" if jedi else "st_power")
	var armor_mod_name := "Empty"
	var armor_mod_mark := 1
	if not r.gear.amods.is_empty():
		armor_mod_name = str(Data.get_table("gear", Gear.POOL_KEY.a).get(str(r.gear.amods[0]), {}).get("n", r.gear.amods[0]))
		armor_mod_mark = int(r.gear.mk.get("a." + str(r.gear.amods[0]), 1))
	_slot("armor_mod", "ARMOR MOD", armor_mod_name, armor_mod_mark, "st_armor")
	if jedi: _slot("form", "SABER FORM", str(Data.get_table("gear", "FORMS").get(str(r.gear.get("form", "shiiCho")), {}).get("n", "Shii-Cho")), 1, "strike")
	var color_name := "Accent"
	if jedi:
		color_name = "Kyber"
		for color_key in Data.get_table("gear", "CRYSTALS"):
			if str(Data.get_table("gear", "CRYSTALS")[color_key]) == str(r.get("col", "")):
				color_name = str(color_key).capitalize(); break
	_slot("color", "CRYSTAL" if jedi else "ACCENT", color_name, 1, "kyber" if jedi else "st_armor")
	_slot("evolution", "PATH", "Rank %d" % int(r.rank), 1, "st_will")

func _slot(key: String, title: String, value: String, mark: int, icon: String) -> void:
	var compact := Phone.narrow(get_tree().root.size)
	var portrait := compact and host.size.x < 500
	var b := S.button("", _select_slot.bind(key)); b.name = "Slot_" + key
	b.custom_minimum_size = Vector2(84 if compact else 116, 88 if portrait else 68)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.tooltip_text = value
	var art_key: String = str({"weapon":"saber" if icon == "strike" else "blaster", "armor":icon, "utility":"utility", "base_mod":"module", "armor_mod":"armor_mod", "form":"form", "color":"crystal", "evolution":"path"}.get(key, "module"))
	var glyph := TextureRect.new(); glyph.name = "GearArt"
	var source: Texture2D = _baked_icon(str(host.flow.session().soldier(soldier_id).cls).to_lower()) if key == "evolution" else _baked_icon("strike") if key == "form" else load("res://assets/loadout/icons13/saber.png") if key == "weapon" and jedi_actor else Art16.tile_for(key, jedi_actor, mark, actor_color, art_key)
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = source.get_image().get_used_rect()
	glyph.texture = cropped
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; glyph.stretch_mode = TextureRect.STRETCH_SCALE
	var art_height := 40.0 if compact else 48.0
	var narrow_tile := compact and get_tree().root.size.x < 900 and key in ["weapon", "form"]
	var art_width := minf(art_height * cropped.region.size.x / cropped.region.size.y, 14.0 if narrow_tile else 24.0 if compact else 42.0)
	glyph.position = Vector2(2.0 if narrow_tile else 3.0 + ((30.0 if compact else 42.0) - art_width) * 0.5, 37 if portrait else 26 if compact else 10)
	glyph.size = Vector2(art_width, art_height)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(glyph)
	var short_title: String = {"SABER MOD":"SAB MOD", "WEAPON MOD":"WPN MOD", "ARMOR MOD":"ARM MOD", "SABER FORM":"FORM"}.get(title, title) if compact else title
	var name_label := UI.label(short_title, 14 if compact else 10, S.CYAN)
	name_label.name = "SlotLabel"
	name_label.position = Vector2(4 if compact else 51, 4 if portrait else 2 if compact else 5)
	name_label.size = Vector2(76 if compact else 62, 23 if portrait else 19 if compact else 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(name_label)
	var display_value := value.get_slice(" (", 0) if key == "form" else value
	display_value = display_value.trim_suffix(" saber").trim_suffix(" robes")
	var item_label := UI.label(display_value, 14)
	var item_left := 17 if narrow_tile else 31 if compact else 51
	item_label.name = "ItemName"; item_label.position = Vector2(item_left, 29 if portrait else 20 if compact else 24)
	item_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	item_label.clip_text = true
	item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_label.size = Vector2(maxf(51, b.custom_minimum_size.x - item_left - 4), 23 if portrait else 19)
	var fit_item := func() -> void:
		item_label.size.x = maxf(51, b.size.x - item_left - 4)
		var full_width := ThemeDB.fallback_font.get_string_size(display_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		item_label.text = display_value if full_width <= item_label.size.x else display_value.get_slice(" ", 0)
	b.resized.connect(fit_item)
	fit_item.call()

	b.add_child(item_label)
	var tier := UI.label("Mk " + _mark(mark), 14, _tier_color(mark))
	tier.name = "Tier"; tier.position = Vector2(31 if compact else 51, 55 if portrait else 39 if compact else 45)
	if portrait: tier.size = Vector2(48, 22)
	tier.autowrap_mode = TextServer.AUTOWRAP_OFF
	tier.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(tier)
	for i in 3:
		var pip := ColorRect.new(); pip.name = "TierPip%d" % i
		pip.color = _tier_color(mark) if i < mark else Color("2b3d44")
		pip.position = Vector2((31 if compact else 51) + i * 14, 82 if portrait else 63 if compact else 61)
		pip.size = Vector2(10, 3); pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pip)
	slot_row.add_child(b); host.wire_button(b)

func _baked_icon(key: String) -> Texture2D:
	var image := S.icon(key).get_image()
	image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func _tier_color(mark: int) -> Color:
	return S.GOLD if mark >= 3 else S.CYAN if mark == 2 else S.MUTED

func _mark(level: int) -> String:
	return ["I", "II", "III"][clampi(level - 1, 0, 2)]

func _select_slot(slot: String) -> void:
	active_slot = slot; host.armory_slot = slot; skill_view = false; _filter()
	_update_preview()
	# One owner for the list position: the container's scroll value, set once per tap.
	if get_parent() is ScrollContainer:
		var scroll := get_parent() as ScrollContainer
		await get_tree().process_frame
		if not is_instance_valid(scroll): return
		scroll.scroll_vertical = maxi(0, int(picker.position.y) - 20) if Phone.narrow(get_tree().root.size) else 0
		scroll.notification(Container.NOTIFICATION_SORT_CHILDREN)
		for entry in offers:
			if entry.slot != slot or not entry.card.visible: continue
			var deltas: Control = entry.card.find_child("Deltas", true, false)
			if deltas != null:
				scroll.ensure_control_visible(deltas)
				var overshoot := deltas.get_global_rect().end.y - scroll.get_global_rect().end.y + 4.0
				if overshoot > 0: scroll.scroll_vertical += ceili(overshoot)
				scroll.notification(Container.NOTIFICATION_SORT_CHILDREN)
				break

func _update_preview() -> void:
	if is_instance_valid(preview_card):
		preview_card.get_parent().remove_child(preview_card); preview_card.queue_free()
	var key := active_slot if active_slot != "" else "weapon"
	var tile := slot_row.get_node_or_null("Slot_" + key) as Button
	if tile == null: return
	var phone := Phone.narrow(get_tree().root.size)
	preview_card = Preview15.make(host.flow.session(), host.flow.session().soldier(soldier_id), tile, phone)
	feature_row.add_child(preview_card)
	if feature_row is HBoxContainer: feature_row.move_child(preview_card, 0)

func _exit_tree() -> void:
	if is_instance_valid(preview_card) and preview_card.get_parent() != self:
		preview_card.queue_free()
	if is_instance_valid(hangar_sign): hangar_sign.queue_free()

func _show_gear() -> void:
	skill_view = false; feature_row.visible = true; secondary_button.visible = Phone.narrow(Phone.window_size()); _filter()
	if get_parent() is ScrollContainer: get_parent().scroll_vertical = 0

func _show_skills() -> void:
	skill_view = true; feature_row.visible = false; secondary_button.visible = false; _filter()
	if get_parent() is ScrollContainer: get_parent().scroll_vertical = 0

func _filter() -> void:
	if is_instance_valid(slot_prompt): slot_prompt.visible = not skill_view and active_slot == ""
	for entry in offer_cards: entry.node.visible = not skill_view and entry.slot == active_slot
	if is_instance_valid(picker):
		for child in picker.get_children():
			if child.name == "SkillTree": child.visible = skill_view
	var existing := picker.get_node_or_null("SkillTree")
	if skill_view and existing == null: _build_skills()

func _build_skills() -> void:
	var tree := SkillTree.new(); picker.add_child(tree); tree.setup(host, soldier_id)

func _choose_skill(key: String) -> void:
	# Legacy direct action used by promotion tests; tree taps use preview then confirm.
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	if Progression.choose(r, key):
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
	var compact := Phone.narrow(get_tree().root.size)
	var equipped := reason == "Equipped"
	var card := S.panel(); card.add_theme_stylebox_override("panel", S.box(Color("14232a"), S.EDGE, 3 if compact else 5))
	picker.add_child(card); offer_cards.append({"slot":slot, "node":card})
	var column := S.column(2); card.add_child(column)
	var heading := HBoxContainer.new(); heading.add_theme_constant_override("separation", 5); column.add_child(heading)
	var icon := TextureRect.new(); icon.texture = Art16.tile_for(slot, jedi_actor, _offer_mark(action, kind, key), actor_color, {"weapon":"saber" if jedi_actor else "blaster", "armor":"armor", "utility":"utility", "base_mod":"module", "armor_mod":"armor_mod", "form":"form", "evolution":"path"}.get(slot, "module"))
	icon.custom_minimum_size = Vector2(42, 42); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; heading.add_child(icon)
	var info := S.column(0); info.size_flags_horizontal = SIZE_EXPAND_FILL; heading.add_child(info)
	var upgrade := action in ["upgrade", "base_mark", "armor_mark"]
	var mark := _offer_mark(action, kind, key)
	var item_name := title
	if upgrade: item_name = "Forge to Mk " + _mark(mark)
	var name_label := UI.label(item_name, 14)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; info.add_child(name_label)
	var tier_label := UI.label("Mk " + _mark(mark) + ("  ·  %d Cr" % cost if cost > 0 else "") + (" + %d Ky" % kyber if kyber > 0 else ""), 14, _tier_color(mark))
	info.add_child(tier_label)
	var callback: Callable = armor_upgrade if action == "armor_mark" else base_upgrade.bind(kind) if action == "base_mark" else host.change_gear.bind(action, kind, key)
	var b := S.button("EQUIPPED" if equipped else "UPGRADE" if upgrade else "EQUIP", callback, reason == "")
	b.custom_minimum_size = Vector2(90 if compact else 86, 44)
	b.tooltip_text = tip; heading.add_child(b); host.wire_button(b)
	var delta: Array = host.loadout_delta25(soldier_id, {"action":action, "kind":kind, "key":key})
	var details := VBoxContainer.new(); details.add_theme_constant_override("separation", 2); column.add_child(details)
	var stat_line := UI.label(tip.get_slice("\n", 0) if tip != "" else "Stats unchanged" if delta.is_empty() else "STAT CHANGE", 14, S.MUTED)
	stat_line.clip_text = true; stat_line.autowrap_mode = TextServer.AUTOWRAP_OFF; stat_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; details.add_child(stat_line)
	if not delta.is_empty():
		var stats := HBoxContainer.new(); stats.name = "Deltas"; stats.add_theme_constant_override("separation", 9); details.add_child(stats)
		for change in delta:
			var gain := int(change.after[0]) >= int(change.before[0]) if change.after is Array else int(change.after) >= int(change.before)
			var delta_label := UI.label("%s %s→%s" % [change.stat, str(change.before), str(change.after)], 14, S.GREEN if gain else S.RED)
			delta_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			stats.add_child(delta_label)
	if reason != "" and not equipped:
		var why := UI.label("LOCKED  ·  " + reason, 14, S.RED); why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(why)
	offers.append({"action":action, "kind":kind, "key":key, "slot":slot, "enabled":reason == "", "button":b, "card":card, "delta":delta})

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
