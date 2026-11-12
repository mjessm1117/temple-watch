extends Control
const S = preload("res://scripts/campaign/loadout_style.gd")
const Details = preload("res://scripts/campaign/loadout_details.gd")
const Stage = preload("res://scripts/campaign/loadout_stage.gd")
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
const Arsenal = preload("res://scripts/campaign/loadout_arsenal.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const JediModels = preload("res://scripts/characters/jedi_models.gd")
const StoryPortraits = preload("res://scripts/story14_portraits.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const People25 = preload("res://scripts/w25_roster_people.gd")
var from_temple := false
var temple_soldier_id := ""
var temple_focus := ""
var capacity := 5
var flow: Node
var selected: Array = []
var deploy: Button
var counter: Label
var choices: Dictionary = {}
var cards: Dictionary = {}
var portraits: Dictionary = {}
var portrait_actors: Dictionary = {}
var stage: Node3D
var stage_container: SubViewportContainer
var card_row: HBoxContainer
var card_scroll: ScrollContainer
var footer: HBoxContainer
var footer_bg: ColorRect
var swap_button: Button
var skill_confirm: Button
var header: PanelContainer
var drawer: ColorRect
var drawer_content: Control
var resources: Label
var notice: Label
var focus_index := -1
var drawer_tab := "arsenal"
var hover_index := -1
var audio: AudioStreamPlayer
var hum: AudioStreamPlayer
var arsenal: VBoxContainer
var compact_layout := false
var armory_skills := false
var armory_slot := ""

static func open_from_temple(tree: SceneTree, focus: String = "", soldier_id: String = "") -> Control:
	var screen: Control = load("res://scenes/squad.tscn").instantiate()
	screen.from_temple = true
	screen.temple_focus = focus if focus in ["medical", "loadout"] else "loadout"
	screen.temple_soldier_id = soldier_id if soldier_id != "" else "" if focus in ["medical", "loadout"] else focus
	var previous := tree.current_scene
	tree.root.add_child(screen)
	tree.current_scene = screen
	if previous != null and previous != screen: previous.queue_free()
	return screen

func patient_actions25(soldier_id: String) -> Array:
	return People25.patient_actions(flow.session(), soldier_id)

func loadout_delta25(soldier_id: String, item_id: Variant) -> Array:
	return People25.delta(flow.session(), soldier_id, item_id)

func apply_patient_action25(soldier_id: String, action: String) -> bool:
	if not People25.apply_patient(flow.session(), soldier_id, action): return false
	flow.save()
	if focus_index >= 0: _build_drawer()
	return true

func best_ready_fill25() -> void:
	selected = People25.best_ready(flow.session(), capacity)
	focus_index = -1
	drawer.hide()
	_persist_selection()
	_refresh()

func _ready() -> void:
	flow = get_node("/root/CampaignFlow")
	var c = flow.session()
	var option: Dictionary = c.state.pending_mission if not c.state.pending_mission.is_empty() else c.state.get("launch_option",{})
	capacity = mini(c.squad_capacity(),int(preload("res://scripts/mission_fronts.gd").squad_rule(c.state).max))
	selected = c.state.pending_mission.get("squad", c.state.get("loadout_squad", c.default_squad(option).slice(0, capacity))).duplicate()
	selected = selected.filter(func(id): return Details.fit(c.soldier(str(id))) and id not in preload("res://scripts/mission_fronts.gd").squad_rule(c.state).used).slice(0, capacity)
	if not preload("res://scripts/campaign/strat_deployment.gd").validate(c,selected,option): selected = c.default_squad(option)
	for id in c.default_squad(option):
		if selected.size() < capacity and not selected.has(id): selected.append(id)
	if from_temple and temple_soldier_id == "": temple_soldier_id = str(c.state.get("armory_selected_id", ""))
	if from_temple and temple_soldier_id != "" and not c.soldier(temple_soldier_id).is_empty():
		if not selected.has(temple_soldier_id):
			if selected.is_empty(): selected.append(temple_soldier_id)
			else: selected[0] = temple_soldier_id
		focus_index = selected.find(temple_soldier_id)
		c.state.armory_selected_id = temple_soldier_id
		flow.save()
	if from_temple and temple_focus == "medical":
		for r in c.state.roster:
			if int(r.get("wound", 0)) > 0:
				if not selected.has(r.id):
					if selected.is_empty(): selected.append(r.id)
					else: selected[0] = r.id
				focus_index = selected.find(r.id)
				break
	var bg := ColorRect.new(); bg.color = S.BG; bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(bg)
	_build_stage(); _build_header(); _build_footer()
	swap_button = S.button("SWAP", _tab.bind("roster")); add_child(swap_button); wire_button(swap_button)
	skill_confirm = S.button("CONFIRM", _confirm_skill); skill_confirm.name = "SkillConfirm"; add_child(skill_confirm); wire_button(skill_confirm)
	card_row = HBoxContainer.new(); card_row.add_theme_constant_override("separation", 6)
	card_scroll = preload("res://scripts/touch_scroll.gd").new(); card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	card_scroll.z_index = 1
	add_child(card_scroll); card_scroll.add_child(card_row)
	card_scroll.resized.connect(_sync_roster_visibility)
	drawer = ColorRect.new(); drawer.color = S.PANEL; drawer.clip_contents = true; add_child(drawer); drawer.hide()
	move_child(card_scroll, -1)
	for r in c.state.roster: _portrait(r)
	_make_audio()
	resized.connect(_layout)
	_refresh(); _layout(); _layout.call_deferred()
	if from_temple and focus_index >= 0:
		inspect(focus_index)
		if temple_focus == "medical": _tab("medical")

func _build_stage() -> void:
	stage_container = SubViewportContainer.new(); stage_container.stretch = true
	stage_container.mouse_filter = MOUSE_FILTER_IGNORE; add_child(stage_container)
	var viewport := SubViewport.new(); viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.msaa_3d = Viewport.MSAA_2X
	stage_container.add_child(viewport); stage = Stage.new(); viewport.add_child(stage)

func _build_header() -> void:
	var compact := Phone.narrow(Phone.window_size())
	header = S.panel(); add_child(header); var row := HBoxContainer.new(); header.add_child(row)
	var title := S.column(3); title.size_flags_horizontal = SIZE_EXPAND_FILL; row.add_child(title)
	if not compact: title.add_child(UI.label("JEDI TEMPLE  /  HANGAR 07  /  %s" % ("ARMORY" if from_temple else "DEPLOYMENT"), 14, S.CYAN))
	title.add_child(UI.label("TEMPLE ARMORY" if from_temple else "SQUAD LOADOUT", 20 if compact else 32))
	if not compact: title.add_child(UI.label("Choose up to %d. Equip for the mission. Bring everyone home." % capacity, 14, S.MUTED))
	var info := S.column(5); row.add_child(info)
	resources = UI.label("", 14, S.GOLD); resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; info.add_child(resources)
	if not compact: resources.custom_minimum_size.x = 300
	if compact:
		resources.reparent(title)
		resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.remove_child(info)
		info.free()
		header.add_theme_stylebox_override("panel", S.box(S.PANEL, S.EDGE, 4))
	var option: Dictionary = flow.session().state.get("launch_option", {})
	var mission := str(option.get("n", option.get("mission", "Detention Line"))).to_upper().replace("_", " ")
	if not from_temple and not compact: info.add_child(UI.label("OPERATION  /  " + mission, 16, S.CYAN))
	var mission_id := str(option.get("mission", "rescue"))
	var hint := "Select a soldier to inspect gear or swap with the roster."
	if preload("res://scripts/campaign/battle_bridge.gd").map_path(mission_id).ends_with("rescue.json") and mission_id != "rescue":
		hint = "Battlefield: Detention Line · free Mira and reach evacuation."
	if not compact: info.add_child(UI.label(hint, 14, S.MUTED))

func _build_footer() -> void:
	footer_bg = ColorRect.new(); footer_bg.color = S.BG; footer_bg.mouse_filter = MOUSE_FILTER_IGNORE; footer_bg.z_index = 10; add_child(footer_bg)
	footer = HBoxContainer.new(); footer.z_index = 11; footer.add_theme_constant_override("separation", 16); add_child(footer)
	var back := S.button("DONE" if from_temple else "Temple" if Phone.touch_device() else "← Temple", func():
		if from_temple: flow.go("temple")
		else: flow.back_from_squad()); footer.add_child(back); wire_button(back)
	var text := S.column(2); text.size_flags_horizontal = SIZE_EXPAND_FILL; footer.add_child(text)
	counter = UI.label("", 17, S.CYAN); text.add_child(counter)
	notice = UI.label("Tap a soldier to inspect" if Phone.touch_device() else "Click a soldier to inspect  ·  Esc returns to the lineup", 14, S.MUTED); text.add_child(notice)
	if Phone.narrow(Phone.window_size()): notice.hide()
	deploy = S.button("DEPLOY >" if Phone.touch_device() else "DEPLOY →", _deploy); deploy.custom_minimum_size = Vector2(210, 48)
	if Phone.narrow(Phone.window_size()): deploy.custom_minimum_size = Vector2(100, 56)
	deploy.add_theme_font_size_override("font_size", 19)
	deploy.add_theme_stylebox_override("normal", S.box(Color("254651"), S.CYAN, 12)); footer.add_child(deploy); wire_button(deploy)
	if from_temple: deploy.hide()

func _layout() -> void:
	if not is_instance_valid(header): return
	var compact := Phone.narrow(Phone.window_size())
	var raw_safe := Phone.safe_margins(size)
	var safe := Vector4(maxf(0.0, raw_safe.x), maxf(0.0, raw_safe.y), maxf(0.0, raw_safe.z), maxf(0.0, raw_safe.w))
	if compact != compact_layout:
		compact_layout = compact; _draw_cards()
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	if compact:
		card_row.add_theme_constant_override("separation", 8)
		header.visible = focus_index < 0
		counter.visible = focus_index < 0
		footer.visible = true
		swap_button.visible = focus_index >= 0
		swap_button.position = Vector2(safe.x + 9, safe.y + 10); swap_button.size = Vector2(92, 44)
		skill_confirm.visible = focus_index >= 0 and armory_skills
		skill_confirm.position = Vector2(safe.x + 9, safe.y + 60); skill_confirm.size = Vector2(110, 44)
		footer_bg.position = Vector2(0, size.y - safe.w - 70); footer_bg.size = Vector2(size.x, 70)
		header.position = Vector2(safe.x + 6, safe.y + 5)
		header.size = Vector2(size.x - safe.x - safe.z - 12, 64)
		_footer_rect(12 + safe.x, -66 - safe.w, -12 - safe.w)
		if focus_index >= 0:
			stage_container.custom_minimum_size.y = 0
			if size.x < 500:
				stage_container.position = Vector2(0, safe.y)
				stage_container.size = Vector2(size.x, maxf(184.0, size.y * 0.45) if from_temple else 184.0)
				stage.camera.keep_aspect = Camera3D.KEEP_HEIGHT
				stage.camera.fov = 30.0
				card_scroll.visible = false
				card_scroll.process_mode = Node.PROCESS_MODE_DISABLED
				drawer.position = Vector2(safe.x + 12, safe.y + stage_container.size.y + 8)
				drawer.size = Vector2(size.x - safe.x - safe.z - 24, size.y - safe.y - safe.w - stage_container.size.y - 90)
			else:
				stage_container.position = Vector2(0, safe.y + 4)
				stage_container.size = Vector2(249.0 if Phone.window_size().x <= 900 else 168.0, size.y - safe.y - safe.w - 120.0)
				stage.camera.v_offset = -0.5 if Phone.window_size().x <= 900 else 0.0
				card_scroll.visible = true
				card_scroll.process_mode = Node.PROCESS_MODE_INHERIT
				card_scroll.position = Vector2(safe.x + 6, size.y - safe.w - 117)
				card_scroll.size = Vector2(size.x - safe.x - safe.z - 12, 86)
				drawer.position = Vector2(stage_container.size.x + 6, safe.y + 4)
				drawer.size = Vector2(size.x - safe.z - stage_container.size.x - 12, size.y - safe.y - safe.w - 74)
		else:
			stage_container.position = Vector2(0, 64)
			stage_container.custom_minimum_size.y = 0
			stage_container.size = Vector2(size.x, maxf(110, size.y - safe.y - safe.w - 228))
			card_scroll.visible = true
			card_scroll.process_mode = Node.PROCESS_MODE_INHERIT
			card_scroll.position = Vector2(safe.x + 6, size.y - safe.w - 164)
			card_scroll.size = Vector2(size.x - safe.x - safe.z - 12, 86)
		stage_container.custom_minimum_size.y = stage_container.size.y
		card_row.reset_size()
		_sync_roster_visibility()
		_layout_drawer_children()
		return
	card_row.add_theme_constant_override("separation", 6)
	header.visible = true
	counter.visible = true
	card_scroll.modulate.a = 1.0
	card_scroll.process_mode = Node.PROCESS_MODE_INHERIT
	header.position = Vector2(24, 16); header.size = Vector2(size.x - 48, 100)
	_footer_rect(24, -80, -12)
	footer.visible = true
	swap_button.visible = focus_index >= 0
	swap_button.position = Vector2(24, 132); swap_button.size = Vector2(92, 44)
	skill_confirm.visible = focus_index >= 0 and armory_skills
	skill_confirm.position = Vector2(24, 182); skill_confirm.size = Vector2(110, 44)
	footer_bg.position = Vector2(0, size.y - 84); footer_bg.size = Vector2(size.x, 84)
	var stage_width := 480.0 if focus_index >= 0 else size.x
	stage_container.position = Vector2(0, 120)
	stage_container.custom_minimum_size.y = 0
	stage_container.size = Vector2(stage_width, maxf(160, size.y - 310))
	stage_container.custom_minimum_size.y = maxf(160, size.y - 310)
	card_scroll.visible = true
	card_scroll.position = Vector2(24, size.y - 180)
	card_scroll.size = Vector2(size.x - 48, 94)
	drawer.position = Vector2(492, 128)
	drawer.size = Vector2(size.x - 516, size.y - 312)
	card_row.reset_size(); card_row.size.x = size.x - 48
	_layout_drawer_children()

func _sync_roster_visibility() -> void:
	if not is_instance_valid(card_scroll): return
	var phone_focus := focus_index >= 0 and Phone.narrow(Phone.window_size())
	if phone_focus and size.x < 500:
		card_scroll.visible = false
		return
	var compact_strip := card_scroll.size.x <= 350.0
	card_scroll.visible = true
	card_scroll.modulate.a = 0.0 if phone_focus and not compact_strip else 1.0
	move_child(card_scroll, 0 if phone_focus and not compact_strip else -1)
	for card in cards.values():
		var button: Button = card.get_child(0).get_child(0)
		button.disabled = phone_focus and not compact_strip

func _layout_drawer_children() -> void:
	if not is_instance_valid(drawer_content) or drawer_content.get_parent() != drawer: return
	drawer_content.position = Vector2(12, 12)
	drawer_content.size = drawer.size - Vector2(24, 24)
	var top := 0.0
	for child in drawer_content.get_children():
		child.position = Vector2(0, top)
		if child is ScrollContainer:
			child.size = Vector2(drawer_content.size.x, maxf(44, drawer_content.size.y - top))
		else:
			child.size = Vector2(drawer_content.size.x, 44)
			top += 52.0 if Phone.narrow(Phone.window_size()) else 46.0

func _footer_rect(margin: float, top: float, bottom: float) -> void:
	footer.anchor_left = 0.0; footer.anchor_right = 1.0
	footer.anchor_top = 1.0; footer.anchor_bottom = 1.0
	footer.offset_left = margin; footer.offset_right = -margin
	footer.offset_top = top; footer.offset_bottom = bottom

func _portrait(r: Dictionary) -> void:
	var viewport := SubViewport.new(); viewport.name = "Portrait_" + str(r.id)
	viewport.size = Vector2i(100, 112); viewport.own_world_3d = true; viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE; add_child(viewport)
	var world := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1c303b"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d4e6ed"); env.ambient_light_energy = 1.0; world.environment = env; viewport.add_child(world)
	var actor := Actor.new(); viewport.add_child(actor); actor.setup(r, true)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-25, -25, 0); light.light_energy = 1.5; viewport.add_child(light)
	var camera := Camera3D.new(); camera.position = Vector3(0, 1.85, 2); camera.fov = 27; viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.65, 0))
	portraits[str(r.id)] = viewport; portrait_actors[str(r.id)] = actor

