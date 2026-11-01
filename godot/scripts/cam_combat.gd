extends Node
## One camera owner; completion (or an explicit skip) gates attack resolution.
const BLEND := 0.6
var g
var skip_requested := false
var return_pivot := Vector3.ZERO
var trace: Array[String] = []

func wait(seconds: float) -> void:
	seconds /= float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed"))
	var elapsed := 0.0
	while elapsed < seconds and not skip_requested and is_instance_valid(g) and g.is_inside_tree():
		await g.get_tree().process_frame
		if not is_instance_valid(g) or not g.is_inside_tree(): return
		elapsed += get_process_delta_time() / maxf(Engine.time_scale, 0.01)

func frame(from: Vector3, to: Vector3, style: String = "shoot") -> void:
	if not g.action_camera or skip_requested: return
	if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
	if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
	if not g.cinematic: return_pivot = g.pivot
	g.cinematic = true
	trace.append("camera_start")
	var direction := to - from; direction.y = 0
	if direction.length_squared() < 0.01: direction = Vector3.FORWARD
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0, direction.x)
	var shoulder := from - direction * 3.0 + side * 1.25 + Vector3.UP * 2.3
	var look := from.lerp(to, 0.65) + Vector3.UP
	if style in ["push", "pull", "force", "reveal"]:
		shoulder = from.lerp(to, 0.4) + side * maxf(4.0, from.distance_to(to) * 0.8) + Vector3.UP * 3.4
		look = from.lerp(to, 0.5) + Vector3.UP
	var initial_look: Vector3 = g.camera.position - g.camera.global_basis.z * 8.0
	g.action_tween = g.create_tween().set_parallel(true).set_speed_scale(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")))
	g.action_tween.tween_property(g.camera, "position", shoulder, BLEND).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	g.action_tween.tween_method(func(value: Vector3): g.camera.look_at(value, Vector3.UP), initial_look, look, BLEND)
	await wait(BLEND)
	if not skip_requested:
		g.camera.position = shoulder; g.camera.look_at(look, Vector3.UP)
	trace.append("camera_ready")

func skip() -> void:
	skip_requested = true
	trace.append("camera_skipped")
	finish()

func finish() -> void:
	if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
	if g.cinematic: g.pivot = return_pivot
	g.cinematic = false
	g._update_camera()
