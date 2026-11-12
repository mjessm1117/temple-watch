extends Node
## One camera owner; completion (or an explicit skip) gates attack resolution.
const Shot = preload("res://scripts/shot.gd")
const BLEND := 0.16
const REPEAT_BLEND := 0.08
const PLAYER_SHOT_BLEND := 0.36
const AIM_BLEND := 0.28
const RETURN_BLEND24 := 0.28
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
var return_tween24: Tween
var safe_rect24 := Rect2()
var frame_drag_serial24 := 0
var return_fov24 := 45.0
var preview_hidden: Array[Node3D] = []
var preview_fov := 45.0
var preview_shoulder: Node3D
var preview_source_model: Node3D
var close_pitch := deg_to_rad(53.0)
var overhead := false
var last_frame_at := -10.0
var framed_move_actor28 := -1
var framed_move_position28 := Vector2i(-1, -1)

func _ready() -> void:
	touch.g = g

func set_battle_safe_rect24(rect: Rect2) -> void:
	safe_rect24 = rect

func cancel_return24(manual: bool = false) -> void:
	if return_tween24 != null and return_tween24.is_running():
		return_tween24.kill()
		g.cinematic = false
		g.camera.fov = return_fov24
		g.camera.v_offset = TACTICAL_V_OFFSET
		g._update_camera()
	if manual:
		if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
		if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
		if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
		g.cinematic = false
		g.camera.fov = return_fov24
		g.camera.v_offset = TACTICAL_V_OFFSET

func await_return24() -> void:
	while return_tween24 != null and return_tween24.is_running() and is_instance_valid(g) and g.is_inside_tree():
		await g.get_tree().process_frame

func _process(_delta: float) -> void:
	if g == null or g.camera == null or g.cinematic or preview_active: return
	if preload("res://scripts/phone_layout.gd").narrow(Vector2i(g.get_viewport().get_visible_rect().size)):
		var actor: Dictionary = g.mission.unit_by_id(g.selected_id) if g.mission != null else {}
		if not actor.is_empty() and g.action == "move":
			var location := Vector2i(int(actor.x), int(actor.y))
			if framed_move_actor28 != g.selected_id or framed_move_position28 != location:
				framed_move_actor28 = g.selected_id; framed_move_position28 = location
				frame_selected_move28.call_deferred()
	if g.playing_enemy_events and not skip_requested and g.quiet_motions.is_empty():
		for enemy in g.mission.living("enemy"):
			var view = g.views.get(int(enemy.id))
			if view == null or view.motion == null or not view.motion.is_running(): continue
			if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
			g.pivot = g.pivot.lerp(Vector3(view.position.x, 0.0, view.position.z), minf(1.0, _delta * 7.0))
			g._update_camera()
			break
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

func move_preview_state28() -> Dictionary:
	var tile: Vector2i = g.preview_tile if g != null else Vector2i(-1, -1)
	var cost := 0
	if g != null and tile.x >= 0 and g.action == "move":
		var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
		cost = int(preload("res://scripts/input_controls.gd").move_preview(g.mission, actor, tile).get("ap", 0))
	return {"tile": tile, "cost": cost, "confirmed": false}

func _map_rect28() -> Rect2:
	var size: Vector2 = g.get_viewport().get_visible_rect().size
	if g.has_method("hud_safe_rect28"):
		var supplied: Variant = g.call("hud_safe_rect28")
		if supplied is Rect2 and supplied.has_area(): return supplied
	if g.get("hud_controls") != null and g.hud_controls.phone != null and g.hud_controls.phone.has_method("hud_safe_rect28"):
		var supplied: Variant = g.hud_controls.phone.call("hud_safe_rect28")
		if supplied is Rect2 and supplied.has_area(): return supplied
	return Rect2(Vector2(0, size.y * 0.12), Vector2(size.x, size.y * 0.63))

func _ground_at28(screen: Vector2) -> Vector3:
	var origin: Vector3 = g.camera.project_ray_origin(screen)
	var direction: Vector3 = g.camera.project_ray_normal(screen)
	return origin + direction * (-origin.y / direction.y) if absf(direction.y) > 0.001 else g.pivot

func frame_selected_safe29() -> void:
	if g != null and is_instance_valid(g) and g.camera != null:
		preload("res://scripts/w29a_phone_frame.gd").frame(g, _map_rect28())

