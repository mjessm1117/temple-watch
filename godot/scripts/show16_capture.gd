extends SceneTree
## Native-size visual and performance evidence for the show lane.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var before := "--before" in args
	var story := "--story" in args
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	if not story:
		var flow := root.get_node("CampaignFlow")
		flow.campaign = preload("res://scripts/campaign/state.gd").new()
		flow.story = flow.campaign.story
	var scene: Control = (preload("res://scenes/briefing.tscn") if story else preload("res://scenes/temple.tscn")).instantiate()
	root.add_child(scene)
	current_scene = scene
	for frame in 18: await process_frame
	if story: scene._reveal()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var category := "story" if story else "temple"
	var path := "res://../docs/godot/shots/wave16-show-%s-%s-%s.png" % ["before" if before else "after", category, "phone" if phone else "desktop"]
	var err := root.get_texture().get_image().save_png(path)
	print("SHOW16 CAPTURE %s error=%d draws=%d tris=%d" % [path, err, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	quit(0 if err == OK else 1)
