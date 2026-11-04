extends SceneTree
## Render an actual battle at the two supported viewport sizes.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "phone" in args
	var aiming := "aim" in args
	var size := Vector2i(844, 390) if phone else Vector2i(1366, 768)
	root.borderless = true; root.unresizable = true
	root.size = size; root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game); await process_frame
	game.demo_mode = true; game.set_process(false)
	if aiming:
		var actor: Dictionary = {}
		for unit in game.mission.living("player"):
			if "shoot" in unit.get("kit", []): actor = unit; break
		if not actor.is_empty():
			game._select(int(actor.id))
			var nearby: Dictionary = game.mission.paths(actor, 3)
			for tile in nearby.costs:
				if int(nearby.costs[tile]) == 1:
					var enemy: Dictionary = game.mission.living("enemy")[0]
					enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
					break
			game._refresh_figures(); game.action = "shoot"
			game._cycle_target(1); game._refresh()
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	var name := "wave12-battle-%s%s.png" % ["phone" if phone else "desktop", "-aim" if aiming else ""]
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/" + name)
	var result := root.get_texture().get_image().save_png(path)
	print("BATTLE12 SCREENSHOT: %s (%s)" % [path, error_string(result)])
	quit(0 if result == OK else 1)