func frame_selected_move28() -> void:
	if g == null or not is_instance_valid(g) or g.camera == null or g.cinematic: return
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	if actor.is_empty(): return
	if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
	# Keep the soldier legible even when the entire dash reach cannot fit the HUD gap.
	var legible_zoom: float = preload("res://scripts/battle11_camera.gd").selected_zoom(g.mission)
	g.zoom = minf(g.zoom, legible_zoom)
	g._update_camera()
	var reach: Dictionary = g.mission.reach_tiles(actor, mini(2, int(actor.get("ap", 0))))
	var bounds := Rect2()
	var first := true
	for tile in reach.get("costs", {}):
		var point: Vector2 = g.camera.unproject_position(Vector3(tile.x, preload("res://scripts/shot.gd").elevation(g.mission, tile) * 0.7 + 0.3, tile.y))
		if first: bounds = Rect2(point, Vector2.ZERO); first = false
		else: bounds = bounds.expand(point)
	if first: return
	var safe := _map_rect28().grow(-18.0)
	var factor: float = maxf(bounds.size.x / maxf(1.0, safe.size.x), bounds.size.y / maxf(1.0, safe.size.y))
	if factor > 1.0:
		g.zoom = minf(legible_zoom, preload("res://scripts/battle11_camera.gd").clamp_zoom(g.zoom * minf(factor * 1.12, 2.2)))
		g._update_camera()
		bounds = Rect2(); first = true
		for tile in reach.get("costs", {}):
			var point: Vector2 = g.camera.unproject_position(Vector3(tile.x, preload("res://scripts/shot.gd").elevation(g.mission, tile) * 0.7 + 0.3, tile.y))
			if first: bounds = Rect2(point, Vector2.ZERO); first = false
			else: bounds = bounds.expand(point)
	var desired: Vector2 = safe.get_center()
	var actual: Vector2 = bounds.get_center()
	g.pivot += _ground_at28(actual) - _ground_at28(desired)
	g._update_camera()
	preload("res://scripts/w29a_phone_frame.gd").frame(g, _map_rect28())

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
	var shoulder := aim_shoulder(g.mission, origin, destination, phone, g.get_viewport().get_visible_rect().size, safe_rect24)
	var view_direction := destination - shoulder
	view_direction.y = 0.0
	var screen_right := view_direction.normalized().cross(Vector3.UP)
	var look := destination + screen_right * (0.75 if phone else 0.0) + Vector3.UP * 1.25
	look = safe_look24(shoulder, look, destination + Vector3.UP * 1.25, g.get_viewport().get_visible_rect().size, 58.0 if phone else 52.0, safe_rect24)
	g.cinematic = true
	preview_tween = g.create_tween().set_parallel(true)
	preview_tween.tween_property(g.camera, "position", shoulder, AIM_BLEND).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	preview_tween.tween_property(g.camera, "fov", 58.0 if phone else 52.0, AIM_BLEND)
	var initial_look: Vector3 = g.camera.position - g.camera.global_basis.z * 8.0
	preview_tween.tween_method(func(value: Vector3) -> void: g.camera.look_at(value, Vector3.UP), initial_look, look, AIM_BLEND)

static func aim_screen_point(eye: Vector3, look: Vector3, target: Vector3, viewport: Vector2, fov: float = 58.0) -> Vector2:
	var forward := (look - eye).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward).normalized()
	var delta := target - eye
	var depth := maxf(0.01, delta.dot(forward))
	var scale := tan(deg_to_rad(fov) * 0.5)
	var aspect := viewport.x / maxf(1.0, viewport.y)
	return Vector2(0.5 + delta.dot(right) / (2.0 * depth * scale * aspect), 0.5 - delta.dot(up) / (2.0 * depth * scale))

static func safe_look24(eye: Vector3, look: Vector3, target: Vector3, viewport: Vector2, fov: float, rect: Rect2) -> Vector3:
	if not rect.has_area(): return look
	var screen := aim_screen_point(eye, look, target, viewport, fov) * viewport
	if not rect.has_point(screen): return look
	var margin := 10.0
	var candidates := [Vector2(rect.position.x - margin, screen.y), Vector2(rect.end.x + margin, screen.y), Vector2(screen.x, rect.position.y - margin), Vector2(screen.x, rect.end.y + margin)]
	var best := screen
	var distance := INF
	for point in candidates:
		if point.x < margin or point.y < margin or point.x > viewport.x - margin or point.y > viewport.y - margin: continue
		if screen.distance_squared_to(point) < distance: best = point; distance = screen.distance_squared_to(point)
	if distance == INF: return look
	var forward := (look - eye).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward).normalized()
	var depth := maxf(0.01, (target - eye).dot(forward))
	var world_per_pixel := 2.0 * depth * tan(deg_to_rad(fov) * 0.5) / maxf(1.0, viewport.y)
	var shift: Vector2 = best - screen
	return look - right * shift.x * world_per_pixel + up * shift.y * world_per_pixel

