extends SceneTree
const Presentation = preload("res://scripts/enemy_presentation.gd")
const AimCamera = preload("res://scripts/cam_combat.gd")
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Killcam = preload("res://scripts/battle16_killcam.gd")
const Events = preload("res://scripts/feelcam22_events.gd")
const InputControls = preload("res://scripts/input_controls.gd")
var checks := 0
var failures := 0
class CueProbe extends Node:
	var cues: Array[String] = []
	var states: Array[String] = []
	func cue(kind: String) -> void: cues.append(kind)
	func set_music_state(state: String) -> void: states.append(state)
	func play(_kind: String) -> void: pass

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	game.mission.rng.seed = 2201
	var seen: Array[Dictionary] = []
	var objective_frame: Array[Vector2] = []
	game.battle_event.connect(func(kind: String, actor_id: String, target_id: String, context: Dictionary) -> void:
		seen.append({"kind":kind, "actor":actor_id, "target":target_id, "context":context})
		if kind == "objective_hit":
			objective_frame.append(game.camera.unproject_position(context.source_pos))
			objective_frame.append(game.camera.unproject_position(context.world_pos)))
	game.playing_enemy_events = true
	game.mission.presentation_active = true
	var enemies: Array[Dictionary] = game.mission.living("enemy")
	check(enemies.size() >= 4, "four enemies in fixture")
	var player: Dictionary = game.mission.living("player")[0]
	var events: Array[Dictionary] = []
	for i in range(4):
		var e: Dictionary = enemies[i]
		e.awake = true; e.spotted = true
		var from := Vector2i(int(e.x), int(e.y))
		var to := from + Vector2i(1, 0)
		if game.mission.tile(to) == "#": to = from + Vector2i(-1, 0)
		e.x = to.x; e.y = to.y
		events.append({"kind":"move", "actor":int(e.id), "from":from, "to":to, "path":[to]})
	var shooter: Dictionary = enemies[0]
	var shot_from := Vector2i(int(shooter.x), int(shooter.y))
	var shot_to := Vector2i(int(player.x), int(player.y))
	events.append({"kind":"attack", "actor":int(shooter.id), "target":int(player.id), "from":shot_from, "to":shot_to, "mode":"shoot", "enemy":true, "outcome":"hits", "damage":2, "killed":false})
	game._refresh_figures()
	var start := Time.get_ticks_msec()
	await Presentation.play(game, events, 0)
	var elapsed := Time.get_ticks_msec() - start
	print("FEELCAM22 BENCH seed=2201 four moves one attack: %d ms" % elapsed)
	check(elapsed <= 495, "four moves and one attack <= 60%% of 825 ms baseline: %d" % elapsed)
	check(game.cam.trace.count("camera_start") == 1, "one attack camera beat for four moves")
	check(game.quiet_motions.is_empty(), "all batched travel completes before attack result")
	for i in range(4):
		var unit: Dictionary = enemies[i]
		var view: Node3D = game.views.get(int(unit.id))
		check(view != null and view.position.distance_to(Vector3(unit.x, view.position.y, unit.y)) < 0.1, "quiet actor %d lands on destination" % i)
	check(seen.size() >= 2 and seen[0].kind == "hit" and seen[1].kind == "hurt", "hit and hurt signal order")
	check(int(seen[0].context.damage) == 2 and seen[0].context.world_pos is Vector3 and int(seen[0].context.turn) == game.mission.turn, "battle_event has numeric damage, position and turn")
	check(AimCamera.BLEND <= 0.25 and AimCamera.REPEAT_BLEND <= 0.15, "shot and repeat blends are short")
	check(Killcam.eligible(game, {"actor":int(game.mission.living("player")[0].id), "killed":false}) == false, "nonkill has no killcam")
	var shrine := Combat.adopt(Mission.new(2201, "res://data/maps/shrine.json"))
	var shrine_actor: Dictionary = shrine.living("player")[0]
	var shrine_target: Dictionary = shrine.living("enemy")[0]
	var origin := Vector3(shrine_actor.x, 0, shrine_actor.y)
	var destination := Vector3(shrine_target.x, 0, shrine_target.y)
	var eye := AimCamera.aim_shoulder(shrine, origin, destination, true, Vector2(844,390))
	var direction := destination - eye; direction.y = 0.0
	var look := destination + direction.normalized().cross(Vector3.UP) * 0.75 + Vector3.UP * 1.25
	var target_screen := AimCamera.aim_screen_point(eye, look, destination + Vector3.UP * 1.25, Vector2(844,390))
	var shooter_screen := AimCamera.aim_screen_point(eye, look, origin + Vector3.UP * 1.18, Vector2(844,390))
	check(target_screen.x >= 0.38 and target_screen.x <= 0.70 and target_screen.y >= 0.20 and target_screen.y <= 0.63, "shrine target in clear phone band: %s" % target_screen)
	check(Vector2((target_screen.x-shooter_screen.x)*844.0,(target_screen.y-shooter_screen.y)*390.0).length() >= 40.0, "shrine shooter-to-target sightline remains legible")
	check(AimCamera.aim_ray_clear(shrine, eye, destination + Vector3.UP * 1.25), "shrine shoulder has target line of sight")
	for dims in [Vector2(390,844),Vector2(1366,768)]:
		var other_eye := AimCamera.aim_shoulder(shrine, origin, destination, dims.x < 844, dims)
		var other_direction := destination - other_eye; other_direction.y = 0.0
		var other_look := destination + other_direction.normalized().cross(Vector3.UP) * (0.75 if dims.x < 844 else 0.0) + Vector3.UP * 1.25
		var other_screen := AimCamera.aim_screen_point(other_eye, other_look, destination + Vector3.UP * 1.25, dims, 58.0 if dims.x < 844 else 52.0)
		check(other_screen.x >= 0.30 and other_screen.x <= 0.75 and other_screen.y >= 0.20 and other_screen.y <= 0.70, "shrine target visible at %s: %s" % [dims,other_screen])
	var probe := CueProbe.new(); game.add_child(probe)
	game.sound = probe
	var objective_actor: Dictionary = enemies[1]
	game.mission.objective_state.relay_hp = 17
	var objective_event := {"kind":"objective_attack", "actor":int(objective_actor.id), "from":Vector2i(objective_actor.x,objective_actor.y), "to":Vector2i(player.x,player.y), "damage":2}
	await Presentation.show_event(game, objective_event)
	var objective_signal: Dictionary = seen.back()
	check(objective_signal.kind == "objective_hit" and objective_signal.target == "gate" and int(objective_signal.context.objective_hp) == 17 and int(objective_signal.context.damage) == 2, "objective signal carries gate ID, HP and damage")
	check(objective_signal.context.source_pos.distance_to(objective_signal.context.world_pos) > 0.1 and "17 HP" in game.phase_banner.text and str(objective_actor.name) in game.phase_banner.text, "gate HP and attacker origin are visible")
	check(probe.cues == ["objective_hit"], "objective hit reaches B cue")
	check(objective_frame.size() == 2 and objective_frame[0].x > 0 and objective_frame[0].x < 844 and objective_frame[1].x > 0 and objective_frame[1].x < 844 and objective_frame[0].y > 0 and objective_frame[0].y < 390 and objective_frame[1].y > 0 and objective_frame[1].y < 390, "attacker and gate share the 844x390 frame: %s" % str(objective_frame))
	var group := int(enemies[2].group)
	var reveal := {"kind":"activation", "actor":int(enemies[2].id), "at":Vector2i(enemies[2].x,enemies[2].y)}
	var before_reveals := seen.filter(func(e: Dictionary) -> bool: return e.kind == "reveal").size()
	await Presentation.show_event(game, reveal)
	await Presentation.show_event(game, reveal)
	var after_reveals := seen.filter(func(e: Dictionary) -> bool: return e.kind == "reveal").size()
	check(after_reveals == before_reveals + 1 and game.last_reveal_group == group, "nearby reveal group gets one camera beat")
	check(int(seen.back().context.group) == group and int(seen.back().context.count) >= 1, "reveal signal describes the group")
	check(probe.cues == ["objective_hit", "alert"] and probe.states == ["contact"], "group reveal reaches B alert and contact music")
	var pressure_script: Script = preload("res://scripts/mission_pressure.gd")
	check(pressure_script.has_method("setup"), "script guard detects static D API")
	if pressure_script.has_method("reveal_info"):
		check(game.phase_banner.text != "PATROL ALERTED", "D reveal title is shown when available")
	Events.cue(game,"blast")
	check(probe.cues.back() == "blast", "blast reaches B cue through game.sound")
	var skip_event := {"kind":"move", "actor":int(enemies[3].id), "from":Vector2i(enemies[3].x,enemies[3].y), "to":Vector2i(enemies[3].x+1,enemies[3].y), "path":[Vector2i(enemies[3].x+1,enemies[3].y)]}
	await Presentation.show_event(game, skip_event)
	game.cam.skip()
	var skip_start := Time.get_ticks_msec()
	await Presentation.flush_quiet(game)
	check(Time.get_ticks_msec() - skip_start < 100 and game.quiet_motions.is_empty(), "tap skip releases batched travel within 100 ms")
	game.cam.skip_requested = false
	var enemy_story_start := Time.get_ticks_msec()
	await game.cue_story("reveal", Vector3(player.x,0,player.y))
	check(Time.get_ticks_msec() - enemy_story_start <= 600 and game.cam.trace.has("camera_ready"), "story reveal focus works during enemy activity")
	game.cam.finish()
	game.playing_enemy_events = false
	var focus_start := Time.get_ticks_msec()
	await game.cue_story("focus", Vector3(player.x,0,player.y))
	check(Time.get_ticks_msec() - focus_start <= 600 and Time.get_ticks_msec() - focus_start >= 100, "story focus releases within 0.6 seconds")
	var jedi: Dictionary = {}
	for unit in game.mission.living("player"):
		if str(unit.get("model", "")) == "jedi" and not preload("res://scripts/characters/jedi_models.gd").id_for(unit).is_empty(): jedi = unit; break
	check(not jedi.is_empty(), "named Jedi kill fixture")
	if not jedi.is_empty():
		var kill_event := {"actor":int(jedi.id), "target":int(enemies[0].id), "to":Vector2i(enemies[0].x,enemies[0].y), "killed":true}
		check(Killcam.eligible(game, kill_event), "named Jedi kill is eligible")
		var kill_start := Time.get_ticks_msec()
		await Killcam.play(game, kill_event)
		check(Time.get_ticks_msec() - kill_start <= 300 and "jedi_killcam_return" in game.cam.trace, "Jedi kill beat returns within 0.3 seconds")
	var test_attack := {"kind":"attack", "actor":int(player.id), "target":int(enemies[1].id), "from":Vector2i(player.x,player.y), "to":Vector2i(enemies[1].x,enemies[1].y), "mode":"shoot", "enemy":false, "outcome":"crits", "damage":2, "killed":true, "flanked":true}
	var event_count := seen.size()
	await Presentation.impact(game, test_attack)
	check(probe.cues.slice(-3) == ["hit","crit","kill"], "hit, crit and kill reach B cue in order")
	check(seen[event_count].kind == "hit" and seen[event_count+1].kind == "flank" and seen[event_count+2].kind == "crit" and seen[event_count+3].kind == "kill", "hit, flank, crit and kill battle events keep impact order")
	var miss_event := {"kind":"attack", "actor":int(player.id), "target":int(enemies[2].id), "from":Vector2i(player.x,player.y), "to":Vector2i(enemies[2].x,enemies[2].y), "mode":"shoot", "enemy":false, "outcome":"misses", "damage":0, "killed":false}
	await Presentation.impact(game, miss_event)
	check(seen.back().kind == "miss" and int(seen.back().context.turn) == game.mission.turn, "miss event reports current turn")
	game.mission.objective_state.villain_outcome = "retreated"
	await Presentation.impact(game, {"kind":"attack", "actor":int(player.id), "target":int(enemies[2].id), "from":Vector2i(player.x,player.y), "to":Vector2i(enemies[2].x,enemies[2].y), "mode":"shoot", "enemy":false, "outcome":"hits", "damage":1, "killed":false})
	check(seen.back().kind == "villain_retreat" and game.villain_retreat_seen, "villain retreat follows the hit event")
	game.mission.objective_state.villain_outcome = ""
	game.animate_headless = false
	var turn_count := seen.size()
	game._end_turn()
	check(seen.size() >= turn_count + 3 and seen[turn_count].kind == "enemy_turn_start" and seen[turn_count+1].kind == "enemy_turn_end" and seen[turn_count+2].kind == "player_turn_start", "turn signals follow true phase order")
	check(probe.states.slice(-2) == ["enemy","contact"], "enemy and contact music follow turn phases")
	var kept: Array[Dictionary] = []
	var enemy_count := 0
	for unit in game.mission.units:
		if str(unit.side) == "enemy":
			if enemy_count >= 4: continue
			enemy_count += 1
			unit.awake = true; unit.spotted = true
		kept.append(unit)
	game.mission.units = kept
	for enemy in game.mission.living("enemy"):
		enemy.villain11 = true
		break
	game._refresh_figures()
	game.animate_headless = true
	var live_start := Time.get_ticks_msec()
	game._end_turn()
	while game.playing_enemy_events and Time.get_ticks_msec() - live_start < 10000: await process_frame
	check(not game.playing_enemy_events and game.mission.phase == "player", "four enemy live turn returns control within ten seconds")
	check(game.cam.trace.has("group_frame_4"), "nearby enemies get one grouped camera beat")
	check(seen.any(func(e: Dictionary) -> bool: return e.kind == "villain_reveal") and "villain" in probe.cues, "villain reveal camera event and B cue fire once")
	for enemy in game.mission.living("enemy"): enemy.erase("villain11")
	var ready: Dictionary = game.mission.unit_by_id(game.selected_id)
	var ready_screen: Vector2 = game.camera.unproject_position(Vector3(ready.x,1.0,ready.y)) if not ready.is_empty() else Vector2(-1,-1)
	check(not ready.is_empty() and int(ready.ap) > 0 and ready_screen.x > 0 and ready_screen.x < 844 and ready_screen.y > 0 and ready_screen.y < 390, "next ready unit returns in board frame")
	var kill_shooter: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []) and int(unit.ap) > 0: kill_shooter = unit; break
	check(not kill_shooter.is_empty(), "ready shooter for kill handoff")
	if not kill_shooter.is_empty() and not game.mission.living("enemy").is_empty():
		var victim: Dictionary = game.mission.living("enemy")[0]
		var reach: Dictionary = game.mission.paths(kill_shooter, 2)
		var legal := false
		for tile in reach.costs:
			if int(reach.costs[tile]) != 1: continue
			victim.x = tile.x; victim.y = tile.y; victim.awake = true; victim.spotted = true
			if InputControls.valid_targets(game.mission, kill_shooter, "shoot").any(func(candidate: Dictionary) -> bool: return int(candidate.id) == int(victim.id)): legal = true; break
		check(legal, "kill target is legal")
		if legal:
			victim.hp = 1; kill_shooter.aim = 200; kill_shooter.damage = [20,20]
			game._refresh_figures(); game._select(int(kill_shooter.id))
			game.action = "shoot"; game.target_id = int(victim.id)
			game._attack(int(victim.id), "shoot")
			var attack_start := Time.get_ticks_msec()
			while game.player_attack_pending and Time.get_ticks_msec() - attack_start < 5000: await process_frame
			for i in range(12): await process_frame
			var next_ready_id: int = InputControls.next_squad(game.mission, int(kill_shooter.id), 1, true)
			var next_ready: Dictionary = game.mission.unit_by_id(next_ready_id)
			var next_screen: Vector2 = game.camera.unproject_position(Vector3(next_ready.x,1,next_ready.y)) if not next_ready.is_empty() else Vector2(-1,-1)
			check(not game.player_attack_pending and int(victim.hp) <= 0 and not next_ready.is_empty() and next_screen.x > 0 and next_screen.x < 844 and next_screen.y > 0 and next_screen.y < 390, "kill returns to board with next ready unit visible")
	for i in range(4): await process_frame
	game.queue_free()
	for i in range(4): await process_frame
	var turn_output: Array = []
	var turn_args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--rendering-method", "gl_compatibility", "--resolution", "844x390", "-s", "scripts/feelcam22_turnbench.gd"])
	var turn_status := OS.execute(OS.get_executable_path(), turn_args, turn_output, true)
	var turn_text := "\n".join(turn_output)
	var pattern := RegEx.new(); pattern.compile("wall=([0-9]+) ms")
	var timing := pattern.search(turn_text)
	var turn_ms := int(timing.get_string(1)) if timing != null else -1
	check(turn_status == 0 and turn_ms > 0 and turn_ms <= 2802 and "actors=4 attacks=1 moves=3 phase=player" in turn_text, "full four-enemy turn <= 60%% of 4670 ms baseline: %d ms" % turn_ms)
	print("FEELCAM22 FULL TURN VERIFIED: %d ms versus 4670 ms baseline" % turn_ms)
	print("FEELCAM22 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
