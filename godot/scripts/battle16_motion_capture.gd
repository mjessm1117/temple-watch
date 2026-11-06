extends SceneTree
## Native phone battle frames from the named Jedi run and swing clips.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.borderless = true; root.unresizable = true
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	var graphics := root.get_node_or_null("Graphics")
	if graphics != null: graphics.effective = "low"
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	var chosen: Dictionary = {}
	for unit in game.mission.living("player"):
		if str(unit.get("name", "")) == "Kira Venn": chosen = unit; break
	if chosen.is_empty(): push_error("Kira absent from battle"); quit(2); return
	var actor: Node3D = game.views.get(int(chosen.id))
	if actor == null or actor.animation == null: quit(3); return
	if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
	game.cinematic = true
	for i in range(16): await process_frame
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	game.camera.v_offset = 0.0
	game.camera.fov = 45.0
	game.camera.position = actor.global_position + Vector3(1.8, 1.8, 2.9)
	game.camera.look_at(actor.global_position + Vector3.UP * 1.25, Vector3.UP)
	for clip in ["run", "swing"]:
		if not actor.animation.has_animation(clip): push_error("Missing " + clip); quit(4); return
		var length: float = actor.animation.get_animation(clip).length
		for index in range(3):
			actor.animation.play(clip)
			actor.animation.seek(length * [0.08, 0.42, 0.76][index], true)
			actor.animation.pause()
			await process_frame
			game.phase_banner.hide()
			await RenderingServer.frame_post_draw
			var path := ProjectSettings.globalize_path("res://../docs/godot/shots/w16-intfix-phone-low-%s-%d.png" % [clip, index + 1])
			var err := root.get_texture().get_image().save_png(path)
			print("MOTION %s frame=%d result=%s draws=%d triangles=%d" % [clip, index + 1, error_string(err), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
			if err != OK: quit(5); return
	quit()
