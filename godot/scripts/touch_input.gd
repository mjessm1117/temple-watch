extends RefCounted
## Battle gestures. Mouse emulation remains enabled for normal UI controls.
const THRESHOLD := 18.0 # Viewport positions are logical pixels on high-density phones.
const CameraRules = preload("res://scripts/battle11_camera.gd")
var g
var fingers: Dictionary = {}
var start := Vector2.ZERO
var moved := false
var pinching := false
var pinch_distance := 0.0
var pinch_target := 0.0
var twist_angle := 0.0
var board_start := false
var pressed_control: Control
var start_on_scroll := false
var gesture := ""
var pair_start_distance := 0.0
var pair_start_angle := 0.0
var pair_start_center := Vector2.ZERO
var pair_center := Vector2.ZERO
var cam_sensitivity := 1.0
var invert_rotate := false
var invert_pan := false

static func is_tap(distance: float) -> bool:
	return distance <= THRESHOLD

static func should_click(from: Vector2, to: Vector2, was_dragged: bool, was_pinched: bool) -> bool:
	return not was_dragged and not was_pinched and is_tap(from.distance_to(to))

static func pinched_zoom(current: float, before: float, after: float) -> float:
	return CameraRules.clamp_zoom(current * before / after) if before > 1.0 and after > 1.0 else current

static func snap_twist(yaw: float, accumulated: float) -> float:
	# Legacy helper kept for the W1 compatibility assertion; gestures use rotate_delta24.
	if absf(accumulated) < 0.35: return yaw
	return yaw + signf(accumulated) * PI * 0.5

static func rotate_delta24(yaw: float, delta: float) -> float:
	return yaw + clampf(delta, -0.25, 0.25)

func _settings() -> void:
	cam_sensitivity = 1.0; invert_rotate = false; invert_pan = false
	var cfg := ConfigFile.new()
	if cfg.load("user://controls24.cfg") != OK: return
	cam_sensitivity = clampf(float(cfg.get_value("controls", "cam_sensitivity", 1.0)), 0.5, 2.0)
	invert_rotate = bool(cfg.get_value("controls", "invert_rotate", false))
	invert_pan = bool(cfg.get_value("controls", "invert_pan", false))

func _cancel_glide() -> void:
	if g.has_method("cancel_camera_glide24"):
		g.cancel_camera_glide24()
	elif g.camera_tween != null and g.camera_tween.is_running():
		g.camera_tween.kill()

func _pan(delta: Vector2) -> void:
	var right: Vector3 = g.camera.global_basis.x
	var forward: Vector3 = -g.camera.global_basis.z
	forward.y = 0.0; forward = forward.normalized()
	var direction := -1.0 if invert_pan else 1.0
	g.pivot += (-right * delta.x + forward * delta.y) * g.zoom * 0.0015 * cam_sensitivity * direction
	g._update_camera()

func handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			if fingers.size() == 1:
				_settings()
				start = event.position; moved = false; pinching = false
				gesture = ""
				pressed_control = _control_at(g.get_viewport(), event.position)
				start_on_scroll = _in_scroll(pressed_control)
				board_start = pressed_control == null and g._screen_tile(event.position).x >= 0
				# The board input owner must not see the emulated press.
				g.set_process_unhandled_input(false)
			elif fingers.size() == 2:
				pinching = true; moved = true
				gesture = ""; pinch_distance = _distance()
				pair_start_distance = pinch_distance
				pinch_target = g.zoom
				twist_angle = _angle(); pair_start_angle = twist_angle
				pair_center = _center(); pair_start_center = pair_center
		else:
			var tap := fingers.size() == 1 and should_click(start, event.position, moved, pinching)
			fingers.erase(event.index)
			if fingers.is_empty():
				if moved and pressed_control is BaseButton and not start_on_scroll:
					pressed_control.notification(Control.NOTIFICATION_SCROLL_END)
				if tap and g.cam.beat_tween != null and g.cam.beat_tween.is_running():
					g.cam.skip()
					g.set_process_unhandled_input.call_deferred(true)
					pinching = false
					return
				if tap and g.cam.preview_active and g.cam.preview_tween != null and g.cam.preview_tween.is_running():
					g.cam.skip_preview_transition()
					g.set_process_unhandled_input.call_deferred(true)
					pinching = false
					return
				if tap and not (pressed_control is BaseButton) and g.get_viewport().gui_get_hovered_control() == null and g._screen_tile(event.position).x >= 0:
					var click := InputEventMouseButton.new()
					click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = event.position
					g.input_controls.handle_event(click)
				g.set_process_unhandled_input.call_deferred(true)
				pinching = false
				pressed_control = null
				gesture = ""
			else:
				pinch_distance = 0.0
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var previous: Vector2 = fingers[event.index]
		fingers[event.index] = event.position
		if fingers.size() == 2:
			var next_distance := _distance()
			var next_angle := _angle()
			var next_center := _center()
			if gesture == "" and pressed_control == null and _control_at(g.get_viewport(), fingers.values()[0]) == null and _control_at(g.get_viewport(), fingers.values()[1]) == null:
				var spread := absf(next_distance - pair_start_distance)
				var rotation := absf(wrapf(next_angle - pair_start_angle, -PI, PI))
				var travel := next_center.distance_to(pair_start_center)
				if rotation >= 0.1 or spread >= 12.0 or travel >= 12.0:
					gesture = "rotate" if rotation / 0.1 >= maxf(spread / 12.0, travel / 12.0) else "pinch" if spread >= travel else "pan"
					_cancel_glide()
			if gesture == "rotate":
				var delta := wrapf(next_angle - twist_angle, -PI, PI) * cam_sensitivity * (-1.0 if invert_rotate else 1.0)
				g.yaw = rotate_delta24(g.yaw, delta)
				g._update_camera()
			elif gesture == "pinch" and pinch_distance > 0.0:
				pinch_target = pinched_zoom(pinch_target, pinch_distance, lerpf(pinch_distance, next_distance, cam_sensitivity))
				if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
				g.camera_tween = g.create_tween()
				g.camera_tween.tween_property(g, "zoom", pinch_target, 0.12 / cam_sensitivity).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			elif gesture == "pan":
				_pan(next_center - pair_center)
			twist_angle = next_angle
			pinch_distance = next_distance
			pair_center = next_center
		elif not pinching:
			if not moved and start.distance_to(event.position) > THRESHOLD:
				moved = true
				if board_start: _cancel_glide()
				if pressed_control is BaseButton and not start_on_scroll: pressed_control.notification(Control.NOTIFICATION_SCROLL_BEGIN)
			if moved and board_start:
				_pan(event.position - previous)

func _control_at(node: Node, point: Vector2) -> Control:
	if node == null or not node.is_inside_tree(): return null
	var children := node.get_children()
	for i in range(children.size() - 1, -1, -1):
		var hit := _control_at(children[i], point)
		if hit != null: return hit
	if node is Control and node != g.overlay and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE and node.get_global_rect().has_point(point):
		return node
	return null

func _in_scroll(control: Control) -> bool:
	var ancestor := control
	while ancestor != null:
		if ancestor is ScrollContainer: return true
		ancestor = ancestor.get_parent() as Control
	return false

func _distance() -> float:
	var positions := fingers.values()
	return positions[0].distance_to(positions[1])

func _angle() -> float:
	var positions := fingers.values()
	return (positions[1] - positions[0]).angle()

func _center() -> Vector2:
	var positions := fingers.values()
	return (positions[0] + positions[1]) * 0.5

func _empty_board(position: Vector2) -> bool:
	var tile: Vector2i = g._screen_tile(position)
	if tile.x < 0: return false
	for side in ["player", "enemy"]:
		for unit in g.mission.living(side):
			if Vector2i(int(unit.x), int(unit.y)) == tile: return false
	return true
