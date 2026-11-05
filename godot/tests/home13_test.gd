extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const TempleScene = preload("res://scenes/temple.tscn")
const Plates = preload("res://scripts/campaign/home13_room_plates.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func settle() -> void:
	for i in 8: await process_frame
	await create_timer(0.5).timeout

func capture(label: String) -> void:
	if not ("--capture" in OS.get_cmdline_user_args() or "--before" in OS.get_cmdline_user_args()): return
	await settle()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == root.size, "capture exact resolution " + label)
	check(image.save_png("res://../docs/godot/shots/wave13-home-%s.png" % label) == OK, "capture " + label)
	print("HOME13 PERF %s: draw calls %d, triangles %d, fps estimate %.1f (%s)" % [label, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), Engine.get_frames_per_second(), RenderingServer.get_video_adapter_name()])

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var phase := "before" if "--before" in args else "after"
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	var size_name := "phone" if phone else "desktop"
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://home13-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	var temple := TempleScene.instantiate()
	root.add_child(temple); current_scene = temple
	await settle()
	var home := current_scene
	check(home != null and home.temple_view != null, "Temple loads")
	if phase == "after":
		check(home.mini_galaxy != null and home.mini_galaxy.map.mini, "Home galaxy teaser remains live")
		check(home.mini_galaxy.get_global_rect().end.x <= root.size.x, "Galaxy teaser fits")
		var empty := 0
		var built := 0
		for id in home.temple_view.rooms:
			var info: Dictionary = home.temple_view.rooms[id]
			var button: Button = home.temple_view.buttons[id]
			if info.built: built += 1
			else: empty += 1
			for node_name in ["RoomName", "RoomDetail"]:
				var label: Label = button.get_node(node_name)
				if not label.visible: continue
				var text_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
				if node_name == "RoomName":
					check((label.autowrap_mode == TextServer.AUTOWRAP_WORD and label.get_line_count() <= 2 and label.size.y >= 20) or (label.autowrap_mode == TextServer.AUTOWRAP_OFF and text_width <= button.size.x + 1.0), "Room name fits inside %s" % id)
				else:
					check(text_width <= button.size.x + 1.0, "%s fits room %s" % [node_name, id])
		check(built > 0 and empty > 0, "Built and empty rooms visible")
		if not phone:
			for id in ["war", "archives", "sp0", "sp1"]:
				print("HOME13 ROOM %s: button %s label %s" % [id, home.temple_view.buttons[id].get_global_rect(), home.temple_view.buttons[id].get_node("RoomName").get_global_rect()])
		check(Plates.state_text({"status":"Under construction", "built":false}) == "BUILDING", "Construction state is explicit")
	await capture("%s-temple-%s" % [phase, size_name])
	home._open_galaxy()
	await settle()
	var galaxy := current_scene
	check(galaxy != null and galaxy.map_view != null, "Galaxy opens from Temple")
	if phase == "after":
		if RenderingServer.get_current_rendering_method() == "gl_compatibility":
			check(root.get_node("Graphics").effective == "low", "Compatibility still selects Low tier")
		var map_rect: Rect2 = galaxy.map_view.get_global_rect()
		var panel_rect: Rect2 = galaxy.scroll.get_global_rect()
		print("HOME13 LAYOUT %s: map %s briefing %s" % [size_name, map_rect, panel_rect])
		check(map_rect.end.x <= root.size.x and map_rect.end.y <= root.size.y, "Galaxy map fits viewport")
		check(panel_rect.end.x <= root.size.x and panel_rect.end.y <= root.size.y, "Briefing fits viewport")
		check(map_rect.size.x >= panel_rect.size.x * 1.7 and map_rect.size.y >= root.size.y * 0.5, "Full strategy map has priority")
		check(galaxy.map_view.planets.size() == 14 and galaxy.map_view.offers.size() > 0, "Regions and mission markers exist")
		check(galaxy.launch_button != null and galaxy.launch_button.visible, "Mission briefing remains reachable")
	await capture("%s-galaxy-%s" % [phase, size_name])
	if phase == "after":
		galaxy._back()
		await settle()
		check(current_scene != galaxy and current_scene.scene_file_path == "res://scenes/temple.tscn", "Back returns to Temple")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("HOME13 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
