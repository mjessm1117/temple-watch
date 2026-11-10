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
var header: PanelContainer
var drawer: PanelContainer
var drawer_content: VBoxContainer
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
	var bg := ColorRect.new(); bg.color = S.BG; bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(bg)
	_build_stage(); _build_header(); _build_footer()
	card_row = HBoxContainer.new(); card_row.add_theme_constant_override("separation", 6)
	card_scroll = preload("res://scripts/touch_scroll.gd").new(); card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(card_scroll); card_scroll.add_child(card_row)
	drawer = S.panel(); add_child(drawer); drawer.hide()
	for r in c.state.roster: _portrait(r)
	_make_audio()
	resized.connect(_layout)
	_refresh(); _layout()

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
	if not compact: title.add_child(S.label("JEDI TEMPLE  /  HANGAR 07  /  DEPLOYMENT", 12, S.CYAN))
	title.add_child(S.label("SQUAD LOADOUT", 20 if compact else 32))
	if not compact: title.add_child(S.label("Choose up to %d. Equip for the mission. Bring everyone home." % capacity, 13, S.MUTED))
	var info := S.column(5); row.add_child(info)
	resources = S.label("", 14, S.GOLD); resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; info.add_child(resources)
	var option: Dictionary = flow.session().state.get("launch_option", {})
	var mission := str(option.get("n", option.get("mission", "Detention Line"))).to_upper().replace("_", " ")
	info.add_child(S.label("OPERATION  /  " + mission, 12 if compact else 16, S.CYAN))
	var mission_id := str(option.get("mission", "rescue"))
	var hint := "Select a soldier to inspect gear or swap with the roster."
	if preload("res://scripts/campaign/battle_bridge.gd").map_path(mission_id).ends_with("rescue.json") and mission_id != "rescue":
		hint = "Battlefield: Detention Line · free Mira and reach evacuation."
	if not compact: info.add_child(S.label(hint, 12, S.MUTED))

func _build_footer() -> void:
	footer = HBoxContainer.new(); footer.add_theme_constant_override("separation", 16); add_child(footer)
	var back := S.button("Temple" if Phone.touch_device() else "← Temple", func(): flow.go("temple")); footer.add_child(back); wire_button(back)
	var text := S.column(2); text.size_flags_horizontal = SIZE_EXPAND_FILL; footer.add_child(text)
	counter = S.label("", 17, S.CYAN); text.add_child(counter)
	notice = S.label("Tap a soldier to inspect" if Phone.touch_device() else "Click a soldier to inspect  ·  Esc returns to the lineup", 12, S.MUTED); text.add_child(notice)
	if Phone.narrow(Phone.window_size()): notice.hide()
	deploy = S.button("DEPLOY >" if Phone.touch_device() else "DEPLOY →", _deploy); deploy.custom_minimum_size = Vector2(210, 48)
	if Phone.narrow(Phone.window_size()): deploy.custom_minimum_size = Vector2(100, 56)
	deploy.add_theme_font_size_override("font_size", 19)
	deploy.add_theme_stylebox_override("normal", S.box(Color("254651"), S.CYAN, 12)); footer.add_child(deploy); wire_button(deploy)

func _layout() -> void:
	if not is_instance_valid(header): return
	var compact := Phone.narrow(Phone.window_size())
	var safe := Phone.safe_margins(size)
	if compact != compact_layout:
		compact_layout = compact; _draw_cards()
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if compact:
		card_row.add_theme_constant_override("separation",8)
		header.visible = focus_index < 0; footer.visible = focus_index < 0
		header.position = Vector2(safe.x + 6, safe.y + 5); header.size = Vector2(size.x - safe.x - safe.z - 12, 56)
		_footer_rect(6, -78, -6)
		footer.offset_left += safe.x; footer.offset_right -= safe.z
		footer.offset_top -= safe.w; footer.offset_bottom -= safe.w
		if focus_index >= 0:
			stage_container.position = Vector2(0, 4); stage_container.size = Vector2(168, size.y - 88)
			card_scroll.position = Vector2(safe.x + 6, size.y - safe.w - 84); card_scroll.size = Vector2(size.x - safe.x - safe.z - 12, 80)
			drawer.position = Vector2(174, safe.y + 4); drawer.size = Vector2(size.x - safe.z - 180, size.y - safe.y - safe.w - 88)
		else:
			stage_container.position = Vector2(0, 64); stage_container.size = Vector2(size.x, 78)
			card_scroll.position = Vector2(safe.x + 6, safe.y + 146); card_scroll.size = Vector2(size.x - safe.x - safe.z - 12, maxf(65, size.y - safe.y - safe.w - 200))
		stage_container.custom_minimum_size.y = stage_container.size.y
		card_scroll.visible = true; stage_container.visible = true
		card_row.reset_size()
		return
	card_row.add_theme_constant_override("separation",6)
	header.position = Vector2(24, 16); header.size = Vector2(size.x - 48, 100)
	_footer_rect(24, -80, -8)
	var width := size.x - (536 if focus_index >= 0 else 0)
	stage_container.position = Vector2(0, 120); stage_container.size = Vector2(width, maxf(160, size.y - 270))
	stage_container.custom_minimum_size.y = maxf(160, size.y - 270)
	card_scroll.position = Vector2(24, size.y - 180); card_scroll.size = Vector2(width - 48, 94)
	drawer.position = Vector2(size.x - 524, 128); drawer.size = Vector2(500, size.y - 204)
	card_row.reset_size()
	card_row.size.x = width - 48

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
	counter.text = "%d / %d READY FOR DEPLOYMENT" % [selected.size(), capacity]
	deploy.disabled = not preload("res://scripts/campaign/strat_deployment.gd").validate(c, selected, c.state.get("launch_option",{}))
	resources.text = "%d Cr   /   %d Intel   /   %d Kyber" % [c.state.res.credits, c.state.res.intel, c.state.res.kyber]
	if focus_index >= selected.size(): focus_index = -1
	if focus_index >= 0: _build_drawer()
	_layout()


