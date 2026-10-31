extends Control
signal mission_launch_requested(mission_id: String, squad_ids: Array, option: Dictionary)
const Campaign = preload("res://scripts/campaign/state.gd")
const Data = preload("res://scripts/campaign/data.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const GalaxyMap = preload("res://scripts/campaign/galaxy_map.gd")
var campaign: Campaign = Campaign.new()
var selected := 0
var detail: VBoxContainer
var map_view: Control
var message: Label

func _ready() -> void:
	campaign = get_node("/root/CampaignFlow").session()
	_build()
	_show_details()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_T:
			_back(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP or event.keycode == KEY_DOWN:
			var direction := -1 if event.keycode == KEY_UP else 1
			selected = posmod(selected + direction, maxi(1, campaign.state.options.size()))
			_show_details(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			_launch(); get_viewport().set_input_as_handled()

func _build() -> void:
	var bg := ColorRect.new(); bg.color = UI.BG; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var outer := UI.column(15); outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 30; outer.offset_top = 22; outer.offset_right = -30; outer.offset_bottom = -22; add_child(outer)
	var head := HBoxContainer.new(); outer.add_child(head)
	var title := UI.column(0); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(title)
	title.add_child(UI.label("GALAXY COMMAND", 38, UI.ACCENT))
	title.add_child(UI.label("Choose the Order’s next mission  /  select a signal to inspect", 16, UI.MUTED))
	head.add_child(UI.button("←  TEMPLE", _back))
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 16); outer.add_child(body)
	var left := UI.column(13); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(left)
	var map_panel := UI.panel(); map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(map_panel)
	map_view = GalaxyMap.new(); map_view.campaign = campaign; map_view.selected = selected
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL; map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.mission_selected.connect(_select)
	map_panel.add_child(map_view)
	var legend := UI.panel(); left.add_child(legend)
	legend.add_child(UI.label("●  Story signal       ●  Crisis signal       •  Planet       │  Arrow keys: choose    Enter: launch", 15, UI.MUTED))
	var right := UI.panel(); right.custom_minimum_size.x = 460; body.add_child(right)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; right.add_child(scroll)
	detail = UI.column(12); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(detail)
	message = UI.label("", 14, UI.GOLD)
	outer.add_child(message)

func _show_details() -> void:
	UI.clear(detail)
	map_view.selected = selected; map_view.queue_redraw()
	var options: Array = campaign.state.options
	if options.is_empty():
		detail.add_child(UI.label("No active missions", 25, UI.GOLD))
		detail.add_child(UI.label("This chapter is complete. Return to the Temple to continue the Order’s story.", 16, UI.MUTED))
		return
	selected = clampi(selected, 0, options.size() - 1)
	var o: Dictionary = options[selected]
	var m: Dictionary = get_node("/root/CampaignFlow").story.mission(str(o.mission))
	detail.add_child(UI.label("MISSION SIGNALS  ·  %d AVAILABLE" % options.size(), 15, UI.ACCENT))
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var mission: Dictionary = get_node("/root/CampaignFlow").story.mission(str(option.mission))
		var b := UI.button("%d  %s" % [i + 1, option.get("n", mission.get("n", option.mission))], _select.bind(i))
		b.button_pressed = i == selected
		detail.add_child(b)
	var sep := HSeparator.new(); detail.add_child(sep)
	detail.add_child(UI.label(str(o.get("n", m.get("n", o.mission))), 27, UI.GOLD))
	detail.add_child(UI.label("%s  ·  %s" % [str(o.get("kind", "Story")), str(m.get("where", "Unknown region"))], 15, UI.ACCENT))
	detail.add_child(UI.label(str(o.get("text", m.get("brief", "Awaiting mission briefing."))), 16, UI.TEXT))
	detail.add_child(UI.label("OBJECTIVE: %s" % str(m.get("type", "Mission")).to_upper(), 15, UI.MUTED))
	var reward: Dictionary = m.get("reward", {})
	var reward_text := []
	for key in reward: reward_text.append("%s +%d" % [str(key).capitalize(), int(reward[key])])
	detail.add_child(UI.label("REWARD: %s" % (", ".join(reward_text) if int(campaign.state.wings.comms) > 0 or bool(o.get("story", false)) else "Build Comms Hub to reveal"), 15, UI.MUTED))
	if o.has("ignore") and not o.ignore.is_empty():
		var penalty := []
		for key in o.ignore: penalty.append("%s %d" % [str(key).capitalize(), int(o.ignore[key])])
		detail.add_child(UI.label("IF IGNORED: %s" % ", ".join(penalty), 15, UI.DANGER))
	var squad: Array = campaign.default_squad(o)
	var names := []
	for id in squad: names.append(str(campaign.soldier(str(id)).n))
	detail.add_child(UI.label("AVAILABLE ROSTER  ·  %s" % ", ".join(names), 15, UI.MUTED))
	detail.add_child(UI.button("MISSION BRIEFING  →", _launch, not squad.is_empty() and campaign.state.pending_mission.is_empty()))
	if not campaign.state.pending_mission.is_empty(): detail.add_child(UI.label("Deployment ready. Return to the Temple to resume.", 15, UI.GOLD))
	var field_box := UI.panel(UI.PANEL_ALT); detail.add_child(field_box)
	var f := UI.column(7); field_box.add_child(f)
	f.add_child(UI.label("FIELD OPERATIONS", 18, UI.ACCENT))
	f.add_child(UI.label("Send 2–3 fit soldiers away for 15–30 days. They return with experience and resources.", 14, UI.MUTED))
	for key in ["convoy", "smugglers", "pirates"]:
		var item: Dictionary = Data.get_table("galaxy", "FIELD_OPS")[key]
		f.add_child(UI.button("%s  ·  %d days" % [item.n, int(item.days)], _send_field.bind(key)))
	var teams := UI.panel(UI.PANEL_ALT); detail.add_child(teams)
	var t := UI.column(5); teams.add_child(t)
	t.add_child(UI.label("STRIKE TEAMS  ·  %d / 4" % campaign.team_capacity(), 18, UI.ACCENT))
	for team in campaign.state.teams: t.add_child(UI.label(str(team.n), 15, UI.MUTED))
	if str(o.get("crisis", "")) != "" and options.size() > 1:
		var assignment := UI.panel(UI.PANEL_ALT); detail.add_child(assignment)
		var a := UI.column(5); assignment.add_child(a)
		a.add_child(UI.label("SECOND SQUAD", 18, UI.ACCENT))
		a.add_child(UI.label("Assign a team here. It will resolve this crisis when you launch a different mission.", 14, UI.MUTED))
		for team in campaign.state.teams:
			a.add_child(UI.button("Assign %s%s" % [team.n, "  ✓" if str(campaign.state.team_assignments.get(str(o.crisis), "")) == str(team.id) else ""], _assign_team.bind(str(o.crisis), str(team.id))))

func _select(index: int) -> void:
	selected = index; _show_details()

func _send_field(key: String) -> void:
	var ids := campaign.default_squad()
	if ids.size() >= 2 and campaign.send_field_op(key, [ids[0], ids[1]]):
		get_node("/root/CampaignFlow").save(); message.text = "%s team deployed." % Data.get_table("galaxy", "FIELD_OPS")[key].n
func _assign_team(crisis: String, team_id: String) -> void:
	if campaign.assign_team_to_crisis(crisis, team_id):
		get_node("/root/CampaignFlow").save()
		_show_details()

func _launch() -> void:
	if campaign.state.options.is_empty() or not campaign.state.pending_mission.is_empty(): return
	get_node("/root/CampaignFlow").prepare_briefing(selected)

func _back() -> void:
	get_node("/root/CampaignFlow").save()
	get_tree().change_scene_to_file("res://scenes/temple.tscn")
