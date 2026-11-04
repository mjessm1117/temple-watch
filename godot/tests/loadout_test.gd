extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Details = preload("res://scripts/campaign/loadout_details.gd")
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("LOADOUT: " + message)

func run() -> void:
	root.size = Vector2i(1366, 768)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://loadout-test.json"; flow.campaign = Campaign.new(); flow.active = true
	var c = flow.campaign; c.state.launch_index = 0
	var screen = load("res://scenes/squad.tscn").instantiate(); root.add_child(screen)
	await process_frame
	check(screen.selected.size() == 4 and screen.stage.actors.size() == 4, "four selected soldiers have full 3D actors")
	check(screen.portraits.size() == c.state.roster.size(), "every roster soldier has a portrait model")
	for r in c.state.roster:
		check(ResourceLoader.exists(Actor.model_path(r)), "model resolves: " + str(r.cls))
		var actor = screen.portrait_actors[str(r.id)]
		check(actor.model != null and actor.animation != null and actor.animation.is_playing(), "animated portrait: " + str(r.id))
		if r.cls == "Medic": check(actor.model.find_child("Medkit", true, false) != null, "Medic carries medkit")
		if not screen.selected.has(r.id):
			screen.inspect(3); check(screen.swap_soldier(str(r.id)), "roster replacement: " + str(r.id))
		check(screen.cards.has(str(r.id)), "roster soldier receives card: " + str(r.id))
	for cls in preload("res://scripts/campaign/data.gd").get_table("core", "CLASS"):
		check(ResourceLoader.exists(Actor.model_path({"cls":cls})), "fallback model for class: " + str(cls))
	screen.close_inspector()
	await process_frame
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = Vector2(1180, 280)
	root.push_input(click)
	await process_frame
	check(screen.drawer.visible and screen.stage.focused == 3, "clicking a 3D soldier opens panel and focuses camera")
	c.soldier("u5").wound = 8
	check(not screen.swap_soldier("u5"), "wounded soldier cannot replace selected soldier")
	screen._tab("roster")
	check(screen.choices["u5"].disabled, "wounded roster button is disabled")
	check(Details.status(c, c.soldier("u5")).contains("8 days"), "wound recovery time displayed")
	c.soldier("u5").assign = "rest"
	check(Details.status(c, c.soldier("u5")).contains("4 days"), "rest assignment recovery rate displayed")
	c.soldier("u5").wound = 0; c.soldier("u5").assign = "train"
	check(not screen.swap_soldier("u5"), "assigned soldier cannot deploy")
	c.soldier("u5").assign = "field:f1"
	c.state.field.list = [{"st":"team", "team":["u5"], "left":3}]
	check(Details.status(c, c.soldier("u5")).contains("3 days"), "field assignment days displayed")
	c.soldier("u5").assign = ""; c.state.field.list = []
	check(screen.swap_soldier("u5"), "recovered Medic can replace soldier")
	check(c.state.loadout_squad == screen.selected, "selection persists before launch")
	check(not screen.swap_soldier("u1"), "duplicate squad members rejected")
	var before := int(Gear.battle_stats(c, "u5").aim)
	check(screen.change_gear("fit", "w", "scope"), "weapon module fits through Arsenal")
	check(int(Gear.battle_stats(c, "u5").aim) > before, "module applies live aim stats")
	check(screen.cards["u5"].get_child_count() > 0, "live card rebuilt after module purchase")
	var credits := int(c.state.res.credits)
	check(not screen.change_gear("fit", "w", "scope") and int(c.state.res.credits) == credits, "duplicate module costs nothing")
	check(not screen.change_gear("upgrade", "w", "scope"), "Mk upgrade requires research")
	c.state.research.done.append(str(preload("res://scripts/campaign/data.gd").get_table("gear", "MK_RES").w[0]))
	check(screen.change_gear("upgrade", "w", "scope"), "researched Mk II upgrade applies")
	check(Details.modules_text(c.soldier("u5")).contains("Mk II"), "card shows equipped Mk tier")
	check(not screen.change_gear("armor", "", "medium"), "armor wing lock enforced")
	c.state.wings.armory = 2; c.state.res.credits = 2000
	check(screen.change_gear("armor", "", "medium"), "available armor purchase applies")
	check(screen.change_gear("weapon"), "weapon tier applies")
	check(screen.stage.actors[3].weapon_tier == 2 and screen.stage.actors[3].armor_key == "medium", "model equipment tracks new weapon and armor")
	check(screen.change_gear("color", "", "#9fc6d6"), "model tint applies")
	check(screen.stage.actors[3].tint == Color("9fc6d6"), "model reflects saved color immediately")
	check(screen.change_gear("utility", "", "medpac"), "utility purchase applies")
	screen._tab("arsenal")
	check(not screen.arsenal.offers.is_empty(), "Arsenal exposes equipment controls")
	c.state.res.credits = 0; screen._tab("arsenal")
	check(screen.arsenal.offers.any(func(o): return not o.enabled), "unaffordable or locked offers disabled")
	c.state.res.credits = 2000
	check(screen.change_gear("remove", "w", "scope"), "module can be removed without refund")
	check(int(c.state.res.credits) == 2000, "removal never refunds credits")

	screen.inspect(0)
	check(not screen.change_gear("saber"), "saber crafting respects forge lock")
	c.state.wings.forge = 2; c.state.res.kyber = 10
	check(screen.change_gear("saber"), "Jedi saber craft applies")
	check(screen.change_gear("color", "", "#c58cff"), "Jedi crystal palette matches web")
	check(screen.stage.actors[0].saber_light.light_color == Color("c58cff"), "saber glow reflects crystal immediately")
	screen.close_inspector()
	check(not screen.drawer.visible and screen.stage.focused == -1, "close restores lineup")
	await process_frame
	check(screen.deploy.get_global_rect().end.y <= screen.size.y, "launch remains in viewport")
	# Launch through the real CampaignFlow contract, then inspect its battle units.
	var sent: Array = screen.selected.duplicate()
	check(flow.launch_squad(sent), "actual campaign launch accepts replacement squad")
	await process_frame
	check(c.state.pending_mission.squad == sent, "swapped squad reaches pending battle")
	var battle = preload("res://scripts/campaign/battle_bridge.gd").create(c, 8)
	check(battle.living("player").map(func(u): return u.rid) == sent, "battle spawns precisely the selected roster")
	var medic: Dictionary = battle.living("player").filter(func(u): return u.rid == "u5")[0]
	check(medic.kit.has("reviveStim"), "Medic kit matches deployed abilities")
	check(int(medic.armor) == int(Gear.battle_stats(c, "u5").armor), "new armor reaches battle")
	var loaded := Campaign.new(); check(loaded.load_save(flow.save_path), "loadout save loads")
	check(JSON.parse_string(JSON.stringify(loaded.soldier("u5").gear)) == JSON.parse_string(JSON.stringify(c.soldier("u5").gear)), "gear changes survive save/load")
	screen.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("LOADOUT TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
