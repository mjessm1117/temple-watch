extends RefCounted
const AI = preload("res://scripts/ai.gd")
const Round = preload("res://scripts/combat_round.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")

static func play(game: Node3D) -> void:
	game.playing_enemy_events = true
	game.mission.presentation_active = true
	game.cam.skip_requested = false
	game.phase_banner.text = "ENEMY ACTIVITY  •  SPACE TO SKIP"
	game.phase_banner.visible = true
	game.sound.play("turn")
	game.mission.defer_resolution = true
	Round.begin(game.mission)
	await Presentation.drain(game)
	var fired: Dictionary = {}
	for enemy in game.mission.living("enemy"):
		if game.mission.result != "": break
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
	game.phase_banner.visible = false
	game._refresh()
	game.get_node("/root/CampaignFlow").battle_beat(game)
