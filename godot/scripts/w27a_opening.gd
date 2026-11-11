extends RefCounted
## Opening positions are movement commitments; the player still chooses the route.

static func choices(m: RefCounted) -> Dictionary:
	if not m._is_opening_defense26() or m.turn > 2: return {}
	return {"options":[
		{"id":"hold", "label":"Hold the gate line", "tiles":[Vector2i(12, 16), Vector2i(13, 16), Vector2i(14, 16)], "purpose":"Keep defenders in the gate zone and cover the approach."},
		{"id":"flank", "label":"Push the west flank", "tiles":[Vector2i(9, 18), Vector2i(10, 18)], "purpose":"Reach side cover and cut off the west pod."}
	], "decision_turns_left":maxi(0, 3-m.turn)}