func _refresh() -> void:
	var c = flow.session()
	_draw_cards()
	var roster: Array = selected.map(func(id): return c.soldier(str(id)))
	stage.show_squad(roster); stage.focus_slot(focus_index)
	UI.ensure_phone_type(stage)
	counter.text = "%d / %d IN SQUAD" % [selected.size(), capacity] if from_temple else "%d / %d READY FOR DEPLOYMENT" % [selected.size(), capacity]
	if Phone.narrow(Phone.window_size()):
		counter.text = "%d/%d SQUAD" % [selected.size(), capacity] if from_temple else "%d/%d READY" % [selected.size(), capacity]
		counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	deploy.disabled = not preload("res://scripts/campaign/strat_deployment.gd").validate(c, selected, c.state.get("launch_option",{}))
	resources.text = "%d Cr   /   %d Intel   /   %d Kyber" % [c.state.res.credits, c.state.res.intel, c.state.res.kyber]
	if Phone.narrow(Phone.window_size()): resources.text = "Cr %d  ·  Intel %d  ·  Ky %d" % [c.state.res.credits, c.state.res.intel, c.state.res.kyber]
	if focus_index >= selected.size(): focus_index = -1
	if focus_index >= 0: _build_drawer()
	_layout()
	UI.ensure_phone_type(self)


