extends SceneTree
## Full rescue scene, fixed offscreen size, Compatibility counters.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var size := Vector2i(844,390)
	var phase := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			size = Vector2i(int(parts[0]),int(parts[1]))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var view := SubViewport.new(); view.size = size
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var game = load("res://scenes/rescue.tscn").instantiate()
	view.add_child(game)
	for i in 30: await process_frame
	root.get_node("Graphics").apply_all()
	for i in 20: await process_frame
	var draws := 0; var triangles := 0
	for i in 90:
		await process_frame
		draws = maxi(draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		triangles = maxi(triangles,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	print("MAP14 FIGHT %s %s: draws=%d triangles=%d adapter=%s" % [phase,size,draws,triangles,RenderingServer.get_video_adapter_name()])
	game.sound.player.stop(); game.sound.player.stream = null
	view.queue_free(); await process_frame
	quit(0 if draws > 0 and triangles > 0 else 1)
