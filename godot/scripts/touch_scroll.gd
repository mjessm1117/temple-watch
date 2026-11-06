extends ScrollContainer
var touch_origin := Vector2.ZERO
var scroll_origin := Vector2.ZERO
var touch_dragging := false

# Let the container recognize a finger drag through cards and buttons.
# A stationary tap still reaches the original control.
func _ready() -> void:
	scroll_deadzone = 10
	_watch(self)

func _gui_input(event: InputEvent) -> void:
	# Godot's native touch scroll path is disabled by the headless display driver.
	# This also covers web devices that report touch events but no touchscreen.
	if DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_origin = event.position
			scroll_origin = Vector2(scroll_horizontal, scroll_vertical)
			touch_dragging = false
		elif touch_dragging:
			touch_dragging = false
			propagate_notification(NOTIFICATION_SCROLL_END)
	elif event is InputEventScreenDrag:
		var displacement: Vector2 = event.position - touch_origin
		if not touch_dragging and displacement.length() > scroll_deadzone:
			# Like Godot's own touch scroll: children cancel their pending press.
			touch_dragging = true
			propagate_notification(NOTIFICATION_SCROLL_BEGIN)
		if touch_dragging:
			if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
				scroll_horizontal = maxi(0, int(scroll_origin.x - displacement.x))
			if vertical_scroll_mode != SCROLL_MODE_DISABLED:
				scroll_vertical = maxi(0, int(scroll_origin.y - displacement.y))

func _watch(node: Node) -> void:
	if node is ScrollBar:
		return
	if node != self and node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	if not node.child_entered_tree.is_connected(_watch):
		node.child_entered_tree.connect(_watch)
	for child in node.get_children():
		_watch(child)
