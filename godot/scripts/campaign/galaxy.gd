extends Control
signal mission_launch_requested(mission_id: String, squad_ids: Array, option: Dictionary)
const Campaign = preload("res://scripts/campaign/state.gd")
const Data = preload("res://scripts/campaign/data.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const GalaxyMap = preload("res://scripts/campaign/galaxy_map.gd")
const Intel = preload("res://scripts/campaign/galaxy_intel.gd")
const Details = preload("res://scripts/campaign/galaxy_details.gd")
const Art = preload("res://scripts/campaign/galaxy_art.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Strategy25 = preload("res://scripts/w25_galaxy_strategy.gd")
var campaign: Campaign
var selected := 0
var detail: VBoxContainer
var map_view: Control
var message: Label
var status: Label
var tabs: HBoxContainer
var tab_scroll: ScrollContainer
var chips: HFlowContainer
var scroll: ScrollContainer
var excerpt: Label
var phone_more := false
var page := "Briefing"
var region := "outer"
var planet := ""
var field_key := "convoy"
var field_team: Array = []
var transition: Tween
var back_button: Button
var launch_button: Button
var sound: AudioStreamPlayer
var detail_panel: PanelContainer
var detail_open := false
var detail_left := 0.0
var detail_right := 0.0
var selected_card: PanelContainer
var selected_title: Label
var selected_forecast: Label
var contact_action: Button
var scan_site := ""
var scan_feedback := ""
var scan_events: Array = []
var deadline_rail: Label
var region_strip: HBoxContainer
var ready_shortcut32: Button
var detail_scroll_key32 := ""
var test_safe_insets32 := Vector4.ZERO

func _ready() -> void:
	campaign = get_node("/root/CampaignFlow").session()
	Strategy25.ensure(campaign.state)
	if Strategy25.settle_months(campaign) > 0: get_node("/root/CampaignFlow").save()
	if campaign.has_signal("month_advanced"): campaign.month_advanced.connect(_month_advanced25)
	for i in campaign.state.options.size():
		if str(campaign.state.options[i].mission) == str(campaign.state.w25_selected_mission_id): selected = i; break
	_build(); _show_details()
	if Phone.narrow(Phone.window_size()):
		detail_panel.show(); detail_panel.modulate.a = 0.0
		get_tree().process_frame.connect(_hide_initial_detail, CONNECT_ONE_SHOT)
	sound = preload("res://scripts/campaign/galaxy_sound.gd").new(); add_child(sound)
	_wire_buttons(self)

func _hide_initial_detail() -> void:
	if not detail_open: detail_panel.hide()
	detail_panel.modulate.a = 1.0

func _month_advanced25(_month: int, _snapshot: Dictionary) -> void:
	if Strategy25.settle_months(campaign) > 0:
		get_node("/root/CampaignFlow").save()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: _back(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_T: _temple(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP or event.keycode == KEY_DOWN:
			var direction := -1 if event.keycode == KEY_UP else 1
			_select(posmod(selected+direction,maxi(1,campaign.state.options.size()))); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER and page == "Briefing": _launch(); get_viewport().set_input_as_handled()

func _build() -> void:
	var compact := Phone.narrow(Phone.window_size())
	var physical := Phone.window_size()
	var portrait := compact and (get_viewport_rect().size.x < get_viewport_rect().size.y or physical.x < physical.y)
	var safe := test_safe_insets32 if test_safe_insets32 != Vector4.ZERO else Phone.safe_margins(get_viewport_rect().size)
	var bg := ColorRect.new(); bg.color = Color("0a1113"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var outer := UI.column(6); outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = safe.x + (12 if compact else 22); outer.offset_top = safe.y + (12 if compact else 16)
	outer.offset_right = -safe.z - (12 if compact else 22); outer.offset_bottom = -safe.w - (12 if compact else 12); add_child(outer)
	var head: BoxContainer = VBoxContainer.new() if portrait else HBoxContainer.new()
	head.add_theme_constant_override("separation", 8 if compact else 4); outer.add_child(head)
	var title := UI.column(0); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(title)
	if not compact: title.add_child(UI.label("J E D I   T E M P L E   /   W A R   R O O M",12,Color("79d3e2")))
	title.add_child(UI.label("Galaxy command",20 if compact else 30,Color("dbe7e4")))
	var actions: BoxContainer = HBoxContainer.new() if portrait else head
	if portrait:
		actions.add_theme_constant_override("separation", 8)
		head.add_child(actions)
	back_button = UI.button("← MAP" if portrait else "GALAXY" if Phone.touch_device() else "←  GALAXY", _overview); back_button.name = "GalaxyOverview"; back_button.visible = false; actions.add_child(back_button)
	var intelligence := UI.button("INTEL" if portrait else "INTEL WORKBENCH",open_intel_view25); intelligence.name = "Intelligence"
	if compact: intelligence.custom_minimum_size.y = 44
	actions.add_child(intelligence)
	var temple_button := UI.button("TEMPLE" if Phone.touch_device() else "←  TEMPLE",_temple); temple_button.name = "TempleReturn"
	if compact: temple_button.custom_minimum_size.y = 44
	actions.add_child(temple_button)
	if portrait:
		for button in actions.get_children(): button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status = UI.label("",14,Color("8aa2a5")); outer.add_child(status)
	deadline_rail = UI.label("", 14, UI.GOLD); deadline_rail.name = "ThreatCountdown25"; outer.add_child(deadline_rail)
	contact_action = UI.button("",_contact_primary25)
	contact_action.name = "ContactChoice25"; contact_action.custom_minimum_size.y = 44
	contact_action.clip_text = true
	contact_action.add_theme_font_size_override("font_size",14)
	if compact and not portrait:
		contact_action.custom_minimum_size.x = 185
		actions.add_child(contact_action)
	else: outer.add_child(contact_action)
	if portrait and physical.x < 420:
		ready_shortcut32 = UI.button("READY SIGNAL", _launch)
		ready_shortcut32.name = "SignalReadyShortcut32"
		ready_shortcut32.custom_minimum_size.y = 44
		outer.add_child(ready_shortcut32)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); outer.add_child(body)
	var left := UI.column(8); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(left)
	var map_panel := UI.panel(Color("0f191c")); map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; left.add_child(map_panel)
	var style := map_panel.get_theme_stylebox("panel").duplicate(); style.set_content_margin_all(0); map_panel.add_theme_stylebox_override("panel",style)
	map_view = GalaxyMap.new(); map_view.campaign = campaign; map_view.clip_contents = true; map_panel.add_child(map_view)
	if compact: map_view.custom_minimum_size = Vector2(260, 130)
	map_view.field_selected.connect(_field); map_view.mission_selected.connect(_select); map_view.planet_selected.connect(_planet); map_view.region_selected.connect(_region); map_view.scan_selected.connect(_scan_site_open)
	var right := UI.panel(UI.SURFACE_RAISED); detail_panel = right
	if compact:
		var overlay := Control.new()
		overlay.name = "SiteOverlay"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.clip_contents = true
		add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(right)
		right.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT if portrait else Control.PRESET_RIGHT_WIDE)
		right.anchor_top = 1.0 if portrait else right.anchor_top
		right.offset_left = safe.x + 12 if portrait else -minf(370.0, get_viewport_rect().size.x * 0.30)
		right.offset_right = -safe.z - 12
		right.offset_top = -minf(450.0, get_viewport_rect().size.y * 0.55) if portrait else safe.y + 56
		right.offset_bottom = -safe.w - 12
		detail_left = right.offset_left; detail_right = right.offset_right
		right.visible = false
	else:
		right.custom_minimum_size.x = 330; body.add_child(right)
	var column := UI.column(8 if compact else 7); column.custom_minimum_size.x = 0 if compact else 304; right.add_child(column)
	var top_actions: HBoxContainer
	if compact:
		top_actions = HBoxContainer.new()
		top_actions.add_theme_constant_override("separation", 8)
		column.add_child(top_actions)
		var close := UI.button("← BACK TO MAP" if portrait else "CLOSE", _overview)
		close.name = "CloseSite"; close.custom_minimum_size.y = 44
		close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_actions.add_child(close)
		region_strip = HBoxContainer.new(); region_strip.name = "SelectedRegionStrip25"
		region_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL; column.add_child(region_strip)
	tabs = HBoxContainer.new()
	if compact:
		var tab_row := HBoxContainer.new(); tab_row.add_theme_constant_override("separation", 8); column.add_child(tab_row)
		var previous := UI.button("‹", func(): tab_scroll.scroll_horizontal = maxi(0, tab_scroll.scroll_horizontal - 120))
		previous.custom_minimum_size.x = 44
		previous.tooltip_text = "Scroll tabs left"; tab_row.add_child(previous)
		tab_scroll = preload("res://scripts/touch_scroll.gd").new(); tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tab_scroll.custom_minimum_size.y = 44; tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_row.add_child(tab_scroll); tab_scroll.add_child(tabs)
		var next := UI.button("›", func(): tab_scroll.scroll_horizontal += 120)
		next.custom_minimum_size.x = 44
		next.tooltip_text = "Scroll tabs right"; tab_row.add_child(next)
	else: column.add_child(tabs)
	for tab in ["Briefing","Regions","Field ops","Teams","Sith ops"]:
		var button := UI.button(tab,_tab.bind(tab)); button.add_theme_font_size_override("font_size",14 if compact else 11)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.add_child(button)
	if compact: tabs.add_theme_constant_override("separation", 8)
	var legend := HFlowContainer.new(); legend.add_theme_constant_override("h_separation",14); column.add_child(legend)
	legend.add_child(UI.label("RISK",12,UI.MUTED))
	for i in 4: legend.add_child(UI.label("● " + str(Data.get_table("galaxy","RISK")[i][1]),12,Intel.COLORS[i]))
	legend.add_child(UI.label("◇ Field op   /   Red haze: Darkness + unrest",12,UI.MUTED))
	for item in legend.get_children(): item.autowrap_mode = TextServer.AUTOWRAP_OFF
	if compact: legend.hide()
	var offer_scroll := preload("res://scripts/touch_scroll.gd").new(); offer_scroll.custom_minimum_size.y = 44 if compact else 70
	offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(offer_scroll)
	if compact: offer_scroll.hide()
	chips = HFlowContainer.new(); chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL; offer_scroll.add_child(chips)
	if compact:
		var summary := HBoxContainer.new(); column.add_child(summary)
		excerpt = UI.label("", 14, UI.TEXT); excerpt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		excerpt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.add_child(excerpt)
		var more := UI.button("MORE", func(): phone_more = true; _show_details())
		more.name = "BriefingMore"; more.custom_minimum_size = Vector2(52, 44); summary.add_child(more)
	scroll = preload("res://scripts/touch_scroll.gd").new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	detail = UI.column(10); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(detail)
	launch_button = UI.button("READY  >" if compact else "READY FOR MISSION  →",_launch)
	if compact: launch_button.custom_minimum_size.y = 44
	column.add_child(launch_button)
	if compact:
		launch_button.reparent(top_actions)
		launch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message = UI.label("Tap a world or signal to inspect it." if Phone.touch_device() else "Select a world or a signal.  ↑ ↓ offers  ·  Enter briefing  ·  Esc back  ·  T Temple",12,Color("8aa2a5")); outer.add_child(message)
	if compact: message.hide(); status.hide()
	if compact: _phone_text_floor(self)
	_refresh_chips()
	if compact: _phone_text_floor(chips)
	_sync_ui_safe_rect.call_deferred()

func _phone_text_floor(node: Node) -> void:
	if node is Label and node.get_theme_font_size("font_size") < 14:
		node.add_theme_font_size_override("font_size", 14)
	if node is BaseButton and node.get_theme_font_size("font_size") < 14:
		node.add_theme_font_size_override("font_size", 14)
	for child in node.get_children(): _phone_text_floor(child)

func _refresh_chips() -> void:
	UI.clear(chips)
	for i in campaign.state.options.size():
		var o: Dictionary = campaign.state.options[i]; var m: Dictionary = campaign.story.mission(str(o.mission))
		var rk := Intel.risk(campaign,m,o)
		var contacted: bool = Strategy25.contacted(campaign.state,campaign.region_for_mission(str(o.mission))) or bool(o.get("story",false))
		var b := UI.button("%d  %s\n%s · %s" % [i+1,o.get("n",m.get("n",o.mission)) if contacted else "Rumour",Intel.planet_for(m),rk.name if contacted else "uncontacted"],_select.bind(i))
		b.add_theme_font_size_override("font_size",13); b.add_theme_color_override("font_color",rk.color)
		b.tooltip_text = Intel.deadline(o,campaign.state.options); chips.add_child(b)

func _show_details() -> void:
	if detail_panel != null and Phone.narrow(Phone.window_size()): detail_panel.visible = detail_open
	if transition and transition.is_running(): transition.kill()
	detail.position.x = 0; detail.modulate.a = 1
	# Rebuilding the same detail keeps its position, including between gestures.
	var next_scroll_key := "%s|%s|%s|%s|%s" % [page, str(campaign.state.options[selected].mission) if not campaign.state.options.is_empty() else "", region, planet, scan_site]
	var held_scroll := scroll.scroll_vertical
	UI.clear(detail)
	if next_scroll_key != detail_scroll_key32:
		detail_scroll_key32 = next_scroll_key
		scroll.scroll_vertical = 0
	else:
		scroll.set_deferred("scroll_vertical", held_scroll)
	_refresh_strategy25()
	if (get_viewport_rect().size.y > get_viewport_rect().size.x or Phone.window_size().y > Phone.window_size().x) and page == "Briefing" and not campaign.state.options.is_empty():
		_build_selected_card()
	_sync_ui_safe_rect.call_deferred()
	if excerpt != null:
		excerpt.get_parent().visible = page == "Briefing" and not phone_more and not campaign.state.options.is_empty()
		if not campaign.state.options.is_empty():
			var offer: Dictionary = campaign.state.options[clampi(selected, 0, campaign.state.options.size() - 1)]
			var mission: Dictionary = campaign.story.mission(str(offer.mission))
			var copy := str(offer.get("text", mission.get("brief", "Awaiting briefing."))).replace("\n", " ")
			excerpt.text = copy.substr(0, 34).strip_edges() + ("…" if copy.length() > 34 else "")
	launch_button.visible = page == "Briefing"
	launch_button.disabled = campaign.state.options.is_empty() or not campaign.state.pending_mission.is_empty()
	if not campaign.state.options.is_empty(): launch_button.disabled = launch_button.disabled or campaign.default_squad(campaign.state.options[selected]).is_empty()
	var project: Dictionary = campaign.sith.project_status()
	status.text = "Cr %d · Intel %d · Favor %d  |  Order Darkness %d/100  |  Sith Darkness %d/12 · next escalation day %d  |  M%d D%d" % [campaign.state.res.credits,campaign.state.res.intel,campaign.state.res.favor,campaign.state.orderDark,project.segments,project.next_escalation,campaign.state.month,campaign.state.day]
	if Phone.narrow(Phone.window_size()):
		status.text = "Cr %d · Intel %d · Favor %d · Darkness %d/100 · Sith %d/12 · M%d D%d" % [campaign.state.res.credits,campaign.state.res.intel,campaign.state.res.favor,campaign.state.orderDark,project.segments,campaign.state.month,campaign.state.day]
	launch_button.disabled = launch_button.disabled or project.defeated
	if not campaign.state.options.is_empty():
		var offer_region := campaign.region_for_mission(str(campaign.state.options[selected].mission))
		launch_button.disabled = launch_button.disabled or (offer_region != "" and not Strategy25.contacted(campaign.state, offer_region) and not campaign.state.options[selected].get("story", false))
	if ready_shortcut32 != null:
		ready_shortcut32.disabled = launch_button.disabled
		ready_shortcut32.text = "READY · %s" % str(campaign.state.options[selected].get("n", "SIGNAL")) if not campaign.state.options.is_empty() else "NO SIGNAL READY"
	if campaign.state.get("twin",{}).get("stage", "") == "b":
		detail.add_child(UI.label("FRONT B · fresh squad · up to 4, at most 2 Jedi",16,UI.GOLD))
		detail.add_child(UI.button("Auto resolve (%d%%)" % preload("res://scripts/mission_fronts.gd").auto_odds(campaign.state,campaign.default_squad()),_front_auto))
		detail.add_child(UI.button("Stand down Front B",_front_stand_down))
	for b in tabs.get_children(): b.modulate = Color("79d3e2") if b.text == page else Color.WHITE
	map_view.selected = selected
	back_button.visible = not map_view.focused.is_empty() and not (Phone.narrow(Phone.window_size()) and (get_viewport_rect().size.x < get_viewport_rect().size.y or Phone.window_size().x < Phone.window_size().y))
	match page:
		"Event": _scan_event_panel25()
		"Scan": _scan_panel25()
		"Intel": _intel_panel25()
		"Regions": Details.region_panel(self)
		"Field ops": _field_panel()
		"Teams": Details.teams_panel(self)
		"Sith ops": _sith_panel()
		_: Details.mission_panel(self)
	Details.events_panel(self)
	_wire_buttons(detail)
	if Phone.narrow(Phone.window_size()): _phone_text_floor(detail)

func _build_selected_card() -> void:
	var offer: Dictionary = campaign.state.options[clampi(selected, 0, campaign.state.options.size() - 1)]
	var mission: Dictionary = campaign.story.mission(str(offer.mission))
	var risk: Dictionary = Intel.risk(campaign, mission, offer)
	var contacted := Strategy25.contacted(campaign.state,campaign.region_for_mission(str(offer.mission)))
	var reward := "RUMOUR" if not contacted and not offer.get("story",false) else "UNKNOWN · build Comms Hub" if int(campaign.state.wings.comms) <= 0 and not offer.get("story", false) else Intel.resources(mission.get("reward", {}))
	selected_card = UI.panel(UI.SURFACE)
	selected_card.name = "SelectedMissionCard"
	detail.add_child(selected_card)
	var copy := UI.column(2)
	selected_card.add_child(copy)
	selected_title = UI.label(str(offer.get("n", mission.get("n", offer.mission))) if contacted or offer.get("story",false) else "Mission rumour", UI.TYPE_ACTION, UI.GOLD)
	copy.add_child(selected_title)
	var deadline_chip := "NO DEADLINE" if offer.get("story",false) else "NEXT MISSION" if offer.get("adv",false) else "THIS STEP"
	selected_forecast = UI.label("THREAT  %d/4   ·   REWARD  %s\nDEADLINE  %s" % [int(risk.level),reward,deadline_chip], 14, risk.color)
	selected_forecast.max_lines_visible = 2
	copy.add_child(selected_forecast)

func _choose_event(index: int) -> void:
	if preload("res://scripts/campaign/events11_engine.gd").choose(campaign, index):
		get_node("/root/CampaignFlow").save(); map_view.refresh_signals(); _show_details()
	else: message.text = "Insufficient resources for that choice."

func _choose_crisis(id: String, index: int) -> void:
	if preload("res://scripts/campaign/crisis11_engine.gd").choose(campaign, id, index):
		get_node("/root/CampaignFlow").save(); map_view.refresh_signals(); _show_details()
	else: message.text = "Insufficient resources or the next crisis step is not ready."

func _slide(open_panel: bool = false) -> void:
	if transition and transition.is_running(): transition.kill()
	detail.modulate.a = 0.0
	# Child of the scroll container slides in without disturbing the map layout.
	var home := 0.0; detail.position.x = 32
	transition = create_tween().set_parallel(true)
	transition.tween_property(detail,"modulate:a",1.0,0.32)
	transition.tween_property(detail,"position:x",home,0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if open_panel and Phone.narrow(Phone.window_size()) and detail_panel != null and get_viewport_rect().size.x >= get_viewport_rect().size.y and Phone.window_size().x >= Phone.window_size().y:
		detail_panel.offset_left = detail_left + detail_panel.size.x
		detail_panel.offset_right = detail_right + detail_panel.size.x
		transition.tween_property(detail_panel, "offset_left", detail_left, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		transition.tween_property(detail_panel, "offset_right", detail_right, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _tab(value: String) -> void:
	page = value; _show_details(); _slide()

func _select(index: int) -> void:
	if campaign.state.options.is_empty(): return
	selected = clampi(index,0,campaign.state.options.size()-1); page = "Briefing"
	campaign.state.w25_selected_mission_id = str(campaign.state.options[selected].mission)
	get_node("/root/CampaignFlow").save()
	if get_viewport_rect().size.x < get_viewport_rect().size.y or Phone.window_size().x < Phone.window_size().y: phone_more = true
	var m: Dictionary = campaign.story.mission(str(campaign.state.options[selected].mission))
	planet = Intel.planet_for(m); region = str(Data.get_table("galaxy","PLANETS")[planet].reg)
	map_view.focus_offer(selected); detail_open = true; _show_details(); _slide(true)

func _planet(title: String) -> void:
	planet = title; region = str(Data.get_table("galaxy","PLANETS")[title].reg)
	for offer in map_view.offers:
		if offer.planet == title: _select(int(offer.index)); return
	map_view.focus_planet(title); page = "Regions"; detail_open = true; _show_details(); _slide(true)

func _region(key: String) -> void:
	region = key; planet = ""; page = "Regions"; detail_open = true; _show_details(); _slide(true)

func _overview() -> void:
	map_view.return_to_overview(); planet = ""; detail_open = false; _show_details()
	if Phone.narrow(Phone.window_size()):
		detail_panel.offset_left = detail_left; detail_panel.offset_right = detail_right
	_sync_ui_safe_rect.call_deferred()

func _sync_ui_safe_rect() -> void:
	if not is_instance_valid(map_view) or not map_view.is_inside_tree() or not map_view.has_method("set_ui_safe_rect"): return
	map_view.call("set_ui_safe_rect", detail_panel.get_global_rect() if detail_open and is_instance_valid(detail_panel) else Rect2())

func _back() -> void:
	if detail_open or not map_view.focused.is_empty(): _overview()
	else: _temple()

func _temple() -> void:
	get_node("/root/CampaignFlow").save(); get_tree().change_scene_to_file("res://scenes/temple.tscn")

func _launch() -> void:
	if campaign.state.options.is_empty() or not campaign.state.pending_mission.is_empty(): return
	var flow := get_node("/root/CampaignFlow")
	var mission_id := str(campaign.state.options[selected].mission)
	var offer_region := campaign.region_for_mission(mission_id)
	if offer_region != "" and not Strategy25.contacted(campaign.state,offer_region) and not campaign.state.options[selected].get("story",false): return
	if flow.has_method("launch_ready25"): flow.call("launch_ready25", mission_id)
	else: flow.prepare_briefing(selected)

func _refresh_strategy25() -> void:
	var s: Dictionary = campaign.state
	var project: Dictionary = campaign.sith.project_status()
	deadline_rail.text = "DAY %d · SITH ESCALATION IN %d DAYS · %d/%d CONTACTS · +%d Cr/MO" % [int(s.elapsed_days), maxi(0, int(project.next_escalation) - int(s.elapsed_days)), s.w25_contacts.size(), Strategy25.contact_capacity(s), Strategy25.monthly_income(s)]
	var safe := test_safe_insets32 if test_safe_insets32 != Vector4.ZERO else Phone.safe_margins(get_viewport_rect().size)
	var narrow_safe_width := get_viewport_rect().size.x - safe.x - safe.z - 24 < 320
	if narrow_safe_width and Phone.window_size().x < 420:
		deadline_rail.text = "DAY %d · SITH %dD · %d/%d CONTACTS" % [int(s.elapsed_days), maxi(0, int(project.next_escalation) - int(s.elapsed_days)), s.w25_contacts.size(), Strategy25.contact_capacity(s)]
	var phone_landscape := Phone.narrow(Phone.window_size()) and get_viewport_rect().size.x > get_viewport_rect().size.y and Phone.window_size().x > Phone.window_size().y
	deadline_rail.visible = not phone_landscape
	var next_region := _next_contact25()
	var cost := Strategy25.contact_cost(next_region)
	contact_action.text = "CONTACT %s · %d Intel + %d Cr · %d/%d SLOTS" % [Intel.region_name(next_region).to_upper(),int(cost.intel),int(cost.credits),s.w25_contacts.size(),Strategy25.contact_capacity(s)] if next_region != "" else "CONTACT NETWORK FULL · %d/%d SLOTS" % [s.w25_contacts.size(),Strategy25.contact_capacity(s)]
	if narrow_safe_width and Phone.window_size().x < 420:
		contact_action.text = "CONTACT %s · %dI + %dCr" % [Intel.region_name(next_region).to_upper(),int(cost.intel),int(cost.credits)] if next_region != "" else "CONTACTS FULL · %d/%d" % [s.w25_contacts.size(),Strategy25.contact_capacity(s)]
	if phone_landscape:
		contact_action.text = "%s %dI/%dCr · SITH %dD" % [Intel.region_name(next_region).to_upper(),int(cost.intel),int(cost.credits),maxi(0,int(project.next_escalation)-int(s.elapsed_days))] if next_region != "" else "CONTACTS FULL · SITH %dD" % maxi(0,int(project.next_escalation)-int(s.elapsed_days))
	contact_action.disabled = next_region == "" or not campaign.can_afford(cost)
	if region_strip != null:
		UI.clear(region_strip)
		if page == "Briefing" and not s.options.is_empty():
			var offer: Dictionary = s.options[clampi(selected,0,s.options.size()-1)]
			var key := campaign.region_for_mission(str(offer.mission))
			if key == "": key = str(Data.get_table("galaxy", "PLANETS")[Intel.planet_for(campaign.story.mission(str(offer.mission)))].reg)
			var rows: Array = Data.get_table("galaxy", "REGIONS")
			var position := 0
			for i in rows.size():
				if str(rows[i][0]) == key: position = i; break
			var neighbors := "%s  ›  [%s]  ›  %s" % [str(rows[maxi(0,position-1)][1]).to_upper(),Intel.region_name(key).to_upper(),str(rows[mini(rows.size()-1,position+1)][1]).to_upper()]
			var strip := UI.label("%s\n%s" % [neighbors,Intel.deadline(offer,s.options)],14,UI.GOLD)
			strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			region_strip.add_child(strip)
		region_strip.visible = page == "Briefing" and (get_viewport_rect().size.x < get_viewport_rect().size.y or Phone.window_size().x < Phone.window_size().y)

func _contact25(key: String) -> void:
	if Strategy25.make_contact(campaign,key):
		get_node("/root/CampaignFlow").save()
		map_view.refresh_signals(); _show_details()
	else:
		message.text = "Contact needs an open slot, Intel and credits."

func _next_contact25() -> String:
	if campaign.state.w25_contacts.size() >= Strategy25.contact_capacity(campaign.state): return ""
	for key in ["mid","inner","colonies","core","deep","unknown"]:
		if not Strategy25.contacted(campaign.state,key): return key
	return ""

func _contact_primary25() -> void:
	var key := _next_contact25()
	if key != "": _contact25(key)

func _scan_site_open(id: String) -> void:
	scan_site = id; scan_feedback = ""; page = "Scan"; detail_open = true
	_show_details(); _slide(true)

func _scan_panel25() -> void:
	if not scan_feedback.is_empty(): detail.add_child(UI.label(scan_feedback,14,UI.GOLD))
	for site in Strategy25.active_scans(campaign.state):
		if str(site.id) != scan_site: continue
		var remaining := maxi(0,int(site.days)-int(campaign.state.w25_scan_progress.get(scan_site,0)))
		detail.add_child(UI.label("SCAN SITE · %s" % str(site.planet).to_upper(),14,UI.ACCENT))
		detail.add_child(UI.label(str(site.n),21,UI.TEXT))
		detail.add_child(UI.label("Commit %d days · gain %s. New events pause the scan." % [remaining,Intel.resources(site.reward)],14,UI.GOLD))
		var button := UI.button("SCAN HERE · %d DAYS" % remaining,_scan_commit25)
		button.name = "ScanCommit25"; button.custom_minimum_size.y = 44
		button.disabled = not campaign.has_method("advance_strategy_day25")
		detail.add_child(button)
		return
	detail.add_child(UI.label("Scan site no longer available.",14,UI.MUTED))

func _scan_commit25() -> void:
	var receipt := Strategy25.scan(campaign,scan_site)
	scan_feedback = str(receipt.message)
	scan_events = receipt.events
	Strategy25.settle_months(campaign)
	get_node("/root/CampaignFlow").save()
	message.text = str(receipt.message)
	map_view.refresh_signals(); _refresh_chips(); _show_details()
	if not receipt.events.is_empty() or not preload("res://scripts/campaign/events11_engine.gd").pending(campaign.state).is_empty():
		page = "Event"; _show_details()

func _scan_event_panel25() -> void:
	detail.add_child(UI.label("SCAN INTERRUPTED",20,UI.GOLD))
	detail.add_child(UI.label(scan_feedback,14,UI.TEXT))
	var pending: Dictionary = preload("res://scripts/campaign/events11_engine.gd").pending(campaign.state)
	if not pending.is_empty():
		detail.add_child(UI.label(str(pending.title),18,UI.DANGER))
		detail.add_child(UI.label(str(pending.text),14,UI.TEXT))
	elif not scan_events.is_empty():
		detail.add_child(UI.label(str(scan_events[0]),16,UI.DANGER))

func open_intel_view25() -> void:
	page = "Intel"; detail_open = true; _show_details(); _slide(true)

func _intel_panel25() -> void:
	detail.add_child(UI.label("INTEL WORKBENCH",20,UI.ACCENT))
	detail.add_child(UI.label("Trace Sith movements, choose a counter operation, then follow the research it exposes.",14,UI.MUTED))
	var visible := 0
	for op in campaign.sith.operations():
		if op.status not in ["open","team"]: continue
		var reg := Strategy25.operation_region(campaign,op)
		if not Strategy25.operation_known(campaign,op): continue
		visible += 1
		var known_op := Strategy25.operation_display(campaign,op)
		detail.add_child(UI.label("%s · day %d" % [str(known_op.n),int(op.deadline)],14,UI.DANGER))
		detail.add_child(UI.label(str(known_op.desc),14,UI.TEXT))
		for i in campaign.state.options.size():
			if campaign.state.options[i].get("sith_offer_id", "") == op.mission_id:
				detail.add_child(UI.button("COUNTER OP →",_select.bind(i)))
	if visible == 0: detail.add_child(UI.label("No identified Sith operation in contacted space.",14,UI.MUTED))
	detail.add_child(UI.label("SCAN LEADS · %d" % campaign.state.w25_leads.size(),14,UI.GOLD))
	var done: Array = campaign.state.research.done
	detail.add_child(UI.label("RESEARCH LINK · %s" % ("Sith Tactics complete · +5 squad aim" if "sithTactics" in done else "Codebreak → Sith Tactics · +5 squad aim"),14,UI.GOLD))
	detail.add_child(UI.button("STUDY AT TEMPLE ARCHIVES",_temple))
	detail.add_child(UI.button("OPEN SITH DOSSIER",func(): get_node("/root/CampaignFlow").open_intelligence()))

func _assign_team(crisis: String, team_id: String) -> void:
	if campaign.assign_team_to_crisis(crisis,team_id):
		get_node("/root/CampaignFlow").save(); _show_details()

func _field_panel() -> void:
	Details.field_panel(self)

func _toggle_field(id: String) -> void:
	if field_team.has(id): field_team.erase(id)
	elif field_team.size() < 3: field_team.append(id)
	_show_details()

func _send_field(key: String) -> void:
	if campaign.send_field_op(key,field_team):
		field_team.clear(); get_node("/root/CampaignFlow").save()
		message.text = "%s team deployed. Track its shuttle on the map." % "Field operation"
		map_view.refresh_signals(); _refresh_chips(); _show_details()
	else: message.text = "Choose 2–3 available soldiers and check the operation fee."

func _wire_buttons(node: Node) -> void:
	if node is BaseButton and not node.has_meta("galaxy_sound"):
		node.set_meta("galaxy_sound",true)
		node.mouse_entered.connect(func(): if is_instance_valid(sound) and not node.disabled: sound.play())
	for child in node.get_children(): _wire_buttons(child)

func _field(key: String) -> void:
	field_key = key; page = "Field ops"; detail_open = true; _show_details(); _slide(true)

func _front_auto() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var receipt := preload("res://scripts/mission_fronts.gd").auto_resolve(campaign.state,selected,campaign.default_squad(),rng)
	if campaign.Integration.settle_front(campaign,receipt):
		get_node("/root/CampaignFlow").save(); selected = 0; map_view.refresh_signals(); _refresh_chips(); _show_details()

func _front_stand_down() -> void:
	var receipt := preload("res://scripts/mission_fronts.gd").stand_down(campaign.state)
	if campaign.Integration.settle_front(campaign,receipt):
		get_node("/root/CampaignFlow").save(); selected = 0; map_view.refresh_signals(); _refresh_chips(); _show_details()

func _sith_panel() -> void:
	detail.add_child(UI.label("DARK EVENTS",20,UI.DANGER))
	detail.add_child(UI.label("Choose one counter mission this month. Intel and covert teams offer other ways to intervene.",14,UI.MUTED))
	for op in campaign.sith.operations():
		var op_region := Strategy25.operation_region(campaign,op)
		if not Strategy25.operation_known(campaign,op) and op_region != "": continue
		var known_op := Strategy25.operation_display(campaign,op)
		Details.fact(detail,str(known_op.n),"Day %d · %s" % [int(op.deadline),str(op.status).capitalize()],UI.GOLD)
		detail.add_child(UI.label(str(known_op.desc),14))
		for i in campaign.state.options.size():
			var option: Dictionary = campaign.state.options[i]
			if option.get("sith_offer_id", "") == op.mission_id:
				detail.add_child(UI.button("COUNTER MISSION →",_select.bind(i),op.status == "open"))
	detail.add_child(UI.button("Intel, teams & rival dossiers",func(): get_node("/root/CampaignFlow").open_intelligence()))
	detail.add_child(UI.label("RIVAL OPERATIONS",18,UI.DANGER))
	for rival in campaign.sith.rivals():
		detail.add_child(UI.label("%s · %s" % [rival.n,str(rival.phase).capitalize()],14,UI.GOLD))
	for i in campaign.state.options.size():
		var option: Dictionary = campaign.state.options[i]
		if option.has("rival_id") or option.get("kind", "") in ["retaliation", "project"]:
			detail.add_child(UI.button(str(option.n),_select.bind(i)))
