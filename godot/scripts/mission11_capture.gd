extends SceneTree
## Capture the same Ruusan campaign locations before and after the new mission rules.
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Settings = preload("res://scripts/settings.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	Settings.difficulty = "normal"
	root.borderless = true; root.unresizable = true
	root.size = Vector2i(1920,1080); root.content_scale_size = Vector2i(1920,1080)
	var cases := {"holocron":["r_caves","w11_holocron"],"evacuation":["r_ravine","w11_evacuation"],"duel":["r_seventh","w11_duel"]}
	var failures := 0
	for label in cases:
		if "--only" in OS.get_cmdline_user_args() and label != OS.get_cmdline_user_args()[-1]: continue
		for state in ["before","after"]:
			var path := "res://data/maps/%s.json" % (cases[label][0] if state == "before" else cases[label][1])
			var source = Mission.new(17,path)
			var game = load("res://scenes/rescue.tscn").instantiate()
			root.add_child(game); await process_frame
			game.demo_mode = true; game.set_process(false)
			game.mission = Combat.adopt(source)
			for view in game.figures.get_children():
				if view.name != "Prisoner": game.figures.remove_child(view); view.queue_free()
			game.views.clear(); game.selected_id = int(game.mission.living("player")[0].id)
			game.hud.queue_free(); game.portrait_viewport.queue_free(); game.portrait_kind = ""; game.action_buttons.clear(); game._build_ui()
			for enemy in game.mission.living("enemy"):
				enemy.awake = true; enemy.spotted = true
			game._build_terrain(); game.terrain_seen_board = game.mission.board.duplicate(); game.terrain_seen_revision = game.mission.terrain_revision
			game.pivot = Vector3(float(source.spec.width)*0.5,0,float(source.spec.height)*0.5)
			game.zoom = maxf(float(source.spec.width),float(source.spec.height))*1.15
			game.pitch = 0.78; game.yaw = 0.3; game.action_camera = true
			game._update_camera(); game._refresh(); Presentation.decorate(game); game.scene_view.arrange_labels()
			await create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			var output := ProjectSettings.globalize_path("res://../docs/godot/shots/wave11-missions-%s-%s.png" % [label,state])
			var error := root.get_texture().get_image().save_png(output)
			print("MISSIONS11 CAPTURE: %s (%s)" % [output,error_string(error)])
			if error != OK: failures += 1
			game.queue_free(); await process_frame
	quit(1 if failures else 0)
