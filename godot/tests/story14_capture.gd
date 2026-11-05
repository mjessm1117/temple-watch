extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase := "before" if "--before" in args else "after"
	var phone := "--phone" in args
	root.size = Vector2i(844,390) if phone else Vector2i(1366,768)
	var scene: Control = preload("res://scenes/briefing.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 12: await process_frame
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/shots/wave14-story-%s-%s.png" % [phase,"phone" if phone else "desktop"]
	var image := root.get_texture().get_image()
	var err := image.save_png(path)
	print("STORY14 SHOT %s %s" % [path,"ok" if err == OK else str(err)])
	print("STORY14 PERF draw %d tri %d" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	quit(0 if err == OK else 1)
