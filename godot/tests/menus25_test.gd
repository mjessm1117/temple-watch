extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Room = preload("res://scripts/w25_menus_room_story.gd")
const UI = preload("res://scripts/campaign/ui.gd")
var checks := 0
var failures := 0
var capture_mode := false

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MENUS25: " + detail)

func settle(frames: int = 12) -> void:
	for i in frames: await process_frame

func resize_to(dimensions: Vector2i) -> void:
	DisplayServer.window_set_size(dimensions)
	root.size = dimensions
	root.content_scale_size = dimensions

func capture(label: String) -> void:
	if not capture_mode: return
	await RenderingServer.frame_post_draw
	var path := "/home/jess/projects/tw-logs/w25/menus/" + label + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + label)

func within(node: Control) -> bool:
	if node == null: return false
	var rect := node.get_global_rect()
	var view := Rect2(Vector2.ZERO, Vector2(root.size))
	return rect.size.x >= 44 and rect.size.y >= 44 and view.encloses(rect)

func run() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	Phone.test_touch = 1
	Phone.test_mobile = 1
	resize_to(Vector2i(390, 844))
	var flow := root.get_node("CampaignFlow")
	flow.fade_duration = 0.01
	flow.go("menu")
	await settle()
	var clock := Time.get_ticks_msec()
	flow.open_settings()
	print("MENUS25 latency settings %d ms" % (Time.get_ticks_msec() - clock))
	await settle()
	var panel: Control = flow.settings_panel
	var scroll: ScrollContainer = panel.find_child("SettingsScroll", true, false)
	var back: Button = panel.find_child("SettingsBack", true, false)
	var controls: Control = panel.find_child("ControlsSection", true, false)
	await capture("after-settings-390x844")
	check(scroll != null and controls != null and within(back), "portrait settings sticky Back and controls")
	var remaps: Array = controls.key_buttons.values()
	check(not remaps.is_empty(), "settings has remap buttons")
	var last: Button = remaps.back()
	var start := scroll.get_global_rect().get_center()
	var down := InputEventScreenTouch.new(); down.position = start; down.pressed = true
	scroll._gui_input(down)
	for i in 14:
		var drag := InputEventScreenDrag.new()
		drag.position = start + Vector2(0, -85 * (i + 1))
		scroll._gui_input(drag)
	await settle()
	check(scroll.scroll_vertical > 0 and scroll.get_global_rect().intersects(last.get_global_rect()), "finger drag reaches final remap")
	await capture("after-settings-bottom-390x844")
	flow.open_settings()
	flow.open_settings()
	await settle()
	scroll = flow.settings_panel.find_child("SettingsScroll", true, false)
	var stored := ConfigFile.new()
	check(stored.load("user://settings25.cfg") == OK and int(stored.get_value("settings", "w25_scroll", 0)) > 0, "settings scroll saved to device")
	check(scroll.scroll_vertical > 0 and within(flow.settings_panel.find_child("SettingsBack", true, false)), "scroll position restored and Back fixed")
	flow.open_settings()
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	var temple: Control = load("res://scenes/temple.tscn").instantiate()
	var old_scene := current_scene
	root.add_child(temple)
	current_scene = temple
	old_scene.queue_free()
	await settle(30)
	resize_to(Vector2i(390, 844))
	flow.open_settings()
	await settle(3)
	check(is_instance_valid(flow.settings_panel) and within(flow.settings_panel.find_child("SettingsBack", true, false)), "Temple opens same settings sheet")
	flow.open_settings()
	var before := int(flow.campaign.state.res.get("favor", 0))
	clock = Time.get_ticks_msec()
	check(flow.open_room_story25("archives"), "Archives beat opens")
	print("MENUS25 latency room %d ms" % (Time.get_ticks_msec() - clock))
	var card: Control = current_scene.find_child("RoomStory25", true, false)
	await settle(4)
	await capture("after-room-390x844")
	check(card != null and within(card.find_child("RoomStoryBack", true, false)) and within(card.find_child("RoomChoice1", true, false)), "room card has reachable Back and choices")
	card._choose(0)
	await settle(2)
	check(not flow.open_room_story25("archives") and int(flow.campaign.state.res.get("favor", 0)) == before + 1, "room beat plays once and applies effect")
	var reloaded := Campaign.new()
	check(reloaded.load_save(flow.save_path) and reloaded.state.get("w25_room_seen", {}).has("archives_lamp") and reloaded.state.get("w25_room_journal", []).size() == 1, "room effect and Journal line persist")
	flow.open_saves("temple")
	await settle(20)
	var saves = current_scene
	var first_row: PanelContainer = saves.list.get_child(0)
	var first_column: VBoxContainer = first_row.get_child(1)
	check(str(first_column.get_child(0).text).begins_with("CURRENT") and not saves._mission_name(0).is_empty(), "current save highlighted with mission")
	await capture("after-save-390x844")
	flow.go("temple")
	await settle(20)
	flow.campaign.state.story.done = 1
	var living: Array = flow.campaign.state.roster.filter(func(r): return str(r.get("status", "")) == "active")
	check(living.size() >= 2 and not Room.due(flow.campaign, "barracks").is_empty(), "optional living soldier bond beat due")
	check(Room.due(flow.campaign, "memorial").is_empty(), "Memorial waits for a fallen soldier")
	living[0].status = "dead"
	check(not Room.due(flow.campaign, "memorial").is_empty(), "Memorial response due after a loss")
	var memory_before := int(flow.campaign.state.res.get("favor", 0))
	check(flow.open_room_story25("memorial"), "fallen soldier memory opens")
	current_scene.find_child("RoomStory25", true, false)._choose(0)
	await settle(2)
	check(int(flow.campaign.state.res.get("favor", 0)) == memory_before + 1, "Memorial answer has persistent resolve effect")
	living[0].status = "active"
	check(flow.open_room_story25("barracks"), "living soldier conversation opens")
	current_scene.find_child("RoomStory25", true, false)._choose(0)
	check(not flow.campaign.state.bonds.is_empty() and flow.campaign.state.get("w25_room_journal", []).size() == 3, "Barracks bond and follow-ups persist")
	var hint_label := UI.label("hint", 12, Color("627d87"))
	check(hint_label.get_theme_font_size("font_size") >= 14 and UI._contrast(UI.readable(Color("627d87")), UI.PANEL_ALT) >= 4.5 and UI._contrast(UI.HINT, UI.PANEL_ALT) >= 4.5 and UI._contrast(UI.SECONDARY, UI.PANEL_ALT) >= 4.5, "shared hint and secondary size and contrast")
	hint_label.free()
	var option: Dictionary = flow.campaign.state.options[0]
	clock = Time.get_ticks_msec()
	flow.launch_ready25(str(option.get("mission", "")))
	print("MENUS25 latency readiness %d ms" % (Time.get_ticks_msec() - clock))
	await settle(30)
	resize_to(Vector2i(390, 844))
	await settle(3)
	check(current_scene.name == "Readiness25", "mission opens one readiness page")
	var ready = current_scene
	await capture("after-readiness-390x844")
	check(within(ready.find_child("ReadyBack", true, false)) and within(ready.find_child("ReadyDeploy", true, false)), "readiness Back and Deploy visible")
	if not ready.choice_buttons.is_empty(): ready._choose(str(flow.screen.choices[0].id))
	ready._confirm()
	check(ready.find_child("ReadyConfirm", true, false) != null and (1 if ready.choice_buttons.is_empty() else 2) + 1 <= 3, "Deploy needs one confirm in three taps or fewer")
	flow.back_from_ready25()
	await settle(30)
	check(current_scene.scene_file_path.ends_with("galaxy.tscn"), "Back returns to Galaxy")
	for dimensions in [Vector2i(390, 844), Vector2i(844, 390)]:
		resize_to(dimensions)
		await settle()
		if dimensions.x > dimensions.y:
			check(flow.open_room_story25("forge"), "landscape room beat opens")
			var land_card: Control = current_scene.find_child("RoomStory25", true, false)
			await settle(3)
			check(within(land_card.find_child("RoomStoryBack", true, false)) and within(land_card.find_child("RoomChoice1", true, false)), "landscape room controls inside viewport")
			land_card.queue_free()
			flow.launch_ready25(str(option.get("mission", "")))
			await settle(6)
			resize_to(dimensions)
			check(within(current_scene.find_child("ReadyBack", true, false)) and within(current_scene.find_child("ReadyDeploy", true, false)), "landscape readiness controls inside viewport")
			flow.back_from_ready25()
			await settle(20)
			resize_to(dimensions)
		var defeat: Control = load("res://scenes/dialogue.tscn").instantiate()
		defeat.set_campaign_state(flow.campaign.state)
		defeat.show_scene({"kind":"debrief", "name":"Satele Shan", "title":"The plaza is lost", "text":"The plaza is lost.", "choices":[{"id":"a", "label":"Keep faith"}, {"id":"b", "label":"Hold the line"}]})
		root.add_child(defeat)
		await settle()
		defeat._skip_dialogue()
		await settle()
		await capture("after-defeat-%dx%d" % [dimensions.x, dimensions.y])
		check(defeat.phone_decisions != null and defeat.phone_decisions.visible and defeat.choice_buttons.all(func(button): return within(button)), "defeat choices visible at %s" % str(dimensions))
		defeat.queue_free()
		await settle(2)
		if dimensions.x > dimensions.y:
			flow.open_settings()
			await settle()
			await capture("after-settings-844x390")
			check(within(flow.settings_panel.find_child("SettingsBack", true, false)), "landscape settings Back inside viewport")
			flow.open_settings()
	resize_to(Vector2i(1366, 768))
	await settle()
	flow.open_settings()
	await settle()
	await capture("after-settings-1366x768")
	check(within(flow.settings_panel.find_child("SettingsBack", true, false)), "desktop settings Back inside viewport")
	flow.open_settings()
	var wide_temple: Control = load("res://scenes/temple.tscn").instantiate()
	var wide_previous := current_scene
	root.add_child(wide_temple)
	current_scene = wide_temple
	wide_previous.queue_free()
	await settle(12)
	flow.campaign.state.story.done = 2
	check(flow.open_room_story25("council"), "Council beat opens at progress gate")
	var wide_card: Control = current_scene.find_child("RoomStory25", true, false)
	await settle(4)
	await capture("after-room-1366x768")
	check(within(wide_card.find_child("RoomStoryBack", true, false)) and within(wide_card.find_child("RoomChoice1", true, false)), "desktop room card controls inside viewport")
	wide_card.queue_free()
	if capture_mode:
		current_scene.queue_free()
		await settle(3)
		flow.campaign = null
		flow.story = null
		UI.fonts.clear()
		print("menus25_capture: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	flow.go("galaxy")
	await settle(20)
	flow.launch_ready25(str(option.get("mission", "")))
	await settle(8)
	var final_ready = current_scene
	check(within(final_ready.find_child("ReadyBack", true, false)) and within(final_ready.find_child("ReadyDeploy", true, false)), "desktop readiness controls inside viewport")
	if not final_ready.choice_buttons.is_empty(): final_ready._choose(str(flow.screen.choices[0].id))
	final_ready._confirm()
	final_ready._launch()
	check(flow.campaign.state.flow_stage == "battle", "confirmed readiness actually launches mission")
	await settle(30)
	check(current_scene.scene_file_path.ends_with("rescue.tscn"), "launch reaches battle")
	var night = current_scene.hud_controls.night
	night.pause_back.visible = true
	night.settings_box.visible = true
	await settle(6)
	check(is_instance_valid(flow.settings_panel) and flow.settings_panel.find_child("SettingsScroll", true, false) != null, "pause Settings routes to shared sheet")
	if is_instance_valid(flow.settings_panel): flow.open_settings()
	night.settings_box.visible = false
	night.pause_back.visible = false
	var phone_hud = current_scene.hud_controls.phone
	if phone_hud != null:
		phone_hud._show_menu()
		phone_hud._show_settings()
		await settle(6)
		check(is_instance_valid(flow.settings_panel) and flow.settings_panel.find_child("SettingsScroll", true, false) != null, "battle phone Settings routes to shared sheet")
		if is_instance_valid(flow.settings_panel): flow.open_settings()
	current_scene.queue_free()
	await settle(3)
	flow.campaign = null
	flow.story = null
	UI.fonts.clear()
	print("menus25_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