func _draw_cards() -> void:
	var c = flow.session()
	S.clear(card_row); cards.clear()
	for i in selected.size():
		var r: Dictionary = c.soldier(str(selected[i]))
		var card := Details.card(c, r, inspect.bind(i), _portrait_texture(r)); card_row.add_child(card); cards[str(r.id)] = card
		if Phone.narrow(Phone.window_size()) and size.x > 700.0:
			card.custom_minimum_size.x = minf(166.0,(size.x-26.0-8.0*6.0)/7.0)
		if focus_index == i: card.add_theme_stylebox_override("panel", S.box(Color("213a42"), S.CYAN, 8))
		var button: Button = card.get_child(0).get_child(0); wire_button(button)
		button.mouse_entered.connect(func(): stage.highlight(i))
		button.mouse_exited.connect(func(): stage.highlight(-1))

func inspect(index: int) -> void:
	if index < 0 or index >= selected.size(): return
	focus_index = index; drawer_tab = "arsenal"; armory_skills = false; armory_slot = ""
	drawer.show(); stage.focus_slot(index); _draw_cards(); _build_drawer(); _layout()
	drawer.modulate.a = 0.0; create_tween().tween_property(drawer, "modulate:a", 1.0, 0.22)

func close_inspector() -> void:
	focus_index = -1; drawer.hide(); stage.focus_slot(-1); _draw_cards(); _layout()

func _build_drawer() -> void:
	S.clear(drawer); choices.clear()
	drawer_content = S.column(9); drawer.add_child(drawer_content)
	var r: Dictionary = flow.session().soldier(str(selected[focus_index]))
	var compact := Phone.narrow(Phone.window_size())
	if not compact:
		var top := HBoxContainer.new(); drawer_content.add_child(top)
		var title := S.label(str(r.n), 22); title.size_flags_horizontal = SIZE_EXPAND_FILL; top.add_child(title)
		top.add_child(S.label("%d Cr · %d Ky" % [flow.session().state.res.credits, flow.session().state.res.kyber], 11, S.GOLD))
		var close := S.button("×", close_inspector); close.custom_minimum_size = Vector2(44, 44)
		close.tooltip_text = "Return to lineup" if Phone.touch_device() else "Return to lineup (Esc)"; top.add_child(close); wire_button(close)
	var stats := Gear.battle_stats(flow.session(), str(r.id))
	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation", 8 if compact else 4); drawer_content.add_child(tabs)
	for tab in ["roster", "arsenal", "skills"]:
		var label := "SWAP" if tab == "roster" and compact else "SWAP SOLDIER" if tab == "roster" else "SKILLS" if tab == "skills" else "GEAR" if compact else "ARMORY"
		var b := S.button(label, _tab_armory_skills if tab == "skills" else _tab.bind(tab)); b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.modulate = S.CYAN if (tab == "skills" and armory_skills) or (drawer_tab == tab and not armory_skills) else Color.WHITE
		tabs.add_child(b); wire_button(b)
	if compact:
		var close := S.button("×", close_inspector); close.custom_minimum_size = Vector2(44, 44)
		tabs.add_child(close); wire_button(close)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; drawer_content.add_child(scroll)
	if drawer_tab == "arsenal":
		arsenal = Arsenal.new(); arsenal.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(arsenal); arsenal.setup(self, str(r.id))
		if armory_skills: arsenal._show_skills()
	else:
		var list := S.column(8); list.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(list)
		list.add_child(S.label("ROSTER  /  %d SOLDIERS" % flow.session().state.roster.size(), 12, S.CYAN))
		for soldier in flow.session().state.roster: _roster_row(list, soldier)

func _tab(tab: String) -> void:
	drawer_tab = tab; armory_skills = false; _build_drawer()
	drawer_content.modulate.a = 0.3; create_tween().tween_property(drawer_content, "modulate:a", 1.0, 0.16)

func _tab_armory_skills() -> void:
	drawer_tab = "arsenal"; armory_skills = true; _build_drawer()

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
	col.add_child(S.label("%s · R%d · %s" % [r.cls, int(r.rank), Details.nickname(r)], 11, S.MUTED))
	var status := S.label(Details.status(flow.session(), r), 11, S.GREEN if fit else S.RED)
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
	var c = flow.session(); c.state.loadout_squad = selected.duplicate()
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
	button.mouse_entered.connect(func(): if audio and not button.disabled: audio.play())
	button.pressed.connect(func(): if audio: audio.play())

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
		var desired := -78.0 if Phone.narrow(Phone.window_size()) else -80.0
		if absf(footer.offset_top - desired) > 1.0: _footer_rect(6 if desired == -78.0 else 24, desired, -6 if desired == -78.0 else -8)
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
	if not flow.launch_squad(selected): notice.text = "Deployment unavailable; review squad readiness and mission requirements."
