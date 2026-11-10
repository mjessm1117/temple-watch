extends SceneTree

const Story = preload("res://scripts/story/story_engine.gd")
const Beats = preload("res://scripts/story/story14_beats.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Villain = preload("res://scripts/story/villain11_arc.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STORYCONTENT22: " + reason)

func words(line: String) -> int:
	return line.replace("\n", " ").split(" ", false).size()

func load_json(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/story/" + name + ".json"))

func run() -> void:
	var engine := Story.new()
	var after: Dictionary = engine.table("AFTER")["relay:win"]
	check(not str(after.text).contains("prisoner") or str(after.text).contains("wounded driver"), "gate aftermath has no invented prisoners")
	check(str(after.text).contains("withdrew") and str(after.text).contains("transports"), "gate withdrawal continuity")
	check(after.ch.size() == 3 and after.ch[1].fx.orderDark == -4 and after.ch[2].fx.orderDark == 4, "gate ethics effects preserved")
	var missions: Dictionary = engine.table("BASE_MISSIONS")
	for id in ["rescue", "shrine", "archive"]:
		var row: Dictionary = missions[id]
		var bridge: PackedStringArray = str(row.brief).split("\n")
		var bridge_words := words(" ".join(bridge.slice(1)))
		check(bridge_words >= 60 and bridge_words <= 90 and bridge.size() == 3 and words(bridge[1]) <= 60 and words(bridge[2]) <= 60, id + " bridge length and phone split")
		var crisis_debrief: Dictionary = engine.story20.missions[id]
		check(str(crisis_debrief.win).contains("gate") and str(crisis_debrief.win).contains("envoy") and str(crisis_debrief.lose).contains("gate") and str(crisis_debrief.lose).contains("envoy"), id + " gate-to-envoy debrief")
		var played: Dictionary = Story.new().start_debrief({"mission_id":id, "won":true})
		check(str(played.text).contains("gate") and str(played.text).contains("envoy"), id + " composed debrief carries the bridge")
	var barks: Dictionary = load_json("story14-barks")
	var ids := ["kira", "tor", "satele", "ressa", "kell", "sava", "tem"]
	for id in ids:
		var name: String = Beats.NAMES[id]
		for kind in ["kill", "hurt", "flank", "crit", "miss", "reveal"]:
			var lines: Array = barks.heroes[name][kind]
			check(lines.size() >= 1 and words(str(lines[0])) <= 14, name + " " + kind + " line")
			var picked: Dictionary = Beats.pick_bark(kind, id, id, {})
			check(picked.get("speaker", "") == name and words(str(picked.get("text", ""))) <= 14, name + " " + kind + " actor priority")
	for advisor in ["Jace Malcom", "Ilsa Myr"]:
		for kind in ["kill", "hurt", "flank", "crit", "miss", "reveal"]:
			check(barks.advisors[advisor][kind].size() >= 1 and words(str(barks.advisors[advisor][kind][0])) <= 14, advisor + " " + kind + " fallback")
	check(Beats.pick_bark("hurt", "kira", "tor", {}).speaker == "Tor Saalen", "hurt target speaks first")
	check(Beats.pick_bark("kill", "unknown", "enemy", {"bondmate_id":"kira"}).speaker == "Kira Venn", "bondmate second")
	check(Beats.pick_bark("kill", "unknown", "enemy", {}).speaker == "Jace Malcom", "advisor fallback")
	check(Beats.pick_bark("player_turn_start", "kira", "", {}).is_empty(), "unhandled event silent")
	for villain in ["Lord Kaan", "Darth Bane", "Darth Malgus"]:
		var data: Dictionary = load_json("wave11-villain").records.W11_BATTLE_LINES[villain]
		check(data.intro != data.taunt and data.intro != data.retreat and data.taunt != data.retreat, villain + " three distinct lines")
		for event in ["villain_reveal", "villain_taunt", "villain_retreat"]:
			var picked: Dictionary = Beats.pick_bark(event, "", "", {"villain_name":villain})
			check(picked.get("speaker", "") == villain and picked.get("priority", 0) >= 3, villain + " radio " + event)
			if event == "villain_reveal": check(str(picked.text).split("\n").size() == 2, villain + " reveal and taunt are two lines")
	var encounter := {"id":"r_caves"}
	Villain.briefing(engine.state, encounter)
	check(encounter.get("villain_name", "") == "Darth Bane" and encounter.get("villain_start_bark", "") != encounter.get("villain_end_bark", "") and not str(encounter.get("villain_taunt_bark", "")).is_empty(), "Bane encounter carries distinct battle lines")
	var mid: Array = engine.table("W10_MID")
	check(mid.size() == 8, "eight W10 fallback beats")
	for row in mid:
		check(not str(row.get("speaker", "")).is_empty() and str(row.speaker) != "Jedi Council", row.id + " named speaker")
	var fallback_beat: Dictionary = engine.next_squad_beat(engine.state, "relay", 2, [])
	check(fallback_beat.get("name", "") == "Sgt. Rhal Dax" and fallback_beat.get("choices", []).size() == 2, "gate fallback renders its field speaker")
	var scene: Dictionary = engine.start_debrief({"mission_id":"relay", "won":true, "units":[{"id":"kira","status":"dead","kills":2}], "objective":"Outer gate"})
	check(str(scene.text).begins_with("Outer gate held; Kira Venn did not return."), "debrief prioritizes objective and named death")
	check(words(str(scene.text).split("\n")[0]) <= 25, "priority line stays short")
	check(not str(scene.text).contains("The Republic fleet drops out of hyperspace"), "duplicate base debrief line trimmed")
	check(scene.choices.size() == 3 and scene.choices[0].id == "after:0" and scene.choices[2].id == "after:2", "gate aftermath choice ids stable")
	var without_units: Dictionary = Story.new().start_debrief({"mission_id":"relay", "won":false})
	check(not str(without_units.text).is_empty() and str(without_units.text).contains("lost"), "missing units handled")
	var state: Dictionary = engine.state
	state.beat_decision = "Protect the people first"
	check(Beats.debrief(state, {"won":true,"units":[{"id":"tor","hp":2,"max_hp":5}]}, missions.relay).contains("Tor Saalen returned wounded"), "wound named")
	check(Beats.debrief(state, {"won":true}, missions.relay).contains("Field choice: Protect the people first"), "mid beat acknowledged")
	var squad_scenes: Array = engine.table("W11_SCENES")
	check(squad_scenes.size() == 14, "fourteen squad scenes")
	var expected_names := [["Kira", "Tor"], ["Rhal", "Ilsa"], ["Kira", "Rhal", "Bren"], ["Tor", "Bren"], ["Ressa", "Kell"], ["Bo", "Mira"], ["Ressa", "Bo", "Ilo"], ["Kell", "Rusk"], ["Sava", "Tem"], ["Dace", "Kiri"], ["Sava", "Halden", "Bruk"], ["Tem", "Kiri"], ["Kira", "Tor"], ["Rhal", "Ilsa"]]
	var labels: Dictionary = {}
	for index in squad_scenes.size():
		var row: Dictionary = squad_scenes[index]
		check(row.choices.size() == 2 and str(row.choices[0].label) != str(row.choices[1].label), row.id + " two distinct choices")
		for c in row.choices:
			labels[c.label] = true
			for name in expected_names[index]: check(str(c.label).contains(name), row.id + " names " + name)
	check(labels.size() == 28, "all fourteen choice pairs unique")
	var opening: Array = load_json("opening").pages
	var opening_words := 0
	var opening_titles: Dictionary = {}
	for page in opening:
		opening_words += words(str(page.text))
		opening_titles[page.title] = true
		check(words(str(page.text)) <= 60, "opening phone page <=60 words")
	check(opening_words >= 974, "opening story volume preserved")
	check(opening_titles.size() == opening.size(), "opening pages have distinct beat titles")
	var expansion: Dictionary = load_json("story20-expansion")
	var expansion_words := 0
	for category in expansion:
		for row in expansion[category].values():
			for value in (row.values() if row is Dictionary else [row]):
				if not value is String: continue
				expansion_words += words(str(value))
				for segment in str(value).split("\n"):
					check(words(segment) <= 60, "expansion phone segment <=60 words")
	check(expansion_words >= 8365, "W20 expansion volume preserved")
	for size in [Vector2i(844, 390), Vector2i(390, 844), Vector2i(1366, 768)]:
		Phone.test_window_size = size
		Phone.test_touch = 1 if size.x < 900 else 0
		Phone.test_mobile = Phone.test_touch
		DisplayServer.window_set_size(size)
		root.size = size
		root.content_scale_size = size
		var opening_scene: Control = preload("res://scenes/opening.tscn").instantiate()
		root.add_child(opening_scene)
		for frame in 3: await process_frame
		opening_scene.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		opening_scene.position = Vector2.ZERO
		opening_scene.size = size
		opening_scene._layout()
		await process_frame
		var next_rect: Rect2 = opening_scene.next_button.get_global_rect()
		check(next_rect.size.y >= 44 and next_rect.position.x >= 12 and next_rect.end.x <= size.x - 12, "opening tap target fits " + str(size))
		var skip_button: Button = opening_scene.actions.get_child(1 if opening_scene.hint.visible else 1)
		check(skip_button.get_global_rect().end.x <= next_rect.position.x, "opening actions do not overlap " + str(size))
		check(opening_scene.narrative.size.x > 100 and opening_scene.narrative.size.y > 100, "opening text viewport fits " + str(size))
		opening_scene.queue_free()
		await process_frame
	print("Storycontent22: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
