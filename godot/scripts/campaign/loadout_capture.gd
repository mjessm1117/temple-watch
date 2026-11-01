extends SceneTree
## Real-window screenshot harness; uses a separate disposable campaign save.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://wave6-loadout-capture.json"
	flow.campaign = preload("res://scripts/campaign/state.gd").new()
	flow.campaign.state.launch_index = 0
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	var wide := "wide" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080) if wide else Vector2i(1366, 768)
	var view = load("res://scenes/squad.tscn").instantiate(); root.add_child(view)
	view._toggle("u3"); view._toggle("u5")
	await create_timer(2.0).timeout
	await shot("lineup-1920" if wide else "lineup")
	view.inspect(3)
	await create_timer(1.0).timeout
	await shot("roster-1920" if wide else "roster")
	flow.campaign.state.wings.armory = 2
	flow.campaign.state.research.done.append("gunMk2")
	view._tab("arsenal"); view.change_gear("fit", "w", "scope")
	await create_timer(0.7).timeout
	await shot("arsenal-1920" if wide else "arsenal")
	if not wide:
		view.close_inspector(); view.inspect(0); view._tab("arsenal")
		await create_timer(1.0).timeout
		await shot("jedi")
	view._tab("roster"); flow.campaign.soldier("u3").wound = 6
	flow.campaign.soldier("u6").assign = "train"; view._build_drawer()
	await create_timer(0.3).timeout
	if not wide: await shot("unavailable")
	view.close_inspector()
	await create_timer(3.0).timeout
	print("LOADOUT RENDER FPS: ", Engine.get_frames_per_second())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path)); quit()

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave6-loadout-%s.png" % label)
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png(path))
