extends SceneTree
## Real-window evidence scenes, run with -- --kind=targeting|concealment|reaction --output=/absolute/file.png.
const Shot = preload("res://scripts/shot.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var kind := "targeting"
	var output := "/tmp/combat7.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kind="): kind = arg.trim_prefix("--kind=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	var m: RefCounted = game.mission
	var players: Array = m.living("player")
	var enemy: Dictionary = m.living("enemy")[0]
	for y in range(17,24):
		for x in range(3,14): m.set_tile(Vector2i(x,y),"_")
	for i in range(players.size()): players[i].x = 5 + i; players[i].y = 22
	enemy.x=9; enemy.y=18; enemy.awake=true; enemy.spotted=true; enemy.hp=14; enemy.max_hp=14; enemy.armor=2
	m.set_tile(Vector2i(9,19),"c")
	m.set_tile(Vector2i(7,22),"^")
	m.terrain_revision += 1
	game.selected_id=int(players[2].id)
	game.pivot=Vector3(8,0,20); game.zoom=15; game.yaw=0.2; game.pitch=0.83
	game._refresh(); game._update_camera()
	if kind == "concealment":
		m.spec.concealed=true; m.setup_combat(); enemy.awake=false
		game._refresh()
		game.warning_label.text="SQUAD CONCEALED  •  Red tiles expose the squad. Set overwatch before opening the ambush."
	elif kind == "blocked":
		for x in range(3,14): m.set_tile(Vector2i(x,20),"#")
		m.terrain_revision += 1
		game.action="shoot"; game.target_id=int(enemy.id); game._refresh()
	else:
		game.action="shoot"; game.target_id=int(enemy.id); game._refresh()
		game.warning_label.text="PREVIEW  •  Height, cover, armor and ammunition are included before confirmation."
	await create_timer(0.8).timeout
	if kind == "reaction":
		game.phase_banner.text="AMBUSH  •  REACTION FIRE"; game.phase_banner.visible=true
		players[2].overwatch = true
		m.defer_resolution = true; m._reaction_fire(enemy); m.defer_resolution = false
		game.playing_enemy_events = true
		reaction(game)
		await create_timer(0.68).timeout
	for i in range(3): await process_frame
	var error := root.get_texture().get_image().save_png(output)
	print("COMBAT7 WINDOW CAPTURE: %s (%d)" % [output,error])
	game._skip_activity()
	while game.player_attack_pending or game.playing_enemy_events: await process_frame
	game.queue_free(); await process_frame
	quit(0 if error==OK else 1)

func reaction(game: Node3D) -> void:
	await preload("res://scripts/enemy_presentation.gd").drain(game)
	game.cam.finish()
	game.playing_enemy_events = false
	game._refresh()
