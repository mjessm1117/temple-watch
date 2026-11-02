extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Queue = preload("res://scripts/campaign/research_queue.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("GEAR RESEARCH: " + message)

func run() -> void:
	var c = Campaign.new()
	c.state.wings.archives = 2; c.state.wings.forge = 2; c.state.wings.armory = 2
	c.state.facility.relay = 4
	c.state.era = 3; c.state.elapsed_days = 240
	c.state.res.credits = 100000; c.state.res.intel = 1000; c.state.res.kyber = 1000
	var projects: Dictionary = Data.get_table("research", "RESEARCH")
	check(projects.size() >= 34 and projects.size() <= 38, "research tree has about 35 studies")
	var listed := []
	for branch in Data.get_table("research", "RES_TREE"):
		for id in branch.ids:
			check(projects.has(id) and id not in listed, "branch references a unique project: " + str(id))
			listed.append(id)
	check(listed.size() == projects.size(), "every project is visible in a branch")
	check(not c.start_research("gunMk3"), "unmet prerequisites block direct study")
	check(not Queue.can_queue(c, "gunMk3"), "unmet prerequisites block queue")
	var pending: Array = projects.keys()
	while not pending.is_empty():
		var progress := false
		for id in pending.duplicate():
			var p: Dictionary = projects[id]
			var ready := true
			for need in p.get("need", []):
				if not c.researched(str(need)): ready = false
			if not ready: continue
			check(c.start_research(str(id)), "start " + str(id))
			c._tick_research(int(p.days) + 1)
			check(c.researched(str(id)) and str(c.state.research.cur) == "", "complete " + str(id))
			pending.erase(id); progress = true
		check(progress, "dependency graph has no dead ends")
		if not progress: break
	check(c.state.research.done.size() == projects.size(), "all studies complete")
	var troop_id := "u3"
	var jedi_id := "u1"
	var troop: Dictionary = c.soldier(troop_id)
	var jedi: Dictionary = c.soldier(jedi_id)
	check(Gear.buy_weapon(c, troop_id), "weapon style line reachable")
	check(Gear.craft_saber(c, jedi_id), "saber style line reachable")
	for tier in [2, 3]:
		var before: Dictionary = Gear.battle_stats(c, troop_id)
		check(Gear.upgrade_base(c, troop_id, "w"), "weapon Mk %d purchasable" % tier)
		var after: Dictionary = Gear.battle_stats(c, troop_id)
		check(int(after.dmg[0]) > int(before.dmg[0]) and Gear.slots(troop, "w") >= 5, "weapon mark applies damage alongside style slots")
		before = Gear.battle_stats(c, jedi_id)
		check(Gear.upgrade_base(c, jedi_id, "s"), "saber Mk %d craftable" % tier)
		after = Gear.battle_stats(c, jedi_id)
		check(int(after.dmg[0]) > int(before.dmg[0]) and Gear.slots(jedi, "s") >= 5, "saber mark applies damage alongside style slots")
	for key in Data.get_table("gear", "ARMOR"):
		var item: Dictionary = Data.get_table("gear", "ARMOR")[key]
		if key == "none": continue
		var id := jedi_id if item.who == "jedi" else troop_id
		var r: Dictionary = c.soldier(id)
		if str(r.gear.armor) != key: check(Gear.buy_armor(c, id, str(key)), "armor line reachable: " + str(key))
		var hp := int(Gear.battle_stats(c, id).hp)
		check(Gear.upgrade_armor(c, id), "armor Mk II " + str(key))
		check(int(Gear.battle_stats(c, id).hp) > hp, "armor Mk II HP payoff " + str(key))
		check(Gear.upgrade_armor(c, id), "armor Mk III " + str(key))
		check(int(Gear.battle_stats(c, id).armor) > int(item.get("mod", {}).get("armor", 0)), "armor Mk III protection " + str(key))
	for kind in Gear.MOD_KEY:
		var id := jedi_id if kind == "s" else troop_id
		var pool: Dictionary = Data.get_table("gear", Gear.POOL_KEY[kind])
		for key in pool:
			c.soldier(id).gear[Gear.MOD_KEY[kind]] = []
			var before: String = JSON.stringify(Gear.battle_stats(c, id))
			check(Gear.fit_module(c, id, kind, str(key)), "fit module " + kind + "." + str(key))
			var first: String = JSON.stringify(Gear.battle_stats(c, id))
			check(first != before, "module Mk I applies stats " + str(key))
			check(Gear.upgrade_module(c, id, kind, str(key)), "module Mk II " + str(key))
			var second: String = JSON.stringify(Gear.battle_stats(c, id))
			check(second != first, "module Mk II applies stats " + str(key))
			check(Gear.upgrade_module(c, id, kind, str(key)), "module Mk III " + str(key))
			check(JSON.stringify(Gear.battle_stats(c, id)) != second, "module Mk III applies stats " + str(key))
			check(int(c.soldier(id).gear.mk[kind + "." + str(key)]) == 3, "module mark stored " + str(key))
	var path := "user://gear-research-test.json"
	check(c.save(path), "save completed research and marks")
	var loaded = Campaign.new()
	check(loaded.load_save(path), "reload completed research and marks")
	check(loaded.state.research.done.size() == projects.size(), "completed research survives load")
	check(int(loaded.soldier(troop_id).gear.mk.get("armor:" + str(troop.gear.armor), 0)) == 3, "armor mark survives load")
	check(int(loaded.soldier(troop_id).gear.mk.w) == 3 and int(loaded.soldier(jedi_id).gear.mk.s) == 3, "weapon and saber marks survive load")
	var old: Dictionary = loaded.state.duplicate(true)
	old.research.erase("queue"); old.research.erase("last")
	for r in old.roster: r.gear.mk.erase("armor:" + str(r.gear.armor))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"v":2, "C":old})); file.close()
	var migrated = Campaign.new()
	check(migrated.load_save(path), "old save loads")
	check(migrated.state.research.queue.is_empty() and migrated.state.research.last == "", "research queue migrates")
	check(Gear.battle_stats(migrated, troop_id).has("hp"), "missing armor mark defaults to Mk I")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var queue_c = Campaign.new()
	queue_c.state.wings.archives = 1; queue_c.state.facility.relay = 4
	queue_c.state.res.credits = 1000
	check(Queue.enqueue(queue_c, "eliteMods"), "root project queues")
	check(Queue.enqueue(queue_c, "gunMk2"), "dependent project queues behind active study")
	check(not Queue.enqueue(queue_c, "gunMk3"), "future-era project cannot queue")
	check(queue_c.save(path), "save active research queue")
	var queue_loaded = Campaign.new()
	check(queue_loaded.load_save(path), "load active research queue")
	check(queue_loaded.state.research.cur == "eliteMods" and queue_loaded.state.research.queue == ["gunMk2"], "active and queued studies persist")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(not queue_c.start_research("visors"), "queued order cannot be bypassed")
	queue_c.state.elapsed_days = 75
	queue_c._tick_research(100)
	check(queue_c.researched("eliteMods") and str(queue_c.state.research.cur) == "gunMk2", "queue automatically advances")
	queue_c._tick_research(100)
	check(queue_c.researched("gunMk2"), "queued dependent study completes")
	var cancel_c = Campaign.new()
	cancel_c.state.era = 3; cancel_c.state.elapsed_days = 240
	cancel_c.state.wings.archives = 1; cancel_c.state.facility.relay = 4
	cancel_c.state.res.credits = 1000
	check(Queue.enqueue(cancel_c, "eliteMods"), "cancel fixture starts prerequisite")
	check(Queue.enqueue(cancel_c, "gunMk2") and Queue.enqueue(cancel_c, "gunMk3"), "dependent chain can queue")
	check(Queue.dequeue(cancel_c, "gunMk2"), "queued project can be removed")
	check(cancel_c.state.research.queue.is_empty(), "removing a prerequisite removes its dependent queue entries")
	if "--capture" in OS.get_cmdline_user_args(): await capture_screens()
	print("GEAR RESEARCH TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture_screens() -> void:
	root.size = Vector2i(1366, 768)
	var flow = root.get_node("CampaignFlow")
	var c = Campaign.new()
	c.state.wings.archives = 2; c.state.wings.forge = 2; c.state.wings.armory = 2
	c.state.facility.relay = 4; c.state.era = 3; c.state.elapsed_days = 240
	c.state.res.credits = 10000; c.state.res.intel = 100; c.state.res.kyber = 100
	c.state.research.done = ["eliteMods", "alloys", "kyberLore", "visors"]
	c.state.research.cur = "gunMk2"; c.state.research.prog = 10.0
	c.state.research.queue = ["gunMk3"]
	flow.campaign = c; flow.story = c.story; flow.active = true
	flow.save_path = "user://gear-capture.json"
	var temple = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple); current_scene = temple
	await process_frame; await process_frame
	temple._change_page("Research", "archives")
	await capture("research-tree")
	c._tick_research(20); temple._refresh_shell()
	await capture("research-unlocked")
	c.state.research.last = ""; c.state.research.done = Data.get_table("research", "RESEARCH").keys()
	c.state.research.cur = ""; c.state.research.queue = []
	temple.selected_id = "u3"
	temple.temple_view.activate_room("forge")
	await process_frame
	await capture("forge-before")
	var forge_panel = temple.page_content.find_child("Wave10Forge", true, false)
	check(forge_panel != null, "Forge upgrade panel appears in the Temple")
	if forge_panel != null:
		for button in forge_panel.find_children("*", "Button", true, false):
			if button.text == "Forge Weapon Mk II": button.pressed.emit(); break
	check(int(c.soldier("u3").gear.mk.w) == 2, "rendered Forge button upgrades the weapon")
	await process_frame
	await capture("forge-after")
	temple.queue_free(); current_scene = null
	await process_frame
	for r in c.state.roster:
		r.gear.mk.w = 3; r.gear.mk.s = 3
		r.gear.mk["armor:" + str(r.gear.armor)] = 3
	var squad = load("res://scenes/squad.tscn").instantiate()
	root.add_child(squad); current_scene = squad
	await process_frame; await process_frame
	squad.inspect(0); squad._tab("arsenal")
	await capture("loadout-mkiii")
	squad.queue_free(); current_scene = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))

func capture(label: String) -> void:
	print("CAPTURE ", label)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/shots/wave10-gear-%s.png" % label
	check(root.get_texture().get_image().save_png(path) == OK, "screenshot " + label)
