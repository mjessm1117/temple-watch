extends Control
## Native vector redraws of the web's 24px stroke icons (icons.js).
var kind := "kyber"
var ink := Color("79d3e2")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var side := minf(size.x, size.y)
	draw_set_transform((size - Vector2.ONE * side) * 0.5, 0, Vector2.ONE * side / 24.0)
	match kind:
		"relay":
			_line([Vector2(12,2),Vector2(12,8),Vector2(6,22),Vector2(12,8),Vector2(18,22)])
			_line([Vector2(8,4),Vector2(12,8),Vector2(16,4)])
			_line([Vector2(8,17),Vector2(16,17)])
		"guardian":
			_line([Vector2(15,2),Vector2(15,14),Vector2(15,20)])
			_line([Vector2(13,14),Vector2(17,14)])
			_line([Vector2(3,6),Vector2(8,4),Vector2(13,6),Vector2(13,11),Vector2(11,15),Vector2(8,18),Vector2(5,15),Vector2(3,11),Vector2(3,6)])
		"locked":
			draw_arc(Vector2(12,9),5,PI,TAU,18,ink,1.6,true)
			draw_rect(Rect2(5,9,14,12),ink,false,1.6)
			_line([Vector2(12,13),Vector2(12,17)])
		"holocron":
			_line([Vector2(12,2),Vector2(22,7),Vector2(22,17),Vector2(12,22),Vector2(2,17),Vector2(2,7),Vector2(12,2),Vector2(12,22)])
			_line([Vector2(2,7),Vector2(12,12),Vector2(22,7)])
		_:
			_line([Vector2(12,2),Vector2(17,9),Vector2(12,22),Vector2(7,9),Vector2(12,2)])
			_line([Vector2(7,9),Vector2(17,9)])

func _line(points: Array) -> void:
	draw_polyline(PackedVector2Array(points),ink,1.5,true)

func _process(_delta: float) -> void:
	if kind == "holocron":
		var glow := 0.88 + sin(Time.get_ticks_msec()*0.0015)*0.12
		modulate = Color(glow,glow,glow)
