extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Rooms = preload("res://scripts/campaign/temple_rooms.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Events = preload("res://scripts/campaign/events11_engine.gd")
const Crisis = preload("res://scripts/campaign/crisis11_engine.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var c = Campaign.new()
	var wings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/temple.json")).BATTLE_BONUS
	check(wings.size() == 8, "eight Temple wings have battle effects")
	for wing in c.state.wings: c.state.wings[wing] = 0
	check(not c.select_mission(0).is_empty(), "mission selected for upgrade audit")
	var unbonused = Battle.create(c, 11)
	check(unbonused != null, "unbonused battle creates")
	var jedi_base: Dictionary = unbonused.living("player")[0]
	var troop_base: Dictionary = unbonused.living("player")[-1]
	for wing in wings:
		for level in range(1, wings[wing].size()):
			var bonus: Dictionary = Rooms.bonus(wing, level)
			check(bonus.size() > 2 and str(bonus.get("text", "")) != "", "%s level %d effect" % [wing, level])
			c.state.wings[wing] = level
			check(Rooms.active(c.state).any(func(row): return row.wing == wing and row.level == level), "%s level %d reaches deployment" % [wing, level])
			var upgraded = Battle.create(c, 11)
			var jedi: Dictionary = upgraded.living("player")[0]
			var troop: Dictionary = upgraded.living("player")[-1]
			var changed := false
			for key in bonus:
				match str(key):
					"hp": changed = changed or int(jedi.max_hp) > int(jedi_base.max_hp)
					"kit": changed = changed or int(jedi.medpacs) > int(jedi_base.medpacs)
					"rookieAim", "aim": changed = changed or int(jedi.aim) > int(jedi_base.aim)
					"troopAim": changed = changed or int(troop.aim) > int(troop_base.aim)
					"jdmg": changed = changed or int(jedi.damage[0]) > int(jedi_base.damage[0])
					"tarmor": changed = changed or int(troop.armor) > int(troop_base.armor)
					"crit": changed = changed or int(jedi.crit) > int(jedi_base.crit)
					"will": changed = changed or int(jedi.will) > int(jedi_base.will)
			check(changed, "%s level %d changes real battle stats" % [wing, level])
			c.state.wings[wing] = 0
	c.state.wings.medical = 1; c.state.wings.barracks = 1
	var baseline = Battle.create(c, 11)
	check(baseline != null, "baseline battle creates")
	var before: Dictionary = baseline.living("player")[0].duplicate(true)
	c.state.wings.training = 1
	var trained = Battle.create(c, 11)
	var after: Dictionary = trained.living("player")[0]
	check(int(after.aim) >= int(before.aim) + 5 or int(after.rank) > 2, "rookie aim reaches actual battle unit")
	c.state.wings.training = 0
	c.state.mods.spire.sp1 = true
	c.state.mods.dug.u0 = true; c.state.mods.features.u0 = "spring"
	check(Rooms.active_descriptions(c.state).size() >= 4, "spire and vault effects reach briefing")
	for room_id in ["sp1", "u0"]:
		var row: Array = Rooms.ROOMS.filter(func(item): return item[0] == room_id)[0]
		check(str(Rooms.describe(row, c.state).battle_plate) != "", "%s effect appears on room plate" % room_id)

	c = Campaign.new()
	check(Events.definitions().EVENTS.size() >= 15, "event deck has at least 15 cards")
	check(Events.threat(c.state, "Taris") == 3 and Events.threat(c.state, "Nar Shaddaa") == 2, "planet threat initializes from galaxy state")
	check(Crisis.definitions().size() == 3, "three crisis definitions")
	for n in 1:
		Events.after_mission(c, {}, {}, true)
	check(c.state.events11.pending == "", "no event after one mission")
	Events.after_mission(c, {}, {}, true)
	check(c.state.events11.pending != "", "event fires after two missions")
	check(Events.choose(c, 0), "event choice resolves")
	var next: int = c.state.events11.next
	for n in range(3, next + 1): Events.after_mission(c, {}, {}, true)
	check(c.state.events11.pending != "", "next event fires on scheduled mission")
	check(Crisis.deadlines(c.state).size() >= 1, "first crisis opens with deadline")
	var active: Dictionary = c.state.crises11.active[0]
	var id: String = active.id
	c.state.res.credits = 1000; c.state.res.intel = 100; c.state.res.favor = 100
	check(Crisis.choose(c, id, 0), "first crisis step resolves")
	check(not Crisis.choose(c, id, 0), "second step waits for next day")
	var path := "user://campaign11-test.json"
	check(c.save(path), "active crisis and event save")
	var mid = Campaign.new()
	check(mid.load_save(path), "active crisis and event load")
	check(mid.state.events11.pending == c.state.events11.pending and int(mid.state.crises11.active[0].stage) == 1, "pending event and crisis stage round trip")
	c.state.elapsed_days = int(c.state.elapsed_days) + 1
	check(Crisis.choose(c, id, 0), "second step wins crisis")
	check(c.state.crises11.done.has(id), "win persists")
	Events.after_mission(c, {}, {}, true)
	Events.after_mission(c, {}, {}, true)
	Events.after_mission(c, {}, {}, true)
	check(c.state.crises11.active.size() >= 1, "second crisis opens")
	var doomed: Dictionary = c.state.crises11.active[0]
	var doomed_id: String = doomed.id
	var old_threat := Events.threat(c.state, str(Crisis.definition(doomed_id).planet))
	c.state.elapsed_days = int(doomed.deadline)
	Crisis.tick(c)
	check(c.state.crises11.done.has(doomed_id) and c.state.crises11.active.is_empty(), "deadline loss persists")
	check(Events.threat(c.state, str(Crisis.definition(doomed_id).planet)) > old_threat, "crisis loss has lasting planetary threat")
	check(c.save(path), "campaign saves event and crisis state")
	var restored = Campaign.new()
	check(restored.load_save(path), "campaign loads event and crisis state")
	check(int(restored.state.events11.missions) == int(c.state.events11.missions) and restored.state.events11.pending == c.state.events11.pending and restored.state.events11.seen == c.state.events11.seen and restored.state.crises11.done == c.state.crises11.done, "events and crises round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if "--capture-campaign" in OS.get_cmdline_user_args(): await capture_ui()
	print("CAMPAIGN11 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture_ui() -> void:
	root.size = Vector2i(1366, 768)
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://campaign11-capture.json"
	var fixture = Campaign.new()
	flow.campaign = fixture; flow.story = fixture.story
	await capture_scene("res://scenes/temple.tscn", "before-temple")
	await capture_scene("res://scenes/galaxy.tscn", "before-galaxy")
	fixture.state.wings.training = 2; fixture.state.wings.archives = 1
	fixture.state.events11.missions = 3
	Events.draw(fixture); Crisis.after_mission(fixture)
	fixture.state.events11.summary = {"month":1,"day":22,"changes":["Credits +90","Intel +2","Taris threat +1"],"pending":fixture.state.events11.pending,"crises":Crisis.deadlines(fixture.state),"shown":true}
	await capture_scene("res://scenes/temple.tscn", "after-temple")
	await capture_scene("res://scenes/galaxy.tscn", "after-galaxy")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))

func capture_scene(path: String, name: String) -> void:
	var scene: Node = load(path).instantiate()
	root.add_child(scene); current_scene = scene
	for i in 5: await process_frame
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	save_shot(name)
	if name == "after-temple":
		scene._change_page("Command")
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		save_shot("after-temple-summary")
	if name == "after-galaxy":
		scene.scroll.scroll_vertical = int(scene.scroll.get_v_scroll_bar().max_value)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		save_shot("after-galaxy-event")
	current_scene = null; scene.queue_free()
	for i in 3: await process_frame

func save_shot(name: String) -> void:
	var image: Image = root.get_texture().get_image()
	check(image.save_png("res://../docs/godot/shots/wave11-campaign-%s.png" % name) == OK, "capture " + name)
