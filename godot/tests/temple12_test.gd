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
		check(rect.size.y >= 44 and rect.position.x >= 0 and rect.end.x <= root.size.x and rect.end.y <= root.size.y, "visible 44px command: " + name)
	check(home.nav_buttons.Galaxy.get_node("Badge").visible, "live galaxy mission badge")
	if phone:
		check(home.phone_grid != null and home.phone_grid.room_buttons.size() == 22, "phone grid exposes every room")
		check(home.phone_grid.galaxy_button.get_global_rect().size.y >= 44, "large galaxy opening")
		var room: Button = home.phone_grid.room_buttons.archives
		check("staff" in room.text and "Archives" in room.text, "phone room gives name, status and staff")
		room.pressed.emit()
		await process_frame
		check(home.page == "Build" and home.panel_open, "unbuilt phone room opens construction panel")
	else:
		check(home.temple_view.buttons.war.has_node("RoomAlert"), "war room has live alert badge")
		check(home.temple_view.buttons.medical.get_node("RoomDetail").text.contains("staff"), "desktop plate shows staff")
	if "--capture" in OS.get_cmdline_user_args():
		if phone: home._close_station()
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var path := "res://../docs/godot/shots/wave12-temple-%s.png" % ("phone" if phone else "desktop")
		var image := root.get_texture().get_image()
		check(image.get_size() == root.size, "capture has exact size")
		check(image.save_png(path) == OK, "capture saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("TEMPLE12 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
