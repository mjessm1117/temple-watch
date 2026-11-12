extends RefCounted
## Early campaign consequences live in the campaign Dictionary and its normal save path.

static func ensure(s: Dictionary) -> void:
	if not s.has("w29e_events"): s.w29e_events = {}
	if not s.has("w29e_journal"): s.w29e_journal = []
	if not s.has("w29e_reserved"): s.w29e_reserved = []

static func briefing(s: Dictionary, scene: Dictionary, squad_rows: Array) -> void:
	ensure(s)
	if int(s.get("era", 1)) != 1: return
	if scene.id == "envoy":
		if s.w29e_events.get("rescue_saved", false):
			scene.text += "\n\nThe captive heard the envoy's transfer code. Follow that voice to his terminals."
		elif s.w29e_events.get("archive_saved", false):
			scene.text += "\n\nThe recovered records carry the envoy's cipher. Match it at his terminals."
	var milestone := 1 if scene.id in ["rescue", "archive"] else 2 if scene.id == "envoy" else -1
	if milestone < 0: return
	var scene_id := "s11_01" if milestone == 1 else "s11_02"
	for row in squad_rows:
		if str(row.get("id", "")) != scene_id or s.w29e_reserved.has(scene_id) or s.scenes11_seen.has(scene_id): continue
		var names: Array[String] = []
		var available := true
		for index in row.members:
			if int(index) < s.roster.size():
				names.append(str(s.roster[int(index)].get("n", "")))
				if str(s.roster[int(index)].get("status", "")) != "active": available = false
		if names.size() != row.members.size(): return
		if not available:
			var missed := "%s — %s (missed before deployment)" % [" & ".join(names), row.title]
			if not s.w29e_journal.has(missed): s.w29e_journal.append(missed)
			s.w29e_reserved.append(scene_id)
			return
		var beat := " / ".join(row.lines)
		scene.text += "\n\n" + beat
		s.w29e_reserved.append(scene_id)
		s.scenes11_seen.append(scene_id)
		s.scenes11_log.append("%s — %s (heard before deployment)" % [" & ".join(names), row.title])
		return

static func debrief(s: Dictionary, scene: Dictionary, result: Dictionary, squad_rows: Array) -> void:
	ensure(s)
	if int(s.get("era", 1)) != 1: return
	var id := str(scene.get("id", ""))
	var won := bool(result.get("won", false))
	s.w29e_events.battle_seen = true
	if id == "rescue":
		s.w29e_events.rescue_saved = won
		scene.text += "\n\n" + ("The captive gives Kira the envoy's transfer code." if won else "The captive was lost; Kira has only the broken signal.")
	elif id == "archive":
		s.w29e_events.archive_saved = won
		scene.text += "\n\n" + ("Ilsa finds the envoy's cipher in the recovered records." if won else "The records were lost; Ilsa has only a partial cipher.")
	if not s.w29e_events.get("kira_gate", false):
		for unit in result.get("units", []):
			if str(unit.get("id", "")) == "kira" and int(unit.get("kills", 0)) > 0 and not s.w29e_events.get("kira_gate", false):
				s.w29e_events.kira_gate = true
				scene.text += "\n\n" + ("Kira held the gate herself. Tor takes the next watch." if id == "relay" else "Kira cleared a path. Tor takes the next watch.")
				break
	if not s.w29e_events.get("tor_action", false) and result.get("saved_by", {}).values().has("tor"):
		s.w29e_events.tor_action = true
		scene.text += "\n\nTor got a squadmate standing. The ward is ready."
	# Optional conversations missed at the next campaign milestone remain readable.
	if id in ["relay", "rescue", "archive", "envoy"]:
		var done := int(s.story.get("done", 0))
		for row in squad_rows:
			if int(row.get("era", 0)) != 1 or int(row.get("done", 999)) >= done: continue
			var key := str(row.id)
			if key in ["s11_01", "s11_02"]: continue
			if s.scenes11_seen.has(key) or s.w29e_reserved.has(key): continue
			var line := "%s — %s (missed at the Temple)" % [key, row.title]
			if not s.w29e_journal.has(line): s.w29e_journal.append(line)

static func journal(s: Dictionary, record: Dictionary) -> void:
	ensure(s)
	for line in s.w29e_journal: record.squad.append(line)
