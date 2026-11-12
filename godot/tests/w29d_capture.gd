extends SceneTree
## Render the envoy objective at phone sizes for before/after review.
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Settings = preload("res://scripts/settings.gd")
const Phone = preload("res://scripts/phone_layout.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	Settings.difficulty = "normal"
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var stage := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	var failed := false
	for size in [Vector2i(844,390), Vector2i(390,844)]:
		root.size = size; root.content_scale_size = size
		DisplayServer.window_set_size(size)
		var source = Mission.new(17,"res://data/maps/envoy.json")
		if stage == "after":
			var actor: Dictionary = source.living("player")[0]
			actor.x = 12; actor.y = 4
			if not source.use_ability(int(actor.id),"interact",-1,Vector2i(13,4)):
				push_error("Cannot stage envoy extraction")
				failed = true
		var game = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.demo_mode = true; game.set_process(false)
		game.mission = Combat.adopt(source)
		for view in game.figures.get_children():
			if view.name != "Prisoner": game.figures.remove_child(view); view.queue_free()
		game.views.clear(); game.selected_id = int(game.mission.living("player")[0].id)
		game.hud.queue_free(); game.portrait_viewport.queue_free(); game.portrait_kind = ""; game.action_buttons.clear(); game._build_ui()
		for enemy in game.mission.living("enemy"):
			enemy.awake = true; enemy.spotted = true
		game._build_terrain(); game.terrain_seen_board = game.mission.board.duplicate(); game.terrain_seen_revision = game.mission.terrain_revision
		game.pivot = Vector3(13,0,15)
		game.zoom = 32.0; game.pitch = 0.78; game.yaw = 0.3; game.action_camera = true
		game._update_camera(); game._refresh(); game.scene_view.arrange_labels()
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var output := "/home/jess/projects/tw-logs/w29/balance29/2026-11-12-balance29-%s-%dx%d.png" % [stage,size.x,size.y]
		var err := root.get_texture().get_image().save_png(output)
		print("BALANCE29 CAPTURE ", output, " ", error_string(err), " phase=", source.objective_state.phase)
		if err != OK: failed = true
		game.queue_free(); await process_frame
	quit(1 if failed else 0)
