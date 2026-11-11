extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Scene = preload("res://scenes/temple.tscn")
const Phone = preload("res://scripts/phone_layout.gd")
const W25UI = preload("res://scripts/w25_temple_ui.gd")
const OUT = "/home/jess/projects/tw-logs/w25/temple/"
var checks := 0
var failures := 0
var display: SubViewport

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 8: await process_frame

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await process_frame
	check(display.get_texture().get_image().save_png(OUT + name + ".png") == OK, "capture " + name)

func run() -> void:
	var size := Vector2i(390, 844) if "--portrait" in OS.get_cmdline_user_args() else Vector2i(1366, 768) if "--desktop" in OS.get_cmdline_user_args() else Vector2i(844, 390)
	Phone.test_window_size = size
	display = SubViewport.new(); display.size = size; display.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(display)
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://temple25-%d.json" % OS.get_process_id()
	var c := Campaign.new()
	c.state.wings.archives = 1
	c.state.wings.comms = 1
	c.state.roster[0].wound = 4
	c.state.mods.dug["u2"] = true
	flow.campaign = c; flow.story = c.story; flow.active = true
	var home: Control = Scene.instantiate(); display.add_child(home)
	await settle()
	var stage: Control = home.temple_view
	var rail: Button = home.find_child("TaskRailCard", true, false)
	check(rail != null and rail.size.y >= 44, "one task rail card")
	check(c.has_method("strategic_snapshot25") and home.priority_room == str(c.strategic_snapshot25().top_priority.room_id), "task rail uses economy priority snapshot")
	var center := Rect2(Vector2(size.x * 0.34, size.y * 0.21), Vector2(size.x * 0.50, size.y * 0.55))
	for key in stage.edge_badges:
		var badge: Button = stage.edge_badges[key]
		check(badge.size.x >= 44 and badge.size.y >= 44 and badge.get_global_rect().intersection(center).get_area() == 0, "edge badge clears centre " + key)
		check(badge.get_global_rect().end.x <= size.x and badge.get_global_rect().end.y <= size.y, "edge badge fits " + key)
	for id in stage.buttons:
		var button: Button = stage.buttons[id]
		for label_name in ["ActionBadge", "BattleBonus", "RoomAlert"]:
			if button.has_node(label_name): check(not button.get_node(label_name).visible, "plate clear of centre " + str(id))
		if size.x != 1366 and button.get_node("RoomName").visible:
			check(button.get_node("RoomName").get_global_rect().intersection(center).get_area() == 0, "room name stays at edge " + str(id))
	check(rail.get_global_rect().intersection(center).get_area() == 0, "task rail clears centre")
	check(stage.stage25.workers.size() > 0, "staffed room has focal worker")
	check(stage.cell_nodes["archives"].has_node("FocalWorker_archives"), "Archives frames an archivist")
	check(stage.stage25.walkers.size() > 0, "idle figures patrol adjacent rooms")
	for entry in stage.stage25.workers:
		check(entry.figure.scale.x > 1.0 and entry.project.get_parent().has_node("ProjectProgress"), "worker, project and progress ring")
	await capture("after-home-%dx%d" % [size.x, size.y])
	await process_frame
	print("TEMPLE25 PERF %s draws=%d tris=%d" % [size, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	if size.x < size.y:
		home.room_picker.hide()
		stage._project_rooms()
		check(stage.buttons["u0"].visible, "sealed bay tappable in portrait cutaway")
	var tap_at := Time.get_ticks_usec()
	stage.buttons["archives"].pressed.emit()
	check(stage.highlighted_room == "archives" and stage.last_highlight_usec - tap_at <= 100000, "Archives tap responds within 100 ms")
	await create_timer(1.2).timeout
	check(home.selected_room == "archives" and home.page == "Research" and stage.focused_room == "archives", "Archives one tap and framed")
	var first: Button = home.find_child("FirstStudyButton", true, false)
	check(first != null and first.get_global_rect().end.y <= home.station_panel.get_global_rect().end.y, "first study above fold")
	await capture("after-archives-%dx%d" % [size.x, size.y])
	home._close_station(); await create_timer(0.2).timeout
	stage.buttons["medical"].pressed.emit()
	var medical_screen: Control = current_scene
	check(medical_screen != null and medical_screen.get("temple_focus") == "medical" and medical_screen.get("temple_soldier_id") == home.selected_id, "medical opens focused squad screen")
	check("1 wounded" in W25UI.medical_status(c) and "3 days" in W25UI.medical_status(c), "medical count and accurate return ETA")
	await create_timer(0.8).timeout
	await capture("after-medical-%dx%d" % [size.x, size.y])
	check(home.room_story_attempted.has("medical"), "room story attempted once")
	current_scene = null
	if medical_screen != null: medical_screen.queue_free()
	await process_frame
	stage.buttons["medical"].pressed.emit()
	check(home.room_story_attempted.size() == 2, "repeat room tap does not repeat story")
	medical_screen = current_scene
	current_scene = null
	if medical_screen != null: medical_screen.queue_free()
	await process_frame
	home._close_station(); await create_timer(0.2).timeout
	stage.buttons["u0"].pressed.emit()
	check(home.selected_room == "u0" and home.build_slot == "u0" and stage.highlighted_room == "u0", "sealed bay selected and highlighted")
	check(home.page == "Build" and home.find_child("Bay_u0", true, false) != null, "build grid fallback")
	await create_timer(0.8).timeout
	await capture("after-bay-%dx%d" % [size.x, size.y])
	home._close_station(); await create_timer(0.2).timeout
	stage.buttons["u2"].pressed.emit()
	check(home.page == "Legacy" and home.selected_room == "u2", "Memorial opens Legacy")
	check(home.find_child("RememberAction", true, false) == null, "Remember hidden without story contract")
	await create_timer(0.8).timeout
	await capture("after-memorial-%dx%d" % [size.x, size.y])
	var route_events := []
	var home_route := Callable(home, "_open_room")
	stage.room_selected.disconnect(home_route)
	var record_route := func(id: String, tab: String): route_events.append({"id":id, "tab":tab})
	stage.room_selected.connect(record_route)
	for id in stage.buttons:
		stage.buttons[id].pressed.emit()
	check(route_events.size() == stage.buttons.size(), "every room target emits one route")
	for event in route_events: check(str(event.tab) == str(stage.rooms[event.id].tab), "room tap routes " + str(event.id))
	stage.room_selected.disconnect(record_route)
	stage.room_selected.connect(home_route)
	stage.buttons["comms"].pressed.emit()
	await settle()
	check(current_scene != null and current_scene.scene_file_path.ends_with("galaxy.tscn"), "Comms falls back to Galaxy when intelligence is unavailable")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("TEMPLE25: %d checks, %d failures at %s" % [checks, failures, size])
	quit(1 if failures else 0)
