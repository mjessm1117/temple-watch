extends Control
## Tiny vector glyphs for the Temple navigation rail.
var kind := "Command"
var ink := Color("8aa2a5")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var c := size * 0.5
	match kind:
		"Command":
			draw_arc(c, 6, 0, TAU, 20, ink, 1.5); draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), ink, 1.3); draw_line(c + Vector2(0, -8), c + Vector2(0, 8), ink, 1.3)
		"Roster":
			draw_arc(c + Vector2(0, -4), 3, 0, TAU, 16, ink, 1.5); draw_arc(c + Vector2(0, 6), 7, PI, TAU, 16, ink, 1.5)
		"Research":
			draw_rect(Rect2(c - Vector2(7, 6), Vector2(14, 12)), ink, false, 1.5); draw_line(c, c + Vector2(0, 6), ink, 1.2)
		"Build":
			draw_rect(Rect2(c - Vector2(6, 6), Vector2(12, 12)), ink, false, 1.5); draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), ink, 1.5); draw_line(c + Vector2(0, -8), c + Vector2(0, 8), ink, 1.5)
		"Arsenal":
			draw_line(c + Vector2(-6, 7), c + Vector2(6, -7), ink, 2); draw_line(c + Vector2(-8, 3), c + Vector2(-3, 8), ink, 2)
		"Teams":
			draw_arc(c + Vector2(-4, -3), 3, 0, TAU, 12, ink, 1.5); draw_arc(c + Vector2(4, -3), 3, 0, TAU, 12, ink, 1.5); draw_line(c + Vector2(-9, 7), c + Vector2(9, 7), ink, 1.5)
		"Legacy":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(7, -4), c + Vector2(5, 6), c + Vector2(0, 9), c + Vector2(-5, 6), c + Vector2(-7, -4)]), ink)
		"Codex":
			draw_rect(Rect2(c - Vector2(6, 7), Vector2(12, 14)), ink, false, 1.5); draw_line(c + Vector2(-2, -5), c + Vector2(-2, 5), ink, 1.2)
		"Galaxy":
			draw_arc(c, 6, 0, TAU, 20, ink, 1.5); draw_arc(c, 2, 0, TAU, 12, ink, 1.3); draw_line(c + Vector2(-8, 5), c + Vector2(8, -5), ink, 1.2)
