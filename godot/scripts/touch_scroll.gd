extends ScrollContainer
## Shared touch motion for all strategy menus.
const DEADZONE := 10.0
const EDGE_LIMIT := 28.0
const FRICTION := 7.5
const SPRING := 38.0
static var last_handled_drag := -1
var touch_origin := Vector2.ZERO
var last_touch := Vector2.ZERO
var touch_dragging := false
var finger_down := false
var velocity := Vector2.ZERO
var edge := Vector2.ZERO
var edge_velocity := Vector2.ZERO
var last_drag_time := 0
var touch_events := 0
var drag_events := 0
var last_event_id := -1
var mouse_down := false
var mouse_dragging := false
var mouse_origin := Vector2.ZERO
var mouse_last := Vector2.ZERO
var mouse_drag_events := 0
var last_scroll := Vector2.ZERO

func _ready() -> void:
	scroll_deadzone = int(DEADZONE)
	_watch(self)
	set_process(true)
	if OS.has_feature("web") and get_tree().root.get_node_or_null("W29bWebProbe") == null:
		if bool(JavaScriptBridge.eval("location.search.includes('w29b_probe=1')")) and ResourceLoader.exists("res://scripts/w29b_web_probe.gd"):
			var probe: Node = load("res://scripts/w29b_web_probe.gd").new()
			probe.name = "W29bWebProbe"
			get_tree().root.call_deferred("add_child", probe)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and get_global_rect().has_point(event.position):
		velocity = Vector2.ZERO
	if OS.has_feature("web") and event is InputEventScreenTouch and not event.pressed and finger_down:
		_gui_input(event)
	if not OS.has_feature("web") or not is_visible_in_tree(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_rect().has_point(event.position) and not _inner_at(event.position):
			mouse_down = true
			mouse_dragging = false
			mouse_origin = event.position
			mouse_last = event.position
			velocity = Vector2.ZERO
		elif not event.pressed and mouse_down:
			mouse_down = false
			if mouse_dragging:
				mouse_dragging = false
				propagate_notification(NOTIFICATION_SCROLL_END)
				get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and mouse_down and not touch_dragging:
		var delta_move: Vector2 = mouse_last - event.position
		if not mouse_dragging and is_drag((event.position - mouse_origin).length()):
			mouse_dragging = true
			propagate_notification(NOTIFICATION_SCROLL_BEGIN)
		if mouse_dragging and delta_move.length_squared() > 0.01:
			velocity = velocity.lerp(delta_move / 0.016, 0.65)
			_move(delta_move, true)
			mouse_drag_events += 1
			get_viewport().set_input_as_handled()
		mouse_last = event.position
		return

func _inner_at(point: Vector2) -> bool:
	for child in find_children("*", "ScrollContainer", true, false):
		var scroll := child as ScrollContainer
		if scroll != self and scroll.is_visible_in_tree() and scroll.get_global_rect().has_point(point):
			return true
	return false

static func decay(v: float, delta: float) -> float:
	return v * exp(-FRICTION * delta)

static func spring_step(offset: float, speed: float, delta: float) -> Vector2:
	var next_speed := (speed - offset * SPRING * delta) * exp(-9.0 * delta)
	var next_offset := offset + next_speed * delta
	if absf(next_offset) < 0.15 and absf(next_speed) < 0.5: return Vector2.ZERO
	return Vector2(next_offset, next_speed)

static func is_drag(distance: float) -> bool:
	return distance >= DEADZONE

static func handoff(delta: float, position: float, maximum: float) -> float:
	if delta < 0.0 and position <= 0.0: return delta
	if delta > 0.0 and position >= maximum: return delta
	return 0.0

func _limit(axis: int) -> float:
	var bar: ScrollBar = get_h_scroll_bar() if axis == 0 else get_v_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page)

func _enabled(axis: int) -> bool:
	return (horizontal_scroll_mode if axis == 0 else vertical_scroll_mode) != SCROLL_MODE_DISABLED

func _position(axis: int) -> float:
	return float(scroll_horizontal if axis == 0 else scroll_vertical)

func _set_scroll_axis(axis: int, value: float) -> void:
	if axis == 0: scroll_horizontal = roundi(value)
	else: scroll_vertical = roundi(value)

