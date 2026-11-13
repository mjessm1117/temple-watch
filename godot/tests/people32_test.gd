extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Details = preload("res://scripts/campaign/loadout_details.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Squad = preload("res://scripts/campaign/squad.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0
const VIEW := Vector2i(390, 844)
const TIERS := {"jedi":["Padawan", "Knight", "Master", "Council Master", "Grand Master"], "soldier":["Recruit", "Specialist", "Expert", "Elite", "Legend"]}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PEOPLE32: " + message)

func settled() -> void:
	for i in 4: await process_frame

func label_fits(label: Label, parent: Control, message: String) -> void:
	var rect := label.get_global_rect()
	var bounds := parent.get_global_rect()
	check(bounds.grow(1).encloses(rect), message + " within card")
	check(label.get_visible_line_count() >= label.get_line_count(), message + " all lines visible")
	check(not label.clip_text and label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, message + " no clipped text")

func class_cards(c, viewport: SubViewport) -> void:
	var seed: Dictionary = c.soldier("u1")
	var tested := 0
	for side_name in ["jedi", "soldier"]:
		for id in Classes.IDS[side_name]:
			var r: Dictionary = seed.duplicate(true)
			r.id = "people32-%s" % id
			r.n = "Class Test"
			r.cls = str(Classes.class_data(id).get("name", id))
			var tier_index: int = tested % 5
			r.rank = ([1, 3, 5, 7, 8] if side_name == "jedi" else [1, 2, 3, 5, 7])[tier_index]
			r.rank_tier = TIERS[side_name][tier_index]
			r.combo_tag = "STAGGERED" if id == "officer" else "MARKED" if id != "guardian" else ""
			if id == "guardian": r.picks = ["guardian_challenging_glare"]
			var card: PanelContainer = Details.card(c, r, func(): pass)
			Squad.decorate_roster_card(card, r)
			viewport.add_child(card)
			card.position = Vector2(12, 100)
			card.size = Vector2(160, 138)
			await settled()
			var class_label: Label = card.find_child("ClassName", true, false)
			var tier_label: Label = card.find_child("RankTier", true, false)
			var tag_label: Label = card.find_child("ChainTag", true, false)
			check(class_label != null and tier_label != null and tag_label != null, "%s labels exist" % id)
			if class_label != null and tier_label != null and tag_label != null:
				check(class_label.text.contains(str(r.cls)), "%s full class name" % id)
				check(tier_label.text.contains(str(r.rank_tier)), "%s rank tier" % id)
				check(tag_label.text.contains(Roster.chain_tag_label(r)), "%s combo tag" % id)
				for label in [class_label, tier_label, tag_label]: label_fits(label, card, id + " " + label.name)
				check(class_label.get_global_rect().end.y <= tier_label.get_global_rect().position.y + 1, "%s class/tier do not overlap" % id)
				check(tier_label.get_global_rect().end.y <= tag_label.get_global_rect().position.y + 1, "%s tier/tag do not overlap" % id)
			card.queue_free()
			await process_frame
			tested += 1
	check(tested == 15, "all W28 classes rendered")

func promotion_cards(c, viewport: SubViewport) -> void:
	var r: Dictionary = c.soldier("u1")
	r.cls = "Guardian"; r.rank = 3; r.picks = ["guardian_deflect", "guardian_brace"]; r.pick = 3
	var screen := Promotion.new()
	viewport.add_child(screen)
	screen.setup(c, "u1")
	await settled()
	var grid: GridContainer = screen.rank_rows[3].find_child("ChoiceGrid", true, false)
	check(grid != null and grid.columns == 1, "390 promotion choices use one column (columns %s, viewport %s, scroll %s)" % [grid.columns if grid != null else -1, screen.get_viewport_rect().size, screen.scroll.size])
	check(not screen.cards.is_empty(), "promotion choices rendered")
	for card in screen.cards.values():
		check(card.get_global_rect().size.y >= 44, "%s choice at least 44 px" % card.name)
		var scroll_rect := screen.scroll.get_global_rect()
		var card_rect: Rect2 = card.get_global_rect()
		check(card_rect.position.x >= scroll_rect.position.x - 1 and card_rect.end.x <= scroll_rect.end.x + 1, "%s choice fits scroll width" % card.name)
		for label in card.find_children("*", "Label", true, false): label_fits(label, card, card.name + " " + label.name)
	check(screen.confirm.get_global_rect().end.y <= VIEW.y + 1 and screen.confirm.get_global_rect().position.y >= screen.scroll.get_global_rect().end.y - 1, "confirm fixed below scroll")
	screen.queue_free()
	await process_frame

func roster_strip(viewport: SubViewport) -> void:
	var screen = load("res://scenes/squad.tscn").instantiate()
	viewport.add_child(screen)
	screen.size = VIEW
	await settled()
	var card: PanelContainer = screen.cards.get("u1")
	check(card != null, "roster strip renders a unit card")
	if card != null:
		check(card.custom_minimum_size.x >= 160, "portrait roster card has readable width")
		check(screen.card_scroll.size.y >= card.get_combined_minimum_size().y, "portrait roster strip shows full card height")
		check(card.find_child("ClassName", true, false) != null and card.find_child("RankTier", true, false) != null and card.find_child("ChainTag", true, false) != null, "live roster card shows class, tier and chain")
	screen.queue_free()
	await process_frame

func run() -> void:
	DisplayServer.window_set_size(VIEW)
	root.size = VIEW; root.content_scale_size = VIEW
	Phone.test_window_size = VIEW
	var viewport := SubViewport.new()
	viewport.size = VIEW
	root.add_child(viewport)
	await settled()
	var c = Campaign.new("normal")
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://people32-test.json"
	flow.campaign = c; flow.story = c.story; flow.active = true
	await class_cards(c, viewport)
	await promotion_cards(c, viewport)
	await roster_strip(viewport)
	viewport.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("PEOPLE32 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
