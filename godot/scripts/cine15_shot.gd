extends RefCounted
## Short player-shot camera beats around the existing lit bolt and impact effects.
const Presentation = preload("res://scripts/enemy_presentation.gd")
const JediKillcam = preload("res://scripts/battle16_killcam.gd")

static func play(game: Node3D, event: Dictionary) -> void:
	var camera_on: bool = game.action_camera and not game.cam.skip_requested
	var hidden: Array[Node3D] = []
	if camera_on and str(event.get("mode", "shoot")) in ["shoot", "strike"]:
		for ally in game.mission.living("player"):
			if int(ally.id) == int(event.actor): continue
			var view: Node3D = game.views.get(int(ally.id))
			if view != null and view.visible:
				view.hide(); hidden.append(view)
		if game.hud_controls.aim_ui != null:
			game.hud_controls.aim_ui.panel.hide()
			game.hud_controls.aim_ui.sight.hide()
			game.hud_controls.night.chips.hide()
		var to: Vector2i = event.to
		var point := Vector3(float(to.x), 1.2, float(to.y))
		var forward: Vector3 = (point - game.camera.global_position).normalized()
		var tween := game.create_tween()
		tween.tween_property(game.camera, "position", game.camera.position + forward * 0.7, 0.12).set_trans(Tween.TRANS_SINE)
		await game.cam.wait(0.12)
		if tween.is_running(): tween.kill()
		await game.cam.wait(0.17)
		game.cam.trace.append("cine15_push")
	await Presentation.show_event(game, event)
	if camera_on and bool(event.get("killed", false)) and not game.cam.skip_requested:
		if JediKillcam.eligible(game, event):
			await JediKillcam.play(game, event)
		else:
			var tile: Vector2i = event.to
			var at := Vector3(float(tile.x), 1.0, float(tile.y))
			var previous_position: Vector3 = game.camera.position
			var previous_fov: float = game.camera.fov
			game.cinematic = true
			game.camera.position = at + Vector3(2.2, 1.8, 2.6)
			game.camera.look_at(at, Vector3.UP)
			game.camera.fov = 46.0
			game.cam.trace.append("cine15_fall_frame")
			await game.cam.wait(0.22)
			game.camera.position = previous_position
			game.camera.fov = previous_fov
		game.cam.finish()
	for view in hidden:
		if is_instance_valid(view): view.show()
