extends Control
## Original code-drawn Sith intelligence portraits, with no external art dependencies.
var variant := 0
var ink := Color("e77787")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var center := Vector2(w * 0.5, h * 0.48)
	draw_rect(Rect2(Vector2.ZERO, size), Color("101720"))
	for i in 24:
		var x := fmod(float(i * 83 + 21), w)
		var y := fmod(float(i * 47 + 11), h)
		draw_circle(Vector2(x, y), 1.0, Color(ink, 0.25))
	for radius in [0.29, 0.41, 0.53]:
		draw_arc(center, h * radius, -PI * 0.92, PI * 0.6, 70, Color(ink, 0.17), 1.0, true)
	draw_line(Vector2(20, h * 0.6), Vector2(w - 20, h * 0.6), Color(ink, 0.15), 1.0)
	var scale := minf(w / 320.0, h / 210.0)
	var origin := Vector2(w * 0.5, h)
	poly([Vector2(-112, 0), Vector2(-87, -44), Vector2(-42, -69), Vector2(-27, -93), Vector2(27, -93), Vector2(42, -69), Vector2(87, -44), Vector2(112, 0)], origin, scale, Color("242732"))
	if variant == 1:
		poly([Vector2(-110, -9), Vector2(-94, -57), Vector2(-46, -80), Vector2(-31, -20), Vector2(-53, 0)], origin, scale, Color("3d3531"))
		poly([Vector2(110, -9), Vector2(94, -57), Vector2(46, -80), Vector2(31, -20), Vector2(53, 0)], origin, scale, Color("3d3531"))
	poly([Vector2(-67, -48), Vector2(-52, -146), Vector2(-20, -193), Vector2(15, -198), Vector2(52, -146), Vector2(67, -48), Vector2(33, -68), Vector2(-33, -68)], origin, scale, Color("38303c") if variant == 0 else Color("343242"))
	poly([Vector2(-38, -138), Vector2(-10, -169), Vector2(18, -166), Vector2(39, -135), Vector2(27, -85), Vector2(0, -65), Vector2(-27, -86)], origin, scale, Color("090d14"))
	poly([Vector2(-29, -129), Vector2(-5, -150), Vector2(20, -144), Vector2(28, -117), Vector2(18, -84), Vector2(0, -76), Vector2(-20, -91)], origin, scale, Color("30313c"))
	poly([Vector2(-4, -148), Vector2(20, -144), Vector2(28, -117), Vector2(18, -84), Vector2(0, -76)], origin, scale, Color("1a202a"))
	if variant == 1:
		poly([Vector2(-28, -117), Vector2(28, -117), Vector2(19, -84), Vector2(0, -76), Vector2(-20, -91)], origin, scale, Color("554b46"))
	for x in [-19, 9]:
		draw_line(origin + Vector2(x, -125) * scale, origin + Vector2(x + 10, -123) * scale, ink, 2.5 * scale, true)
	if variant == 2:
		draw_line(origin + Vector2(0, -146) * scale, origin + Vector2(0, -112) * scale, ink, 1.5 * scale)
		for x in [-62, 62]: draw_circle(origin + Vector2(x, -121) * scale, 5 * scale, Color(ink, 0.5))
	draw_line(origin + Vector2(-45, -70) * scale, origin + Vector2(-67, 0) * scale, Color(ink, 0.55), scale)
	draw_line(origin + Vector2(45, -70) * scale, origin + Vector2(67, 0) * scale, Color(ink, 0.35), scale)
	for i in 6:
		draw_line(Vector2(16, 14 + i * 5), Vector2(16 + (25 if i % 2 else 39), 14 + i * 5), Color(ink, 0.3), 1.0)
	draw_line(Vector2(0, h - 1), Vector2(w, h - 1), Color(ink, 0.65), 2.0)

func poly(points: Array, origin: Vector2, factor: float, color: Color) -> void:
	var vertices := PackedVector2Array()
	for point in points: vertices.append(origin + point * factor)
	draw_colored_polygon(vertices, color)
