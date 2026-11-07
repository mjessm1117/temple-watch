extends Control
## Full-screen rank and cross-training view. TouchScroll handles drags from buttons.
const UI = preload("res://scripts/campaign/ui.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Mentor = preload("res://scripts/campaign/mentor17.gd")
var campaign: RefCounted
var unit_id := ""
var scroll: ScrollContainer
var content: VBoxContainer
signal changed
signal closed

func setup(c: RefCounted, id: String) -> void:
	campaign = c
	unit_id = id
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.045, 0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := UI.label("TRAINING & PROMOTION", 20, UI.ACCENT)
	if heading is Label: heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var back := UI.button("Done", _close)
	back.custom_minimum_size.y = 44
	header.add_child(back)
	scroll = preload("res://scripts/touch_scroll.gd").new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = UI.column(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_refresh()

func _add_button(label_text: String, callback: Callable) -> void:
	var button := UI.button(label_text, callback)
	button.custom_minimum_size.y = 44
	content.add_child(button)

func _refresh() -> void:
	var offset := scroll.scroll_vertical
	UI.clear(content)
	var r: Dictionary = campaign.soldier(unit_id)
	if r.is_empty(): return
	var side_name := Classes.side(str(r.cls))
	var rank: Dictionary = Classes.rank_data(side_name, int(r.get("rank", 1)))
	content.add_child(UI.label("%s  ·  %s" % [r.n, r.cls], 19, UI.GOLD))
	content.add_child(UI.label("RANK %d: %s  ·  POWER %d" % [int(r.rank), str(rank.get("title", r.get("title", ""))), Classes.power(side_name, int(r.rank))], 16))
	content.add_child(UI.label("TIER  %s" % str(rank.get("tier", "")), 15, UI.ACCENT))
	if rank.has("aura"): content.add_child(UI.label("Aura ×%d  ·  third action once per mission" % int(rank.aura), 14))
	elif rank.has("saber_forms"): content.add_child(UI.label("Second Focus pip  ·  saber forms", 14))
	content.add_child(UI.label("BLEND SLOTS  %d / %d" % [r.get("classes", []).size(), Classes.blend_slots(side_name, int(r.rank))], 15, UI.ACCENT))
	content.add_child(UI.label("Paths: %s" % ", ".join(r.get("classes", [])), 14))
	if side_name == "jedi" and int(r.rank) <= 2:
		if str(r.get("mentor_id", "")) != "":
			var master: Dictionary = campaign.soldier(str(r.mentor_id))
			content.add_child(UI.label("Mentor: %s  ·  taught %s" % [master.get("n", ""), r.get("taught_ability", "")], 14, UI.GOLD))
		else:
			content.add_child(UI.label("CHOOSE A MASTER MENTOR", 14, UI.GOLD))
			for master in campaign.state.roster:
				if master == r or str(master.get("status", "")) != "active" or Classes.side(str(master.get("cls", ""))) != "jedi" or int(master.get("rank", 0)) < 5: continue
				var pupils := 0
				for other in campaign.state.roster:
					if str(other.get("mentor_id", "")) == str(master.id) and str(other.get("status", "")) == "active" and int(other.get("rank", 0)) <= 2: pupils += 1
				if pupils >= 2: continue
				var signature := str(Classes.class_data(str(master.cls)).get("signature", ""))
				if signature != "": _add_button("Train with %s · %s" % [master.n, signature], _mentor.bind(str(master.id), signature))
	for legacy in r.get("legacies", []):
		content.add_child(UI.label("Legacy: %s · %s at 50%% power" % [legacy.get("mentor", ""), legacy.get("ability", "")], 14, UI.GOLD))
	if r.get("classes", []).size() < Classes.blend_slots(side_name, int(r.rank)):
		content.add_child(UI.label("CHOOSE ANOTHER PATH", 14, UI.GOLD))
		for id in Classes.IDS[side_name]:
			if Classes.can_blend(r, str(id)): _add_button("Train %s" % Classes.class_data(str(id)).get("name", id), _blend.bind(str(id)))
	if int(r.get("pick", 0)) > 0:
		content.add_child(UI.label("RANK %d ABILITY PICK" % int(r.pick), 14, UI.GOLD))
		for id in Progression.tree_options(r, int(r.pick)):
			_add_button(str(id), _pick.bind(str(id)))
	var options := Progression.cross_options(r)
	if not options.is_empty():
		content.add_child(UI.label("CROSS-TRAINED ABILITIES", 14, UI.GOLD))
		for id in options: _add_button(str(id), _cross_pick.bind(str(id)))
	if options.is_empty() and int(r.get("pick", 0)) == 0:
		content.add_child(UI.label("Next ability choices unlock with rank and training.", 14, UI.MUTED))
	scroll.set_deferred("scroll_vertical", offset)

func _save() -> void:
	var flow := get_node_or_null("/root/CampaignFlow")
	if flow != null: flow.save()
	changed.emit()
	_refresh()

func _pick(id: String) -> void:
	if Progression.choose(campaign.soldier(unit_id), id): _save()

func _blend(id: String) -> void:
	if Classes.cross_train(campaign.soldier(unit_id), id): _save()

func _cross_pick(id: String) -> void:
	if Progression.choose_cross(campaign.soldier(unit_id), id): _save()

func _mentor(id: String, skill: String) -> void:
	if Mentor.assign(campaign, id, unit_id, skill): _save()

func _close() -> void:
	closed.emit()
	queue_free()
