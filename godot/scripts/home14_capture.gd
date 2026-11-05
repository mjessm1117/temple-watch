extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var kind := "temple"
	for name in ["galaxy", "armory", "menu", "settings", "research", "forge"]:
		if "--" + name in args: kind = name
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://home14-capture-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	var scene_name := "squad" if kind == "armory" else "menu" if kind in ["menu", "settings"] else "galaxy" if kind == "galaxy" else "temple"
	var view: Control = load("res://scenes/%s.tscn" % scene_name).instantiate()
	root.add_child(view); current_scene = view
	for i in 10: await process_frame
	if kind == "armory":
		view.inspect(0)
		print("HOME14 ARMORY focus=", view.focus_index, " selected=", view.selected.size(), " drawer=", view.drawer.visible)
	elif kind == "settings" and phone:
		var body: VBoxContainer = view.get_child(view.get_child_count() - 1).get_child(0)
		view._phone_settings(body)
	elif kind in ["research", "forge"]: view._change_page("Research" if kind == "research" else "Arsenal", "" if kind == "research" else "forge")
	await create_timer(1.8).timeout
	for i in 3: await process_frame
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave14-home-after-%s-%s.png" % [kind, "phone" if phone else "desktop"])
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	print("HOME14 CAPTURE %s error=%d draw=%d tri=%d" % [path, error, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	quit(0 if error == OK else 1)
