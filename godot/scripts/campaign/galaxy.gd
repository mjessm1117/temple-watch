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
var page := "Briefing"
var region := "outer"
var planet := ""
var field_key := "convoy"
var field_team: Array = []
var transition: Tween
var back_button: Button
var launch_button: Button
var sound: AudioStreamPlayer

func _ready() -> void:
	campaign = get_node("/root/CampaignFlow").session()
	_build(); _show_details()
	sound = preload("res://scripts/campaign/galaxy_sound.gd").new(); add_child(sound)
	_wire_buttons(self)

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
	var bg := ColorRect.new(); bg.color = Color("0a1113"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var outer := UI.column(6); outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 8 if compact else 22; outer.offset_top = 5 if compact else 16
	outer.offset_right = -8 if compact else -22; outer.offset_bottom = -5 if compact else -12; add_child(outer)
	var head := HBoxContainer.new(); outer.add_child(head)
	var title := UI.column(0); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(title)
	if not compact: title.add_child(UI.label("J E D I   T E M P L E   /   W A R   R O O M",12,Color("79d3e2")))
	title.add_child(UI.label("Galaxy command",20 if compact else 30,Color("dbe7e4")))
	back_button = UI.button("←  GALAXY", _overview); back_button.visible = false; head.add_child(back_button)
	head.add_child(UI.button("SITH INTELLIGENCE",func(): get_node("/root/CampaignFlow").open_intelligence()))
	head.add_child(UI.button("←  TEMPLE",_temple))
	status = UI.label("",14,Color("8aa2a5")); outer.add_child(status)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); outer.add_child(body)
	var left := UI.column(8); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(left)
	var map_panel := UI.panel(Color("0f191c")); map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; left.add_child(map_panel)
	var style := map_panel.get_theme_stylebox("panel").duplicate(); style.set_content_margin_all(0); map_panel.add_theme_stylebox_override("panel",style)
	map_view = GalaxyMap.new(); map_view.campaign = campaign; map_view.clip_contents = true; map_panel.add_child(map_view)
	if compact: map_view.custom_minimum_size = Vector2(260, 130)
	map_view.field_selected.connect(_field); map_view.mission_selected.connect(_select); map_view.planet_selected.connect(_planet); map_view.region_selected.connect(_region)
	var right := UI.panel(Color("15232a")); right.custom_minimum_size.x = 228 if compact else 330; body.add_child(right)
	var column := UI.column(7); column.custom_minimum_size.x = 212 if compact else 304; right.add_child(column)
	tabs = HBoxContainer.new()
	if compact:
		var tab_row := HBoxContainer.new(); column.add_child(tab_row)
		var previous := UI.button("‹", func(): tab_scroll.scroll_horizontal = maxi(0, tab_scroll.scroll_horizontal - 120))
		previous.tooltip_text = "Scroll tabs left"; tab_row.add_child(previous)
		tab_scroll = ScrollContainer.new(); tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tab_scroll.custom_minimum_size.y = 39; tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_row.add_child(tab_scroll); tab_scroll.add_child(tabs)
		var next := UI.button("›", func(): tab_scroll.scroll_horizontal += 120)
		next.tooltip_text = "Scroll tabs right"; tab_row.add_child(next)
	else: column.add_child(tabs)
	for tab in ["Briefing","Regions","Field ops","Teams","Sith ops"]:
		var button := UI.button(tab,_tab.bind(tab)); button.add_theme_font_size_override("font_size",12 if compact else 11)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.add_child(button)
	var legend := HFlowContainer.new(); legend.add_theme_constant_override("h_separation",14); column.add_child(legend)
	legend.add_child(UI.label("RISK",12,UI.MUTED))
	for i in 4: legend.add_child(UI.label("● " + str(Data.get_table("galaxy","RISK")[i][1]),12,Intel.COLORS[i]))
	legend.add_child(UI.label("◇ Field op   /   Red haze: Darkness + unrest",12,UI.MUTED))
	for item in legend.get_children(): item.autowrap_mode = TextServer.AUTOWRAP_OFF
	if compact: legend.hide()
	var offer_scroll := ScrollContainer.new(); offer_scroll.custom_minimum_size.y = 44 if compact else 70
	offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(offer_scroll)
	if compact: offer_scroll.hide()
	chips = HFlowContainer.new(); chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL; offer_scroll.add_child(chips)
	scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	detail = UI.column(10); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(detail)
	launch_button = UI.button("MISSION BRIEFING  →",_launch); column.add_child(launch_button)
	message = UI.label("Select a world or a signal.  ↑ ↓ offers  ·  Enter briefing  ·  Esc back  ·  T Temple",12,Color("8aa2a5")); outer.add_child(message)
	if compact: message.hide()
	_refresh_chips()

func _refresh_chips() -> void:
	UI.clear(chips)
	for i in campaign.state.options.size():
		var o: Dictionary = campaign.state.options[i]; var m: Dictionary = campaign.story.mission(str(o.mission))
		var rk := Intel.risk(campaign,m,o)
		var b := UI.button("%d  %s\n%s · %s risk" % [i+1,o.get("n",m.get("n",o.mission)),Intel.planet_for(m),rk.name],_select.bind(i))
		b.add_theme_font_size_override("font_size",13); b.add_theme_color_override("font_color",rk.color)
		b.tooltip_text = Intel.deadline(o,campaign.state.options); chips.add_child(b)

