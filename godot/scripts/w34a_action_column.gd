extends RefCounted
## Phone action controls occupy the left map margin above the unit card.

static func box(area: Vector2, plate: Rect2) -> Rect2:
	var top := 76.0 if area.y > area.x else 48.0 if area.y < 300.0 else 54.0
	return Rect2(8.0, top, 132.0, minf(276.0, maxf(0.0, plate.position.y - 8.0 - top)))