func _draw_cards() -> void:
	var c = flow.session()
	S.clear(card_row); cards.clear()
	for i in selected.size():
		var r: Dictionary = c.soldier(str(selected[i]))
		var card := Details.card(c, r, inspect.bind(i), _portrait_texture(r)); card_row.add_child(card); cards[str(r.id)] = card
		if Phone.narrow(Phone.window_size()):
			# Three readable cards fit a portrait strip; the rest remain swipeable.
			card.custom_minimum_size.x = 138.0 if size.x < 500.0 else 150.0
		if focus_index == i: card.add_theme_stylebox_override("panel", S.box(Color("213a42"), S.CYAN, 8))
		var button: Button = card.get_child(0).get_child(0); wire_button(button)
		button.mouse_entered.connect(func(): stage.highlight(i))
		button.mouse_exited.connect(func(): stage.highlight(-1))

func inspect(index: int) -> void:
	if index < 0 or index >= selected.size(): return
	focus_index = index; drawer_tab = "arsenal"; armory_skills = false; armory_slot = ""
	if from_temple:
		flow.session().state.armory_selected_id = str(selected[index])
		flow.save()
	drawer.show(); stage.focus_slot(index); _draw_cards(); _layout(); _build_drawer(); _layout()
	drawer.modulate.a = 0.0; create_tween().tween_property(drawer, "modulate:a", 1.0, 0.22)

