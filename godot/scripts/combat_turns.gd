extends RefCounted
const AI = preload("res://scripts/ai.gd")
const Round = preload("res://scripts/combat_round.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Events = preload("res://scripts/feelcam22_events.gd")
const EnemyTiming = preload("res://scripts/w34c_enemy_timing.gd")

static func play(game: Node3D) -> void:
	game.playing_enemy_events = true
	game.mission.presentation_active = true
	game.cam.skip_requested = false
	game.cam.fast_forward_w34c = false
	if game.has_meta("w34c_drama_started_ms"): game.remove_meta("w34c_drama_started_ms")
	var prior_handoff: Variant = game.phase_banner.get_meta("handoff_tween") if game.phase_banner.has_meta("handoff_tween") else null
	if prior_handoff is Tween and prior_handoff.is_running(): prior_handoff.kill()
	game.phase_banner.text = "ENEMY ACTIVITY  •  TAP TO SPEED UP"
	game.phase_banner.modulate.a = 1.0
	game.phase_banner.visible = true
	game.sound.play("turn")
	game.mission.defer_resolution = true
	Round.begin(game.mission)
	Events.emit(game, "enemy_turn_start", {}, game.pivot)
	Events.music(game, "enemy")
	await Presentation.drain(game)
	if not game.villain_seen:
		for enemy in game.mission.living("enemy"):
			if not bool(enemy.get("villain11", false)): continue
			game.villain_seen = true
			var at := Vector3(enemy.x, 0, enemy.y)
			await game.cam.frame(at, at, "reveal")
			Events.emit(game, "villain_reveal", {"actor":enemy.id}, at)
			Events.cue(game, "villain")
			Events.music(game, "contact")
			await game.cam.hold_drama_w34c()
			game.cam.finish()
			break
	var fired: Dictionary = {}
	var group_center := Vector3.ZERO
	var group_count := 0
	for near_enemy in game.mission.living("enemy"):
		if not bool(near_enemy.awake): continue
		group_center += Vector3(near_enemy.x, 0, near_enemy.y)
		group_count += 1
		if group_count == 4: break
	if group_count > 0 and EnemyTiming.on_screen(game, group_center / float(group_count)):
		game.cam.trace.append("group_frame_%d" % group_count)
	for enemy in game.mission.living("enemy"):
		if game.mission.result != "": break
		game.cam.trace.append("actor_%d" % int(enemy.id))
		game.mission.enemy_actor(enemy, fired)
		await Presentation.drain(game)
		# Important events finish before the next decision; quiet travel may overlap.
	Presentation.release_quiet_w34c(game)
	if game.has_meta("w34c_drama_started_ms"):
		await game.cam.hold_drama_until_w34c(int(game.get_meta("w34c_drama_started_ms")))
	game.mission.defer_resolution = false
	Round.finish(game.mission)
	await Presentation.drain(game)
	game.cam.finish()
	game.playing_enemy_events = false
	game.mission.presentation_active = false
	Events.emit(game, "enemy_turn_end", {}, game.pivot)
	game.phase_banner.visible = game.mission.result == ""
	if game.mission.result == "":
		Events.music(game, "contact")
		Events.emit(game, "player_turn_start", {}, game.pivot)
		game.phase_banner.text = "YOUR TURN"
		game.phase_banner.modulate.a = 1.0
		var handoff := game.create_tween(); handoff.tween_interval(1.0); handoff.tween_property(game.phase_banner, "modulate:a", 0.0, 0.25); handoff.tween_callback(func() -> void: game.phase_banner.visible = false)
		game.phase_banner.set_meta("handoff_tween", handoff)
		var next_id: int = preload("res://scripts/input_controls.gd").next_squad(game.mission, game.selected_id, 1, true)
		if next_id >= 0: game.selected_id = -1; game._select(next_id)
	game._refresh()
	game.get_node("/root/CampaignFlow").battle_beat(game)
