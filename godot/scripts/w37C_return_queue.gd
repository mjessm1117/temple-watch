extends RefCounted
## One return scene per Temple visit; debrief is shown before this queue begins.

const Endings = preload("res://scripts/story/ending_resolution.gd")

static func begin(s: Dictionary, mission_id: String) -> void:
	var stage := "threat"
	if int(s.get("era", 1)) == 3 and mission_id == "h_beacon":
		var ending := Endings.resolve(s)
		s.ending = ending.get("id", "")
		stage = "ending"
	s.w37c_return = {"stage":stage, "mission":mission_id}

static func active(s: Dictionary) -> bool:
	return s.has("w37c_return")

static func next(s: Dictionary, story: RefCounted) -> Dictionary:
	var stage := str(s.get("w37c_return", {}).get("stage", "done"))
	if stage == "ending":
		s.w37c_return.stage = "done"
		var ending := Endings.scene(s)
		s.pending = ending
		return ending
	if stage == "threat":
		s.w37c_return.stage = "talk"
		var threat: Dictionary = story.next_villain_beat(s)
		if not threat.is_empty(): return threat
		stage = "talk"
	if stage == "talk":
		s.w37c_return.stage = "done"
		return story.next_temple_talk(s)
	s.erase("w37c_return")
	return {}
