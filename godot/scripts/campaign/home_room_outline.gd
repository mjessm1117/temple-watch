extends Control
## Gold dashed rim distinguishes rooms awaiting construction or excavation.

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var ink := Color("d3ad75")
	var edges := [Vector2(2, 2), Vector2(size.x - 2, 2), Vector2(size.x - 2, size.y - 2), Vector2(2, size.y - 2)]
	for side in 4:
		var a: Vector2 = edges[side]
		var b: Vector2 = edges[(side + 1) % 4]
		var length := a.distance_to(b)
		var cursor := 0.0
		while cursor < length:
			draw_line(a.lerp(b, cursor / length), a.lerp(b, minf(cursor + 5.0, length) / length), ink, 1.0)
			cursor += 9.0
