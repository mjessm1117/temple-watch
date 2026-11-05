extends Node
## One camera owner; completion (or an explicit skip) gates attack resolution.
const Shot = preload("res://scripts/shot.gd")
const BLEND := 0.42
const AIM_BLEND := 0.28
var g
var skip_requested := false
var return_pivot := Vector3.ZERO
var trace: Array[String] = []
var touch = preload("res://scripts/touch_input.gd").new()
var touch_angle := 0.0
var preview_active := false
var preview_actor := -1
var preview_target := -1
var preview_tween: Tween

func _ready() -> void:
	touch.g = g

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
		g.set_process_unhandled_input(false)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var prior_angle := touch_angle
		var had_pair: bool = touch.fingers.size() == 2
		touch.handle(event)
		if touch.fingers.size() == 2:
			var points: Array = touch.fingers.values()
			touch_angle = (points[1] - points[0]).angle()
			if had_pair and event is InputEventScreenDrag:
				var turn := wrapf(touch_angle - prior_angle, -PI, PI)
				if absf(turn) < 0.35:
					g.yaw -= turn; g._update_camera()

func wait(seconds: float) -> void:
	seconds /= float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if g.playing_enemy_events else 1.0)
	var elapsed := 0.0
	while elapsed < seconds and not skip_requested and is_instance_valid(g) and g.is_inside_tree():
		await g.get_tree().process_frame
		if not is_instance_valid(g) or not g.is_inside_tree(): return
		elapsed += get_process_delta_time() / maxf(Engine.time_scale, 0.01)

func preview(actor: Dictionary, target: Dictionary) -> void:
	if g.player_attack_pending or g.playing_enemy_events: return
	var actor_id := int(actor.id)
	var target_id := int(target.id)
	if preview_active and preview_actor == actor_id and preview_target == target_id: return
	if not preview_active: return_pivot = g.pivot
	preview_active = true
	preview_actor = actor_id
	preview_target = target_id
	if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
	if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
	var origin := Vector3(float(actor.x), Shot.elevation(g.mission, Shot.pos(actor)) * 0.7, float(actor.y))
	var destination := Vector3(float(target.x), Shot.elevation(g.mission, Shot.pos(target)) * 0.7, float(target.y))
	var direction := destination - origin
	direction.y = 0.0
	if direction.length_squared() < 0.01: direction = Vector3.FORWARD
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0.0, direction.x)
	var phone: bool = g.hud_controls != null and g.hud_controls.phone != null
	var shoulder := origin - direction * (0.4 if phone else 0.6) + side * (10.0 if phone else 10.0) + Vector3.UP * (2.0 if phone else 2.6)
	shoulder = preload("res://scripts/battle11_camera.gd").aim_position(g.mission, shoulder)
	var look := origin.lerp(destination, 0.5) + Vector3.UP * (0.58 if phone else 0.75)
	g.cinematic = true
	preview_tween = g.create_tween().set_parallel(true)
	preview_tween.tween_property(g.camera, "position", shoulder, AIM_BLEND).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var initial_look: Vector3 = g.camera.position - g.camera.global_basis.z * 8.0
	preview_tween.tween_method(func(value: Vector3) -> void: g.camera.look_at(value, Vector3.UP), initial_look, look, AIM_BLEND)

func skip_preview_transition() -> void:
	if not preview_active or preview_tween == null or not preview_tween.is_running(): return
	preview_tween.custom_step(AIM_BLEND)

func end_preview() -> void:
	if not preview_active: return
	if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
	preview_active = false
	preview_actor = -1
	preview_target = -1
	g.pivot = return_pivot
	g.cinematic = false
	g._update_camera()

func frame(from: Vector3, to: Vector3, style: String = "shoot") -> void:
	if not g.action_camera or skip_requested: return
	if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
	preview_active = false
	preview_actor = -1
	preview_target = -1
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
	shoulder = preload("res://scripts/battle11_camera.gd").safe_position(g.mission, shoulder)
	var initial_look: Vector3 = g.camera.position - g.camera.global_basis.z * 8.0
	g.action_tween = g.create_tween().set_parallel(true).set_speed_scale(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if g.playing_enemy_events else 1.0))
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
	if preview_active: end_preview(); return
	if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
	if g.cinematic: g.pivot = return_pivot
	g.cinematic = false
	g._update_camera()
