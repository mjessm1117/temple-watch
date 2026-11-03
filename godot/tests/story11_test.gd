extends SceneTree

const Story = preload("res://scripts/story/story_engine.gd")
const Scenes = preload("res://scripts/story/scenes11_squad.gd")
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
	var engine = Story.new()
	var s: Dictionary = engine.state
	var beats: Array = engine.table("W11_VILLAIN")
	var scenes: Array = engine.table("W11_SCENES")
	check(beats.size() == 10, "ten villain beats")
	check(scenes.size() >= 12, "twelve squad scenes")
	var temple = Story.new()
	temple.state.era = 2
	temple.state.roster = temple.data["data-era2"]["ERA2_ROSTER"].duplicate(true)
	for i in temple.state.roster.size():
		temple.state.roster[i].id = "e2_%d" % i
		temple.state.roster[i].status = "active"
	check(temple.next_temple_talk(temple.state).get("kind","") == "scene11", "squad scene appears through Temple story path")
	for row in beats:
		s.era = int(row.era)
		s.story.done = int(row.done)
		if row.has("flag"): s.flags[row.flag] = true
		if row.has("flags_any"): s.flags[row.flags_any[0]] = true
		var beat: Dictionary = engine.next_villain_beat(s)
		check(beat.get("id","") == row.id and beat.get("name","") == row.speaker, "reachable beat " + row.id)
		check(engine.apply_choice(s,"villain:light").ok, "answered beat " + row.id)
	check(s.villain11_seen.size() == beats.size(), "all beats recorded")
	check(int(s.villain11_answers.light) == beats.size(), "light answers counted")
	var reaction: Dictionary = beats[3]
	var light = Story.new()
	light.state.era = 2; light.state.story.done = int(reaction.done)
	light.state.villain11_seen.append("v03")
	var text_light: String = light.next_villain_beat(light.state).text
	var dark = Story.new()
	dark.state.era = 2; dark.state.story.done = int(reaction.done); dark.state.orderDark = 25
	dark.state.villain11_seen.append("v03")
	var text_dark: String = dark.next_villain_beat(dark.state).text
	check(text_light != text_dark, "Darkness changes transmission")
	var lost = Story.new()
	lost.state.era = 2; lost.state.story.done = int(reaction.done); lost.state.memorials.append("Kira Venn died before her watch ended.")
	lost.state.villain11_seen.append("v03")
	var death_text: String = lost.next_villain_beat(lost.state).text
	check(death_text != text_light and death_text.contains("Kira Venn"), "named death changes transmission")
	var arc = Story.new()
	arc.state.era = 2; arc.state.story.done = int(reaction.done); arc.state.personal_arcs.arc_0 = 3
	arc.state.villain11_seen.append("v03")
	check(arc.next_villain_beat(arc.state).text != text_light, "arc choice changes transmission")
	var bomb_loss = Story.new()
	bomb_loss.state.era = 2; bomb_loss.state.story.done = 6; bomb_loss.state.flags.e2_bomb_fired = true
	bomb_loss.state.villain11_seen = ["v03","v04","v05","v06","v07"]
	check(bomb_loss.next_villain_beat(bomb_loss.state).text.contains("bomb fired"), "Bane's turn follows a lost Ruusan finale")
	for id in ["r_caves","r_seventh","r_bomb"]:
		var brief: Dictionary = engine.start_briefing(id)
		check(brief.get("villain_present",false) and not str(brief.get("villain_start_bark","")).is_empty() and not str(brief.get("villain_end_bark","")).is_empty(), "rival battle data " + id)
		var pending := {"mission_id":id}
		preload("res://scripts/story/villain11_arc.gd").attach_battle(s,pending)
		check(pending.get("villain_present",false) and pending.get("villain_name","") == brief.villain_name, "rival flag reaches pending battle " + id)
	for row in scenes:
		s.era = int(row.era); s.story.done = int(row.done); s.step += 1
		if int(s.era) == 1:
			s.roster = Story.new().state.roster
		else: s.roster = engine.data["data-era%d" % int(s.era)]["ERA%d_ROSTER" % int(s.era)].duplicate(true)
		for i in s.roster.size():
			s.roster[i].id = "e%d_%d" % [int(s.era),i]
			s.roster[i].status = "active"
		if int(row.bond) > 0:
			var a := str(s.roster[int(row.members[0])].id)
			var b := str(s.roster[int(row.members[1])].id)
			s.bonds[Scenes._pair(a,b)] = {"lvl":1,"n":0,"dr":[]}
		var scene: Dictionary = Scenes.next(s,[row])
		check(scene.get("id","") == row.id and scene.text.split("\n").size() >= 3, "squad scene unlock " + row.id)
		var bond_before := int(s.bonds.get(scene.get("pair",""),{}).get("n",0))
		check(engine.apply_choice(s,str(scene.choices[0].id)).ok, "squad scene choice " + row.id)
		check(int(s.bonds.get(scene.get("pair",""),{}).get("n",0)) != bond_before, "squad choice shifts bond " + row.id)
	check(engine.journal(s).squad.size() == scenes.size(), "squad scenes in Journal")
	check(engine.journal(s).villain.size() == beats.size(), "villain beats in Journal")
	var ending_light := {"id":"h_beacon","text":"Beacon holds"}
	s.era = 3; s.orderDark = 0; s.story.shadow = 3
	preload("res://scripts/story/villain11_arc.gd").debrief(s,ending_light)
	var ending_dark := {"id":"h_beacon","text":"Beacon holds"}
	s.orderDark = 25; s.villain11_answers = {"light":1,"dark":9}
	preload("res://scripts/story/villain11_arc.gd").debrief(s,ending_dark)
	check(ending_light.text != ending_dark.text and ending_dark.text.contains("Bane"), "finale varies by Darkness and answers")
	var ending_answers := {"id":"h_beacon","text":"Beacon holds"}
	s.orderDark = 0
	preload("res://scripts/story/villain11_arc.gd").debrief(s,ending_answers)
	check(ending_light.text != ending_answers.text and ending_answers.text.contains("Bane"), "finale varies by answers at same Darkness")
	var ending_darkness := {"id":"h_beacon","text":"Beacon holds"}
	s.villain11_answers = {"light":10,"dark":0}; s.orderDark = 25
	preload("res://scripts/story/villain11_arc.gd").debrief(s,ending_darkness)
	check(ending_light.text != ending_darkness.text and ending_darkness.text.contains("fear"), "finale varies by Darkness at same answers")
	print("Story11: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
