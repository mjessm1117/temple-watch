extends SceneTree
## Run headless for assertions; --capture-temple uses a real window for visual evidence.
const Campaign = preload("res://scripts/campaign/state.gd")
const Rooms = preload("res://scripts/campaign/temple_rooms.gd")
const Scene = preload("res://scenes/temple.tscn")
var checks := 0
var failures := 0
var flow: Node
var temple: Control
var capture := false
var suffix := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func frames(count: int = 3) -> void:
	for i in count: await process_frame

func open_temple() -> void:
	# Add before assigning current_scene so the visual fixture does not consume story events.
	temple = Scene.instantiate(); root.add_child(temple); current_scene = temple
	await frames()

func shot(label: String) -> void:
	if not capture: return
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var prefix := "home-after" if "--capture-home" in OS.get_cmdline_user_args() else "wave6-temple"
	var path := "res://../docs/godot/shots/%s-%s%s.png" % [prefix, label, suffix]
	var image := root.get_texture().get_image()
	if suffix == "-1920" and image.get_size() == Vector2i(1920, 1079):
		# Xvfb presents one row less than the requested root size on this host.
		var exact := Image.create(1920, 1080, false, image.get_format())
		exact.blit_rect(image, Rect2i(0, 0, 1920, 1079), Vector2i.ZERO)
		exact.blit_rect(image, Rect2i(0, 1078, 1920, 1), Vector2i(0, 1079))
		image = exact
	check(image.save_png(path) == OK, "window capture " + label)

func run() -> void:
	capture = "--capture-temple" in OS.get_cmdline_user_args() or "--capture-home" in OS.get_cmdline_user_args()
	var large := "--large" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080) if large else Vector2i(1366, 768)
	suffix = "-1920" if large else ""
	flow = root.get_node("CampaignFlow")
	flow.save_path = "user://temple-view-test-%d.json" % OS.get_process_id()
	var fresh := Campaign.new()
	check(fresh.save(flow.save_path), "write isolated fixture save")
	var loaded := Campaign.new(); check(loaded.load_save(flow.save_path), "load fixture save")
	flow.campaign = loaded; flow.story = loaded.story
	await open_temple()
	check(temple.temple_view.rooms.size() == 22, "all 13 web rooms, four spires, three vaults and two annexes")
	check(temple.temple_view.art.planets.size() == 14, "all galaxy.json planets rendered")
	check(not temple.station_panel.visible, "arrival exposes the entire cutaway")
	for row in Rooms.ROOMS:
		var room: Dictionary = temple.temple_view.rooms[row[0]]
		check(temple.temple_view.buttons.has(row[0]), "click target for " + str(row[0]))
		var rect: Rect2 = temple.temple_view.buttons[row[0]].get_global_rect()
		check(rect.position.y > 106 and rect.end.y < 670 and rect.position.x > 0 and rect.end.x < temple.size.x, "room target fits unobscured view " + str(row[0]))
		check(temple.temple_view.cell_nodes.has(row[0]), "3D cell for " + str(row[0]))
		check(room.tab in ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy", "Codex", "Galaxy"], "reachable target " + str(row[0]))
		if row[3] != "":
			check(room.built == (int(loaded.state.wings[row[3]]) > 0), "saved wing state " + str(row[3]))
			if not room.built: check("Cr" in room.status, "unbuilt wing shows cost " + str(row[3]))
	await shot("arrival")
	var initial_angle: float = temple.temple_view.galaxy.rotation.y
	await frames(4)
	check(temple.temple_view.galaxy.rotation.y > initial_angle, "galaxy rotates")
	# Save and reload a developed Temple, including one live construction and module cooldown.
	for wing in loaded.state.wings:
		loaded.state.wings[wing] = mini(2, preload("res://scripts/campaign/data.gd").get_table("core", "WINGS")[wing].cost.size() - 1)
	loaded.state.wings.training = 0; loaded.state.build = "training"
	loaded.state.modules = {"cd":{"medical":2}, "next":{}, "log":[]}
	loaded.state.month = 6
	check(loaded.save(flow.save_path), "save mixed built fixture")
	var developed := Campaign.new(); check(developed.load_save(flow.save_path), "reload mixed fixture")
	flow.campaign = developed; flow.story = developed.story
	temple.campaign = developed; temple._refresh_shell(); await frames()
	check(not temple.temple_view.rooms.training.built, "building is scaffolded until mission completion")
	check(temple.temple_view.rooms.training.status == "Under construction", "construction is labeled")
	check(temple.temple_view.buttons.training.get_node("RoomDetail").text == "BUILDING", "active construction plate stays distinct from free slots")
	check(temple.temple_view.rooms.medical.status == "L2 · 2 missions", "saved module cooldown visible")
	check(temple.temple_view.rooms.archives.module == "Study the Enemy", "built wing exposes module")
	check(temple.temple_view.art.people.size() >= 20, "staff inhabit operational rooms")
	check(temple.temple_view.art.sparks.size() == 12, "built forge emits sparks")
	for wing in developed.state.wings:
		check(temple.temple_view.rooms[wing].built == (int(developed.state.wings[wing]) > 0), "reloaded developed wing " + str(wing))
	await shot("built")
	if capture:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await create_timer(1.0).timeout
		var start := Time.get_ticks_usec()
		await frames(180)
		print("TEMPLE WINDOW PERFORMANCE: %.1f fps at %s; process %.2f ms; draw calls %d; nodes %d" % [180000000.0 / float(Time.get_ticks_usec() - start), root.size, Performance.get_monitor(Performance.TIME_PROCESS) * 1000, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	for id in temple.temple_view.rooms:
		var room: Dictionary = temple.temple_view.rooms[id]
		if room.tab in ["Galaxy", "Codex", "Arsenal"] or id in ["medical", "comms"]: continue
		temple.temple_view.buttons[id].pressed.emit(); await frames(1)
		check(temple.page == room.tab and temple.panel_open, "room button opens " + str(id))
		temple._close_station()
	temple._close_station(); await create_timer(0.2).timeout
	var click := InputEventMouseButton.new(); click.position = temple.temple_view.buttons.archives.get_global_rect().get_center()
	click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; root.push_input(click, true)
	click = click.duplicate(); click.pressed = false; root.push_input(click, true)
	await frames()
	check(temple.page == "Research" and temple.panel_open, "projected room responds to actual mouse click")
	await shot("research")
	temple._close_station(); await create_timer(0.2).timeout
	var hover := InputEventMouseMotion.new(); hover.position = temple.temple_view.buttons.medical.get_global_rect().get_center()
	root.push_input(hover, true); await frames()
	temple.temple_view._hover("medical")
	check("Medical Halls" in temple.notice_label.text and "2 missions" in temple.notice_label.text, "hover names room and saved status")
	await shot("hover")
	for station in ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy"]:
		temple._change_page(station)
		if station == "Arsenal":
			check(current_scene.scene_file_path.ends_with("squad.tscn"), "station preserved " + station)
			current_scene.queue_free(); current_scene = null; await frames()
			await open_temple()
		else: check(temple.page == station, "station preserved " + station)
	temple.temple_view.buttons.u1.pressed.emit(); await frames()
	check(current_scene.scene_file_path.ends_with("codex.tscn"), "holocron cell opens existing Codex")
	current_scene.queue_free(); current_scene = null; await frames()
	await open_temple()
	temple.temple_view.buttons.war.pressed.emit(); await frames()
	check(current_scene.scene_file_path.ends_with("galaxy.tscn"), "war room opens existing Galaxy")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("TEMPLE VIEW TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
