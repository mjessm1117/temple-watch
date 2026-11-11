extends Control
const Campaign = preload("res://scripts/campaign/state.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const PromotionScreen = preload("res://scripts/campaign/promotion_screen.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Modules = preload("res://scripts/campaign/modules.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const StrategyUI = preload("res://scripts/campaign/strat_ui.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const HomeBadges = preload("res://scripts/campaign/home_badges.gd")
const HomeTabs = preload("res://scripts/campaign/home_tabs.gd")
const HomeResources = preload("res://scripts/campaign/home_resources.gd")
const GalaxyCard = preload("res://scripts/campaign/home12_galaxy_card.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
const Squad = preload("res://scripts/campaign/squad.gd")
var build_slot := "b0"
var field_team: Array = []
var edict_draft: Array = []
var campaign: Campaign = Campaign.new()
var page := "Command"
var selected_id := "u1"
var page_content: VBoxContainer
var status_label: Label
var notice_label: Label
var nav_buttons: Dictionary = {}
var temple_view: Control
var station_panel: PanelContainer
var panel_open := false
var panel_tween: Tween
var selected_room := ""
const TempleView = preload("res://scripts/campaign/temple_view.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var room_picker: PanelContainer
var phone_grid: Control
var mini_galaxy: Control
var more_panel: PanelContainer

func _ready() -> void:
	campaign = get_node("/root/CampaignFlow").session()
	get_node("/root/CampaignFlow").active = true
	var remembered_id := str(campaign.state.get("armory_selected_id", ""))
	if remembered_id != "": selected_id = remembered_id
	if campaign.soldier(selected_id).is_empty() and not campaign.state.roster.is_empty(): selected_id = str(campaign.state.roster[0].id)
	edict_draft = campaign.state.strategy.edict.duplicate()
	_build_shell()
	if not campaign.state.events11.summary.is_empty() and not bool(campaign.state.events11.summary.get("shown", false)):
		panel_open = true; campaign.state.events11.summary.shown = true
		get_node("/root/CampaignFlow").save()
	_show_page()
	if panel_open: _slide_station()
	if get_tree().current_scene == self: get_node("/root/CampaignFlow").temple_story.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var names := ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy"]
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			_change_page(names[event.keycode - KEY_1]); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and panel_open:
			_close_station(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			_open_galaxy(); get_viewport().set_input_as_handled()

func _build_shell() -> void:
	var compact := Phone.narrow(Phone.window_size())
	var portrait := compact and get_viewport_rect().size.x < get_viewport_rect().size.y
	var safe := Phone.safe_margins(get_viewport_rect().size)
	temple_view = TempleView.new(); add_child(temple_view); temple_view.setup(campaign.state, HomeBadges.collect(campaign))
	temple_view.room_selected.connect(_open_room)
	temple_view.room_hovered.connect(func(message: String): notice_label.text = message)
	var head := UI.panel(Color(0.035, 0.075, 0.09, 0.94)); add_child(head)
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.offset_left = safe.x + (12 if compact else 20); head.offset_right = -safe.z - (12 if compact else 20)
	head.offset_top = safe.y + (3 if compact else 14); head.offset_bottom = safe.y + (52 if compact else 106)
	if compact:
		var head_style: StyleBoxFlat = head.get_theme_stylebox("panel").duplicate()
		head_style.set_content_margin_all(6); head.add_theme_stylebox_override("panel", head_style)
	var rows := UI.column(5); head.add_child(rows)
	var title := HBoxContainer.new(); rows.add_child(title)
	var brand := UI.label("TEMPLE WATCH", 18 if compact else 27, Color("78d2df")); brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.add_child(brand)
	if compact:
		var rooms_button := UI.button("ROOMS", _toggle_rooms); rooms_button.name = "RoomsDrawer"; rooms_button.custom_minimum_size.y = 44
		title.add_child(rooms_button)
	status_label = UI.label("", 15, UI.GOLD); title.add_child(status_label)
	var resources := HBoxContainer.new(); resources.add_theme_constant_override("separation", 8 if compact else 18)
	rows.add_child(resources)
	if compact: resources.hide()
	HomeResources.add_row(resources, campaign)
	resources.add_child(HomeResources.power_label(campaign))
	resources.add_child(UI.label("Order Darkness  %d/100" % int(campaign.state.orderDark), 13, Color("b5a2d3")))
	if compact and Phone.logical_size(Phone.window_size()).x < 700:
		resources.get_node("Resource_credits").text = "Cr %d" % int(campaign.state.res.credits)
		resources.get_node("Resource_intel").text = "Intel %d" % int(campaign.state.res.intel)
		resources.get_node("Resource_kyber").text = "Kyber %d" % int(campaign.state.res.kyber)
		resources.get_node("Resource_favor").hide()
		resources.get_node("Resource_recruits").hide()
		resources.get_node("PowerStatus").text = "Power %d/%d" % [Base.power(campaign.state).used, Base.power(campaign.state).capacity]
		resources.get_child(resources.get_child_count() - 1).text = "Dark %d" % int(campaign.state.orderDark)
	if not compact:
		var era_label := UI.label("JEDI TEMPLE  /  %s" % {1:"OLD REPUBLIC", 2:"NEW SITH WARS", 3:"HIGH REPUBLIC"}.get(int(campaign.state.era), "REPUBLIC"), 13, UI.MUTED)
		era_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; era_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; resources.add_child(era_label)
	else:
		for label in resources.get_children(): label.add_theme_font_size_override("font_size", 11)
	for row in [title, resources]:
		for child in row.get_children():
			if child is Label: child.autowrap_mode = TextServer.AUTOWRAP_OFF
	var foot_bg := ColorRect.new(); add_child(foot_bg); foot_bg.color = Color(0.02, 0.05, 0.065, 0.84)
	foot_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); foot_bg.offset_top = -116 if portrait else -64 if compact else -97
	foot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var footer := UI.column(7); add_child(footer); footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = safe.x + (12 if compact else 20); footer.offset_right = -safe.z - (12 if compact else 20)
	footer.offset_top = -safe.w - (112 if portrait else 60 if compact else 88); footer.offset_bottom = -safe.w - (12 if compact else 14)
	notice_label = UI.label("Select a room to manage the Order.  •  Gold: module ready  •  Dark: awaiting construction", 14, UI.MUTED)
	if compact: notice_label.hide()
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; footer.add_child(notice_label)
	var nav := GridContainer.new(); nav.columns = 3 if portrait else 6 if compact else 10
	nav.add_theme_constant_override("h_separation", 8 if compact else 7)
	nav.add_theme_constant_override("v_separation", 4); footer.add_child(nav)
	var names := ["Galaxy", "Arsenal", "Roster", "Research", "Build", "Command", "Legacy", "Teams", "Codex"]
	var titles := {"Galaxy":"Galaxy", "Arsenal":"Armory", "Roster":"Squad", "Research":"Archives", "Build":"Build", "Command":"Council", "Legacy":"Memorial", "Teams":"Teams", "Codex":"Journal"}
	for name in names:
		var target: String = "Council" if name == "Command" else name
		var button := UI.button(name, _change_page.bind(target)); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		HomeTabs.decorate(button, name)
		button.text = "   " + str(titles[name])
		if compact: button.add_theme_font_size_override("font_size", 14)
		button.mouse_entered.connect(func(): temple_view.sound.play())
		if not compact or name in ["Galaxy", "Roster", "Research", "Build", "Command"]: nav.add_child(button)
		nav_buttons[name] = button
	var menu_button := UI.button("Menu", func(): get_node("/root/CampaignFlow").go("menu"))
	menu_button.name = "MenuCommand"
	menu_button.custom_minimum_size.y = 44; menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if compact:
		var more := UI.button("More" if Phone.touch_device() else "⋯  More", _toggle_more); more.name = "MoreCommands"
		more.custom_minimum_size.y = 48; more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(more)
		more_panel = UI.panel(Color(0.045, 0.09, 0.115, 0.98)); add_child(more_panel)
		more_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		more_panel.offset_left = safe.x + 12; more_panel.offset_right = -safe.z - 12
		more_panel.offset_top = -168 if portrait else -116; more_panel.offset_bottom = -116 if portrait else -64
		var extras := HBoxContainer.new(); more_panel.add_child(extras)
		for name in ["Arsenal", "Legacy", "Teams", "Codex"]:
			var button: Button = nav_buttons[name]
			button.custom_minimum_size.y = 48; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			extras.add_child(button)
		extras.add_child(menu_button); more_panel.hide()
	else: nav.add_child(menu_button)
	var readout := UI.column(5); add_child(readout); readout.position = Vector2(25, 124); readout.size.x = 200
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	readout.add_child(UI.label("THE ORDER ENDURES", 13, UI.ACCENT))
	var active := 0; var wounded := 0; var built := 0
	for r in campaign.state.roster:
		if str(r.status) == "active": active += 1
		if int(r.wound) > 0: wounded += 1
	for level in campaign.state.wings.values():
		if int(level) > 0: built += 1
	readout.add_child(UI.label("%d active · %d wounded\n%d / 8 wings online\n%d missions waiting" % [active, wounded, built, campaign.state.options.size()], 13, UI.MUTED))
	readout.add_child(HomeResources.power_label(campaign))
	readout.add_child(UI.label("%d staff · squad %d\nSith Darkness %d / 12" % [campaign.state.facility.workers.size(), campaign.squad_capacity(), campaign.darkness_segments()], 13, UI.ACCENT))
	if not Phone.touch_device(): readout.add_child(UI.label("1–7 stations\nG galaxy · Esc close", 12, Color("627d87")))
	if compact: readout.hide()
	mini_galaxy = GalaxyCard.new(); add_child(mini_galaxy)
	mini_galaxy.setup(campaign, compact)
	mini_galaxy.opened.connect(_open_galaxy)
	mini_galaxy.position = Vector2(safe.x + (12 if compact else 25), safe.y + (56 if compact else 340))
	if portrait: mini_galaxy.hide()
	station_panel = UI.panel(UI.SURFACE_RAISED); add_child(station_panel)
	station_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	station_panel.anchor_left = 0.0 if portrait else 0.53 if compact else 0.55; station_panel.offset_left = safe.x + 12 if portrait else 0
	station_panel.anchor_top = 1.0 if portrait else 0.0
	station_panel.offset_top = -minf(440.0, get_viewport_rect().size.y * 0.53) if portrait else safe.y + (58 if compact else 113); station_panel.offset_right = -safe.z - 12 if portrait else -safe.z - 12 if compact else -20
	station_panel.offset_bottom = -safe.w - (118 if portrait else 66 if compact else 100)
	station_panel.visible = panel_open
	var column := UI.column(8); station_panel.add_child(column)
	var top := HBoxContainer.new(); column.add_child(top)
	var heading := UI.label("TEMPLE STATION", UI.TYPE_CAPTION, UI.GOLD); heading.name = "StationHeading"; heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(heading)
	top.add_child(UI.button("Temple view" if Phone.touch_device() else "← Temple view", _close_station))
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	page_content = UI.column(13); page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(page_content)
	if compact:
		_build_room_picker()
		if portrait: room_picker.show()
		phone_grid = null
	_sync_ui_safe_rect.call_deferred()

func _build_room_picker() -> void:
	var safe := Phone.safe_margins(get_viewport_rect().size)
	room_picker = UI.panel(UI.SURFACE_RAISED); room_picker.visible = false
	room_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var portrait := get_viewport_rect().size.x < get_viewport_rect().size.y
	room_picker.offset_left = safe.x + 12; room_picker.offset_right = -safe.z - 12
	room_picker.anchor_top = 1.0 if portrait else 0.0
	room_picker.offset_top = -minf(430.0, get_viewport_rect().size.y * 0.52) if portrait else safe.y + 58
	room_picker.offset_bottom = -safe.w - (118 if portrait else 66)
	add_child(room_picker)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	room_picker.add_child(scroll)
	var list := UI.column(8); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(list)
	var close := UI.button("SHOW TEMPLE" if portrait else "CLOSE ROOMS", _toggle_rooms); close.custom_minimum_size.y = 44; list.add_child(close)
	var ordered := ["war"]
	for id in temple_view.rooms:
		if id != "war" and not (not temple_view.rooms[id].built and temple_view.rooms[id].kind in ["spire", "vault", "annex"]): ordered.append(id)
	for id in temple_view.rooms:
		if not temple_view.rooms[id].built and temple_view.rooms[id].kind in ["spire", "vault", "annex"]: ordered.append(id)
	for id in ordered:
		if not temple_view.rooms.has(id): continue
		if not temple_view.rooms[id].built and temple_view.rooms[id].kind in ["spire", "vault", "annex"] and not list.has_node("SealedGroup"):
			var separator := UI.label("SEALED / LATER ROOMS", 14, UI.GOLD); separator.name = "SealedGroup"; list.add_child(separator)
		var info: Dictionary = temple_view.rooms[id]
		var key: String = TempleView.badge_key(str(id))
		var badge: Dictionary = HomeBadges.collect(campaign).get(key, {})
		var action := "  ·  %d %s" % [int(badge.count), str(badge.action)] if not badge.is_empty() else ""
		var button := UI.button("%s%s" % [info.name, action], _select_phone_room.bind(str(id)))
		button.name = "DrawerRoom_" + str(id); button.custom_minimum_size.y = 44
		list.add_child(button)

func _toggle_rooms() -> void:
	if room_picker != null: room_picker.visible = not room_picker.visible
	_sync_ui_safe_rect.call_deferred()

func _toggle_more() -> void:
	if more_panel != null: more_panel.visible = not more_panel.visible

func _select_phone_room(id: String) -> void:
	room_picker.hide()
	temple_view.activate_room(id)
	_sync_ui_safe_rect.call_deferred()

func _open_room(id: String, target: String) -> void:
	_change_page(target, id)

func _close_station() -> void:
	panel_open = false
	temple_view.restore_camera()
	if room_picker != null and get_viewport_rect().size.x < get_viewport_rect().size.y: room_picker.show()
	_sync_ui_safe_rect.call_deferred()
	HomeTabs.update(nav_buttons, HomeBadges.collect(campaign), page, panel_open)
	if panel_tween != null: panel_tween.kill()
	if Prefs.get_value("motion"):
		station_panel.hide(); return
	panel_tween = create_tween()
	panel_tween.tween_property(station_panel, "modulate:a", 0.0, 0.16)
	panel_tween.tween_callback(func(): station_panel.hide())

func _slide_station() -> void:
	if not panel_open: return
	if panel_tween != null: panel_tween.kill()
	if selected_room != "" and not Prefs.get_value("motion"):
		station_panel.hide()
		await get_tree().create_timer(0.5).timeout
		if not panel_open: return
	station_panel.show()
	_sync_ui_safe_rect.call_deferred()
	var portrait := get_viewport_rect().size.x < get_viewport_rect().size.y
	station_panel.offset_bottom = -Phone.safe_margins(get_viewport_rect().size).w - (118 if portrait else 66 if Phone.narrow(Phone.window_size()) else 100)
	if Prefs.get_value("motion"):
		station_panel.modulate.a = 1.0; return
	station_panel.modulate.a = 0.0
	station_panel.offset_left = 50; station_panel.offset_right = 30
	panel_tween = create_tween().set_parallel(true)
	panel_tween.tween_property(station_panel, "modulate:a", 1.0, 0.22)
	panel_tween.tween_property(station_panel, "offset_left", 12.0 if get_viewport_rect().size.x < get_viewport_rect().size.y else 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(station_panel, "offset_right", -12.0 if Phone.narrow(Phone.window_size()) else -20.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _refresh_shell() -> void:
	if panel_tween != null: panel_tween.kill()
	UI.clear(self)
	nav_buttons.clear()
	_build_shell()
	_show_page()
	if panel_open and selected_room != "" and temple_view.rooms.has(selected_room): temple_view.focus_room(selected_room)

func _change_page(name: String, room_id: String = "") -> void:
	selected_room = room_id
	if name == "Galaxy": _open_galaxy(); return
	if name == "Arsenal": Squad.open_from_temple(get_tree(), selected_id); return
	if name == "Settings": get_node("/root/CampaignFlow").open_settings(); return
	if name == "Codex": get_node("/root/CampaignFlow").open_codex(); return
	if room_id != "": temple_view.focus_room(room_id)
	page = name; panel_open = true; _show_page(); _slide_station()

func _show_page() -> void:
	UI.clear(page_content)
	var heading := station_panel.find_child("StationHeading", true, false) as Label
	if heading != null: heading.text = (str(temple_view.rooms[selected_room].name).to_upper() if selected_room != "" and temple_view.rooms.has(selected_room) else page.to_upper())
	HomeTabs.update(nav_buttons, HomeBadges.collect(campaign), page, panel_open)
	status_label.text = "M%d · D%d" % [int(campaign.state.month), int(campaign.state.day)] if Phone.narrow(Phone.window_size()) and Phone.logical_size(Phone.window_size()).x < 700 else "MONTH %d  ·  DAY %d  ·  WEEK %d" % [int(campaign.state.month), int(campaign.state.day), campaign.week()]
	if selected_room == "training" and page == "Roster":
		var training_room := preload("res://scripts/campaign/training_room19.gd").new()
		page_content.add_child(training_room)
		training_room.setup(campaign)
		training_room.changed.connect(func(): get_node("/root/CampaignFlow").save())
		return
	if page != "Research": page_content.add_child(UI.label(page.to_upper(), 30, UI.ACCENT))
	if page != "Research" and selected_room != "" and temple_view.rooms.has(selected_room):
		var room: Dictionary = temple_view.rooms[selected_room]
		var context := _card(str(room.name), str(room.status))
		if room.wing != "":
			context.add_child(UI.label(Base.summary(campaign.state, room.wing), 14, UI.ACCENT))
			context.add_child(UI.label(Base.production(campaign.state, room.wing), 14, UI.GOLD))
			context.add_child(UI.label("Battle: " + (str(preload("res://scripts/campaign/temple_rooms.gd").bonus(str(room.wing), int(room.level)).get("text", "")) if Base.operational(campaign.state, str(room.wing)) else "offline until power restored" if room.built else "build this room for a squad bonus"), 14, UI.ACCENT))
		elif room.built and room.kind in ["spire", "vault"]: context.add_child(UI.label(str(room.detail), 14, UI.ACCENT))
		if room.built and room.wing != "":
			var action: Dictionary = Data.get_table("temple", "MOD_ACTS")[room.wing]
			context.add_child(UI.label(str(action.desc), 15, UI.MUTED))
			context.add_child(UI.button(str(action.n), _module_action.bind(str(room.wing)), Modules.ready(campaign, str(room.wing)) and campaign.can_afford(action.cost)))
		elif room.kind in ["spire", "vault", "annex"] and not room.built:
			context.add_child(UI.label("Open Temple Works to excavate bays, construct spires and place new wings.", 14, UI.MUTED))
	match page:
		"Command": _command()
		"Roster": _roster()
		"Research": _research()
		"Build": StrategyUI.build(self)
		"Arsenal": _arsenal()
		"Teams": _teams()
		"Legacy": _legacy()
		"Council": StrategyUI.council(self)
		"Settings": StrategyUI.settings(self)

func _sync_ui_safe_rect() -> void:
	if not is_instance_valid(temple_view) or not temple_view.is_inside_tree() or not temple_view.has_method("set_ui_safe_rect"): return
	var covered := Rect2()
	if is_instance_valid(station_panel) and panel_open and station_panel.visible:
		covered = station_panel.get_global_rect()
	elif is_instance_valid(room_picker) and room_picker.visible:
		covered = room_picker.get_global_rect()
	temple_view.call("set_ui_safe_rect", covered)

func _card(title: String, description: String = "") -> VBoxContainer:
	var panel := UI.panel(UI.SURFACE_RAISED); page_content.add_child(panel)
	var box := UI.column(7); panel.add_child(box)
	box.add_child(UI.label(title, 21, UI.GOLD))
	if description != "": box.add_child(UI.label(description, 15, UI.MUTED))
	return box

func _command() -> void:
	var summary: Dictionary = campaign.state.events11.summary
	if not summary.is_empty():
		var report := _card("THIS MONTH · M%d D%d" % [int(summary.month),int(summary.day)],"Changes after your last mission")
		for line in summary.changes: report.add_child(UI.label(str(line),14))
		if summary.changes.is_empty(): report.add_child(UI.label("Resources and planetary threat held steady.",14,UI.MUTED))
		if str(campaign.state.events11.pending) != "": report.add_child(UI.label("Galaxy event awaiting a decision",14,UI.GOLD))
		for line in preload("res://scripts/campaign/crisis11_engine.gd").deadlines(campaign.state): report.add_child(UI.label(str(line),14,UI.DANGER))
	var command := _card("THE ORDER ENDURES", "Guide the roster, tend the wounded, fund research and decide where the next squad deploys.")
	var row := HFlowContainer.new(); command.add_child(row)
	row.add_child(UI.button("Council & edicts", _change_page.bind("Council")))
	row.add_child(UI.button("Presentation settings", _change_page.bind("Settings")))
	var ready := 0; var tired := 0; var away := 0
	for r in campaign.state.roster:
		if preload("res://scripts/campaign/strat_roster.gd").ready(r): ready += 1
		if int(r.fatigue) >= 34: tired += 1
		if str(r.assign).begins_with("field:"): away += 1
	command.add_child(UI.label("%d ready · %d tired or exhausted · %d away" % [ready, tired, away], 15, UI.GOLD))
	command.add_child(UI.label("Edicts: %s" % ", ".join(campaign.state.strategy.edict), 14, UI.MUTED))
	var next := "A story mission awaits." if int(campaign.state.step) in [0, 2] else "%d crises await your decision." % campaign.state.options.size()
	var box := _card("NEXT DEPLOYMENT", next)
	box.add_child(UI.button("OPEN GALAXY  >" if Phone.touch_device() else "OPEN GALAXY  →", _open_galaxy))
	box.add_child(UI.button("Rest 7 days", _rest))
	var flow = get_node("/root/CampaignFlow")
	if not campaign.state.pending_mission.is_empty(): box.add_child(UI.button("Resume deployment", func(): flow.go("squad")))
	var era := int(campaign.state.era)
	if era < 3 and (campaign.state.flags.get("boss_or_won" if era == 1 else "boss_ru_won", false) or campaign.state.flags.get("temple_scarred" if era == 1 else "e2_bomb_fired", false)):
		box.add_child(UI.button("Begin the next era >" if Phone.touch_device() else "Begin the next era →", flow.advance_era))
	if campaign.state.options.is_empty(): _card("CHAPTER COMPLETE", "The Order’s record endures. Tend your roster, explore the Codex, or begin a new campaign from the main menu.")
	if str(campaign.state.build) != "": _card("CONSTRUCTION", "%s · %.1f work days remaining." % [Data.get_table("core", "WINGS")[str(campaign.state.build)].n, campaign.state.facility.build_left])
	if str(campaign.state.research.cur) != "":
		var project: Dictionary = Data.get_table("research", "RESEARCH")[str(campaign.state.research.cur)]
		_card("RESEARCH IN PROGRESS", "%s  ·  %.0f / %d days" % [project.n, float(campaign.state.research.prog), int(project.days)])
	var news_box := _card("COMMAND LOG")
	if campaign.state.news.is_empty(): news_box.add_child(UI.label("The Temple is ready for orders.", 15, UI.MUTED))
	else:
		for entry in campaign.state.news.slice(-5): news_box.add_child(UI.label(str(entry), 15))

func _roster() -> void:
	StrategyUI.roster(self)
	page_content.add_child(UI.label("Assign soldiers to train or recover. Wounded soldiers cannot deploy.", 15, UI.MUTED))
	for r in campaign.state.roster:
		var status := "DEAD" if str(r.status) == "dead" else "WOUNDED · %d DAYS" % int(r.wound) if int(r.wound) > 0 else str(r.status).to_upper()
		var box := _card("%s  ·  %s  ·  RANK %d" % [r.n, r.cls, int(r.rank)], "%s   •   %d XP   •   %d KILLS   •   %d MISSIONS" % [status, int(r.xp), int(r.kills), int(r.missions)])
		if Progression.is_jedi(r):
			var face := preload("res://scripts/story14_portraits.gd").picture(str(r.n), Vector2(64, 78))
			face.name = "JediPortrait_" + str(r.id)
			face.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			box.add_child(face)
		StrategyUI.soldier(self, box, r)
		if str(r.status) == "active": box.add_child(UI.button("Training & promotion", _open_promotion.bind(str(r.id))))
		if Progression.is_jedi(r) and r.status == "active" and r.get("title","") != "Padawan":
			var counsel := OptionButton.new(); counsel.add_item("Counsel: none")
			var mentors: Array = campaign.state.roster.filter(func(m): return m.id != r.id and m.status == "active" and Progression.is_jedi(m) and int(m.rank) >= 4 and m.get("title","") in ["Knight","Master"])
			for mentor in mentors: counsel.add_item(str(mentor.n))
			counsel.item_selected.connect(func(i: int):
				if campaign.sith.set_counsel(str(r.id),str(mentors[i-1].id) if i > 0 else ""):
					get_node("/root/CampaignFlow").save(); notice_label.text = "Counsel assigned.")
			box.add_child(counsel)
		var stats: Dictionary = Gear.battle_stats(campaign, str(r.id))
		box.add_child(UI.label("HP %d   AIM %d   WILL %d   MOVE %d" % [int(stats.get("hp", 0)), int(stats.get("aim", 0)), int(stats.get("will", 0)), int(stats.get("mob", 0))], 15))
		if int(r.get("pick", 0)) > 0:
			var row := HBoxContainer.new(); box.add_child(row)
			row.add_child(UI.label("Choose rank %d:  " % int(r.pick), 15, UI.ACCENT))
			for option in Progression.tree_options(r, int(r.pick)):
				var perk: Dictionary = Data.get_table("temple", "PERKS").get(str(option), {})
				row.add_child(UI.button(str(perk.get("name", option)), _pick.bind(str(r.id), str(option))))
		if str(r.status) == "active":
			var row := HBoxContainer.new(); box.add_child(row)
			row.add_child(UI.button("On call", _assign.bind(str(r.id), ""), str(r.assign) != ""))
			row.add_child(UI.button("Recover", _assign.bind(str(r.id), "rest"), int(campaign.state.wings.medical) > 0 and str(r.assign) != "rest"))
			row.add_child(UI.button("Train", _assign.bind(str(r.id), "train"), int(campaign.state.wings.training) > 0 and str(r.assign) != "train"))

func _research() -> void:
	StrategyUI.projects(self)
	if int(campaign.state.wings.archives) == 0:
		_card("ARCHIVES REQUIRED", "Build Archives to begin research.")

func _arsenal() -> void:
	var row := HFlowContainer.new(); page_content.add_child(row)
	for r in campaign.state.roster:
		if str(r.status) != "dead": row.add_child(UI.button(str(r.n), _select_unit.bind(str(r.id))))
	var r: Dictionary = campaign.soldier(selected_id)
	if r.is_empty(): return
	var gear: Dictionary = r.gear
	var stats: Dictionary = Gear.battle_stats(campaign, selected_id)
	_card("%s  ·  %s" % [r.n, r.cls], "HP %d  ·  AIM %d  ·  DAMAGE %d–%d  ·  ARMOR %d" % [int(stats.get("hp", 0)), int(stats.get("aim", 0)), int(stats.dmg[0]), int(stats.dmg[1]), int(stats.get("armor", 0))])
	var box := _card("PRIMARY GEAR", "Current: %s" % (Data.get_table("gear", "SABERS")[int(gear.saber)].n if Progression.is_jedi(r) else Data.get_table("gear", "WEAPONS")[int(gear.w)].n))
	if Progression.is_jedi(r):
		var next := int(gear.saber) + 1
		if next < Data.get_table("gear", "SABERS").size():
			var item: Dictionary = Data.get_table("gear", "SABERS")[next]
			box.add_child(UI.button("Craft %s  ·  %d Cr + %d Kyber" % [item.n, int(item.cost), int(item.kyber)], _craft_saber.bind(selected_id)))
	else:
		var next := int(gear.w) + 1
		if next < Data.get_table("gear", "WEAPONS").size():
			var item: Dictionary = Data.get_table("gear", "WEAPONS")[next]
			box.add_child(UI.button("Buy %s  ·  %d Cr" % [item.n, int(item.cost)], _buy_weapon.bind(selected_id)))
	box = _card("ARMOR", "Equipped: %s" % Data.get_table("gear", "ARMOR")[str(gear.armor)].n)
	var armor_row := HFlowContainer.new(); box.add_child(armor_row)
	for key in Data.get_table("gear", "ARMOR"):
		var item: Dictionary = Data.get_table("gear", "ARMOR")[key]
		if str(item.who) in ["any", "jedi" if Progression.is_jedi(r) else "troop"]:
			armor_row.add_child(UI.button("%s · %d Cr" % [item.n, int(item.cost)], _buy_armor.bind(selected_id, str(key)), str(gear.armor) != str(key)))
	for kind in ["s", "w", "a"]:
		if Gear.slots(r, kind) == 0: continue
		var slot_name := "SABER" if kind == "s" else "WEAPON" if kind == "w" else "ARMOR"
		var equipped: Array = gear["smods" if kind == "s" else "mods" if kind == "w" else "amods"]
		box = _card("%s MODULES" % slot_name, ("%d / %d slots  ·  tap to fit" if Phone.touch_device() else "%d / %d slots  ·  click to fit") % [equipped.size(), Gear.slots(r, kind)])
		var module_row := HFlowContainer.new(); box.add_child(module_row)
		var pool: Dictionary = Data.get_table("gear", "SMODS" if kind == "s" else "W_MODS" if kind == "w" else "AMODS")
		for key in pool:
			var item: Dictionary = pool[key]
			module_row.add_child(UI.button("%s  ·  %d Cr" % [item.n, int(item.cost)], _fit_mod.bind(selected_id, kind, str(key)), not equipped.has(key) and equipped.size() < Gear.slots(r, kind)))
		for key in equipped:
			box.add_child(UI.button("Upgrade %s to next Mk" % pool[str(key)].n, _upgrade_mod.bind(selected_id, kind, str(key))))
	box = _card("UTILITY KIT", "Equipped: %s" % Data.get_table("gear", "UTIL")[str(gear.util)].n)
	var util_row := HFlowContainer.new(); box.add_child(util_row)
	for key in Data.get_table("gear", "UTIL"):
		var item: Dictionary = Data.get_table("gear", "UTIL")[key]
		util_row.add_child(UI.button("%s · %d Cr" % [item.n, int(item.cost)], _buy_utility.bind(selected_id, str(key)), str(gear.util) != str(key)))
	if Progression.is_jedi(r):
		box = _card("SABER FORM", "Current: %s" % Data.get_table("gear", "FORMS")[str(gear.form)].n)
		var form_row := HFlowContainer.new(); box.add_child(form_row)
		for key in Data.get_table("gear", "FORMS"):
			var form: Dictionary = Data.get_table("gear", "FORMS")[key]
			form_row.add_child(UI.button(str(form.n), _set_form.bind(selected_id, str(key)), campaign.researched(str(form.get("res", "")))))

func _teams() -> void:
	StrategyUI.field(self)
	page_content.add_child(UI.label("Two strike teams at the start. Barracks levels 2 and 3 add one each.", 15, UI.MUTED))
	for team in campaign.state.teams:
		var names := []
		for id in [team.lead] + team.mem:
			var r: Dictionary = campaign.soldier(str(id))
			if not r.is_empty(): names.append(str(r.n))
		var box := _card(str(team.n), "Leader and members: %s" % ", ".join(names))
		for option in campaign.state.options:
			if not option.has("crisis"): continue
			var risk := preload("res://scripts/campaign/strat_ops.gd").team_risk(campaign, team, option)
			box.add_child(UI.label("%s · %d%% success · %s" % [option.get("n", option.mission), risk.success, " · ".join(risk.why)], 13))
		box.add_child(UI.label("Victory: 25% light wound per soldier. Defeat: serious wound; 30% capture or 7% death.", 13, UI.MUTED))

func _legacy() -> void:
	_card("THE ORDER REMEMBERS", "Soldier deeds, bonds, identities and fallen legends persist in campaign saves. Retire a veteran at rank 4.")
	for r in campaign.state.roster:
		var identity := "%s%s  ·  %s  ·  %d kills  ·  %d missions" % [r.n, " “%s”" % r.nick if str(r.get("nick", "")) != "" else "", r.cls, int(r.kills), int(r.missions)]
		var box := _card(identity, "Rank %d  ·  %s" % [int(r.rank), str(r.status)])
		StrategyUI.identity(self, box, r)
		var nick := LineEdit.new(); nick.placeholder_text = "Nickname" if Phone.touch_device() else "Enter a nickname and press Enter"; nick.max_length = int(Data.get_table("legacy", "NICK_MAX")); nick.text_submitted.connect(_set_nick.bind(str(r.id))); box.add_child(nick)
		if str(r.status) == "active" and int(r.rank) >= 4: box.add_child(UI.button("Retire to the Order", _retire.bind(str(r.id))))
	var bonds := _card("BONDS", "Comrades gain bond points when they survive missions together.")
	for pair in campaign.state.bonds:
		var bond: Dictionary = campaign.state.bonds[pair]
		if int(bond.lvl) > 0: bonds.add_child(UI.label("%s  ·  level %d / 8" % [str(pair).replace("|", " & "), int(bond.lvl)], 15))
	for legend in campaign.state.legends:
		_card("IN MEMORY · %s" % legend.n, "%s  ·  %s" % [legend.cls, legend.where])

func _open_galaxy() -> void:
	get_node("/root/CampaignFlow").save()
	get_tree().change_scene_to_file("res://scenes/galaxy.tscn")

func _pick(id: String, key: String) -> void:
	if Progression.choose(campaign.soldier(id), key): get_node("/root/CampaignFlow").save(); _show_page()
func _open_promotion(id: String) -> void:
	var screen := PromotionScreen.new()
	add_child(screen)
	screen.setup(campaign, id)
	screen.changed.connect(func(): notice_label.text = "Training updated.")
func _assign(id: String, job: String) -> void:
	if campaign.assign(id, job): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _start_research(id: String) -> void:
	if campaign.start_research(id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _build_wing(id: String) -> void:
	if campaign.build_wing(id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _select_unit(id: String) -> void:
	selected_id = id; _show_page()
func _buy_weapon(id: String) -> void:
	if Gear.buy_weapon(campaign, id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _craft_saber(id: String) -> void:
	if Gear.craft_saber(campaign, id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _buy_armor(id: String, key: String) -> void:
	if Gear.buy_armor(campaign, id, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _fit_mod(id: String, kind: String, key: String) -> void:
	if Gear.fit_module(campaign, id, kind, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _upgrade_mod(id: String, kind: String, key: String) -> void:
	if Gear.upgrade_module(campaign, id, kind, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _buy_utility(id: String, key: String) -> void:
	if Gear.buy_utility(campaign, id, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _set_form(id: String, key: String) -> void:
	if Gear.set_form(campaign, id, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _module_action(wing: String) -> void:
	if Modules.use(campaign, wing): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _set_nick(value: String, id: String) -> void:
	if Legacy.set_nickname(campaign, id, value): get_node("/root/CampaignFlow").save(); _show_page()
func _retire(id: String) -> void:
	if Legacy.retire(campaign, id): get_node("/root/CampaignFlow").save(); _refresh_shell()

func _rest() -> void:
	campaign.advance_days(7)
	get_node("/root/CampaignFlow").show_sith_events.call_deferred()
	get_node("/root/CampaignFlow").save()
	_refresh_shell()
