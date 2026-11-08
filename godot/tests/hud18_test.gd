extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Tags = preload("res://scripts/hud18_tags.gd")
const Icon = preload("res://scripts/hud18_icon.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HUD18: " + label)

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new(); event.index = 0; event.position = at; event.pressed = pressed
	root.push_input(event, true)

func drag(from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new(); event.index = 0; event.position = to; event.relative = to - from
	root.push_input(event, true)

func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/w18/hud/%s.png" % name
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + name)

func exercise(dimensions: Vector2i) -> void:
	DisplayServer.window_set_size(dimensions)
	root.size = dimensions; root.content_scale_size = dimensions
	await process_frame
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://hud18-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	for i in 8: await process_frame
	game.demo_mode = true
	var hud: Control = game.hud_controls.combo_overlay
	print("HUD18 SIZE ", dimensions, " root=", root.size, " overlay=", hud.size, " viewport=", game.get_viewport().get_visible_rect().size)
	var phone = game.hud_controls.phone
	check(hud != null and phone != null, "HUD exists at %s" % dimensions)
	var squad: Array[Dictionary] = game.mission.living("player")
	var enemies: Array[Dictionary] = game.mission.living("enemy")
	var first: Dictionary = squad[0]
	var second: Dictionary = squad[1]
	var target: Dictionary = enemies[0]
	target.x = int(first.x) + 2; target.y = int(first.y) - 2
	target.awake = true; target.spotted = true
	game._refresh_figures()
	for tag in ["ATTUNED", "INSPIRED", "READY", "SHIELDED"]: Chains.apply_tag(first, tag, int(second.id))
	for tag in ["MARKED", "EXPOSED"]: Chains.apply_tag(target, tag, int(first.id))
	await process_frame
	check(Tags.shown(first.combo_tags).size() == 4 and Tags.shown(first.combo_tags)[3] == "+1", "overflow +1")
	check(hud.icons[int(first.id)].size() == 4 and hud.icons[int(target.id)].size() == 2, "icons over two units")
	check(Icon.GLYPHS.size() == 12 and Icon.COLORS.size() == 12, "all twelve tag styles")
	var glyphs: Dictionary = {}; var colors: Dictionary = {}
	for tag in Icon.GLYPHS:
		glyphs[Icon.GLYPHS[tag]] = true; colors[Icon.COLORS[tag]] = true
	check(glyphs.size() == 12 and colors.size() == 12, "distinct glyph and color per tag")
	hud.icons[int(first.id)][0].pressed.emit()
	check(hud.explanation.visible and hud.explanation_text.text.contains(" — "), "tap explains tag")
	hud.icons[int(first.id)][3].pressed.emit()
	check(hud.explanation_text.text.contains("SHIELDED") and hud.explanation_text.text.contains("absorbs"), "overflow explains hidden tag")
	var elsewhere := InputEventScreenTouch.new(); elsewhere.pressed = true; elsewhere.position = Vector2(10, 260)
	hud._input(elsewhere)
	check(not hud.explanation.visible, "tap elsewhere closes explanation")
	var preview_button = game.action_buttons["shoot"]
	preview_button.set_chain({"chain": {"consume": [{"tag":"MARKED"}], "apply": [{"tag":"PINNED"}]}}, target)
	check(preview_button.combo_ready and preview_button.chain_marks.size() == 2, "ability shows consume/apply and ready glow")
	for icon in hud.icons[int(first.id)] + hud.icons[int(target.id)]:
		var rect: Rect2 = icon.get_global_rect()
		check(rect.size.x >= 44 and rect.size.y >= 44, "icon touch target at %s" % dimensions)
	check(phone.momentum_strike.custom_minimum_size.x >= 44 and phone.momentum_strike.custom_minimum_size.y >= 40, "48 physical pixel strike target")
	for pips in range(4):
		game.mission.chain_momentum = pips; phone.refresh()
		check(phone.momentum_pips.text.count("●") == pips, "pips %d" % pips)
		check(phone.momentum_plate.visible and phone.ability_tray.get_global_rect().encloses(phone.momentum_plate.get_global_rect()), "meter in action tray at %d" % pips)
	check(phone.momentum_strike.visible and not phone.momentum_strike.disabled, "full strike enabled")
	var before_ap := int(first.ap)
	game.selected_id = int(first.id)
	phone._claim_strike()
	check(int(first.ap) == before_ap + 1 and int(game.mission.chain_momentum) == 0, "strike grants one action and resets pips")
	game.mission.chain_momentum = 3; phone._claim_strike()
	check(int(first.ap) == before_ap + 1 and phone.momentum_strike.disabled, "strike once per turn")
	# Restore full pips for the visual capture, then consume a real tag.
	game.mission.chain_strike_used_turn = -1
	game.mission.chain_momentum = 3
	phone.refresh()
	game.mission.abilities["hud18_fixture"] = {"chain": {"consume": [{"tag":"MARKED", "bonus":[{"aim":20}]}]}}
	game.action = "hud18_fixture"
	await create_timer(2.0).timeout
	Chains.resolve(game.mission, first, target, Vector2i(int(target.x), int(target.y)), game.mission.abilities["hud18_fixture"])
	check(not target.get("combo_tags", {}).has("MARKED"), "core chain resolver consumes MARKED")
	hud._process(0.0)
	check(hud.callouts.size() > 0 and str(hud.callouts.back().text).contains("MARKED"), "callout on consume")
	check(hud.icons[int(target.id)].size() == 1, "consumed icon clears")
	await capture("battle-%dx%d" % [dimensions.x, dimensions.y])
	var icon: Button = hud.icons[int(first.id)][0]
	var start: Vector2 = icon.get_global_rect().get_center()
	var pivot: Vector3 = game.pivot
	touch(start, true)
	var previous := start
	for i in 8:
		var next := start + Vector2(-96.0 * float(i + 1) / 8.0, 0)
		drag(previous, next); previous = next
		await process_frame
	touch(previous, false)
	await process_frame
	check(game.pivot.distance_to(pivot) > 0.03, "drag from tag pans camera")
	check(not hud.explanation.visible, "tag drag does not open explanation")
	var pip_start: Vector2 = phone.momentum_pips.get_global_rect().get_center()
	pivot = game.pivot
	touch(pip_start, true); previous = pip_start
	for i in 8:
		var next := pip_start + Vector2(-96.0 * float(i + 1) / 8.0, 0)
		drag(previous, next); previous = next
		await process_frame
	touch(previous, false); await process_frame
	check(game.pivot.distance_to(pivot) > 0.03, "drag from pips pans camera")
	first.combo_tags = {}
	await process_frame
	check(hud.icons[int(first.id)].is_empty(), "icons clear with tags")
	game.queue_free(); await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/godot/w18/hud"))
	await exercise(Vector2i(844, 390))
	await exercise(Vector2i(667, 375))
	print("HUD18 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
