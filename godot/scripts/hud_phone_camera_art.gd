extends Control
## Three camera chips share one canvas item; the transparent buttons own input.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color("101b26f5"); chip.set_corner_radius_all(9)
	draw_style_box(chip, Rect2(0, 0, 48, 144))
	var font := ThemeDB.fallback_font
	for index in 3:
		var glyph: String = ["↶", "⌖", "↷"][index]
		draw_string(font, Vector2(0, index * 48 + 32), glyph, HORIZONTAL_ALIGNMENT_CENTER, 48, 16, Color("f2d99a"))
