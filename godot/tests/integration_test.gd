extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func frames() -> void:
	for i in 4: await process_frame

func run() -> void:
	preload("res://tests/integration_rules.gd").new().run(check)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://wave7-integration-test.json"
	flow.campaign = Campaign.new("normal"); flow.story = Story.new(flow.campaign.state); flow.active = true
	var host := Control.new(); root.add_child(host); current_scene = host
	var c = flow.campaign
	check(c.sith != null and c.sith.s.day == 0 and c.sith.s.segments == 2,"new campaign binds Sith state")
	c.advance_days(30)
	check(c.state.month == 2 and c.sith.s.day == 30 and c.sith.s.reports.size() == 1,"day tick fires exactly one monthly report")
	check(flow.show_sith_events(),"Temple event route opens the Council Report")
	check(is_instance_valid(flow.intelligence) and flow.intelligence.page == "report" and is_same(flow.intelligence.layer.state,c.state),"Council Report uses live campaign")
	flow.intelligence.queue_free(); await frames()
	flow.go("galaxy"); await frames()
	var galaxy = current_scene
	check(galaxy.campaign == c and "Sith Darkness" in galaxy.status.text and "Order Darkness" in galaxy.status.text,"galaxy shows both distinct Darkness values")
	flow.open_intelligence()
	var offer: Dictionary = {}
	for o in c.state.options:
		if o.get("kind","") == "counter": offer = o; break
	check(not offer.is_empty(),"galaxy has a counterable Dark Event")
	flow.intelligence._choose(str(offer.sith_offer_id)); await frames()
	check(current_scene.scene_file_path.ends_with("briefing.tscn") and c.state.launch_option.sith_offer_id == offer.sith_offer_id,"counter action routes through real mission briefing")
	check(c.sith.s.counters.get(str(int(c.sith.s.month)),"") == offer.sith_offer_id,"counter choice reserves exactly that event")
	# Fixture: unlocked squad doctrine. Unlock economics have strategy_test coverage.
	c.state.strategy.squad_upgrades = 1
	var project_index := -1
	for i in c.state.options.size():
		if c.state.options[i].get("kind","") == "project":
			project_index = i
			c.sith.s.missions[c.state.options[i].sith_offer_id].map_variant = 0
	c.refresh_options()
	flow.prepare_briefing(project_index); await frames()
	flow.story_finished(); await frames()
	var ids: Array = c.default_squad()
	check(ids.size() == 5 and current_scene.scene_file_path.ends_with("squad.tscn"),"five soldiers reach real loadout")
	check(flow.launch_squad(ids),"real launch accepts five soldiers")
	await frames()
	var game = current_scene
	var m = game.mission
	check(m.living("player").size() == 5 and m.combat_initialized,"battle bridge creates five combat soldiers")
	var positions := {}
	for u in m.living("player"): positions[Shot.pos(u)] = true
	check(positions.size() == 5,"all five spawns are distinct")
	check(game.terrain.get_child(0).get_script().resource_path.ends_with("map_presentation.gd"),"battle uses the mission map renderer")
	check(m.squad_concealed and m.spec.family == "sabotage","mission concealment and family survive adoption")
	# Position fixture isolates the UI -> Interact -> mission boundary from bot strategy.
	var actor: Dictionary = m.living("player")[0]
	for target in m.interactables().slice(0,2):
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var near: Vector2i = target+d
			if m.passable(near) and not m.occupied(near,int(actor.id)):
				actor.x = near.x; actor.y = near.y; break
		actor.ap = 2; game.selected_id = int(actor.id)
		game._choose_action("interact")
		await game._use_ability(-1,target)
		check(int(actor.ap) == 1,"live Interact consumes exactly one AP")
	check(m.objective_state.phase == "evac" and m.objective_state.done.size() == 2,"Interact completes the sabotage objective in a real battle")
	check(not m.squad_concealed and not "MIRA" in game.objective_label.text,"interaction reveals squad and updates family HUD")
	check(not m.pressure_state.pending.is_empty() and int(m.pressure_state.pending[0].turn) > m.turn,"evac reinforcements announced a turn ahead")
	var old_day := int(c.state.elapsed_days)
	var saved: bool = c.save(flow.save_path)
	var restored = Campaign.new(); restored.load_save(flow.save_path)
	check(saved and restored.sith.s.day == old_day and restored.state.pending_mission.squad.size() == 5,"save roundtrip preserves Sith clock and deployment")
	var legacy: Dictionary = c.state.duplicate(true); legacy.erase("sith")
	restored.state = legacy; restored._migrate()
	check(restored.sith != null and restored.sith.s.day == old_day,"old saves acquire date-aligned Sith defaults")
	flow.active = false; current_scene = null; game.queue_free(); await frames()
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("INTEGRATION TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
