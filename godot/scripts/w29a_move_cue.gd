extends RefCounted
## Presentation only: use the shot rules for cover and flank at a proposed tile.
static func at(m: RefCounted, actor: Dictionary, tile: Vector2i, preview: Dictionary = {}) -> Dictionary:
	var rules: Script = load("res://scripts/shot.gd")
	if not m.has_method("living") or rules == null: return {"label": "○ COVER UNKNOWN", "detail": "Cover information unavailable", "flanked": false, "exposed": false, "cover": 0, "seen": 0}
	var weakest := 40
	var flanked := false
	var exposed := false
	var seen := 0
	for enemy in m.living("enemy"):
		if not bool(enemy.get("spotted", false)) and not bool(enemy.get("detected", false)) and not bool(enemy.get("awake", false)): continue
		var source := Vector2i(int(enemy.get("x", -1)), int(enemy.get("y", -1)))
		if rules.has_method("los") and not bool(rules.call("los", m, source, tile)): continue
		seen += 1
		var proposed := actor.duplicate()
		proposed["x"] = tile.x; proposed["y"] = tile.y
		var shot: Dictionary = rules.call("calculate", m, enemy, proposed) if rules != null and rules.has_method("calculate") else {}
		var cover: int = int(shot.get("cover", rules.call("cover", m, tile, source) if rules.has_method("cover") else 0))
		weakest = mini(weakest, cover)
		flanked = flanked or bool(shot.get("flanked", false))
		if cover == 0:
			exposed = true
	var evaluated := seen > 0
	if not evaluated:
		seen = preview.get("seen_by", []).size()
		flanked = not preview.get("flanks", []).is_empty()
	var value := "FLANKED" if flanked else "EXPOSED" if exposed else "FULL COVER" if weakest >= 40 and evaluated else "HALF COVER" if weakest >= 20 and evaluated else "NO KNOWN FIRE"
	var shield := "◇" if flanked or exposed else "⬟" if weakest >= 40 and evaluated else "◐" if weakest >= 20 and evaluated else "○"
	var height := int(preview.get("height_delta", preview.get("height", 0)))
	var detail := "%s  ·  %d enemy sightline%s" % [value, seen, "" if seen == 1 else "s"]
	if preview.has("height_delta") or preview.has("height"): detail += "  ·  HEIGHT %+d" % height
	if preview.has("cover_damage"): detail += "  ·  COVER DAMAGE %d" % int(preview.cover_damage)
	if preview.has("cover_hp"): detail += "  ·  COVER HP %d" % int(preview.cover_hp)
	var events: Array = preview.get("events", [])
	if not events.is_empty(): detail += "\nROUTE: " + str(events[0].get("kind", "clear")).to_upper()
	return {"label": shield + " " + value, "detail": detail, "flanked": flanked, "exposed": exposed, "cover": weakest if evaluated else 0, "seen": seen}
