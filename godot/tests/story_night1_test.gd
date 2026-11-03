extends SceneTree

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Callbacks = preload("res://scripts/story/callbacks_night1.gd")
const Arcs = preload("res://scripts/story/arc_night1.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, note: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(note)

func run() -> void:
	var story = Story.new()
	var callbacks: Array = story.table("N1_CALLBACKS")
	var arcs: Array = story.table("N1_ARCS")
	check(callbacks.size() >= 20, "twenty callbacks")
	check(callbacks.filter(func(r): return not r.get("fx", {}).is_empty()).size() >= 6, "six mechanical callbacks")
	for row in callbacks:
		var a = Story.new()
		var scene := {"kind":row.kind,"id":row.id,"text":"Baseline","choices":[]}
		Callbacks.apply(a.state,scene,[row])
		check(scene.text == "Baseline", "callback absent without flag: " + row.id)
		a.state.flags[row.flag] = true
		var old_res: Dictionary = a.state.res.duplicate()
		Callbacks.apply(a.state,scene,[row])
		check(scene.text.contains(row.text), "callback fires: " + row.id)
		for resource in row.get("fx", {}): check(int(a.state.res[resource]) == int(old_res[resource]) + int(row.fx[resource]), "mechanic: " + row.id)
		var after: Dictionary = a.state.res.duplicate()
		Callbacks.apply(a.state,scene,[row])
		check(a.state.res == after and scene.text.count(row.text) == 1, "callback once: " + row.id)
		var later := {"kind":row.kind,"id":row.id + ":later","text":"Later"}
		Callbacks.apply(a.state,later,[row])
		check(later.text.contains(row.text) and a.state.res == after, "callback recurs without repeated reward: " + row.id)
	check(arcs.size() == 6, "six starting character arcs")
	for row in arcs:
		var a = Campaign.new()
		var e = Story.new(a.state)
		a.state.story.done = 1
		var first: Dictionary = Arcs.next_talk(a.state,[row])
		check(first.get("kind") == "arc_talk", "step one talk: " + row.name)
		check(e.apply_choice(a.state,"arc:0").ok, "step one resolves: " + row.name)
		var brief := {"kind":"briefing","id":"relay","text":"Mission"}
		Arcs.briefing(a.state,brief,[row])
		check(brief.text.contains(row.brief) and int(a.state.personal_arcs[row.id]) == 2, "step two briefing: " + row.name)
		a.state.story.done = 2
		var last: Dictionary = Arcs.next_talk(a.state,[row])
		check(last.get("kind") == "arc_resolution" and last.choices.size() == 2, "step three choice: " + row.name)
		var r: Dictionary = Arcs.person(a.state,row.name)
		var before := int(r.get("bonus",{}).get("will",0))
		check(e.apply_choice(a.state,"arc:0").ok, "step three resolves: " + row.name)
		check(int(r.bonus.get("will",0)) == before + 5 and int(a.state.personal_arcs[row.id]) == 3, "lasting perk: " + row.name)
		var lost = Campaign.new()
		var dead: Dictionary = Arcs.person(lost.state,row.name)
		dead.status = "dead"
		Arcs.check_losses(lost.state,[row])
		check(int(lost.state.personal_arcs[row.id]) == -1 and lost.state.memorials.size() == 1, "death closes and memorializes: " + row.name)
	var fixture = Campaign.new()
	fixture.state.flags[callbacks[0].flag] = true
	fixture.state.personal_arcs[arcs[0].id] = 1
	Arcs.person(fixture.state,arcs[1].name).status = "dead"
	var record: Dictionary = Story.new(fixture.state).journal(fixture.state)
	check(record.choices.size() == 1 and record.choices[0].contains(callbacks[0].text), "journal choice")
	check(record.arcs.any(func(line): return line.contains(arcs[0].name)), "journal active arc")
	check(record.fallen.any(func(line): return line.contains(arcs[1].name)), "journal memorial")
	for era in [1,2]:
		var interlude: Dictionary = Story.new(fixture.state).era_interlude(fixture.state,era)
		check(interlude.text.contains(callbacks[0].text) and interlude.choices.size() == 1, "era recap: " + str(era))
	var old = Campaign.new()
	old.state.erase("personal_arcs")
	old.state.erase("memorials")
	old.state.erase("callback_seen")
	old.state.erase("callback_rewarded")
	var path := "user://night1-old-save.json"
	check(old.save(path), "old fixture saved")
	var loaded = Campaign.new()
	check(loaded.load_save(path), "old fixture loaded")
	check(loaded.state.personal_arcs is Dictionary and loaded.state.memorials is Array and loaded.state.callback_seen is Dictionary and loaded.state.callback_rewarded is Dictionary, "old save fields default")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("NIGHT1 STORY TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
