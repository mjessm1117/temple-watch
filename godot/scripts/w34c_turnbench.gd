extends SceneTree
## Deterministic live enemy phase at phone resolution. Run with -- --map=rescue|archive.
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var map_id := "rescue"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_id = arg.trim_prefix("--map=")
	if map_id not in ["rescue", "archive"]: quit(2); return
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	var mission: RefCounted = Mission.new(2201, "res://data/maps/%s.json" % map_id)
	game.mission = Combat.adopt(mission)
	game.mission.rng.seed = 2201
	var kept: Array[Dictionary] = []
	var enemies: Array[Dictionary] = []
	for unit in game.mission.units:
		if str(unit.side) == "enemy":
			if map_id == "rescue" and enemies.size() >= 4: continue
			enemies.append(unit)
		kept.append(unit)
	game.mission.units = kept
	var player: Dictionary = game.mission.living("player")[0]
	var shooter: Dictionary = enemies[0]
	for tile in game.mission.paths(player, 5).costs:
		if Shot.distance(tile, Shot.pos(player)) < 2.0 or Shot.distance(tile, Shot.pos(player)) > 5.0: continue
		if not game.mission.passable(tile) or game.mission.occupied(tile): continue
		if not Shot.los(game.mission, tile, Shot.pos(player)): continue
		shooter.x = tile.x; shooter.y = tile.y
		break
	shooter.aim = 200; shooter.range = 8.0
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		enemy.awake = true; enemy.spotted = true
		if i > 0: enemy.disarmed = true; enemy.range = 1.0
	game._build_terrain(); game._refresh_figures()
	var samples: Array[Dictionary] = []
	var current := -1
	var trace_offset := 0
	var motion_seen: Dictionary = {}
	var start := Time.get_ticks_msec()
	game._end_turn()
	while game.playing_enemy_events or game.mission.phase == "enemy":
		var now := Time.get_ticks_msec() - start
		if now > 30000: break
		while trace_offset < game.cam.trace.size():
			var mark: String = game.cam.trace[trace_offset]
			trace_offset += 1
			if mark.begins_with("actor_"): current = int(mark.trim_prefix("actor_"))
			samples.append({"ms":now,"actor":current,"mark":mark})
		for enemy in enemies:
			var id := int(enemy.id)
			var view: Node3D = game.views.get(id)
			var running: bool = view != null and view.motion != null and view.motion.is_running()
			if running != bool(motion_seen.get(id, false)):
				motion_seen[id] = running
				samples.append({"ms":now,"actor":id,"mark":"move_start" if running else "move_end"})
		await process_frame
	var elapsed := Time.get_ticks_msec() - start
	while trace_offset < game.cam.trace.size():
		var final_mark: String = game.cam.trace[trace_offset]
		trace_offset += 1
		if final_mark.begins_with("actor_"): current = int(final_mark.trim_prefix("actor_"))
		samples.append({"ms":elapsed,"actor":current,"mark":final_mark})
	# Visual tails may continue after control returns; measure them separately.
	var tail_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tail_start < 3000:
		var any_motion := false
		for enemy in enemies:
			var id := int(enemy.id)
			var view: Node3D = game.views.get(id)
			var running: bool = view != null and view.motion != null and view.motion.is_running()
			if running != bool(motion_seen.get(id, false)):
				motion_seen[id] = running
				samples.append({"ms":Time.get_ticks_msec()-start,"actor":id,"mark":"move_start" if running else "move_end"})
			any_motion = any_motion or running
		if not any_motion: break
		await process_frame
	var actors: Array[Dictionary] = []
	for i in range(enemies.size()):
		var id := int(enemies[i].id)
		var begin := -1
		var ending := elapsed
		var camera_start := -1
		var camera_ms := 0
		var move_start := -1
		var move_ms := 0
		var impact_at := -1
		for sample in samples:
			var mark: String = sample.mark
			var at: int = sample.ms
			if mark == "actor_%d" % id: begin = at
			elif begin >= 0 and mark.begins_with("actor_"): ending = at; break
			if begin < 0: continue
			if int(sample.actor) == id:
				if mark == "camera_start": camera_start = at
				elif mark == "camera_ready" and camera_start >= 0: camera_ms += at - camera_start; camera_start = -1
				elif mark.begins_with("impact_"): impact_at = at
		for sample in samples:
			if int(sample.actor) != id: continue
			if str(sample.mark) == "move_start": move_start = int(sample.ms)
			elif str(sample.mark) == "move_end" and move_start >= 0: move_ms += int(sample.ms) - move_start; move_start = -1
		if begin < 0: continue
		var first_action := ending
		for sample in samples:
			if int(sample.actor) == id and int(sample.ms) >= begin and str(sample.mark) in ["camera_start", "move_start"]: first_action = mini(first_action, int(sample.ms))
		var shot_ms := 0
		if impact_at >= 0:
			var latest_ready := begin
			for sample in samples:
				if int(sample.actor) == id and str(sample.mark) == "camera_ready" and int(sample.ms) <= impact_at: latest_ready = int(sample.ms)
			shot_ms = impact_at - latest_ready
		var pre_ms := maxi(0, first_action - begin)
		var post_ms := maxi(0, ending - maxi(impact_at, first_action + move_ms))
		actors.append({"id":id,"total_ms":ending-begin,"camera_ms":camera_ms,"pre_ms":pre_ms,"move_ms":move_ms,"shot_ms":shot_ms,"post_ms":post_ms})
	print("W34C_BENCH map=%s phase_ms=%d enemies=%d phase=%s" % [map_id, elapsed, enemies.size(), game.mission.phase])
	for item in actors: print("W34C_ACTOR id=%d total_ms=%d camera_ms=%d pre_ms=%d move_ms=%d shot_ms=%d post_ms=%d" % [item.id,item.total_ms,item.camera_ms,item.pre_ms,item.move_ms,item.shot_ms,item.post_ms])
	print("W34C_TRACE %s" % JSON.stringify(samples))
	var valid: bool = game.mission.phase == "player" and actors.size() == enemies.size() and enemies.size() >= (4 if map_id == "rescue" else 6)
	game.queue_free()
	for i in range(4): await process_frame
	quit(0 if valid else 1)
