extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Squad = preload("res://scripts/campaign/squad.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const GraphicsOptions = preload("res://scripts/graphics_options.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const StylePrefs = preload("res://scripts/campaign/style21_preferences.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0
var capture := false
const OUT = "/home/jess/projects/tw-logs/w21/armory/"

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ARMORY21: " + message)

func resize_to(value: Vector2i) -> void:
	DisplayServer.window_set_min_size(Vector2i(1, 1))
	DisplayServer.window_set_size(value)
	root.size = value
	root.content_scale_size = value
	for i in 4: await process_frame

func shot(label: String) -> void:
	if not capture: return
	for i in 8: await process_frame
	await create_timer(0.2).timeout
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "capture " + label)

func luminance(color: Color) -> float:
	var channels := [color.r, color.g, color.b]
	for i in 3: channels[i] = channels[i] / 12.92 if channels[i] <= 0.04045 else pow((channels[i] + 0.055) / 1.055, 2.4)
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]

func contrast(a: Color, b: Color) -> float:
	var first := luminance(a)
	var second := luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)

func check_themed(node: Node) -> void:
	if node is Button and node.has_theme_stylebox_override("normal"):
		var button := node as Button
		var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
		var disabled := button.get_theme_stylebox("disabled") as StyleBoxFlat
		if normal != null and button.text != "": check(contrast(button.get_theme_color("font_color"), normal.bg_color) >= 4.5, button.name + " normal AA")
		if disabled != null and button.text != "": check(contrast(button.get_theme_color("font_disabled_color"), disabled.bg_color) >= 4.5, button.name + " disabled AA")
	for child in node.get_children(): check_themed(child)

func check_fonts(node: Node) -> void:
	if node is Label and node.visible:
		check((node as Label).get_theme_font_size("font_size") >= 14, node.name + " phone font " + (node as Label).text + " " + str((node as Label).get_theme_font_size("font_size")))
	for child in node.get_children(): check_fonts(child)