static func aim_shoulder(m: RefCounted, origin: Vector3, destination: Vector3, phone: bool = false, viewport: Vector2 = Vector2(844, 390), safe_rect: Rect2 = Rect2()) -> Vector3:
	var forward := destination - origin
	forward.y = 0.0
	if forward.length_squared() < 0.01: forward = Vector3.FORWARD
	forward = forward.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	var target := destination + Vector3.UP * 1.25
	var best := Vector3.ZERO
	var best_score := -INF
	for retreat in [1.15, 1.8, 2.5, 3.5, 5.0]:
		for height in [1.55, 2.15, 2.9]:
			for lateral in [0.85, 1.6, 2.4]:
				for sign_side in [1.0, -1.0]:
					var eye: Vector3 = origin - forward * retreat + side * lateral * sign_side + Vector3.UP * height
					eye = preload("res://scripts/battle11_camera.gd").aim_position(m, eye)
					if not aim_ray_clear(m, eye, target): continue
					var direction := destination - eye; direction.y = 0.0
					var screen_right := direction.normalized().cross(Vector3.UP)
					var look := destination + screen_right * (0.75 if phone else 0.0) + Vector3.UP * 1.25
					look = safe_look24(eye, look, target, viewport, 58.0 if phone else 52.0, safe_rect)
					var screen := aim_screen_point(eye, look, target, viewport, 58.0 if phone else 52.0)
					var source_screen := aim_screen_point(eye, look, origin + Vector3.UP * 1.18, viewport, 58.0 if phone else 52.0)
					var separation := Vector2((screen.x - source_screen.x) * viewport.x, (screen.y - source_screen.y) * viewport.y).length()
					var score := -absf(screen.x - 0.53) * 8.0 - absf(screen.y - 0.43) * 8.0
					if safe_rect.has_area():
						if safe_rect.has_point(screen * viewport): score -= 40.0
						if safe_rect.has_point(source_screen * viewport): score -= 40.0
					if phone and (screen.x < 0.38 or screen.x > 0.70 or screen.y < 0.20 or screen.y > 0.63): score -= 20.0
					if separation < 40.0: score -= 10.0
					score += minf(separation, 100.0) * 0.06
					score += minf(eye.distance_to(target), 12.0) * 0.01
					if score > best_score: best_score = score; best = eye
	if best_score > -INF: return best
	for height in [3.4, 4.5, 6.0, 9.0, 12.0, 20.0]:
		var eye: Vector3 = preload("res://scripts/battle11_camera.gd").aim_position(m, origin - forward * 2.5 + Vector3.UP * height)
		if aim_ray_clear(m, eye, target): return eye
	return preload("res://scripts/battle11_camera.gd").aim_position(m, origin - forward * 2.5 + Vector3.UP * 30.0)

static func aim_ray_clear(m: RefCounted, eye: Vector3, target: Vector3) -> bool:
	# Map art has no physics colliders. Sample the same tile heights used to draw cover.
	var distance := eye.distance_to(target)
	var steps := maxi(1, ceili(distance * 5.0))
	for step in range(1, steps):
		var t := float(step) / float(steps)
		var point := eye.lerp(target, t)
		var tile := Vector2i(roundi(point.x), roundi(point.z))
		var kind: String = m.tile(tile)
		var floor_height: float = float(Shot.elevation(m, tile)) * 0.7
		var top := floor_height + (1.9 if kind == "#" else 0.8 if kind in ["c", "h", "k"] else 0.0)
		if point.y < top and kind in ["#", "c", "h", "k"]: return false
	return true

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
	var drag_serial: int = g.camera_drag_serial24
	var original_fov: float = g.camera.fov
	beat_tween = g.create_tween()
	beat_tween.tween_property(g.camera, "fov", maxf(42.0, original_fov - 5.0), 0.06)
	beat_tween.tween_interval(0.06)
	beat_tween.tween_property(g.camera, "fov", original_fov, 0.06)
	await wait(0.18)
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	if drag_serial == g.camera_drag_serial24: g.camera.fov = original_fov

