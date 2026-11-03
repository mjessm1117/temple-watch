extends RefCounted
const AI = preload("res://scripts/ai.gd")
const Round = preload("res://scripts/combat_round.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")

static func play(game: Node3D) -> void:
	game.playing_enemy_events = true
	game.mission.presentation_active = true
	game.cam.skip_requested = false
	var prior_handoff: Variant = game.phase_banner.get_meta("handoff_tween") if game.phase_banner.has_meta("handoff_tween") else null
	if prior_handoff is Tween and prior_handoff.is_running(): prior_handoff.kill()
	game.phase_banner.text = "ENEMY ACTIVITY  •  SPACE TO SKIP"
	game.phase_banner.modulate.a = 1.0
	game.phase_banner.visible = true
	game.sound.play("turn")
	game.mission.defer_resolution = true
	Round.begin(game.mission)
	await Presentation.drain(game)
	var fired: Dictionary = {}
	for enemy in game.mission.living("enemy"):
		if game.mission.result != "": break
		if not game.cam.skip_requested:
			game.cam.finish()
			game._glide_to(Vector3(enemy.x, 0, enemy.y), 0.25)
			while game.camera_tween != null and game.camera_tween.is_running() and not game.cam.skip_requested: await game.get_tree().process_frame
		game.cam.trace.append("actor_%d" % int(enemy.id))
		game.mission.enemy_actor(enemy, fired)
		await Presentation.drain(game)
		# The next enemy does not decide until this enemy and its reactions finish.
	game.mission.defer_resolution = false
	Round.finish(game.mission)
	await Presentation.drain(game)
	game.cam.finish()
	game.playing_enemy_events = false
	game.mission.presentation_active = false
	game.phase_banner.visible = game.mission.result == ""
	if game.mission.result == "":
		game.phase_banner.text = "YOUR TURN"
		game.phase_banner.modulate.a = 1.0
		var handoff := game.create_tween(); handoff.tween_interval(1.0); handoff.tween_property(game.phase_banner, "modulate:a", 0.0, 0.25); handoff.tween_callback(func() -> void: game.phase_banner.visible = false)
		game.phase_banner.set_meta("handoff_tween", handoff)
		var next_id: int = preload("res://scripts/input_controls.gd").next_squad(game.mission, game.selected_id, 1, true)
		if next_id >= 0: game.selected_id = -1; game._select(next_id)
	game._refresh()
	game.get_node("/root/CampaignFlow").battle_beat(game)
