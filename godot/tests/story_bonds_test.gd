extends SceneTree

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Choices = preload("res://scripts/story/story_choices.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")
const Loss = preload("res://scripts/campaign/bond_story.gd")
const BattleBonds = preload("res://scripts/combat_bonds.gd")
class BondMission:
	extends RefCounted
	var bond_pairs: Dictionary = {}
	var units: Array[Dictionary] = []
	func living(_side: String) -> Array[Dictionary]: return units
	func message(_value: String) -> void: pass
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var c = Campaign.new()
	var story = Story.new(c.state)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/wave10-choices.json")).records
	data.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/story/wave10-talks.json")).records)
	check(data.W10_MID.size() == 8,"eight extra mid-mission scenes")
	check(data.W10_TALKS.size() == 12,"twelve new Temple talks")
	check(data.W10_PAIR_TALKS.size() == 10,"ten bonded pair talks")
	for table_name in ["BASE_MISSIONS","MISSIONS"]:
		for id in story.table(table_name):
			var scene: Dictionary = story.start_briefing(str(id))
			check(scene.choices.size() >= 2,"briefing choices: " + str(id))
			var prior_intel := int(c.state.res.intel)
			check(story.apply_choice(c.state,"brief:0").ok,"briefing resolves: " + str(id))
			check(int(c.state.res.intel) == prior_intel + 1,"briefing consequence: " + str(id))
			var debrief: Dictionary = story.start_debrief({"mission_id":str(id),"won":true})
			check(debrief.choices.size() >= 2,"debrief choices: " + str(id))
			if debrief.choices.size() > 0:
				var first: Dictionary = debrief.choices[0]
				if first.get("need",[]).is_empty(): check(story.apply_choice(c.state,str(first.id)).ok,"debrief resolves: " + str(id))
	for row in data.W10_MID:
		for choice in row.choices:
			var s = Story.new()
			var scene: Dictionary = Choices.mid_scene(s.state,"relay",2,str(row.family),[row])
			s.state.pending = scene
			var before := int(s.state.res.intel) + int(s.state.res.favor)
			var index: int = row.choices.find(choice)
			check(s.apply_choice(s.state,"beat:%d" % index).ok,"mid choice resolves: " + str(row.id))
			check(int(s.state.res.intel) + int(s.state.res.favor) > before,"mid consequence: " + str(row.id))
			check(s.state.get("battle_choice",{}).has("heal" if index == 0 else "aim"),"mid battle effect: " + str(row.id))
	for row in data.W10_TALKS:
		for i in row.choices.size():
			var s = Story.new()
			s.state.era = 2
			var scene := Choices.temple_talk(s.state,[row])
			check(scene.get("id") == row.id,"talk available: " + str(row.id))
			var prior := int(s.state.res.intel) + int(s.state.res.favor)
			check(s.apply_choice(s.state,"talk:%d" % i).ok,"talk resolves: " + str(row.id))
			check(int(s.state.res.intel) + int(s.state.res.favor) == prior + 1,"talk consequence: " + str(row.id))
	for outcome in ["win","lose"]:
		for i in data.W10_DEBRIEF[outcome].size():
			var s = Story.new()
			s.state.pending = {"kind":"debrief","id":"relay","choices":Choices.debrief_choices(data.W10_DEBRIEF,outcome == "win")}
			var prior := int(s.state.res.intel) + int(s.state.res.favor)
			check(s.apply_choice(s.state,"after:%d" % i).ok,"fallback debrief choice resolves")
			check(int(s.state.res.intel) + int(s.state.res.favor) > prior,"fallback debrief consequence applies")
	var jedi: Array = c.state.roster.filter(func(r): return str(r.cls) in ["Guardian","Consular","Sentinel"])
	check(jedi.size() >= 2,"initial Jedi pair")
	if jedi.size() >= 2:
		var a := str(jedi[0].id); var b := str(jedi[1].id)
		check(Legacy.bond_points(c,a,b,8) == 1,"level one at eight cohesion")
		check(Legacy.bond_points(c,a,b,10) == 2,"level two at eighteen cohesion")
		check(Legacy.bond_points(c,a,b,12) == 3,"level three at thirty cohesion")
		var m := BondMission.new()
		m.units = [{"id":1,"rid":a,"class_name":"Guardian","x":4,"y":4,"hp":8,"kit":[],"will":70,"crit":0,"name":"A","ap":1},{"id":2,"rid":b,"class_name":"Consular","x":5,"y":4,"hp":8,"kit":[],"will":70,"crit":0,"name":"B","ap":1}]
		BattleBonds.setup(m,c.state)
		check(int(m.units[0].will) == 75 and int(m.units[0].crit) == 2,"levels two and three unlock battle perks")
		BattleBonds.nearby_cohesion(m)
		check(int(m.bond_pairs[Legacy.bond_key(a,b)].cohesion) == 1,"adjacency gains cohesion")
		BattleBonds.assist(m,m.units[0],m.units[1])
		check(int(m.bond_pairs[Legacy.bond_key(a,b)].cohesion) == 5,"assist gains cohesion")
		var fresh := BondMission.new()
		fresh.units = m.units.duplicate(true)
		BattleBonds.nearby_cohesion(fresh)
		check(int(fresh.bond_pairs.get(Legacy.bond_key(a,b),{}).get("cohesion",0)) == 1,"unbonded Jedi start cohesion nearby")
		for row in data.W10_PAIR_TALKS:
			for i in row.choices.size():
				var pair_story = Story.new(c.state)
				c.state.saga.talked = ""
				var scene := Choices.pair_talk(c.state,[row])
				check(scene.get("id") == row.id,"pair talk unlocks: " + str(row.id))
				var prior_level := int(c.state.bonds[Legacy.bond_key(a,b)].lvl)
				var prior_points := int(c.state.bonds[Legacy.bond_key(a,b)].n)
				check(pair_story.apply_choice(c.state,"talk:%d" % i).ok,"pair choice resolves: " + str(row.id))
				check(int(c.state.bonds[Legacy.bond_key(a,b)].lvl) > prior_level or int(c.state.bonds[Legacy.bond_key(a,b)].n) > prior_points,"pair cohesion applies")
				c.state.saga.seen.erase("pair:" + Legacy.bond_key(a,b) + ":" + str(row.id))
		c.save("user://wave10-bonds.json")
		var loaded = Campaign.new()
		check(loaded.load_save("user://wave10-bonds.json"),"bond save loads")
		check(loaded.state.bonds[Legacy.bond_key(a,b)].lvl >= 3,"bond level persists")
		jedi[0].status = "dead"
		Loss.settle(c,{})
		check(int(jedi[1].bonus.get("will",0)) == -5,"partner loss reduces will")
		check(c.state.story_grief.size() == 1,"partner loss queues Temple beat")
		Loss.settle(c,{})
		check(c.state.story_grief.size() == 1,"loss beat only once")
		var dark_campaign = Campaign.new()
		Legacy.bond_points(dark_campaign,a,b,8)
		dark_campaign.soldier(a).dark = 8
		Loss.settle(dark_campaign,{})
		check(dark_campaign.state.story_grief.size() == 1,"Darkness fall queues Temple beat")
	var old: Dictionary = c.state.duplicate(true)
	old.erase("bonds"); old.erase("story_grief"); old.erase("bond_losses")
	var file := FileAccess.open("user://wave10-old.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"v":2,"C":old})); file.close()
	var migrated = Campaign.new()
	check(migrated.load_save("user://wave10-old.json"),"old save loads")
	check(migrated.state.has("bonds") and migrated.state.has("story_grief") and migrated.state.has("bond_losses"),"old save gains bond fields")
	print("STORY BONDS TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