func _show_details() -> void:
	if transition and transition.is_running(): transition.kill()
	detail.position.x = 0; detail.modulate.a = 1
	UI.clear(detail); scroll.scroll_vertical = 0
	launch_button.visible = page == "Briefing"
	launch_button.disabled = campaign.state.options.is_empty() or not campaign.state.pending_mission.is_empty()
	if not campaign.state.options.is_empty(): launch_button.disabled = launch_button.disabled or campaign.default_squad(campaign.state.options[selected]).is_empty()
	var project: Dictionary = campaign.sith.project_status()
	status.text = "Cr %d · Intel %d · Favor %d  |  Order Darkness %d/100  |  Sith Darkness %d/12 · next escalation day %d  |  M%d D%d" % [campaign.state.res.credits,campaign.state.res.intel,campaign.state.res.favor,campaign.state.orderDark,project.segments,project.next_escalation,campaign.state.month,campaign.state.day]
	if Phone.narrow(Phone.window_size()):
		status.text = "Cr %d · Intel %d · Favor %d · Darkness %d/100 · Sith %d/12 · M%d D%d" % [campaign.state.res.credits,campaign.state.res.intel,campaign.state.res.favor,campaign.state.orderDark,project.segments,campaign.state.month,campaign.state.day]
	launch_button.disabled = launch_button.disabled or project.defeated
	if campaign.state.get("twin",{}).get("stage", "") == "b":
		detail.add_child(UI.label("FRONT B · fresh squad · up to 4, at most 2 Jedi",16,UI.GOLD))
		detail.add_child(UI.button("Auto resolve (%d%%)" % preload("res://scripts/mission_fronts.gd").auto_odds(campaign.state,campaign.default_squad()),_front_auto))
		detail.add_child(UI.button("Stand down Front B",_front_stand_down))
	for b in tabs.get_children(): b.modulate = Color("79d3e2") if b.text == page else Color.WHITE
	map_view.selected = selected; back_button.visible = not map_view.focused.is_empty()
	match page:
		"Regions": Details.region_panel(self)
		"Field ops": _field_panel()
		"Teams": Details.teams_panel(self)
		"Sith ops": _sith_panel()
		_: Details.mission_panel(self)
	Details.events_panel(self)
	_wire_buttons(detail)

func _choose_event(index: int) -> void:
	if preload("res://scripts/campaign/events11_engine.gd").choose(campaign, index):
		get_node("/root/CampaignFlow").save(); map_view.refresh_signals(); _show_details()
	else: message.text = "Insufficient resources for that choice."

func _choose_crisis(id: String, index: int) -> void:
	if preload("res://scripts/campaign/crisis11_engine.gd").choose(campaign, id, index):
		get_node("/root/CampaignFlow").save(); map_view.refresh_signals(); _show_details()
	else: message.text = "Insufficient resources or the next crisis step is not ready."

func _slide() -> void:
	if transition and transition.is_running(): transition.kill()
	detail.modulate.a = 0.0
	# Child of the scroll container slides in without disturbing the map layout.
	var home := 0.0; detail.position.x = 32
	transition = create_tween().set_parallel(true)
	transition.tween_property(detail,"modulate:a",1.0,0.32)
	transition.tween_property(detail,"position:x",home,0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _tab(value: String) -> void:
	page = value; _show_details(); _slide()

func _select(index: int) -> void:
	if campaign.state.options.is_empty(): return
	selected = clampi(index,0,campaign.state.options.size()-1); page = "Briefing"
	var m: Dictionary = campaign.story.mission(str(campaign.state.options[selected].mission))
	planet = Intel.planet_for(m); region = str(Data.get_table("galaxy","PLANETS")[planet].reg)
	map_view.focus_offer(selected); _show_details(); _slide()

func _planet(title: String) -> void:
	planet = title; region = str(Data.get_table("galaxy","PLANETS")[title].reg)
	for offer in map_view.offers:
		if offer.planet == title: _select(int(offer.index)); return
	map_view.focus_planet(title); page = "Regions"; _show_details(); _slide()

func _region(key: String) -> void:
	region = key; planet = ""; page = "Regions"; _show_details(); _slide()

func _overview() -> void:
	map_view.return_to_overview(); planet = ""; _show_details()

func _back() -> void:
	if not map_view.focused.is_empty(): _overview()
	else: _temple()

func _temple() -> void:
	get_node("/root/CampaignFlow").save(); get_tree().change_scene_to_file("res://scenes/temple.tscn")

func _launch() -> void:
	if campaign.state.options.is_empty() or not campaign.state.pending_mission.is_empty(): return
	get_node("/root/CampaignFlow").prepare_briefing(selected)

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
	field_key = key; page = "Field ops"; _show_details(); _slide()

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
		Details.fact(detail,str(op.n),"Day %d · %s" % [int(op.deadline),str(op.status).capitalize()],UI.GOLD)
		detail.add_child(UI.label(str(op.desc),14))
		for i in campaign.state.options.size():
			var option: Dictionary = campaign.state.options[i]
			if option.get("sith_offer_id", "") == op.mission_id:
				detail.add_child(UI.button("COUNTER MISSION →",get_node("/root/CampaignFlow").prepare_briefing.bind(i),op.status == "open"))
	detail.add_child(UI.button("Intel, teams & rival dossiers",func(): get_node("/root/CampaignFlow").open_intelligence()))
	detail.add_child(UI.label("RIVAL OPERATIONS",18,UI.DANGER))
	for rival in campaign.sith.rivals():
		detail.add_child(UI.label("%s · %s" % [rival.n,str(rival.phase).capitalize()],14,UI.GOLD))
	for i in campaign.state.options.size():
		var option: Dictionary = campaign.state.options[i]
		if option.has("rival_id") or option.get("kind", "") in ["retaliation", "project"]:
			detail.add_child(UI.button(str(option.n),get_node("/root/CampaignFlow").prepare_briefing.bind(i)))
