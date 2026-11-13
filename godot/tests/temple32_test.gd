extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Scene = preload("res://scenes/temple.tscn")
const Phone = preload("res://scripts/phone_layout.gd")
const Story = preload("res://scripts/w25_menus_room_story.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("TEMPLE32: " + detail)

func frames(count: int = 2) -> void:
	for i in count: await process_frame

func inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.has_area() and bounds.encloses(rect)

func scenario(size: Vector2i) -> void:
	Phone.test_window_size = size
	Phone.test_touch = 1
	Phone.test_mobile = 1
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_size(size)
	var display := SubViewport.new()
	display.size = size
	display.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(display)
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://temple32-%d.json" % OS.get_process_id()
	var campaign := Campaign.new()
	campaign.state.wings.archives = 1
	campaign.state.wings.comms = 1
	flow.campaign = campaign
	flow.story = campaign.story
	flow.active = true
	var home: Control = Scene.instantiate()
	display.add_child(home)
	await frames(8)
	var stage: Control = home.temple_view
	var bounds := Rect2(Vector2.ZERO, Vector2(size))
	var rail := home.find_child("TaskRailCard", true, false) as Control
	check(rail != null and inside(rail.get_global_rect(), bounds), "%s task card fits" % size)
	for id in stage.rooms:
		var worker := stage.cell_nodes[id].get_node_or_null("FocalWorker_" + str(id)) as Node3D
		check(worker != null and worker.position.length() > 0.01, "%s %s has a placed worker" % [size, id])
		check(not Story.flavour(str(id)).strip_edges().is_empty(), "%s %s has room flavour" % [size, id])
	if size.x < size.y:
		check(home.room_picker.visible, "portrait picker starts open")
		home.nav_buttons["Roster"].pressed.emit()
		await frames(2)
		check(not home.room_picker.visible and home.station_panel.visible and home.page == "Roster", "Squad footer shows Roster within two frames")
		check(home.page_content.get_child_count() > 0, "Roster content exists")
		home._close_station()
		await frames(2)
		check(home.room_picker.visible, "return to Temple opens rooms")
		home.room_picker.hide()
	stage.activate_room("archives")
	await frames(2)
	var flavour := home.find_child("RoomFlavour", true, false) as Label
	check(flavour != null and not flavour.text.strip_edges().is_empty(), "%s selected room shows flavour" % size)
	var worker := stage.cell_nodes["archives"].get_node_or_null("FocalWorker_archives") as Node3D
	if worker != null:
		check(worker.get_parent().has_node("WorkerVignette"), "%s selected actor has a dark backdrop" % size)
		check(stage.stage25.focus_light.visible, "%s selected actor has a foreground light" % size)
		await frames(70)
		var projected: Vector2 = stage.camera.unproject_position(worker.global_position) * Vector2(size) / Vector2(stage.viewport.size)
		check(bounds.grow(-8).has_point(projected), "%s selected actor remains on stage" % size)
		check(not home.station_panel.get_global_rect().has_point(projected), "%s selected actor clears the station panel" % size)
	check(rail != null and inside(rail.get_global_rect(), bounds), "%s task card remains unclipped after selection" % size)
	display.queue_free()
	await frames(2)

func run() -> void:
	await scenario(Vector2i(390, 844))
	await scenario(Vector2i(844, 390))
	print("TEMPLE32: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