func _parent_scroll(axis: int) -> ScrollContainer:
	var node := get_parent()
	while node != null:
		if node is ScrollContainer and node != self and node.has_method("_can_move") and node._enabled(axis):
			return node
		node = node.get_parent()
	return null

func _can_move(axis: int, amount: float) -> bool:
	return _enabled(axis) and handoff(amount, _position(axis), _limit(axis)) == 0.0

func _move(amount: Vector2, soft_edge: bool) -> void:
	for axis in 2:
		if not _enabled(axis): continue
		var desired := _position(axis) + amount[axis]
		var bounded := clampf(desired, 0.0, _limit(axis))
		_set_scroll_axis(axis, bounded)
		var excess := desired - bounded
		if absf(excess) > 0.01:
			var parent_scroll := _parent_scroll(axis)
			if parent_scroll != null and parent_scroll._can_move(axis, excess):
				parent_scroll._move(Vector2(excess, 0) if axis == 0 else Vector2(0, excess), soft_edge)
			elif soft_edge:
				edge[axis] = clampf(edge[axis] - excess * 0.35, -EDGE_LIMIT, EDGE_LIMIT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if last_event_id == event.get_instance_id(): return
		last_event_id = event.get_instance_id()
	if event is InputEventScreenTouch:
		touch_events += 1
		if event.pressed:
			finger_down = true
			touch_origin = event.position
			last_touch = event.position
			touch_dragging = false
			velocity = Vector2.ZERO
			edge_velocity = Vector2.ZERO
			last_drag_time = 0
		else:
			finger_down = false
			if DisplayServer.get_name() == "headless": velocity = Vector2.ZERO
			if touch_dragging:
				touch_dragging = false
				propagate_notification(NOTIFICATION_SCROLL_END)
	elif event is InputEventScreenDrag and finger_down:
		drag_events += 1
		if (last_touch - event.position).length_squared() < 0.01: return
		# GUI input bubbles through nested containers. The inner owner handles it
		# once and passes only its unused distance to the parent.
		if last_handled_drag == event.get_instance_id(): return
		last_handled_drag = event.get_instance_id()
		if not touch_dragging and is_drag((event.position - touch_origin).length()):
			touch_dragging = true
			propagate_notification(NOTIFICATION_SCROLL_BEGIN)
		if touch_dragging:
			var movement: Vector2 = last_touch - event.position
			var now := Time.get_ticks_msec()
			var dt := clampf(float(now - last_drag_time) / 1000.0, 0.008, 0.05) if last_drag_time > 0 else 0.016
			velocity = velocity.lerp(movement / dt, 0.65)
			_move(movement, true)
			last_drag_time = now
		last_touch = event.position

func _process(delta: float) -> void:
	var current := Vector2(scroll_horizontal, scroll_vertical)
	if not finger_down and not mouse_down and current.distance_squared_to(last_scroll) > 400.0:
		velocity = Vector2.ZERO
	if not finger_down and not mouse_down and velocity.length_squared() > 1.0:
		_move(velocity * minf(delta, 0.05), true)
		velocity = Vector2(decay(velocity.x, delta), decay(velocity.y, delta))
		if velocity.length() < 8.0: velocity = Vector2.ZERO
	if not finger_down and not mouse_down:
		for axis in 2:
			var next := spring_step(edge[axis], edge_velocity[axis], minf(delta, 0.05))
			edge[axis] = next.x
			edge_velocity[axis] = next.y
	var content := _content()
	if content != null and edge.length_squared() > 0.01:
		content.position = Vector2(-scroll_horizontal, -scroll_vertical) + edge
	last_scroll = Vector2(scroll_horizontal, scroll_vertical)

func _content() -> Control:
	for child in get_children():
		if child is Control and not child is ScrollBar: return child
	return null

func _watch(node: Node) -> void:
	if node is ScrollBar: return
	if node != self and node is ScrollContainer: return
	if node != self and node is Control:
		if node.mouse_filter == Control.MOUSE_FILTER_STOP:
			node.mouse_filter = Control.MOUSE_FILTER_PASS
		if not node.gui_input.is_connected(_gui_input):
			node.gui_input.connect(_gui_input)
	if not node.child_entered_tree.is_connected(_watch): node.child_entered_tree.connect(_watch)
	for child in node.get_children(): _watch(child)
