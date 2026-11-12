extends Control
## Three camera chips share one canvas item; the transparent buttons own input.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color("101b26f5"); chip.set_corner_radius_all(9)
	draw_style_box(chip, Rect2(0, 0, 44, 148))
	for index in 3:
		var center := Vector2(22, 22 + index * 52)
		var color := Color("f2d99a")
		if index == 1:
			draw_arc(center, 9, 0, TAU, 24, color, 2)
			draw_line(center + Vector2(-15, 0), center + Vector2(-5, 0), color, 2)
			draw_line(center + Vector2(5, 0), center + Vector2(15, 0), color, 2)
		else:
			draw_arc(center, 11, -PI * 0.65 if index == 0 else -PI * 0.35, PI * 0.65 if index == 0 else PI * 1.35, 18, color, 2)
			var tip := center + (Vector2(-11, 0) if index == 0 else Vector2(11, 0))
			draw_line(tip, tip + Vector2(0, -6), color, 2)
			draw_line(tip, tip + Vector2(-5 if index == 0 else 5, 0), color, 2)
