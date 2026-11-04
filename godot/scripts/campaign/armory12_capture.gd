extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var phone := "phone" in OS.get_cmdline_user_args()
	var slots := "slots" in OS.get_cmdline_user_args()
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory12-capture.json"
	flow.campaign = preload("res://scripts/campaign/state.gd").new(); flow.active = true
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	flow.campaign.state.wings.forge = 2
	flow.campaign.state.research.done.append_array(["saberMk2", "saberMk3"])
	flow.campaign.state.res.credits = 500; flow.campaign.state.res.kyber = 10
	flow.campaign.soldier("u1").gear.mk.s = 2
	var screen = load("res://scenes/squad.tscn").instantiate(); root.add_child(screen)
	await process_frame
	screen.inspect(0)
	if not slots: screen.arsenal._select_slot("weapon")
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var name := "wave12-armory-phone-slots.png" if slots else "wave12-armory-phone.png" if phone else "wave12-armory-desktop.png"
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/" + name)
	print("CAPTURE ", name, " ", root.get_texture().get_image().save_png(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	quit()
