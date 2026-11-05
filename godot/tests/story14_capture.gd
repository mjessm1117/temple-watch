extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase := "before" if "--before" in args else "after"
	var phone := "--phone" in args
	var debrief := "--debrief" in args
	var bark := "--bark" in args
	root.size = Vector2i(844,390) if phone else Vector2i(1366,768)
	var scene: Node = (preload("res://scenes/rescue.tscn") if bark else preload("res://scenes/briefing.tscn")).instantiate()
	root.add_child(scene)
	current_scene = scene
	if debrief:
		var story := preload("res://scripts/story/story_engine.gd").new()
		scene.show_scene(story.start_debrief({"mission_id":"relay","won":true,"units":[{"id":"kira","kills":2,"hp":5,"max_hp":5}]}))
		scene._skip_dialogue()
	if bark:
		for i in 12: await process_frame
		var comms := preload("res://scripts/story14_comms.gd").new(scene)
		comms._show(scene,"contact",[{"name":"Kira Venn","hp":5}])
	for i in 12: await process_frame
	if not bark and not debrief: scene._reveal()
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var label := "comms" if bark else "debrief" if debrief else phase
	var path := "res://../docs/godot/shots/wave14-story-%s-%s.png" % [label,"phone" if phone else "desktop"]
	var image := root.get_texture().get_image()
	var err := image.save_png(path)
	print("STORY14 SHOT %s %s" % [path,"ok" if err == OK else str(err)])
	print("STORY14 PERF draw %d tri %d" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	quit(0 if err == OK else 1)
