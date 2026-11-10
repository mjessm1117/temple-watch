extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(844,390)
	root.content_scale_size = root.size
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	game.mission = Combat.adopt(Mission.new(2201))
	game.mission.rng.seed = 2201
	var kept: Array[Dictionary] = []
	var enemies: Array[Dictionary] = []
	for unit in game.mission.units:
		if str(unit.side) == "enemy":
			if enemies.size() >= 4: continue
			enemies.append(unit)
		kept.append(unit)
	game.mission.units = kept
	var player: Dictionary = game.mission.living("player")[0]
	var shooter: Dictionary = enemies[0]
	for tile in game.mission.paths(player,5).costs:
		if Shot.distance(tile,Shot.pos(player)) < 2.0 or Shot.distance(tile,Shot.pos(player)) > 5.0: continue
		if not game.mission.passable(tile) or game.mission.occupied(tile): continue
		if not Shot.los(game.mission,tile,Shot.pos(player)): continue
		shooter.x = tile.x; shooter.y = tile.y
		break
	shooter.aim = 200; shooter.range = 8.0
	var starts: Dictionary = {}
	for i in range(4):
		var enemy: Dictionary = enemies[i]
		enemy.awake = true; enemy.spotted = true
		starts[int(enemy.id)] = Shot.pos(enemy)
		if i > 0: enemy.disarmed = true; enemy.range = 1.0
	game._build_terrain(); game._refresh_figures()
	var start := Time.get_ticks_msec()
	game._end_turn()
	while game.playing_enemy_events or game.mission.phase == "enemy":
		if Time.get_ticks_msec() - start > 20000: break
		await process_frame
	var elapsed := Time.get_ticks_msec() - start
	var attacks := 0
	var actors := 0
	for mark in game.cam.trace:
		if mark.begins_with("impact_"): attacks += 1
		if mark.begins_with("actor_"): actors += 1
	var moves := 0
	for enemy in enemies:
		if Shot.pos(enemy) != starts[int(enemy.id)]: moves += 1
	print("FEELCAM22 FULL TURN seed=2201 wall=%d ms actors=%d attacks=%d moves=%d phase=%s" % [elapsed,actors,attacks,moves,game.mission.phase])
	var valid: bool = actors == 4 and attacks == 1 and moves >= 2 and game.mission.phase == "player"
	game.queue_free()
	for i in range(4): await process_frame
	quit(0 if valid else 1)
