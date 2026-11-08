extends Control
## Lightweight drawn rank device; no textures or extra viewport.
var side_name := "jedi"
var level := 1
var glow := 1.0

func _draw() -> void:
	var c := size * 0.5
	var radius := minf(size.x, size.y) * 0.39
	var color := Color("e0bd78") if side_name == "jedi" else Color("79d3e2")
	color.a = glow
	draw_arc(c, radius, 0, TAU, 48, color.darkened(0.28), 2.0, true)
	if side_name == "jedi":
		var points := 4 if level <= 2 else 5 if level <= 4 else 6 if level <= 6 else 7 if level == 7 else 8
		for i in points:
			var angle := -PI * 0.5 + TAU * float(i) / float(points)
			var tip := c + Vector2(cos(angle), sin(angle)) * radius * 0.78
			var left := c + Vector2(cos(angle - 0.27), sin(angle - 0.27)) * radius * 0.36
			var right := c + Vector2(cos(angle + 0.27), sin(angle + 0.27)) * radius * 0.36
			draw_colored_polygon(PackedVector2Array([tip, left, c, right]), color)
		draw_circle(c, radius * 0.18, Color("102027"))
		draw_arc(c, radius * 0.18, 0, TAU, 24, color, 2.0, true)
	else:
		for i in mini(level, 7):
			var y := c.y + (float(i) - float(level - 1) * 0.5) * radius * 0.28
			draw_line(Vector2(c.x - radius * 0.43, y - radius * 0.12), Vector2(c.x, y + radius * 0.12), color, 3.0, true)
			draw_line(Vector2(c.x, y + radius * 0.12), Vector2(c.x + radius * 0.43, y - radius * 0.12), color, 3.0, true)
