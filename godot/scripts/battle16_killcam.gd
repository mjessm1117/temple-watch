extends RefCounted
## Brief Jedi strike close-up after a killing blow.

static func eligible(game: Node3D, event: Dictionary) -> bool:
	if not game.action_camera or game.cam.skip_requested or not bool(event.get("killed", false)): return false
	var unit: Dictionary = game.mission.unit_by_id(int(event.get("actor", -1)))
	return str(unit.get("model", "")) == "jedi" and not preload("res://scripts/characters/jedi_models.gd").id_for(unit).is_empty()

static func play(game: Node3D, event: Dictionary) -> void:
	var actor: Node3D = game.views.get(int(event.actor))
	if actor == null or actor.model == null or game.cam.skip_requested: return
	var target: Vector2i = event.to
	var forward := Vector3(float(target.x) - actor.global_position.x, 0.0, float(target.y) - actor.global_position.z)
	if forward.length_squared() < 0.01: forward = Vector3.FORWARD
	forward = forward.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	var eye := actor.global_position + forward * 3.0 + side * 0.55 + Vector3.UP * 1.95
	var look := actor.global_position + Vector3.UP * 1.7
	var prior: Transform3D = game.camera.transform
	var prior_fov: float = game.camera.fov
	var prior_pose: Vector3 = actor.model.rotation
	game.cinematic = true
	game.camera.v_offset = 0.0
	game.cam.trace.append("jedi_killcam_start")
	if actor.animation != null and actor.animation.has_animation("swing"):
		actor.animation.play("swing", 0.06)
		actor.animation.seek(0.0, true)
	var pose := game.create_tween()
	pose.tween_property(actor.model, "rotation:z", prior_pose.z - 0.22, 0.24).set_trans(Tween.TRANS_CUBIC)
	pose.tween_property(actor.model, "rotation:z", prior_pose.z + 0.08, 0.23).set_trans(Tween.TRANS_SINE)
	pose.tween_property(actor.model, "rotation:z", prior_pose.z, 0.17)
	var tween := game.create_tween().set_parallel(true)
	tween.tween_property(game.camera, "position", eye, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(game.camera, "fov", 48.0, 0.16)
	var from_look: Vector3 = game.camera.position - game.camera.global_basis.z * 8.0
	tween.tween_method(func(point: Vector3) -> void: game.camera.look_at(point, Vector3.UP), from_look, look, 0.16)
	await game.cam.wait(0.16)
	if tween.is_running(): tween.kill()
	if game.cam.skip_requested:
		pose.kill(); actor.model.rotation = prior_pose
		game.cam.trace.append("jedi_killcam_skipped"); return
	game.camera.position = eye
	game.camera.fov = 48.0
	game.camera.look_at(look, Vector3.UP)
	game.cam.trace.append("jedi_killcam_close")
	await game.cam.wait(0.48)
	if pose.is_running(): pose.kill()
	actor.model.rotation = prior_pose
	if game.cam.skip_requested: game.cam.trace.append("jedi_killcam_skipped"); return
	game.camera.transform = prior
	game.camera.fov = prior_fov
	game.cam.trace.append("jedi_killcam_return")
