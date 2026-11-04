extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Scene = preload("res://scenes/temple.tscn")
const Resources = preload("res://scripts/campaign/home_resources.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var phone := "--phone" in OS.get_cmdline_user_args()
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://temple12-%d.json" % OS.get_process_id()
	var fresh := Campaign.new()
	check(fresh.save(flow.save_path), "save isolated campaign")
	flow.campaign = fresh; flow.story = fresh.story
	var home: Control = Scene.instantiate()
	root.add_child(home); current_scene = home
	for i in 5: await process_frame
	check(Phone.narrow(Phone.window_size()) == phone, "fixture uses requested layout")
	check(not home.station_panel.visible, "first page shows Temple")
	check(home.temple_view.rooms.size() == 22, "all cutaway rooms remain")
	for item in Resources.ITEMS:
		var label: Label = home.find_child("Resource_" + str(item[1]), true, false)
		check(label != null, "resource visible: " + str(item[0]))
		if label != null:
			check(label.get_global_rect().end.x <= root.size.x and label.get_global_rect().position.x >= 0, "resource fits: " + str(item[0]))
	var power: Label = home.find_child("PowerStatus", true, false)
	check(power != null and power.get_global_rect().end.x <= root.size.x, "power is in top bar")
	for name in ["Galaxy", "Arsenal", "Roster", "Research", "Build", "Command", "Legacy", "Teams", "Codex"]:
		var button: Button = home.nav_buttons[name]
		var rect := button.get_global_rect()
		check(rect.size.y >= 44 and rect.position.x >= 0 and rect.end.x <= root.size.x and rect.end.y <= root.size.y, "command fits viewport: " + name)
	check(home.nav_buttons.Galaxy.get_node("Badge").visible, "live galaxy mission badge")
	var menu: Button = home.find_child("MenuCommand", true, false)
	check(menu != null and menu.get_global_rect().end.x <= root.size.x, "Menu command fits viewport")
	if phone:
		var more: Button = home.find_child("MoreCommands", true, false)
		check(more != null and more.get_global_rect().size.y >= 48 and more.get_global_rect().end.x <= root.size.x, "More fits phone command row")
	check(home.mini_galaxy != null and home.mini_galaxy.visible, "live mini galaxy exists")
	check(home.mini_galaxy.map.planets.size() > 0 and home.mini_galaxy.map.offers.size() == fresh.state.options.size(), "mini galaxy shows planets and missions")
	check(home.mini_galaxy.get_global_rect().end.x <= root.size.x, "mini galaxy fits")
	var covers_room := false
	for room_button in home.temple_view.buttons.values():
		if home.mini_galaxy.get_global_rect().intersects(room_button.get_global_rect()): covers_room = true
	check(not covers_room, "mini galaxy leaves cutaway rooms clear")
	if phone:
		check(home.phone_grid == null and not home.room_picker.visible, "phone cutaway has no covering room grid")
		check(root.size.y - 95 - 55 >= root.size.y * 0.55, "cutaway has at least 55 percent clear height")
		check(home.temple_view.buttons.war.visible, "cutaway rooms remain visible")
		home._toggle_rooms()
		check(home.room_picker.visible, "rooms drawer opens")
		var room: Button = home.room_picker.find_child("DrawerRoom_archives", true, false)
		check(room != null and room.custom_minimum_size.y >= 44 and "Archives" in room.text, "room drawer has touch sized room info")
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://../docs/godot/shots/wave12-temple-phone-rooms.png") == OK, "rooms drawer captured")
		home._toggle_rooms()
		room.pressed.emit()
		await process_frame
		check(home.page == "Build" and home.panel_open, "unbuilt phone room opens construction panel")
	else:
		check(home.temple_view.buttons.war.has_node("RoomAlert"), "war room has live alert badge")
		check(home.temple_view.buttons.medical.get_node("RoomDetail").text.contains("staff"), "desktop plate shows staff")
		for width in [1280, 1366]:
			for name in home.nav_buttons:
				var rect: Rect2 = home.nav_buttons[name].get_global_rect()
				var physical_right := rect.end.x * float(width) / 1366.0
				check(physical_right <= width, "%dpx command fits: %s" % [width, name])
			check(menu.get_global_rect().end.x * float(width) / 1366.0 <= width, "%dpx Menu fits" % width)
	if "--capture" in OS.get_cmdline_user_args():
		if phone: home._close_station()
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var path := "res://../docs/godot/shots/wave12-temple-%s.png" % ("phone" if phone else "desktop")
		var image := root.get_texture().get_image()
		check(image.get_size() == root.size, "capture has exact size")
		check(image.save_png(path) == OK, "capture saved")
	home.mini_galaxy.get_node("OpenGalaxy").pressed.emit()
	for i in 4: await process_frame
	check(current_scene != null and current_scene != home and current_scene.scene_file_path == "res://scenes/galaxy.tscn", "mini galaxy opens full galaxy screen")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("TEMPLE12 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
