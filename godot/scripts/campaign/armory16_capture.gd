extends SceneTree
const GUESTS := {"satele":"Satele Shan", "ressa":"Lord Ressa Vaun", "kell":"Kell Darrow", "sava":"Knight Sava Orrin", "tem":"Tem Ruhl"}

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "phone" in args
	var phase := "before" if "before" in args else "after"
	var id := "u1"
	for option in ["u1", "u2", "u3", "u4", "u5", "u6", "u7"]:
		if option in args: id = option
	var mark := 2
	for tier in [1, 2, 3]:
		if "mk%d" % tier in args: mark = tier
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	DisplayServer.window_set_size(root.size)
	root.content_scale_size = root.size
	root.get_node("Graphics").effective = "low" if phone else "high"
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory16-capture.json"
	flow.campaign = preload("res://scripts/campaign/state.gd").new()
	flow.active = true
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	flow.campaign.state.wings.forge = 2
	flow.campaign.state.research.done.append_array(["saberMk2", "saberMk3"])
	flow.campaign.state.res.credits = 500
	flow.campaign.state.res.kyber = 10
	var soldier: Dictionary = flow.campaign.soldier(id)
	var guest := ""
	for key in GUESTS:
		if key in args: guest = key; soldier.n = GUESTS[key]
	if id == "u3": soldier.gear.armor = "heavy"
	else: soldier.gear.armor = "armoredRobes"
	soldier.gear.mk["armor:" + str(soldier.gear.armor)] = mark
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var index: int = screen.selected.find(id)
	screen.inspect(index if index >= 0 else 0)
	screen.arsenal._select_slot("armor" if "armor" in args else "weapon")
	await create_timer(1.4).timeout
	await RenderingServer.frame_post_draw
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var tris := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var suffix := "phone-low" if phone else "desktop-high"
	var filename := "wave16-armory-%s-%s-%s%s-mk%d.png" % [phase, suffix, id, "-" + guest if guest != "" else "", mark]
	if "intfix" in args: filename = "w16-intfix-%s-armory-%s-mk%d.png" % [suffix, id, mark]
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/" + filename)
	print("ARMORY16 PERF %s %s %s mk%d draws=%d triangles=%d fps=%d" % [phase, suffix, id, mark, draws, tris, Engine.get_frames_per_second()])
	print("ARMORY16 SHOT %s result=%d" % [path, root.get_texture().get_image().save_png(path)])
	screen.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	quit()
