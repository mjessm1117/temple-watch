extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Geometry = preload("res://scripts/campaign/temple_geometry.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 6) -> void:
	for i in count: await process_frame

func capture(stage: SubViewport, label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var path := "/home/jess/projects/tw-logs/w23/spaces/after-%s-%dx%d.png" % [label, stage.size.x, stage.size.y]
	check(stage.get_texture().get_image().save_png(path) == OK, "capture " + label)

func run() -> void:
	var dims := Vector2i(390, 844) if "--portrait" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	Phone.test_window_size = dims
	Phone.test_touch = 1 if dims.x < 500 else 0
	Phone.test_mobile = 1 if dims.x < 500 else 0
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://spaces23-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	var art := Geometry.new()
	var sample := Node3D.new()
	for kind in ["holo", "medical", "garden", "forge", "training", "hangar", "vault", "other"]:
		for built in [true, false]:
			var info := {"id":"%s-%s" % [kind, built], "position":Vector3.ZERO, "kind":kind, "built":built, "color":Color("79d3e2"), "staff":0}
			var room := art.room(sample, info)
			check(room.has_node("RoomPractical"), "one room light: " + kind)
			check(room.get_meta("focal_kind", "") == kind, "focal prop: " + kind)
			check(room.has_node("RearAlcove") and room.has_node("FrontCutaway"), "front and rear depth: " + kind)
			var opening := "OpenCanopy" if kind in ["garden", "hangar", "forge"] else "SteppedPortal" if kind in ["holo", "vault"] else "CeilingRib"
			check(room.has_node(opening), "distinct cutaway opening: " + kind)
	check(art.material(Color("536369")).albedo_texture == preload("res://assets/temple/surface_atlas.png"), "shared surface atlas")
	check(FileAccess.get_file_as_bytes("res://assets/temple/human_lod.glb").size() < 500000, "phone human LOD stays compact")
	var lod: Node3D = preload("res://assets/temple/human_lod.glb").instantiate()
	var clips := false
	for player in lod.find_children("*", "AnimationPlayer", true, false):
		if player.has_animation("idle") and player.has_animation("walk"): clips = true
	check(clips, "phone human retains idle and walk clips")
	lod.free()
	sample.free()
	var stage := SubViewport.new(); stage.size = dims; stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var home: Control = load("res://scenes/temple.tscn").instantiate()
	stage.add_child(home)
	await frames(12)
	var view = home.temple_view
	check(view.has_method("set_ui_safe_rect"), "Temple safe rect contract")
	if dims.x < 500: home.room_picker.hide()
	if dims.x < 500:
		var west: Vector2 = view.camera.unproject_position(Vector3(-16, 0, 0)) * view.size / Vector2(view.viewport.size)
		var east: Vector2 = view.camera.unproject_position(Vector3(16, 0, 0)) * view.size / Vector2(view.viewport.size)
		check(west.x >= 0 and east.x <= view.size.x, "overview keeps both Temple wings on screen")
	await capture(stage, "temple-overview")
	var cover := Rect2(Vector2(0, dims.y * 0.60), Vector2(dims.x, dims.y * 0.40))
	view.set_ui_safe_rect(cover)
	view.focus_room("archives")
	await create_timer(0.65).timeout
	var center: Vector2 = view.camera.unproject_position(view.rooms.archives.position + Vector3(0, 1, 0)) * view.size / Vector2(view.viewport.size)
	check(view._clear_area().has_point(center), "focused Temple room stays above sheet")
	await capture(stage, "temple-room")
	view.set_ui_safe_rect(Rect2(Vector2(dims.x * 0.60, 0), Vector2(dims.x * 0.40, dims.y)))
	await create_timer(0.65).timeout
	center = view.camera.unproject_position(view.rooms.archives.position + Vector3(0, 1, 0)) * view.size / Vector2(view.viewport.size)
	check(view._clear_area().has_point(center), "focused Temple room stays beside sheet")
	print("SPACES23 TEMPLE draws=%d tris=%d" % [int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	home.queue_free()
	await frames(3)
	var galaxy: Control = load("res://scenes/galaxy.tscn").instantiate()
	stage.add_child(galaxy)
	await frames(12)
	var map = galaxy.map_view
	check(map.has_method("set_ui_safe_rect"), "Galaxy safe rect contract")
	check(map.zoom <= 50.0 if dims.x < 500 else map.zoom > 50.0, "phone galaxy overview scale")
	await capture(stage, "galaxy-overview")
	var labels: Array = map.marker_label_layout()
	for a in labels:
		for b in labels:
			if a.index != b.index: check(not a.rect.intersects(b.rect), "mission signals separated")
	if not map.offers.is_empty():
		map.set_ui_safe_rect(cover)
		map.focus_offer(0)
		await frames(30)
		var planet: Vector2 = map.projected(map.planets[map.focused].position)
		check(map._clear_area().has_point(planet), "focused galaxy planet stays above card")
		check(map.zoom <= 23.0, "focused planet enlarged")
		await capture(stage, "galaxy-focused")
		map.set_ui_safe_rect(Rect2(Vector2(dims.x * 0.60, 0), Vector2(dims.x * 0.40, dims.y)))
		await frames(30)
		planet = map.projected(map.planets[map.focused].position)
		check(map._clear_area().has_point(planet), "focused galaxy planet stays beside card")
	print("SPACES23 GALAXY draws=%d tris=%d" % [int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("SPACES23: %d checks, %d failures at %s" % [checks, failures, dims])
	quit(1 if failures else 0)
