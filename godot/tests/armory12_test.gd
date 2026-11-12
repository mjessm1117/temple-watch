extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Preview = preload("res://scripts/campaign/armory12_preview.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("ARMORY12: " + message)

func slots_inside(screen: Control, label: String) -> void:
	var viewport := Rect2(Vector2.ZERO, screen.size)
	for tile in screen.arsenal.slot_row.get_children():
		check(viewport.encloses(tile.get_global_rect()), "%s slot %s stays inside viewport" % [label, tile.name])

func deltas_inside(screen: Control, label: String) -> void:
	var found := 0
	for offer in screen.arsenal.offers:
		if not offer.card.visible: continue
		var row: Control = offer.card.find_child("Deltas", true, false)
		if row == null: continue
		for delta in row.get_children():
			found += 1
			check(offer.card.get_global_rect().encloses(delta.get_global_rect()), "%s picker delta stays inside card" % label)
	check(found > 0, "%s picker exposes stat deltas" % label)

func roster_inside(screen: Control, label: String) -> void:
	for card in screen.cards.values():
		check(screen.card_scroll.get_global_rect().encloses(card.get_global_rect()), "%s roster card %s stays visible" % [label, card.name])

func run() -> void:
	root.size = Vector2i(1366, 768)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory12-test.json"; flow.campaign = Campaign.new(); flow.active = true
	var screen = load("res://scenes/squad.tscn").instantiate(); root.add_child(screen)
	await process_frame
	screen.inspect(0)
	check(screen.stage_container.visible and screen.stage.focused == 0, "selected Jedi stays on 3D stage")
	check(screen.stage.actors[0].visible and absf(screen.stage.actors[0].position.x) < 0.01 and not screen.stage.actors[1].visible, "selected actor stands alone at stage center")
	slots_inside(screen, "desktop")
	roster_inside(screen, "desktop")
	screen.arsenal._select_slot("weapon")
	await process_frame
	var desktop_upgrade: Dictionary = screen.arsenal.offers.filter(func(o): return o.action == "base_mark")[0]
	var desktop_delta: Control = desktop_upgrade.card.find_child("Deltas", true, false)
	check(screen.drawer.get_global_rect().encloses(desktop_delta.get_global_rect()), "desktop upgrade deltas remain in inspector")
	screen.arsenal._select_slot("armor")
	await process_frame
	deltas_inside(screen, "desktop")
	check(screen.cards.size() == screen.selected.size(), "all squad portrait cards remain visible")
	check(screen.arsenal.slot_row.get_child_count() >= 7, "gear slots expose saber, armor, utility and modules")
	check(screen.arsenal.offers.any(func(o): return o.action == "saber"), "saber picker has craft offer")
	check(screen.arsenal.offers.any(func(o): return o.action == "armor" and not o.enabled), "locked armor explains research")
	check(screen.arsenal.offers.any(func(o): return o.action == "base_mark"), "tier upgrade is offered")
	var jedi = flow.campaign.soldier(str(screen.selected[0]))
	var before_gear: Dictionary = jedi.gear.duplicate(true)
	var had_evo: bool = jedi.has("evo")
	var change: Array = Preview.changes(flow.campaign, str(jedi.id), "armor", "", "armoredRobes")
	check(change.any(func(x): return x.name == "armor" and x.value > 0), "picker shows a real green armor stat gain")
	check(jedi.gear == before_gear, "preview leaves equipment untouched")
	check(jedi.has("evo") == had_evo, "preview leaves promotion state untouched")
	var preview_rank := int(jedi.rank)
	jedi.rank = 3
	var form_change: Array = Preview.changes(flow.campaign, str(jedi.id), "form", "", "soresu")
	jedi.rank = preview_rank
	check(form_change.any(func(x): return x.value < 0 or int(x.get("high", 0)) < 0), "form picker shows red tradeoff")
	screen.arsenal._select_slot("armor")
	check(screen.arsenal.offers.any(func(o): return o.slot == "armor" and o.card.visible), "slot tap opens only armor cards")
	check(screen.arsenal.offers.all(func(o): return o.card.visible == (o.slot == "armor")), "other picker cards are hidden")
	check(screen.change_gear("armor", "", "none") and screen.arsenal.active_slot == "armor", "equipping keeps the chosen slot open")
	var troop_id := str(screen.selected[2])
	var troop = flow.campaign.soldier(troop_id)
	troop.rank = 2; troop.picks = []
	screen.inspect(2); screen.arsenal._show_skills()
	check(screen.stage.actors[2].visible and absf(screen.stage.actors[2].position.x) < 0.01 and not screen.stage.actors[0].visible, "selection moves the center actor")
	check(screen.arsenal.picker.get_node_or_null("SkillTree") != null, "rank choices appear as a skill tree")
	var options: Array = Progression.tree_options(troop, Progression.pending_rank(troop))
	check(not options.is_empty(), "trooper has a pending promotion choice")
	screen.arsenal._choose_skill(str(options[0]))
	check(troop.picks.has(options[0]), "one tap selects and saves a real skill")
	check(Progression.pending_rank(troop) != 1, "selected rank is no longer pending")
	root.size = Vector2i(844, 390)
	await process_frame
	screen.inspect(0)
	await process_frame
	slots_inside(screen, "phone")
	roster_inside(screen, "phone")
	screen.arsenal._select_slot("weapon")
	await process_frame
	var phone_upgrade: Dictionary = screen.arsenal.offers.filter(func(o): return o.action == "base_mark")[0]
	var phone_delta: Control = phone_upgrade.card.find_child("Deltas", true, false)
	check(screen.drawer.get_global_rect().encloses(phone_delta.get_global_rect()), "phone upgrade deltas remain in inspector")
	screen.arsenal._select_slot("armor")
	await process_frame
	deltas_inside(screen, "phone")
	check(screen.stage.actors[0].visible and absf(screen.stage.actors[0].position.x) < 0.01 and not screen.stage.actors[1].visible, "phone selection centers selected actor")
	check(screen.stage_container.visible and screen.stage_container.size.y >= 200, "phone keeps actor visible")
	check(screen.drawer.get_global_rect().end.x <= screen.size.x and screen.drawer.get_global_rect().end.y <= screen.size.y, "phone picker fits screen")
	check(screen.card_scroll.visible and screen.card_scroll.get_global_rect().end.y <= screen.size.y, "phone squad cards fit screen")
	check(screen.arsenal.slot_row.get_child(0).custom_minimum_size.y >= 44, "phone gear targets are at least 44 px")
	check(screen.arsenal.offers.all(func(o): return o.button.custom_minimum_size.y >= 44), "phone item targets are at least 44 px")
	screen.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("ARMORY12 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
