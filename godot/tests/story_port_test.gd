extends SceneTree

const Story = preload("res://scripts/story/story_engine.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	_test_sources()
	_test_choices_and_talks()
	_test_council_pair_and_finale()
	_test_eras_and_codex()
	await _test_scenes()
	print("STORY TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _test_sources() -> void:
	var files := ["story","data-story","story-era2","data-era2","story-era3","data-era3","saga","data-saga","data-codex","ui-codex","tutorial","data-life","temple-life","spec-story","spec-saga","spec-chains"]
	var root := ProjectSettings.globalize_path("res://../")
	for name in files:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/%s.json" % name))
		check(parsed is Dictionary,"JSON parsed: " + name)
		if not parsed is Dictionary: continue
		var source: String = FileAccess.get_file_as_string(root + parsed.source)
		check(source == parsed.text,"lossless source: " + name)
		check(source.sha256_text() == parsed.sha256,"source hash: " + name)
		check(source.split("\n").size()-1 == int(parsed.lines),"source line count: " + name)
		for key in parsed.counts:
			var value = parsed.records[key]
			var count: int = value.size() if value is Array or value is Dictionary else 1
			check(count == int(parsed.counts[key]),"entry count: %s %s" % [name,key])
	var story = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-story.json"))
	var era2 = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-era2.json"))
	var era3 = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-era3.json"))
	var saga = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-saga.json"))
	check(story.records.EVENTS.size() == 23,"web Era 1 event count")
	check(era2.records.EVENTS.size() == 11,"web Era 2 event count")
	check(era3.records.EVENTS.size() == 9,"web Era 3 event count")
	check(saga.records.TALKS.size() == 21,"web Temple talk count")
	check(saga.records.SQUAD_BEATS.size() == 8,"web mid-mission beat count")
	check(saga.records.AFTER.size() == 15,"web debrief decision count")

func _test_choices_and_talks() -> void:
	var story = Story.new()
	var state: Dictionary = story.state
	var event: Dictionary = story.next_story_event(state)
	check(event.get("id") == "e1_gnost_archive","first web Council event")
	check(story.apply_choice(state,"event:0").get("ok",false),"Council choice applies")
	check(state.flags.get("archive_backup",false),"Council choice flag")
	state.story.done = 1
	var talk: Dictionary = story.next_temple_talk(state)
	check(talk.get("id") == "k1","Kira's first Temple talk")
	check(talk.get("choices",[]).size() == 3,"Temple talk choices")
	story.apply_choice(state,"talk:0")
	check(state.flags.get("kira_told",false),"talk choice flag")
	check(int(state.saga.t.kira) == 1,"named soldier trust rises")
	story.record_mission_bonds(state,["kira","tor"],true)
	check(int(state.bonds["kira|tor"].lvl) == 1,"soldier bond rises after winning together")
	check(int(state.bonds["kira|tor"].n) == 1,"bond keeps overflow points")

func _test_eras_and_codex() -> void:
	var story = Story.new()
	var state: Dictionary = story.state
	var briefing: Dictionary = story.start_briefing("dock")
	check(briefing.get("choices",[]).size() >= 3,"briefing has story approach choices")
	check(state.codex.mission.get("dock",false),"mission Codex unlocks")
	check(state.codex.character.get("malgus",false),"character Codex unlocks")
	var codex: Array = story.codex_entries(state,"character")
	check(codex.any(func(e): return e.id == "malgus" and e.lore != ""),"unlocked Codex lore browsable")
	story.start_debrief({"mission_id":"dock","won":true})
	check(state.flags.get("boss_or_won",false),"Malgus win flag")
	check(story.advance_era(state),"web Era 1 ending opens Ruusan")
	check(int(state.era) == 2 and int(state.story.bby) == 1006,"Era 2 year")
	story.start_debrief({"mission_id":"r_bomb","won":true,"bane":"escaped"})
	check(state.flags.get("boss_ru_won",false),"Ruusan boss win")
	check(state.flags.get("rule_of_two",false),"Bane escape rule")
	check(story.advance_era(state),"web Era 2 ending opens High Republic")
	check(int(state.era) == 3 and int(state.story.bby) == 232,"Era 3 year")
	story.start_debrief({"mission_id":"h_beacon","won":true})
	check(state.flags.get("e3_beacon_saved",false),"Starlight Beacon outcome")

func _test_council_pair_and_finale() -> void:
	var story = Story.new()
	var state: Dictionary = story.state
	var vote: Dictionary = story.next_council_vote(state)
	check(vote.get("id") == "refugees","Council vote content loaded")
	check(story.apply_choice(state,"vote:0").get("ok",false),"Council decision applies")
	check(int(state.res.credits) == 400 and int(state.res.favor) == 56,"Council resource effects")
	check(int(state.story.loyal.darach) == 65 and int(state.story.loyal.zym) == 45,"Council stance loyalty rules")
	for person in state.roster:
		if person.id == "kira": person.title = "Knight"; person.rank = 3
		if person.id == "tor": person.title = "Padawan"
	check(story.set_pair(state,"tor","kira"),"named Master-Padawan pair")
	check(int(state.bonds["kira|tor"].lvl) == 2,"pair begins at web bond level")
	story.record_mission_bonds(state,["kira","tor"],true)
	var tor: Dictionary = state.roster.filter(func(r): return r.id == "tor")[0]
	check(int(tor.xp) == 8,"paired Padawan gains web XP")
	state.flags.kira_watch = true
	var finale: Array = story.finale_battle_effects(state)
	check(finale.any(func(row): return row.k == "kira" and row.fx.get("hurtBoss") == 2),"Kira's saga arc changes Malgus fight")
	state.story.done = 2
	var beat: Dictionary = story.next_squad_beat(state,"relay",2,["Kira Venn","Tor Saalen"])
	check(beat.get("id") == "kb","mid-mission squad beat")
	check(story.apply_choice(state,"beat:0").get("ok",false),"mid-mission choice applies")

func _test_scenes() -> void:
	for scene_name in ["briefing","dialogue","codex"]:
		var packed: PackedScene = load("res://scenes/%s.tscn" % scene_name)
		check(packed != null,"scene loads: " + scene_name)
		if packed == null: continue
		var screen = packed.instantiate()
		root.add_child(screen)
		await process_frame
		check(screen.get_child_count() > 0,"scene builds: " + scene_name)
		screen.queue_free()
		await process_frame