func swipe(viewport: Viewport, from: Vector2, delta: Vector2) -> void:
	var down := InputEventScreenTouch.new(); down.index = 0; down.position = from; down.pressed = true
	viewport.push_input(down, true)
	for step in 5:
		var drag := InputEventScreenDrag.new(); drag.index = 0
		drag.position = from + delta * float(step + 1) / 5.0
		drag.relative = delta / 5.0
		viewport.push_input(drag, true)
		await process_frame
	var up := InputEventScreenTouch.new(); up.index = 0; up.position = from + delta; up.pressed = false
	viewport.push_input(up, true)
	await process_frame

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory21-test.json"
	flow.campaign = Campaign.new("normal")
	flow.story = flow.campaign.story
	flow.active = true
	flow.campaign.state.flow_stage = "temple"
	flow.campaign.state.erase("pending")
	var mission_selection: Array = flow.campaign.state.get("loadout_squad", []).duplicate()
	var visited: Array[String] = []
	var track_scene := func() -> void: visited.append(current_scene.scene_file_path if current_scene != null else "")
	scene_changed.connect(track_scene)
	for size in [Vector2i(844, 390)]:
		await resize_to(size)
		var old := Control.new(); old.name = "TempleFixture"; root.add_child(old); current_scene = old
		var squad: Control = Squad.open_from_temple(self, "u6")
		for i in 6: await process_frame
		check(current_scene == squad and squad.from_temple, "%s temple entry opens squad stage" % size)
		check(squad.focus_index >= 0 and str(squad.selected[squad.focus_index]) == "u6", "%s selected soldier kept" % size)
		check(squad.drawer.visible and squad.arsenal != null, "%s gear drawer opens" % size)
		check(not squad.deploy.visible, "%s Deploy hidden" % size)
		check_themed(squad)
		check_fonts(squad)
		await shot("after-armory-%dx%d" % [size.x, size.y])
		visited.clear()
		squad.footer.get_child(0).pressed.emit()
		for i in 6: await process_frame
		check("res://scenes/temple.tscn" in visited, "%s Done returns Temple" % size)
		check(str(flow.session().state.get("armory_selected_id", "")) == "u6", "%s soldier preserved on return" % size)
		check(flow.session().state.get("loadout_squad", []) == mission_selection, "Armory inspection keeps mission squad")
		var reopened: Control = Squad.open_from_temple(self)
		for i in 4: await process_frame
		check(reopened.focus_index >= 0 and str(reopened.selected[reopened.focus_index]) == "u6", "Armory reopens the same soldier")
		reopened.queue_free(); current_scene = null
		await process_frame
	Phone.test_mobile = 1
	var portrait_viewport := SubViewport.new()
	portrait_viewport.size = Vector2i(390, 844)
	portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(portrait_viewport)
	var portrait_squad: Control = load("res://scenes/squad.tscn").instantiate()
	portrait_squad.from_temple = true
	portrait_squad.temple_soldier_id = "u6"
	portrait_viewport.add_child(portrait_squad)
	for i in 6: await process_frame
	check(portrait_squad.size == Vector2(390, 844), "portrait squad fills phone viewport")
	check(portrait_squad.focus_index >= 0 and portrait_squad.drawer.visible and not portrait_squad.deploy.visible, "portrait armory inspection available")
	check_themed(portrait_squad)
	check_fonts(portrait_squad)
	if capture: check(portrait_viewport.get_texture().get_image().save_png(OUT + "after-armory-390x844.png") == OK, "portrait armory capture")
	var gear_scroll: ScrollContainer = portrait_squad.arsenal.get_parent()
	var slot: Button = portrait_squad.arsenal.slot_row.get_node("Slot_armor")
	portrait_squad.arsenal._select_slot("armor")
	for i in 3: await process_frame
	gear_scroll.scroll_vertical = 0
	await process_frame
	var slot_before: String = portrait_squad.arsenal.active_slot
	await swipe(portrait_viewport, slot.get_global_rect().get_center(), Vector2(0, -120))
	var overflow := gear_scroll.get_v_scroll_bar().max_value > gear_scroll.get_v_scroll_bar().page + 1
	check(gear_scroll.scroll_vertical > 0 if overflow else gear_scroll.scroll_vertical == 0, "portrait gear list drags from a slot")
	check(portrait_squad.arsenal.active_slot == slot_before, "portrait drag does not equip")
	portrait_squad.queue_free(); await process_frame
	var panel := GraphicsOptions.build_settings_panel()
	root.add_child(panel)
	await process_frame
	check(panel is Control and panel.name == "SettingsPanel", "settings builder returns reusable Control")
	check(panel.find_child("GraphicsTier", true, false) is OptionButton, "graphics tier available")
	var text_size := panel.find_child("TextSize", true, false) as OptionButton
	check(text_size != null and text_size.item_count == 3, "text sizes available")
	text_size.item_selected.emit(1)
	check(is_equal_approx(float(StylePrefs.get_value("text_scale")), 1.15), "text size setting works")
	text_size.item_selected.emit(0)
	var sound := panel.find_child("Sound", true, false) as OptionButton
	check(sound != null, "sound setting available")
	sound.item_selected.emit(1)
	check(AudioServer.is_bus_mute(0), "sound mute applies")
	sound.item_selected.emit(0)
	check(not AudioServer.is_bus_mute(0), "sound restores")
	var camera := panel.find_child("ActionCamera", true, false) as OptionButton
	check(camera != null and panel.find_child("CameraMotion", true, false) != null, "camera settings available")
	check_themed(panel)
	check_fonts(panel)
	panel.queue_free(); await process_frame
	var temple: Control = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple)
	temple._change_page("Roster")
	for i in 3: await process_frame
	var heading_found := false
	for entry in temple.page_content.find_children("*", "Label", true, false):
		if (entry as Label).text.begins_with("RECRUITS") and (entry as Label).text.contains("CAPACITY"):
			heading_found = true
			break
	check(heading_found, "roster starts with candidates and capacity")
	temple.queue_free(); await process_frame
	var soldier: Dictionary = flow.campaign.soldier("u1")
	soldier.rank = 3; soldier.picks = ["guardian_deflect", "guardian_brace"]; soldier.pick = 3
	await resize_to(Vector2i(844, 390))
	var screen := Promotion.new(); root.add_child(screen); screen.setup(flow.campaign, "u1")
	for i in 6: await process_frame
	var grid: GridContainer = screen.rank_rows[3].find_child("ChoiceGrid", true, false)
	check(grid.columns == 2, "844 promotion choices side by side")
	var visible_bounds: Rect2 = screen.scroll.get_global_rect()
	for card in screen.cards.values():
		var bounds: Rect2 = card.get_global_rect()
		check(bounds.position.y >= visible_bounds.position.y - 1 and bounds.end.y <= visible_bounds.end.y + 1, "promotion choice visible without scrolling")
		check(card.find_child("Metric_*", true, false) is Label and (card.find_child("Metric_*", true, false) as Label).get_global_rect().end.y <= bounds.end.y, "promotion number shown")
	check_themed(screen)
	check_fonts(screen)
	await shot("after-promotion-844x390")
	screen.queue_free(); await process_frame
	screen = Promotion.new(); portrait_viewport.add_child(screen); screen.setup(flow.campaign, "u1")
	for i in 6: await process_frame
	check(screen.confirm.get_global_rect().end.x <= 390, "portrait promotion controls fit")
	check_fonts(screen)
	if capture: check(portrait_viewport.get_texture().get_image().save_png(OUT + "after-promotion-390x844.png") == OK, "portrait promotion capture")
	screen.queue_free(); await process_frame
	portrait_viewport.queue_free(); Phone.test_mobile = -1
	print("ARMORY21: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