func close_inspector() -> void:
	focus_index = -1; drawer.hide(); stage.focus_slot(-1); _draw_cards(); _layout()

func _build_drawer() -> void:
	S.clear(drawer); choices.clear()
	drawer_content = Control.new(); drawer.add_child(drawer_content)
	var r: Dictionary = flow.session().soldier(str(selected[focus_index]))
	var compact := Phone.narrow(Phone.window_size())
	if not compact:
		drawer_content.add_child(UI.label(str(r.n), 22))
	var stats := Gear.battle_stats(flow.session(), str(r.id))
	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation", 8 if compact else 4); drawer_content.add_child(tabs)
	for tab in (["arsenal", "roster", "medical", "skills"] if from_temple else ["arsenal", "skills"]):
		var label: String = ({"arsenal":"GEAR", "roster":"TEAM", "medical":"CARE", "skills":"SKILL"} if compact else {"arsenal":"GEAR", "roster":"SQUAD", "medical":"MEDICAL", "skills":"SKILLS"})[tab]
		var b := S.button(label, _tab_armory_skills if tab == "skills" else _tab.bind(tab)); b.size_flags_horizontal = SIZE_SHRINK_BEGIN
		b.custom_minimum_size.y = 44
		b.modulate = S.CYAN if (tab == "skills" and armory_skills) or (drawer_tab == tab and not armory_skills) else Color.WHITE
		tabs.add_child(b); wire_button(b)
	if not compact or size.x >= 500:
		var close := S.button("×", close_inspector); close.custom_minimum_size = Vector2(44, 44)
		tabs.add_child(close); wire_button(close)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; drawer_content.add_child(scroll)
	if drawer_tab == "arsenal":
		arsenal = Arsenal.new(); arsenal.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(arsenal); arsenal.setup(self, str(r.id))
		if armory_skills: arsenal._show_skills()
	elif drawer_tab == "medical":
		var list := S.column(8); list.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(list)
		list.add_child(UI.label("PATIENTS  /  RECOVERY", 14, S.CYAN))
		for entry in People25.groups(flow.session()).Wounded:
			var line := S.panel(); list.add_child(line)
			var body := S.column(5); line.add_child(body)
			body.add_child(UI.label("%s · return in about %d days" % [entry.name, entry.eta], 14, S.GOLD))
			for action in patient_actions25(entry.id):
				var button_text := "%s · %d days" % [action.label, int(action.days)] if bool(action.enabled) else "%s unavailable" % action.label
				var button := S.button(button_text, apply_patient_action25.bind(entry.id, action.id), bool(action.enabled))
				button.custom_minimum_size.y = 44; body.add_child(button); wire_button(button)
				var effect := UI.label(str(action.effect), 14, S.MUTED)
				effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_child(effect)
	else:
		var list := S.column(8); list.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(list)
		var fill := S.button("BEST READY SQUAD", best_ready_fill25); fill.custom_minimum_size.y = 44; list.add_child(fill); wire_button(fill)
		for group_name in ["Ready", "Tired", "Wounded"]:
			var entries: Array = People25.groups(flow.session())[group_name]
			list.add_child(UI.label("%s  /  %d" % [group_name.to_upper(), entries.size()], 14, S.CYAN))
			for entry in entries: _roster_row(list, flow.session().soldier(entry.id))
	UI.ensure_phone_type(drawer)

