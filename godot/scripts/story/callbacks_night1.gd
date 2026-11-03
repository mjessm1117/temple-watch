extends RefCounted
## Adds explicit, once-per-scene consequences to scenes already owned by StoryEngine.

static func apply(s: Dictionary, scene: Dictionary, rows: Array) -> Dictionary:
	var kind := str(scene.get("kind", ""))
	var shown: Dictionary = s.get("callback_seen", {})
	var rewarded: Dictionary = s.get("callback_rewarded", {})
	for row in rows:
		if row.kind != kind or not s.flags.get(row.flag, false): continue
		var key := str(row.id) + ":" + str(scene.get("id", ""))
		if shown.get(key, false): continue
		scene.text = str(scene.get("text", "")) + "\n\n" + str(row.text)
		if not row.get("fx", {}).is_empty() and not rewarded.get(row.id, false):
			for resource in row.fx:
				if s.res.has(resource): s.res[resource] = maxi(0, int(s.res.get(resource, 0)) + int(row.fx[resource]))
			rewarded[row.id] = true
		shown[key] = true
	s.callback_seen = shown
	s.callback_rewarded = rewarded
	return scene
