extends Control
## Screen-space aim guide. It follows the camera and does not change combat odds.
var game
var target_point := Vector2.ZERO
var source_point := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(_delta: float) -> void:
	if not visible or game == null or game.camera == null: return
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var target: Dictionary = game.mission.unit_by_id(game.target_id)
	if actor.is_empty() or target.is_empty(): return
	var a: Node3D = game.views.get(int(actor.id))
	var t: Node3D = game.views.get(int(target.id))
	if a == null or t == null: return
	source_point = game.camera.unproject_position(a.global_position + Vector3.UP * 1.18)
	target_point = game.camera.unproject_position(t.global_position + Vector3.UP * 1.22)
	queue_redraw()

func _draw() -> void:
	if source_point == target_point: return
	var direction := (target_point - source_point).normalized()
	var start := source_point + direction * 18.0
	var stop := target_point - direction * 21.0
	var cyan := Color("7ee7ed9c")
	draw_line(start, stop, Color("112c35b0"), 4.0, true)
	draw_line(start, stop, cyan, 2.5, true)
	var gold := Color("f7d78e")
	for angle in [0.15, 1.72, 3.3, 4.87]:
		draw_arc(target_point, 20.0, angle, angle + 0.78, 10, Color("10242c"), 5.0, true)
		draw_arc(target_point, 20.0, angle, angle + 0.78, 10, gold, 2.7, true)
	draw_circle(target_point, 3.5, Color("10242c"))
	draw_circle(target_point, 2.0, gold)
