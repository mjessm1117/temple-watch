extends RefCounted
## Brief Jedi strike close-up after a killing blow.

static func eligible(game: Node3D, event: Dictionary) -> bool:
	if not game.action_camera or game.cam.skip_requested or not bool(event.get("killed", false)): return false
	var unit: Dictionary = game.mission.unit_by_id(int(event.get("actor", -1)))
	return str(unit.get("model", "")) == "jedi" and not preload("res://scripts/characters/jedi_models.gd").id_for(unit).is_empty()

static func play(game: Node3D, event: Dictionary) -> void:
	var actor: Node3D = game.views.get(int(event.actor))
	if actor == null or actor.model == null or game.cam.skip_requested: return
	var victim: Node3D = game.views.get(int(event.target))
	if victim == null: return
	var target: Vector2i = event.to
	var forward := Vector3(float(target.x) - actor.global_position.x, 0.0, float(target.y) - actor.global_position.z)
	if forward.length_squared() < 0.01: forward = Vector3.FORWARD
	forward = forward.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	var eye := actor.global_position - forward * 1.7 - side * 2.25 + Vector3.UP * 1.65
	var look := actor.global_position.lerp(victim.global_position, 0.57) + Vector3.UP * 1.15
	var prior: Transform3D = game.camera.transform
	var prior_fov: float = game.camera.fov
	var prior_pose: Vector3 = actor.model.rotation
	game.cinematic = true
	actor.face(victim.global_position)
	game.camera.v_offset = 0.0
	game.cam.trace.append("jedi_killcam_start")
	if actor.animation != null and actor.animation.has_animation("swing"):
		actor.animation.play("swing", 0.06)
		actor.animation.seek(0.0, true)
	var tween := game.create_tween().set_parallel(true)
	tween.tween_property(game.camera, "position", eye, 0.06).set_trans(Tween.TRANS_SINE)
	tween.tween_property(game.camera, "fov", 54.0, 0.06)
	var from_look: Vector3 = game.camera.position - game.camera.global_basis.z * 8.0
	tween.tween_method(func(point: Vector3) -> void: game.camera.look_at(point, Vector3.UP), from_look, look, 0.06)
	await game.cam.wait(0.06)
	if tween.is_running(): tween.kill()
	if game.cam.skip_requested:
		actor.model.rotation = prior_pose
		game.cam.trace.append("jedi_killcam_skipped"); return
	game.camera.position = eye
	game.camera.fov = 54.0
	game.camera.look_at(look, Vector3.UP)
	game.cam.trace.append("jedi_killcam_close")
	await game.cam.wait(0.09)
	if not game.cam.skip_requested:
		victim.act("hit")
		game.fx.burst(victim.global_position + Vector3.UP * 1.1, Color("b9f5ff"), 8)
		game.cam.trace.append("jedi_killcam_hit")
	await game.cam.wait(0.09)
	actor.model.rotation = prior_pose
	if game.cam.skip_requested: game.cam.trace.append("jedi_killcam_skipped"); return
	game.camera.transform = prior
	game.camera.fov = prior_fov
	game.cam.trace.append("jedi_killcam_return")
