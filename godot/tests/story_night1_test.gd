extends SceneTree

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Callbacks = preload("res://scripts/story/callbacks_night1.gd")
const Arcs = preload("res://scripts/story/arc_night1.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
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
	var reward_signatures: Array[String] = []
	for row in arcs:
		var a = Campaign.new()
		var e = Story.new(a.state)
		check(Arcs.next_talk(a.state,[row]).is_empty(), "talk closed before first mission: " + row.name)
		a.state.story.done = 1
		var first: Dictionary = Arcs.next_talk(a.state,[row])
		check(first.get("kind") == "arc_talk", "step one talk: " + row.name)
		check(e.apply_choice(a.state,"arc:0").ok, "step one resolves: " + row.name)
		var brief := {"kind":"briefing","id":"relay","text":"Mission"}
		Arcs.briefing(a.state,brief,[row])
		check(brief.text == "Mission" and int(a.state.personal_arcs[row.id]) == 1, "briefing closed at mission one: " + row.name)
		a.state.story.done = 2
		Arcs.briefing(a.state,brief,[row])
		check(brief.text == "Mission" and int(a.state.personal_arcs[row.id]) == 1, "briefing closed at mission two: " + row.name)
		a.state.story.done = 3
		Arcs.briefing(a.state,brief,[row])
		check(brief.text.contains(row.brief) and int(a.state.personal_arcs[row.id]) == 2, "step two at mission three: " + row.name)
		a.state.story.done = 5
		check(Arcs.next_talk(a.state,[row]).is_empty(), "resolution closed before mission six: " + row.name)
		a.state.story.done = 6
		var last: Dictionary = Arcs.next_talk(a.state,[row])
		check(last.get("kind") == "arc_resolution" and last.choices.size() == 2, "step three choice: " + row.name)
		for index in 2:
			var reward: Dictionary = row.choices[index]
			check(last.choices[index].effect == reward.effect and not reward.effect.is_empty(), "resolution effect text: " + row.name)
			var branch = Campaign.new()
			var engine = Story.new(branch.state)
			branch.state.story.done = 6
			branch.state.personal_arcs[row.id] = 2
			var member: Dictionary = Arcs.person(branch.state,row.name)
			member.dark = 2
			var old_bonus: Dictionary = member.bonus.duplicate(true)
			var old_res: Dictionary = branch.state.res.duplicate(true)
			var old_stats: Dictionary = Gear.battle_stats(branch, str(member.id))
			Arcs.next_talk(branch.state,[row])
			check(engine.apply_choice(branch.state,"arc:%d" % index).ok, "resolution applies: " + row.name)
			for key in reward.get("bonus",{}): check(int(member.bonus.get(key,0)) == int(old_bonus.get(key,0)) + int(reward.bonus[key]), "bonus applies: " + row.name + " " + key)
			var new_stats: Dictionary = Gear.battle_stats(branch, str(member.id))
			for key in reward.get("bonus",{}): check(int(new_stats.get(key,0)) == int(old_stats.get(key,0)) + int(reward.bonus[key]), "battle stat applies: " + row.name + " " + key)
			for key in reward.get("res",{}): check(int(branch.state.res[key]) == mini(100, int(old_res[key]) + int(reward.res[key])) if key == "favor" else int(branch.state.res[key]) == int(old_res[key]) + int(reward.res[key]), "resource applies: " + row.name + " " + key)
			check(int(member.dark) == 2 + int(reward.get("dark",0)) and int(branch.state.personal_arcs[row.id]) == 3, "darkness and completion: " + row.name)
			var signature := JSON.stringify({"bonus":reward.get("bonus",{}),"dark":reward.get("dark",0),"res":reward.get("res",{})})
			check(not reward_signatures.has(signature), "reward differs across arcs: " + row.name)
			reward_signatures.append(signature)
		var bonded = Campaign.new()
		bonded.state.story.done = 1
		bonded.state.personal_arcs[row.id] = 1
		bonded.state.bonds["u1|u2"] = {"lvl":1}
		var bond_brief := {"text":"Mission"}
		Arcs.briefing(bonded.state,bond_brief,[row])
		check(int(bonded.state.personal_arcs[row.id]) == 2 and bond_brief.text.contains(row.brief), "bond opens briefing: " + row.name)
		check(Arcs.next_talk(bonded.state,[row]).is_empty(), "bond does not open resolution: " + row.name)
		bonded.state.era = 2
		check(Arcs.next_talk(bonded.state,[row]).get("kind") == "arc_resolution", "era two opens resolution: " + row.name)
		var lost = Campaign.new()
		var dead: Dictionary = Arcs.person(lost.state,row.name)
		lost.state.personal_arcs[row.id] = 2
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
	check(record.arcs.any(func(line): return line.contains("After 3 more missions")), "journal resolution hint")
	fixture.state.story.done = 1
	var progressed_record: Dictionary = Story.new(fixture.state).journal(fixture.state)
	check(progressed_record.arcs.any(func(line): return line.contains("After 2 more missions")), "journal briefing hint")
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
	var mid = Campaign.new()
	mid.state.personal_arcs[arcs[0].id] = 1
	mid.state.personal_arcs[arcs[1].id] = 2
	var mid_path := "user://night1-mid-save.json"
	check(mid.save(mid_path), "mid-arc fixture saved")
	var mid_loaded = Campaign.new()
	check(mid_loaded.load_save(mid_path), "mid-arc fixture loaded")
	check(int(mid_loaded.state.personal_arcs[arcs[0].id]) == 1 and int(mid_loaded.state.personal_arcs[arcs[1].id]) == 2, "mid-arc steps preserved")
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://night1-era-transition.json"
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	flow.active = true
	var transition: Dictionary = flow.campaign.state
	transition.flags.boss_or_won = true
	transition.story.done = 2
	for i in 3: transition.personal_arcs[arcs[i].id] = 2
	Arcs.person(transition, arcs[2].name).status = "dead"
	var first_member: Dictionary = Arcs.person(transition, arcs[0].name)
	var second_member: Dictionary = Arcs.person(transition, arcs[1].name)
	var first_bonus: Dictionary = first_member.bonus.duplicate(true)
	var second_bonus: Dictionary = second_member.bonus.duplicate(true)
	flow.advance_era()
	await process_frame
	await process_frame
	check(transition.era == 1 and flow.screen.get("kind") == "arc_resolution" and flow.screen.get("id") == arcs[0].id and transition.flow_stage == "arc_transition", "first era resolution precedes roster swap")
	check(current_scene.scene_file_path.ends_with("dialogue.tscn") and current_scene.scene_data.get("id") == arcs[0].id, "first resolution appears in dialogue")
	check(transition.memorials.size() == 1 and int(transition.personal_arcs[arcs[2].id]) == -1, "fallen arc memorialized during transition")
	flow.continue_campaign()
	await process_frame
	await process_frame
	transition = flow.campaign.state
	check(flow.screen.get("id") == arcs[0].id and flow.screen_return == "era_transition" and transition.era == 1, "pending resolution resumes from save")
	first_member = Arcs.person(transition, arcs[0].name)
	second_member = Arcs.person(transition, arcs[1].name)
	check(flow.story.apply_choice(transition, "arc:0").ok, "first transition choice applies")
	for key in arcs[0].choices[0].get("bonus", {}): check(int(first_member.bonus.get(key, 0)) == int(first_bonus.get(key, 0)) + int(arcs[0].choices[0].bonus[key]), "first transition reward lands: " + key)
	flow.story_finished()
	await process_frame
	await process_frame
	check(transition.era == 1 and flow.screen.get("id") == arcs[1].id and flow.screen.get("kind") == "arc_resolution", "second resolution precedes roster swap")
	check(current_scene.scene_data.get("id") == arcs[1].id, "second resolution appears in dialogue")
	check(flow.story.apply_choice(transition, "arc:1").ok, "second transition choice applies")
	for key in arcs[1].choices[1].get("bonus", {}): check(int(second_member.bonus.get(key, 0)) == int(second_bonus.get(key, 0)) + int(arcs[1].choices[1].bonus[key]), "second transition reward lands: " + key)
	check(int(transition.personal_arcs[arcs[0].id]) == 3 and int(transition.personal_arcs[arcs[1].id]) == 3, "transition arcs complete before swap")
	flow.story_finished()
	await process_frame
	await process_frame
	check(transition.era == 2 and flow.screen.get("kind") == "interlude" and transition.flow_stage == "interlude", "era interlude follows resolutions")
	check(current_scene.scene_data.get("kind") == "interlude", "interlude appears in dialogue")
	check(transition.memorials.size() == 1, "memorial survives era transition")
	flow.story.apply_choice(transition, "interlude:0")
	flow.story_finished()
	check(transition.flow_stage == "temple", "interlude returns to temple")
	flow.active = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(mid_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("NIGHT1 STORY TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
