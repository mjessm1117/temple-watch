extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Layout = preload("res://scripts/hud_phone_layout.gd")
const OUT := "/home/jess/projects/tw-logs/w26/hud/captures/"
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func settle(count: int = 3) -> void:
	for i in count: await process_frame

func source(path: String) -> String:
	return FileAccess.get_file_as_string("res://scripts/" + path)

func geometry(size: Vector2i) -> void:
	root.content_scale_size = size
	var boxes: Dictionary = Layout.boxes(Vector2(size))
	check(Layout.ACTION_MIN_SIZE.x >= 44 and Layout.ACTION_MIN_SIZE.y >= 44, "layout action minimum is 44 x 44")
	var portrait_box: Rect2 = boxes.plate if size.y > size.x else boxes.portrait
	check(portrait_box.position.y >= boxes.header.end.y, str(size) + " portrait below header")
	check(portrait_box.position.y < boxes.tray.position.y, str(size) + " portrait above actions")
	check(boxes.tray.size.y >= 44, str(size) + " tray contains 44 px controls")
	check(boxes.tray.size.x >= 48, str(size) + " action tray width")

func battle(size: Vector2i) -> void:
	print("PHONE26 scene ", size)
	Phone.test_window_size = size
	Phone.test_touch = 1
	Phone.test_mobile = 1
	DisplayServer.window_set_size(size)
	root.size = size
	root.content_scale_size = size
	root.get_node("Graphics").select_tier("low", false)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://phone26-%d.json" % OS.get_process_id()
	var campaign = Campaign.new("normal")
	campaign.select_mission(0)
	campaign.state.flow_stage = "battle"
	flow.campaign = campaign
	flow.story = campaign.story
	flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	print("PHONE26 scene added ", size)
	await settle(18)
	print("PHONE26 scene settled ", size)
	flow.active = false
	game.demo_mode = true
	game.phase_banner.hide()
	var hud = game.hud_controls.phone
	check(hud != null, str(size) + " phone HUD exists")
	if hud != null:
		game._refresh()
		await settle(4)
		var menu: Button = hud.overlay.find_child("PhoneMenu", true, false)
		check(menu.size.x >= 44 and menu.size.y >= 44, str(size) + " menu touch area")
		check(game.objective_label.size.y >= 20, str(size) + " sight label has visible height")
		if size.x < size.y:
			var sight_width: float = game.objective_label.get_theme_font("font").get_string_size(game.objective_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, game.objective_label.get_theme_font_size("font_size")).x
			check(sight_width <= game.objective_label.size.x, "portrait sight line fits")
		var selected: Dictionary = game.mission.unit_by_id(game.selected_id)
		var original_name := str(selected.name)
		selected.name = "Sgt. Rhal D"
		hud.refresh(true)
		check(hud.unit_card.text.contains("Sgt. Rhal D"), str(size) + " full name remains in unit button")
		check(hud.unit_card_readout.text.begins_with("Sgt.\nRhal D"), str(size) + " long rank and surname split")
		selected.name = original_name
		hud.refresh(true)
		check(hud.unit_portrait.get_global_rect().position.y < hud.ability_tray.get_global_rect().position.y, str(size) + " portrait is above tray")
		check(not hud.ability_tray.is_ancestor_of(hud.action_art), str(size) + " caption canvas is outside button VBox")
		for button in hud.ability_buttons:
			if button.visible:
				check(button.size.x >= 44 and button.size.y >= 44, str(size) + " action touch area " + button.ability_id)
		check(hud.overlay.find_child("PhoneObjectiveSummary", false, false) != null, str(size) + " bottom objective label")
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(OUT)
		await settle(2)
		var path := OUT + "gate-%dx%d-low.png" % [size.x, size.y]
		check(root.get_texture().get_image().save_png(path) == OK, "capture " + path)
	game.queue_free()
	await settle(3)

func run() -> void:
	print("PHONE26 start")
	var hud_source := source("hud_phone.gd")
	check(not hud_source.contains(char(0x2212)), "HUD has no Unicode minus")
	check(not hud_source.contains(char(0x25CF)), "HUD has no black circle glyph")
	var marker_source := source("reinforcement_marker.gd")
	for index in marker_source.length():
		check(marker_source.unicode_at(index) < 128, "reinforcement marker uses ASCII text")
	var art_source := source("hud_phone_action_art.gd")
	check(art_source.contains("button.size.y + 13"), "caption is below button touch slot")
	check(art_source.contains("draw_arc(at + Vector2(button.size.x * 0.5, 23)"), "ring remains inside button slot")
	for size in [Vector2i(852, 393), Vector2i(844, 390), Vector2i(390, 844)]:
		geometry(size)
		await battle(size)
	print("PHONE26: %d checks, %d failures" % [checks, failures])
	quit(failures)
