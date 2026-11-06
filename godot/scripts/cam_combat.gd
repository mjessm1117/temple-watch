extends Node
## One camera owner; completion (or an explicit skip) gates attack resolution.
const Shot = preload("res://scripts/shot.gd")
const BLEND := 0.42
const AIM_BLEND := 0.28
const TACTICAL_V_OFFSET := -0.5
var g
var skip_requested := false
var return_pivot := Vector3.ZERO
var trace: Array[String] = []
var touch = preload("res://scripts/touch_input.gd").new()
var preview_active := false
var preview_actor := -1
var preview_target := -1
var preview_tween: Tween
var beat_tween: Tween
var preview_hidden: Array[Node3D] = []
var preview_fov := 45.0
var preview_shoulder: Node3D
var preview_source_model: Node3D
var close_pitch := deg_to_rad(53.0)
var overhead := false

func _ready() -> void:
	touch.g = g

func _process(_delta: float) -> void:
	if g == null or g.camera == null or g.cinematic or preview_active: return
	if g.zoom < 26.0:
		if overhead:
			overhead = false
			g.pitch = close_pitch
			g._update_camera()
		else:
			close_pitch = g.pitch
		return
	if not overhead:
		overhead = true
		close_pitch = g.pitch
	var pitch: float = lerpf(close_pitch, deg_to_rad(78.0), smoothstep(26.0, 42.0, g.zoom))
	if absf(g.pitch - pitch) > 0.002:
		g.pitch = pitch
		g._update_camera()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
		g.set_process_unhandled_input(false)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch.handle(event)

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
	_clear_preview_visuals()
	if not preview_active: return_pivot = g.pivot
	if not preview_active: preview_fov = g.camera.fov
	preview_active = true
	g.camera.v_offset = 0.0
	preview_actor = actor_id
	preview_target = target_id
	var actor_view = g.views.get(actor_id)
	if actor_view != null: actor_view.set_aim_ready(true, Vector3(float(target.x), 0.0, float(target.y)))
	var phone: bool = g.hud_controls != null and g.hud_controls.phone != null
	if phone and actor_view != null:
		preview_source_model = actor_view.model
		preview_shoulder = preview_source_model.duplicate()
		preview_shoulder.name = "AimShoulder"
		g.camera.add_child(preview_shoulder)
		preview_shoulder.position = Vector3(-1.65, -0.94, -2.9)
		preview_shoulder.rotation = Vector3(-0.16, PI, 0.0)
		preview_shoulder.scale *= 0.96
		var pose: AnimationPlayer = actor_view._find_animation(preview_shoulder)
		var clip := "swing" if actor_view.base_clip == "saberIdle" else "shoot"
		if pose != null and pose.has_animation(clip):
			pose.play(clip)
			pose.seek(pose.get_animation(clip).length * 0.28, true)
			pose.pause()
		preview_source_model.hide()
	for ally in g.mission.living("player"):
		if int(ally.id) == actor_id: continue
		var view: Node3D = g.views.get(int(ally.id))
		if view != null and view.visible:
			view.hide()
			preview_hidden.append(view)
	if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
	if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
	var origin := Vector3(float(actor.x), Shot.elevation(g.mission, Shot.pos(actor)) * 0.7, float(actor.y))
	var destination := Vector3(float(target.x), Shot.elevation(g.mission, Shot.pos(target)) * 0.7, float(target.y))
	var direction := destination - origin
	direction.y = 0.0
	if direction.length_squared() < 0.01: direction = Vector3.FORWARD
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0.0, direction.x)
	var shoulder := origin - direction * 0.7 + side * 4.5 + Vector3.UP * (2.2 if phone else 2.55)
	shoulder = preload("res://scripts/battle11_camera.gd").aim_position(g.mission, shoulder)
	var look := origin.lerp(destination, 0.8) + Vector3.UP * (1.4 if phone else 1.25)
	g.cinematic = true
	preview_tween = g.create_tween().set_parallel(true)
	preview_tween.tween_property(g.camera, "position", shoulder, AIM_BLEND).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	preview_tween.tween_property(g.camera, "fov", 74.0 if phone else 52.0, AIM_BLEND)
	var initial_look: Vector3 = g.camera.position - g.camera.global_basis.z * 8.0
	preview_tween.tween_method(func(value: Vector3) -> void: g.camera.look_at(value, Vector3.UP), initial_look, look, AIM_BLEND)

func skip_preview_transition() -> void:
	if not preview_active or preview_tween == null or not preview_tween.is_running(): return
	preview_tween.custom_step(AIM_BLEND)

func end_preview() -> void:
	if not preview_active: return
	_clear_preview_visuals()
	if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
	preview_active = false
	preview_actor = -1
	preview_target = -1
	g.pivot = return_pivot
	g.cinematic = false
	g.camera.fov = preview_fov
	g.camera.v_offset = TACTICAL_V_OFFSET
	g._update_camera()

func _clear_preview_visuals() -> void:
	if preview_shoulder != null:
		preview_shoulder.hide()
		preview_shoulder.queue_free()
		preview_shoulder = null
	if preview_source_model != null:
		preview_source_model.show()
		preview_source_model = null
	var actor_view = g.views.get(preview_actor)
	if actor_view != null: actor_view.set_aim_ready(false, Vector3.ZERO)
	for view in preview_hidden:
		if is_instance_valid(view): view.show()
	preview_hidden.clear()

func impact_beat(point: Vector3) -> void:
	if skip_requested or not g.action_camera: return
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	var original_fov: float = g.camera.fov
	beat_tween = g.create_tween()
	beat_tween.tween_property(g.camera, "fov", maxf(42.0, original_fov - 5.0), 0.11)
	beat_tween.tween_interval(0.12)
	beat_tween.tween_property(g.camera, "fov", original_fov, 0.14)
	await wait(0.38)
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	g.camera.fov = original_fov

func frame(from: Vector3, to: Vector3, style: String = "shoot") -> void:
	_clear_preview_visuals()
	if preview_active: g.camera.fov = preview_fov
	if not g.action_camera or skip_requested: return
	g.camera.v_offset = 0.0
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
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	finish()

func finish() -> void:
	if preview_active: end_preview(); return
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
	if g.cinematic: g.pivot = return_pivot
	g.cinematic = false
	g.camera.v_offset = TACTICAL_V_OFFSET
	g._update_camera()