func _confirm_skill() -> void:
	if not is_instance_valid(arsenal): return
	var tree = arsenal.picker.get_node_or_null("SkillTree")
	if tree != null: tree._confirm()

func _tab(tab: String) -> void:
	drawer_tab = tab; armory_skills = false; _layout(); _build_drawer(); _layout()
	drawer_content.modulate.a = 0.3; create_tween().tween_property(drawer_content, "modulate:a", 1.0, 0.16)

func _tab_armory_skills() -> void:
	drawer_tab = "arsenal"; armory_skills = true; _layout(); _build_drawer(); _layout()

func _roster_row(parent: VBoxContainer, r: Dictionary) -> void:
	var id := str(r.id); var fit := Details.fit(r)
	var row := HBoxContainer.new(); parent.add_child(row)
	var portrait := TextureRect.new(); portrait.texture = _portrait_texture(r)
	portrait.custom_minimum_size = Vector2(56, 70); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; row.add_child(portrait)
	if not fit: portrait.modulate = Color("69747a")
	var col := S.column(3); col.size_flags_horizontal = SIZE_EXPAND_FILL; row.add_child(col)
	var label := str(r.n) + ("  ✓" if selected.has(id) else "")
	var b := S.button(label, swap_soldier.bind(id), fit and not selected.has(id))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.icon = S.icon(str(r.cls).to_lower()); b.clip_text = true
	col.add_child(b); choices[id] = b; wire_button(b)
	var update_name := func() -> void:
		var suffix := "  ✓" if selected.has(id) else ""
		b.text = Details.visible_name(str(r.n), maxf(12.0, b.size.x - 50.0 - ThemeDB.fallback_font.get_string_size(suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)) + suffix
	b.resized.connect(update_name)
	update_name.call_deferred()
	col.add_child(UI.label("%s · R%d · %s" % [r.cls, int(r.rank), Details.nickname(r)], 14, S.MUTED))
	var status_text := "WOUNDED · return ~%d days" % People25.eta(flow.session(), r) if int(r.get("wound", 0)) > 0 else Details.status(flow.session(), r) + (" · fully ready ~%d days" % People25.eta(flow.session(), r) if People25.eta(flow.session(), r) > 0 else "")
	var status := UI.label(status_text, 14, S.GREEN if fit else S.RED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; col.add_child(status)

func _portrait_texture(r: Dictionary) -> Texture2D:
	if JediModels.id_for({"name":str(r.n)}) != "" and Progression.is_jedi(r):
		return StoryPortraits.display_texture(str(r.n))
	return portraits[str(r.id)].get_texture()

func swap_soldier(id: String) -> bool:
	if focus_index < 0 or selected.has(id) or not Details.fit(flow.session().soldier(id)): return false
	selected[focus_index] = id; _persist_selection(); _refresh()
	notice.text = "Squad updated · %s ready" % flow.session().soldier(id).n
	return true

func _toggle(id: String) -> void:
	# Preserve the existing automation/API contract, including remove then add.
	if selected.has(id): selected.erase(id)
	elif selected.size() < capacity and Details.fit(flow.session().soldier(id)): selected.append(id)
	focus_index = -1; drawer.hide(); _persist_selection(); _refresh()

func _persist_selection() -> void:
	var c = flow.session()
	if from_temple:
		if focus_index >= 0: c.state.armory_selected_id = str(selected[focus_index])
		flow.save()
		return
	c.state.loadout_squad = selected.duplicate()
	if not c.state.pending_mission.is_empty(): c.state.pending_mission.squad = selected.duplicate()
	flow.save()

func change_gear(action: String, kind: String = "", key: String = "") -> bool:
	if focus_index < 0: return false
	var c = flow.session(); var id := str(selected[focus_index]); var r: Dictionary = c.soldier(id)
	var changed := false
	match action:
		"weapon": changed = Gear.buy_weapon(c, id)
		"saber": changed = Gear.craft_saber(c, id)
		"armor": changed = Gear.buy_armor(c, id, key)
		"utility": changed = Gear.buy_utility(c, id, key)
		"form": changed = Gear.set_form(c, id, key)
		"evolve": changed = Gear.evolve(c, id)
		"fit": changed = Gear.fit_module(c, id, kind, key)
		"upgrade": changed = Gear.upgrade_module(c, id, kind, key)
		"remove":
			if Gear.MOD_KEY.has(kind) and key in r.gear.get(Gear.MOD_KEY[kind], []):
				r.gear[Gear.MOD_KEY[kind]].erase(key); r.gear.mk.erase(kind + "." + key); changed = true
		"color":
			if key in (preload("res://scripts/campaign/data.gd").get_table("gear", "CRYSTALS").values() if preload("res://scripts/campaign/progression.gd").is_jedi(r) else ["#e0bd78", "#d9a05b", "#9fc6d6", "#c9d27a", "#d6a3a3"]): r.col = key; changed = true
	if changed:
		flow.save()
		remove_child(portraits[id]); portraits[id].queue_free(); _portrait(r)
		_refresh(); notice.text = "Loadout saved · stats and equipment updated"
	else: notice.text = "Unavailable · check credits, research, wing level and free slots"
	return changed

func wire_button(button: Button) -> void:
	UI.style_button(button)
	button.mouse_entered.connect(func(): if audio and not button.disabled: audio.play())
	button.pressed.connect(func(): if is_instance_valid(audio) and audio.is_inside_tree(): audio.play())

func _make_audio() -> void:
	audio = AudioStreamPlayer.new(); audio.volume_db = -28; add_child(audio)
	var synth := preload("res://scripts/audio.gd").new(); audio.stream = synth._synthesize("click"); synth.free()
	hum = AudioStreamPlayer.new(); hum.volume_db = -36; add_child(hum)
	var wav := AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = 22050
	var samples := PackedByteArray(); samples.resize(22050 * 2)
	for i in 22050:
		var t := float(i) / 22050.0
		samples.encode_s16(i * 2, int((sin(TAU * 110 * t) * 0.5 + sin(TAU * 221 * t) * 0.15) * 10000))
	wav.data = samples; wav.loop_mode = AudioStreamWAV.LOOP_FORWARD; wav.loop_end = 22050; hum.stream = wav; hum.play()

func _process(_delta: float) -> void:
	if is_instance_valid(footer):
		var compact := Phone.narrow(Phone.window_size())
		var safe := Phone.safe_margins(size) if compact else Vector4.ZERO
		var margin := 12.0 + maxf(0.0, safe.x) if compact else 24.0
		var top := -66.0 - maxf(0.0, safe.w) if compact else -80.0
		var bottom := -12.0 - maxf(0.0, safe.w) if compact else -12.0
		if absf(footer.offset_top - top) > 1.0 or absf(footer.offset_left - margin) > 1.0:
			_footer_rect(margin, top, bottom)
	if not is_instance_valid(stage_container) or focus_index >= 0: return
	var mouse := get_local_mouse_position()
	var index := -1
	if stage_container.get_rect().has_point(mouse): index = clampi(int(mouse.x / (size.x / maxf(1, selected.size()))), 0, selected.size() - 1)
	if index != hover_index:
		hover_index = index; stage.highlight(index)
		if index >= 0 and audio: audio.play()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_inspector(); get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and focus_index < 0 and stage_container.get_global_rect().has_point(event.position):
		inspect(clampi(int(event.position.x / (size.x / maxf(1, selected.size()))), 0, selected.size() - 1)); get_viewport().set_input_as_handled()

func _deploy() -> void:
	var c = flow.session()
	var was_locked := bool(c.state.get("skill_picks_locked", false))
	c.state.skill_picks_locked = true
	for soldier in c.state.roster: soldier.skill_picks_locked = true
	if not flow.launch_squad(selected):
		c.state.skill_picks_locked = was_locked
		for soldier in c.state.roster: soldier.skill_picks_locked = was_locked
		notice.text = "Deployment unavailable; review squad readiness and mission requirements."
