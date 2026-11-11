extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Scene = preload("res://scenes/temple.tscn")
const Badges = preload("res://scripts/campaign/home_badges.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0
var display: SubViewport

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle() -> void:
	for i in 5: await process_frame

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var path := "/home/jess/projects/tw-logs/w21/temple/after-%s-%dx%d.png" % [name, display.size.x, display.size.y]
	check(display.get_texture().get_image().save_png(path) == OK, "capture " + name)

func run() -> void:
	var size := Vector2i(390, 844) if "--portrait" in OS.get_cmdline_user_args() else Vector2i(1366, 768) if "--desktop" in OS.get_cmdline_user_args() else Vector2i(844, 390)
	Phone.test_window_size = size
	display = SubViewport.new(); display.size = size; display.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(display)
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://temple21-%d.json" % OS.get_process_id()
	var c := Campaign.new()
	c.state.wings.archives = 1
	c.state.research.cur = ""
	c.state.research.queue = []
	flow.campaign = c; flow.story = c.story
	var home: Control = Scene.instantiate(); display.add_child(home)
	await settle()
	var portrait := size.x < size.y
	check(home.temple_view.rooms.size() == 22, "all rooms remain reachable")
	check(home.station_panel.get_global_rect().position.x >= 0 and home.station_panel.get_global_rect().end.x <= size.x, "panel fits width")
	if portrait:
		check(home.room_picker.visible, "portrait room list is primary")
		check(home.room_picker.get_global_rect().position.x >= 12 and home.room_picker.get_global_rect().end.x <= size.x - 12, "room list within safe width")
		for id in home.temple_view.buttons: check(not home.temple_view.buttons[id].visible, "portrait plate hidden behind list " + str(id))
		var list_scroll: ScrollContainer = home.room_picker.get_child(1)
		var first_room: Button = home.room_picker.find_child("DrawerRoom_war", true, false)
		check(first_room != null and first_room.mouse_filter == Control.MOUSE_FILTER_PASS, "room buttons pass finger drags")
		var start_touch := first_room.get_global_rect().get_center()
		var touch := InputEventScreenTouch.new(); touch.pressed = true; touch.position = start_touch
		list_scroll._gui_input(touch)
		var drag := InputEventScreenDrag.new(); drag.position = start_touch - Vector2(0, 120)
		list_scroll._gui_input(drag)
		check(list_scroll.scroll_vertical > 0, "finger drag from room button scrolls list")
		list_scroll.scroll_vertical = 0
	else:
		for id in home.temple_view.buttons:
			var button: Button = home.temple_view.buttons[id]
			if not button.visible: continue
			var rect := button.get_global_rect()
			check(rect.position.x >= 0 and rect.end.x <= size.x and rect.position.y >= 0 and rect.end.y <= size.y, "plate fits " + str(id))
		if size.x == 844:
			var head_bottom: float = home.get_child(1).get_global_rect().end.y
			var footer_top: float = home.nav_buttons.Galaxy.get_global_rect().position.y
			check((footer_top - head_bottom) / size.y >= 0.65, "landscape cutaway fills at least 65 percent")
	for button in home.nav_buttons.values():
		if not button.visible: continue
		var rect: Rect2 = button.get_global_rect()
		check(rect.position.x >= 12 and rect.end.x <= size.x - 12 and rect.end.y <= size.y - 8 and rect.size.y >= 44, "footer control fits " + button.name)
	var badges: Dictionary = Badges.collect(c)
	for id in ["war", "archives", "works", "barracks", "council"]:
		var key: String = home.temple_view.badge_key(id)
		var plate: Button = home.temple_view.buttons[id]
		check(plate.has_node("ActionBadge") == badges.has(key), "room and footer alert agree " + id)
		if badges.has(key):
			check(str(plate.get_node("ActionBadge").text).begins_with(str(badges[key].count)), "room count matches footer " + id)
			check(home.nav_buttons[key].get_node("Badge").text.begins_with(str(badges[key].count)), "footer count matches room " + id)
	check(badges.has("Roster") and str(badges.Roster.action) == "Recruit", "recruit cue for available candidates")
	var promotion_fixture := Campaign.new()
	promotion_fixture.state.cands = []
	promotion_fixture.state.roster[0].pick = 1
	check(str(Badges.collect(promotion_fixture).Roster.action) == "Promote", "promotion becomes the roster action when recruiting is quiet")
	await capture("home")
	if portrait: home.room_picker.hide()
	var start: Vector3 = home.temple_view.camera.position
	home._open_room("archives", "Research")
	await create_timer(0.7).timeout
	check(home.temple_view.focused_room == "archives" and home.temple_view.camera.position.distance_to(start) > 1.0, "room camera tweens toward selection")
	check(home.station_panel.visible and home.station_panel.get_global_rect().end.x <= size.x and home.station_panel.get_global_rect().end.y <= size.y - (112 if portrait else 64 if size.x == 844 else 96), "narrow room panel opens beside the room above footer")
	var first: Button = home.find_child("FirstStudyButton", true, false)
	check(first != null, "first available study has an action")
	if first != null:
		var rect: Rect2 = first.get_global_rect()
		check(rect.position.y >= home.station_panel.get_global_rect().position.y and rect.end.y <= home.station_panel.get_global_rect().end.y, "research action visible without scrolling")
	if size.x == 844:
		c.state.research.cur = "ataru"
		home._show_page(); await settle()
		var active_text := false
		for label in home.page_content.find_children("*", "Label", true, false):
			if "Ataru katas" in label.text: active_text = true
		check(active_text, "active research project appears in first card")
		var next_study: Button = home.find_child("FirstStudyButton", true, false)
		check(next_study != null and next_study.get_global_rect().end.y <= home.station_panel.get_global_rect().end.y, "queue action remains on first fold during active study")
		c.state.research.cur = ""
		home._show_page(); await settle()
	await capture("research")
	home._close_station()
	await create_timer(0.56).timeout
	var framed_home: Vector3 = home.temple_view._framed_position(Vector3(0, 5.8, 0), home.temple_view.camera_home_size)
	check(home.temple_view.camera.position.distance_to(framed_home) < 0.6 and is_equal_approx(home.temple_view.camera.size, home.temple_view.camera_home_size), "Back restores camera with tween")
	if portrait: check(home.room_picker.visible, "Back restores portrait room list")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("TEMPLE21: %d checks, %d failures at %s" % [checks, failures, size])
	quit(1 if failures else 0)
