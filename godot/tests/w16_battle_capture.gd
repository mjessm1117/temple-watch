extends SceneTree
## Evidence capture for the same seven 844x390 battle states on each revision.
const Campaign = preload("res://scripts/campaign/state.gd")

func _initialize() -> void:
	run.call_deferred()

func argument(key: String, fallback: String = "") -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(key + "="): return value.get_slice("=",1)
	return fallback

func touch(game, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index; event.position = position; event.pressed = pressed
	game.cam._input(event)

func drag(game, index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index; event.position = position
	game.cam._input(event)

func run() -> void:
	var item := argument("--case","hud")
	var output := argument("--output")
	if output == "": quit(2); return
	root.size = Vector2i(844,390)
	root.content_scale_size = root.size
	var flow = root.get_node("CampaignFlow")
	var campaign = Campaign.new("normal")
	campaign.select_mission(0)
	campaign.state.flow_stage = "battle"
	flow.campaign = campaign; flow.story = campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true; game.set_process(false)
	game.phase_banner.hide(); game.hud_controls.night.phase_plate.hide()
	var actor: Dictionary = game.mission.living("player")[0]
	if item in ["move","path","camera"]:
		game._select(int(actor.id)); game._choose_action("move")
	if item == "path":
		var reach: Dictionary = game.mission.reach_tiles(actor,2)
		for tile in reach.costs:
			if int(reach.costs[tile]) > int(actor.mob):
				game.preview_tile = tile; game._refresh_highlights(); break
	if item in ["overwatch","overwatch-off"]:
		for member in game.mission.living("player"):
			if float(member.range) >= 2.0:
				actor = member; break
		actor.overwatch = item == "overwatch"
		game._select(int(actor.id)); game._refresh_figures()
		game.terrain.get_child(0).refresh_markers(game.mission)
		game.action = "overwatch"
		game.pivot = Vector3(float(actor.x)-4.0,0,float(actor.y)-4.0)
		game.zoom = 28.0; game._update_camera()
		game._refresh()
	if item == "camera":
		touch(game,0,Vector2(250,190),true)
		touch(game,1,Vector2(350,190),true)
		for position in [Vector2(347,216),Vector2(337,239),Vector2(327,254)]: drag(game,1,position)
		touch(game,1,Vector2(327,254),false)
		touch(game,0,Vector2(250,190),false)
	if item == "hold":
		game.mission.objective_state.held = 2
		game._refresh()
	for i in 15: await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output)
	if item == "defend":
		var arc_count: int = game.terrain.get_child(0).marker_root.get_children().filter(func(node): return node is MeshInstance3D and node.mesh is ImmediateMesh).size()
		print("W16 ZONE arcs=",arc_count," screen=",game.camera.unproject_position(Vector3(13,0.28,13)))
	print("W16 CAPTURE %s %s draws=%d yaw=%.3f" % [item,error_string(error),RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),game.yaw])
	quit(0 if error == OK else 1)
