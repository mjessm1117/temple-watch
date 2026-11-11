extends Node
## Capture busy input before Game._unhandled_input can skip an action animation.
var game: Node

func _ready() -> void:
	if is_instance_valid(game) and game.input_controls != null:
		game.input_controls.connect_busy24()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game) or not game.has_method("is_input_busy24") or not game.is_input_busy24(): return
	var controls = game.input_controls
	if controls == null: return
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		controls._queue_selection24(controls.next_squad(game.mission, game.selected_id, -1 if event.shift_pressed else 1))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var unit: Dictionary = controls.selection_at24(game, event.position)
		if not unit.is_empty(): controls._queue_selection24(int(unit.id))
	elif event is InputEventScreenTouch and event.pressed:
		var unit: Dictionary = controls.selection_at24(game, event.position)
		if not unit.is_empty(): controls._queue_selection24(int(unit.id))
	get_viewport().set_input_as_handled()
