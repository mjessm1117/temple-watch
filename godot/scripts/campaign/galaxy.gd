extends Control
signal mission_launch_requested(mission_id: String, squad_ids: Array, option: Dictionary)
const Campaign = preload("res://scripts/campaign/state.gd")
const Data = preload("res://scripts/campaign/data.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const GalaxyMap = preload("res://scripts/campaign/galaxy_map.gd")
const Intel = preload("res://scripts/campaign/galaxy_intel.gd")
const Details = preload("res://scripts/campaign/galaxy_details.gd")
const Art = preload("res://scripts/campaign/galaxy_art.gd")
var campaign: Campaign
var selected := 0
var detail: VBoxContainer
var map_view: Control
var message: Label
var status: Label
var tabs: HBoxContainer
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
	var bg := ColorRect.new(); bg.color = Color("0a1113"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var outer := UI.column(10); outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 22; outer.offset_top = 16; outer.offset_right = -22; outer.offset_bottom = -12; add_child(outer)
	var head := HBoxContainer.new(); outer.add_child(head)
	var title := UI.column(0); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(title)
	title.add_child(UI.label("J E D I   T E M P L E   /   W A R   R O O M",12,Color("79d3e2")))
	title.add_child(UI.label("Galaxy command",30,Color("dbe7e4")))
	back_button = UI.button("←  GALAXY", _overview); back_button.visible = false; head.add_child(back_button)
	head.add_child(UI.button("←  TEMPLE",_temple))
	status = UI.label("",14,Color("8aa2a5")); outer.add_child(status)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); outer.add_child(body)
	var left := UI.column(8); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(left)
	var map_panel := UI.panel(Color("0f191c")); map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(map_panel)
	var style := map_panel.get_theme_stylebox("panel").duplicate(); style.set_content_margin_all(0); map_panel.add_theme_stylebox_override("panel",style)
	map_view = GalaxyMap.new(); map_view.campaign = campaign; map_view.clip_contents = true; map_panel.add_child(map_view)
	map_view.field_selected.connect(_field); map_view.mission_selected.connect(_select); map_view.planet_selected.connect(_planet); map_view.region_selected.connect(_region)
	var region_chips := HFlowContainer.new(); region_chips.add_theme_constant_override("h_separation",4); left.add_child(region_chips)
	for row in Data.get_table("galaxy","REGIONS"):
		var b := UI.button(str(row[1]),_region.bind(str(row[0]))); b.custom_minimum_size.y = 28
		b.add_theme_font_size_override("font_size",12); b.tooltip_text = str(row[3]); region_chips.add_child(b)
	var legend := HFlowContainer.new(); legend.add_theme_constant_override("h_separation",14); left.add_child(legend)
	legend.add_child(UI.label("RISK",12,UI.MUTED))
	for i in 4: legend.add_child(UI.label("● " + str(Data.get_table("galaxy","RISK")[i][1]),12,Intel.COLORS[i]))
	legend.add_child(UI.label("◇ Field op   /   Red haze: Darkness + unrest",12,UI.MUTED))
	for item in legend.get_children(): item.autowrap_mode = TextServer.AUTOWRAP_OFF
	var offer_scroll := ScrollContainer.new(); offer_scroll.custom_minimum_size.y = 82; offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; left.add_child(offer_scroll)
	chips = HFlowContainer.new(); chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL; offer_scroll.add_child(chips)
	var right := UI.panel(Color("15232a")); right.custom_minimum_size.x = 390; body.add_child(right)
	var column := UI.column(10); column.custom_minimum_size.x = 360; right.add_child(column)
	tabs = HBoxContainer.new(); column.add_child(tabs)
	for tab in ["Briefing","Regions","Field ops","Teams"]:
		var button := UI.button(tab,_tab.bind(tab)); button.add_theme_font_size_override("font_size",13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.add_child(button)
	scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	detail = UI.column(10); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(detail)
	launch_button = UI.button("MISSION BRIEFING  →",_launch); column.add_child(launch_button)
	message = UI.label("Select a world or a signal.  ↑ ↓ offers  ·  Enter briefing  ·  Esc back  ·  T Temple",12,Color("8aa2a5")); outer.add_child(message)
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
	status.text = "Cr %d    In %d    Ky %d    Senate Favor %d    Recruits %d      /      Darkness %d      /      Month %d · Day %d      /      %d mission signals" % [campaign.state.res.credits,campaign.state.res.intel,campaign.state.res.kyber,campaign.state.res.favor,campaign.state.res.recruits,Intel.darkness(campaign),campaign.state.month,campaign.state.day,campaign.state.options.size()]
	for b in tabs.get_children(): b.modulate = Color("79d3e2") if b.text == page else Color.WHITE
	map_view.selected = selected; back_button.visible = not map_view.focused.is_empty()
	match page:
		"Regions": Details.region_panel(self)
		"Field ops": _field_panel()
		"Teams": Details.teams_panel(self)
		_: Details.mission_panel(self)
	_wire_buttons(detail)

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
	detail.add_child(UI.label("FIELD OPERATIONS",19,Color("79d3e2")))
	detail.add_child(UI.label("Send 2–3 fit soldiers. They are unavailable until their team returns; each mission advances 15 days.",14,UI.MUTED))
	var definitions: Dictionary = Data.get_table("galaxy","FIELD_OPS")
	var picker := OptionButton.new(); picker.custom_minimum_size.y = 38; detail.add_child(picker)
	var keys := definitions.keys()
	for key in keys: picker.add_item(str(definitions[key].n))
	picker.select(keys.find(field_key)); picker.item_selected.connect(func(i: int): field_key = str(keys[i]); _show_details())
	var op: Dictionary = definitions[field_key]
	detail.add_child(UI.label(str(op.desc),15))
	Details.fact(detail,"Duration / difficulty","%d days · %s" % [op.days,"★".repeat(int(op.stars))])
	Details.fact(detail,"Preferred",", ".join(op.want))
	Details.fact(detail,"If it fails","Stress +15 each. Nobody dies.",UI.DANGER)
	var rewards: Dictionary = op.res.duplicate()
	if rewards.has("credits"): rewards.credits = roundi(float(rewards.credits)*float(Data.get_table("galaxy","FIELD").cr)*float(Data.get_table("missions","DIFF")[campaign.state.diff].income))
	Details.fact(detail,"Reward",Intel.resources(rewards)+" · 15 XP per soldier")
	if op.has("fee"): Details.fact(detail,"Fee","%d Credits" % int(op.fee))
	for r in campaign.state.roster:
		if r.status != "active" or int(r.wound) > 0 or str(r.assign) != "": continue
		var b := UI.button("%s %s · %s R%d" % ["✓" if field_team.has(r.id) else "+",r.n,r.cls,r.rank],_toggle_field.bind(str(r.id)))
		b.add_theme_font_size_override("font_size",13); b.custom_minimum_size.y = 30; detail.add_child(b)
	var odds: int = campaign.field_odds(field_key,field_team)
	Details.fact(detail,"Success","%d%% · %d / 3 soldiers" % [odds,field_team.size()])
	detail.add_child(UI.button("SEND TEAM  →",_send_field.bind(field_key),odds > 0 and int(campaign.state.res.credits) >= int(op.get("fee",0))))
	detail.add_child(UI.label("TEAMS IN FLIGHT",16,Color("79d3e2")))
	var flying := 0
	for f in campaign.state.field.list:
		if f.st != "team": continue
		flying += 1; var names := PackedStringArray()
		for id in f.team: names.append(str(campaign.soldier(str(id)).get("n",id)))
		Details.fact(detail,str(definitions[f.k].n),"%s · %s\nBack in %d days · %d%% success" % [Intel.operation_planet(campaign,f),", ".join(names),f.left,f.ch])
	if flying == 0: detail.add_child(UI.label("No teams away.",14,UI.MUTED))
	detail.add_child(UI.label("FIELD LOG",16,Color("79d3e2")))
	for entry in campaign.state.field.log:
		detail.add_child(UI.label("M%d · %s · %s" % [entry.month,definitions[entry.k].n,"Success" if entry.win else "Failed"],13,UI.MUTED))
	if campaign.state.field.log.is_empty(): detail.add_child(UI.label("No completed operations yet.",14,UI.MUTED))

func _toggle_field(id: String) -> void:
	if field_team.has(id): field_team.erase(id)
	elif field_team.size() < 3: field_team.append(id)
	_show_details()

func _send_field(key: String) -> void:
	if campaign.send_field_op(key,field_team):
		field_team.clear(); get_node("/root/CampaignFlow").save()
		message.text = "%s team deployed. Track its shuttle on the map." % Data.get_table("galaxy","FIELD_OPS")[key].n
		map_view.refresh_signals(); _refresh_chips(); _show_details()
	else: message.text = "Choose 2–3 available soldiers and check the operation fee."

func _wire_buttons(node: Node) -> void:
	if node is BaseButton and not node.has_meta("galaxy_sound"):
		node.set_meta("galaxy_sound",true)
		node.mouse_entered.connect(func(): if is_instance_valid(sound) and not node.disabled: sound.play())
	for child in node.get_children(): _wire_buttons(child)

func _field(key: String) -> void:
	field_key = key; page = "Field ops"; _show_details(); _slide()
