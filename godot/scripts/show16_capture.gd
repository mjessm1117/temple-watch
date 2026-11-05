extends SceneTree
## Native-size visual and performance evidence for the show lane.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var before := "--before" in args
	var story := "--story" in args
	var roster := "--roster" in args
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	if not story:
		var flow := root.get_node("CampaignFlow")
		flow.campaign = preload("res://scripts/campaign/state.gd").new()
		flow.story = flow.campaign.story
	var scene: Control = (preload("res://scenes/briefing.tscn") if story else preload("res://scenes/temple.tscn")).instantiate()
	root.add_child(scene)
	current_scene = scene
	for frame in 18: await process_frame
	if story:
		scene.show_scene({"kind":"debrief", "name":"Kira Venn", "title":"Relay Secure", "eyebrow":"SQUAD TRANSMISSION", "text":"Kira Venn reports the relay is secure. The fleet has a clear route home.", "choices":[]})
		for frame in 5: await process_frame
		if before:
			var legacy := load("res://assets/story/portraits14/kira.png") as Texture2D
			if is_instance_valid(scene.speaker_portrait): scene.speaker_portrait.texture = legacy
			if is_instance_valid(scene.big_speaker_portrait): scene.big_speaker_portrait.texture = legacy
		scene._reveal()
	if roster:
		scene._change_page("Roster")
		for frame in 4: await process_frame
		var faces: Array = scene.find_children("JediPortrait_*", "TextureRect", true, false)
		if not faces.is_empty():
			var container: Node = faces[0].get_parent()
			while container != null and not container is ScrollContainer: container = container.get_parent()
			if container is ScrollContainer:
				(container as ScrollContainer).ensure_control_visible(faces[0])
				(container as ScrollContainer).scroll_vertical += 85
		if before:
			for face in faces: face.hide()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var category := "story" if story else "roster" if roster else "temple"
	var path := "res://../docs/godot/shots/wave16-show-%s-%s-%s.png" % ["before" if before else "after", category, "phone" if phone else "desktop"]
	var err := root.get_texture().get_image().save_png(path)
	print("SHOW16 CAPTURE %s error=%d draws=%d tris=%d" % [path, err, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	quit(0 if err == OK else 1)
