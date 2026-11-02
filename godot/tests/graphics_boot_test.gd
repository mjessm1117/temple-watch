extends SceneTree
## Run in an isolated user directory. The next process must consume the override.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var graphics = root.get_node("Graphics")
	var failures := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expect="):
			var tier := arg.get_slice("=",1)
			var method := "gl_compatibility" if tier == "low" else "forward_plus"
			if graphics.requested != tier or RenderingServer.get_current_rendering_method() != method:
				failures += 1; push_error("Saved renderer/tier was not loaded at boot: "+tier)
		if arg.begins_with("--save="):
			if graphics.select_tier(arg.get_slice("=",1)) != OK:
				failures += 1; push_error("Could not save graphics")
	print("Graphics restart: %d failures" % failures)
	quit(1 if failures else 0)
