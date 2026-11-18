extends RefCounted
## Holds the completed action in view before automatic squad selection.
const InputControls = preload("res://scripts/input_controls.gd")
const HOLD_SECONDS := 0.60
const PAN_SECONDS := 0.35

static func after_action(g: Node3D) -> void:
	g.preview_tile = Vector2i(-1, -1)
	g.target_id = -1
	g.action = "move"
	g.end_turn_armed = false
	g.warning_label.text = ""
	var current: Dictionary = g.mission.unit_by_id(g.selected_id)
	if not RescueSettings.battle_value("auto_select") or current.is_empty(): return
	var next_id: int = InputControls.next_squad(g.mission, g.selected_id, 1, true)
	if next_id < 0 or next_id == g.selected_id: return
	if bool(g.get("demo_mode")): g._select.call_deferred(next_id); return
	var serial: int = int(g.get_meta("w36turn_handoff_serial", 0)) + 1
	g.set_meta("w36turn_handoff_serial", serial)
	handoff(g, next_id, serial)

static func handoff(g: Node3D, next_id: int, serial: int) -> void:
	var actor_id: int = g.selected_id
	var drag_serial: int = g.camera_drag_serial24
	# The completed move first glides to its destination. Start the hold there.
	while is_instance_valid(g) and g.is_inside_tree() and g.camera_tween != null and g.camera_tween.is_running():
		await g.get_tree().process_frame
		if not _still_current(g, actor_id, drag_serial, serial): return
	if not _still_current(g, actor_id, drag_serial, serial): return
	g.cam.trace.append("handoff_hold_start_%d" % actor_id)
	var start_ms := Time.get_ticks_msec()
	g.set_meta("w36turn_hold_started_ms", start_ms)
	while is_instance_valid(g) and g.is_inside_tree() and Time.get_ticks_msec() - start_ms < int(HOLD_SECONDS * 1000.0):
		await g.get_tree().process_frame
		if not _still_current(g, actor_id, drag_serial, serial):
			if is_instance_valid(g): g.cam.trace.append("handoff_cancel_%d" % actor_id)
			return
	if not _still_current(g, actor_id, drag_serial, serial): return
	g.cam.trace.append("handoff_pan_%d_to_%d" % [actor_id, next_id])
	g.set_meta("w36turn_pan_started_ms", Time.get_ticks_msec())
	g._select(next_id)

static func _still_current(g: Variant, actor_id: int, drag_serial: int, serial: int) -> bool:
	return is_instance_valid(g) and g.is_inside_tree() and g.selected_id == actor_id and g.camera_drag_serial24 == drag_serial and int(g.get_meta("w36turn_handoff_serial", 0)) == serial and not g.playing_enemy_events