func frame(from: Vector3, to: Vector3, style: String = "shoot") -> void:
	if return_tween24 != null and return_tween24.is_running(): return_tween24.kill()
	_clear_preview_visuals()
	if preview_active: g.camera.fov = preview_fov; return_fov24 = preview_fov
	if not g.action_camera or skip_requested: return
	g.camera.v_offset = 0.0
	if preview_tween != null and preview_tween.is_running(): preview_tween.kill()
	preview_active = false
	preview_actor = -1
	preview_target = -1
	if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
	if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
	if not g.cinematic: return_pivot = g.pivot
	if not g.cinematic: return_fov24 = g.camera.fov
	g.cinematic = true
	frame_drag_serial24 = g.camera_drag_serial24
	trace.append("camera_start")
	var direction := to - from; direction.y = 0
	if direction.length_squared() < 0.01: direction = Vector3.FORWARD
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0, direction.x)
	var shoulder := from - direction * 3.0 + side * 1.25 + Vector3.UP * 2.3
	var look := from.lerp(to, 0.65) + Vector3.UP
	if style == "objective":
		shoulder = from.lerp(to, 0.5) + side * maxf(4.0, from.distance_to(to) * 0.8) + Vector3.UP * 3.8
		look = from.lerp(to, 0.5) + Vector3.UP
	if style in ["push", "pull", "force", "reveal"]:
		shoulder = from.lerp(to, 0.4) + side * maxf(4.0, from.distance_to(to) * 0.8) + Vector3.UP * 3.4
		look = from.lerp(to, 0.5) + Vector3.UP
	if safe_rect24.has_area() and style in ["shoot", "strike"]:
		var viewport: Vector2 = g.get_viewport().get_visible_rect().size
		shoulder = aim_shoulder(g.mission, from, to, viewport.x < viewport.y, viewport, safe_rect24)
		look = to + Vector3.UP * 1.25
		look = safe_look24(shoulder, look, to + Vector3.UP * 1.25, viewport, 58.0 if viewport.x < viewport.y else 52.0, safe_rect24)
	shoulder = preload("res://scripts/battle11_camera.gd").safe_position(g.mission, shoulder)
	var initial_look: Vector3 = g.camera.position - g.camera.global_basis.z * 8.0
	g.action_tween = g.create_tween().set_parallel(true).set_speed_scale(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if g.playing_enemy_events else 1.0))
	var duration := REPEAT_BLEND if g.playing_enemy_events and Time.get_ticks_msec() / 1000.0 - last_frame_at < 1.0 else PLAYER_SHOT_BLEND if not g.playing_enemy_events and style in ["shoot", "strike"] else BLEND
	last_frame_at = Time.get_ticks_msec() / 1000.0
	g.action_tween.tween_property(g.camera, "position", shoulder, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	g.action_tween.tween_method(func(value: Vector3): g.camera.look_at(value, Vector3.UP), initial_look, look, duration)
	await wait(duration)
	if not skip_requested and frame_drag_serial24 == g.camera_drag_serial24:
		g.camera.position = shoulder; g.camera.look_at(look, Vector3.UP)
	trace.append("camera_ready")

func skip() -> void:
	skip_requested = true
	trace.append("camera_skipped")
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	finish()

func finish(target_pivot: Vector3 = Vector3.INF) -> void:
	if preview_active: end_preview(); return
	if beat_tween != null and beat_tween.is_running(): beat_tween.kill()
	if g.action_tween != null and g.action_tween.is_running(): g.action_tween.kill()
	if frame_drag_serial24 != g.camera_drag_serial24:
		g.cinematic = false
		return
	if not g.cinematic: return
	if return_tween24 != null and return_tween24.is_running(): return_tween24.kill()
	var start: Transform3D = g.camera.transform
	var start_fov: float = g.camera.fov
	var start_offset: float = g.camera.v_offset
	g.pivot = target_pivot if target_pivot.is_finite() else return_pivot
	g._update_camera()
	var goal: Transform3D = g.camera.transform
	var goal_fov: float = return_fov24
	g.camera.transform = start
	g.camera.fov = start_fov
	g.camera.v_offset = start_offset
	var duration := 0.0 if skip_requested else RETURN_BLEND24
	if duration <= 0.0:
		g.camera.transform = goal; g.camera.fov = goal_fov; g.camera.v_offset = TACTICAL_V_OFFSET; g.cinematic = false
		return
	return_tween24 = g.create_tween().set_parallel(true)
	return_tween24.tween_property(g.camera, "transform", goal, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return_tween24.tween_property(g.camera, "fov", goal_fov, duration)
	return_tween24.tween_property(g.camera, "v_offset", TACTICAL_V_OFFSET, duration)
	return_tween24.chain().tween_callback(func() -> void:
		g.cinematic = false
		g._update_camera()
		trace.append("camera_return24"))
