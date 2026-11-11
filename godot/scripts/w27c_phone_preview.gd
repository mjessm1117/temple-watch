extends RefCounted
## Compact route facts from lane B's guarded decision_preview27 contract.

static func move_text(preview: Dictionary) -> String:
	if preview.is_empty(): return ""
	var cover := str(preview.get("cover", "none")).to_upper()
	var height := int(preview.get("height", 0))
	var flank := int(preview.get("flank", 0))
	var result := "%s COVER  ·  HEIGHT %+d  ·  FLANK %+d" % [cover, height, flank]
	var events: Array = preview.get("events", [])
	if events.is_empty(): return result
	var first: Dictionary = events[0]
	var kind := str(first.get("kind", ""))
	var tile: Vector2i = first.get("tile", Vector2i(-1, -1))
	var source := str(first.get("source_name", ""))
	var label := "OVERWATCH " + source if kind == "overwatch" else "REVEAL" if kind == "reveal" else "WAVE ENTRY" if kind == "wave_entry" else "FLANK RISK"
	return result + "\n" + label + " AT %d,%d" % [tile.x, tile.y]
