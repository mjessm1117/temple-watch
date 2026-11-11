extends Node
## A horizontal gesture changes the aim target exactly once; release never confirms fire.
var game: Node
var panel: Control
var target_row: Control
var finger := -1
var start := Vector2.ZERO
var cycled := false

func _input(event: InputEvent) -> void:
	if not is_instance_valid(panel) or not panel.visible: return
	if event is InputEventScreenTouch:
		if event.pressed and finger < 0 and (panel.get_global_rect().has_point(event.position) or (is_instance_valid(target_row) and target_row.get_global_rect().has_point(event.position))):
			finger = event.index; start = event.position; cycled = false
		elif not event.pressed and event.index == finger:
			if cycled: get_viewport().set_input_as_handled()
			finger = -1
	elif event is InputEventScreenDrag and event.index == finger and not cycled:
		var delta: Vector2 = event.position - start
		if absf(delta.x) >= 34.0 and absf(delta.x) > absf(delta.y) * 1.3:
			cycled = true
			if is_instance_valid(game) and game.has_method("_cycle_target"):
				game._cycle_target(1 if delta.x < 0 else -1)
			get_viewport().set_input_as_handled()
