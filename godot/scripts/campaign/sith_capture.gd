extends SceneTree
## Real display capture, isolated from the host campaign and its save.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var wide := "wide" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080) if wide else Vector2i(1366, 768)
	var view: Control = load("res://scenes/sith_report.tscn").instantiate()
	root.add_child(view)
	for page in ["operations", "rivals", "report"]:
		view.show_page(page)
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var path := "res://../docs/godot/shots/wave7-sith-%s%s.png" % [page, "-1920" if wide else ""]
		print("CAPTURE ", path, " ", root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)))
		if page == "rivals":
			view.page_content.get_parent().scroll_vertical = 1000
			await create_timer(0.2).timeout
			await RenderingServer.frame_post_draw
			path = "res://../docs/godot/shots/wave7-sith-rival-counters%s.png" % ("-1920" if wide else "")
			print("CAPTURE ", path, " ", root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)))
	quit()
