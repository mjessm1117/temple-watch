extends RefCounted
## Battle gestures. Mouse emulation remains enabled for normal UI controls.
const THRESHOLD := 12.0
const CameraRules = preload("res://scripts/battle11_camera.gd")
var g
var fingers: Dictionary = {}
var start := Vector2.ZERO
var moved := false
var pinching := false
var pinch_distance := 0.0
var twist_angle := 0.0
var twist_accum := 0.0
var board_start := false
var pressed_control: BaseButton
var start_on_scroll := false
const TWIST_DEAD_ZONE := 0.35

static func is_tap(distance: float) -> bool:
	return distance <= THRESHOLD

static func should_click(from: Vector2, to: Vector2, was_dragged: bool, was_pinched: bool) -> bool:
	return not was_dragged and not was_pinched and is_tap(from.distance_to(to))

static func pinched_zoom(current: float, before: float, after: float) -> float:
	return CameraRules.clamp_zoom(current * before / after) if before > 1.0 and after > 1.0 else current

static func snap_twist(yaw: float, accumulated: float) -> float:
	if absf(accumulated) < TWIST_DEAD_ZONE: return yaw
	return yaw + signf(accumulated) * PI * 0.5

func handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			if fingers.size() == 1:
				start = event.position; moved = false; pinching = false
				pressed_control = _button_at(g.overlay, event.position)
				start_on_scroll = _in_scroll(pressed_control)
				board_start = not start_on_scroll and (pressed_control != null or g._screen_tile(event.position).x >= 0)
				# The board input owner must not see the emulated press.
				g.set_process_unhandled_input(false)
			elif fingers.size() == 2:
				pinching = true; moved = true
				pinch_distance = _distance()
				twist_angle = _angle(); twist_accum = 0.0
		else:
			var tap := fingers.size() == 1 and should_click(start, event.position, moved, pinching)
			fingers.erase(event.index)
			if fingers.is_empty():
				if moved and pressed_control != null and not start_on_scroll:
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
				if tap and pressed_control == null and g.get_viewport().gui_get_hovered_control() == null and g._screen_tile(event.position).x >= 0:
					var click := InputEventMouseButton.new()
					click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = event.position
					g.input_controls.handle_event(click)
				g.set_process_unhandled_input.call_deferred(true)
				pinching = false
				pressed_control = null
			else:
				pinch_distance = 0.0
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var previous: Vector2 = fingers[event.index]
		fingers[event.index] = event.position
		if fingers.size() == 2:
			var next_distance := _distance()
			var next_angle := _angle()
			twist_accum += wrapf(next_angle - twist_angle, -PI, PI)
			twist_angle = next_angle
			if absf(twist_accum) >= TWIST_DEAD_ZONE:
				g.yaw = snap_twist(g.yaw, twist_accum)
				twist_accum = 0.0
			if pinch_distance > 0.0:
				g.zoom = pinched_zoom(g.zoom, pinch_distance, next_distance)
				g._update_camera()
			pinch_distance = next_distance
		elif not pinching:
			if not moved and start.distance_to(event.position) > THRESHOLD:
				moved = true
				if pressed_control != null and not start_on_scroll: pressed_control.notification(Control.NOTIFICATION_SCROLL_BEGIN)
			if moved and board_start:
				var right: Vector3 = g.camera.global_basis.x
				var forward: Vector3 = -g.camera.global_basis.z
				forward.y = 0.0; forward = forward.normalized()
				g.pivot += (-right * (event.position.x - previous.x) + forward * (event.position.y - previous.y)) * g.zoom * 0.0015
				g._update_camera()

func _button_at(node: Node, point: Vector2) -> BaseButton:
	if node == null or not node.is_inside_tree(): return null
	var children := node.get_children()
	for i in range(children.size() - 1, -1, -1):
		var hit := _button_at(children[i], point)
		if hit != null: return hit
	if node is BaseButton and node.is_visible_in_tree() and not node.disabled and node.get_global_rect().has_point(point): return node
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

func _empty_board(position: Vector2) -> bool:
	var tile: Vector2i = g._screen_tile(position)
	if tile.x < 0: return false
	for side in ["player", "enemy"]:
		for unit in g.mission.living(side):
			if Vector2i(int(unit.x), int(unit.y)) == tile: return false
	return true
