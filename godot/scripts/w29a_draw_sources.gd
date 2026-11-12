extends SceneTree
## Debug-only draw attribution by rendering one visual source at a time.
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")

func _initialize() -> void:
	call_deferred("run")

func bucket(node: Node, game: Node, art: Node) -> String:
	if art.marker_root != null and art.marker_root.is_ancestor_of(node): return "objective markers"
	if art.damage_root != null and art.damage_root.is_ancestor_of(node): return "cover damage"
	if game.terrain.is_ancestor_of(node): return "terrain and scenery"
	if game.figures.is_ancestor_of(node): return "units"
	if game.highlights.is_ancestor_of(node): return "movement and selection"
	if game.fx.is_ancestor_of(node): return "VFX"
	if game.reinforcement_view.is_ancestor_of(node): return "reinforcement markers"
	return "other world visuals"

func sample() -> int:
	var peak := 0
	for frame in 8:
		await process_frame
		peak = maxi(peak, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	return peak

func run() -> void:
	root.size = Vector2i(390, 844); root.content_scale_size = root.size
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var flow: Node = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for frame in 60: await process_frame
	var art: Node = game.terrain.get_child(0)
	var groups: Dictionary = {"terrain and scenery": [], "units": [], "objective markers": [], "cover damage": [], "movement and selection": [], "VFX": [], "reinforcement markers": [], "other world visuals": []}
	var was_visible: Dictionary = {}
	for node in game.find_children("*", "VisualInstance3D", true, false):
		var kind := bucket(node, game, art)
		if not groups.has(kind): groups[kind] = []
		groups[kind].append(node)
		was_visible[node] = node.visible
	var total := await sample()
	for node in was_visible: node.visible = false
	var hud_visible: bool = game.hud.visible
	game.hud.visible = false
	var empty := await sample()
	var rows: Array[Dictionary] = []
	for kind in groups:
		for node in groups[kind]: node.visible = was_visible[node]
		var draws := await sample()
		rows.append({"source": kind, "draws": maxi(0, draws - empty), "visuals": groups[kind].size()})
		for node in groups[kind]: node.visible = false
	game.hud.visible = hud_visible
	var hud_draws: int = maxi(0, (await sample()) - empty)
	var action_art: Control = game.hud_controls.phone.action_art
	var art_visible: bool = action_art.visible
	action_art.visible = false
	var hud_without_art: int = maxi(0, (await sample()) - empty)
	action_art.visible = art_visible
	rows.append({"source": "HUD action art", "draws": maxi(0, hud_draws - hud_without_art), "visuals": 0})
	rows.append({"source": "HUD other canvas", "draws": hud_without_art, "visuals": 0})
	rows.sort_custom(func(a, b): return int(a.draws) > int(b.draws))
	var lines: Array[String] = ["Portrait Low draw attribution (isolated source, peak of 8 frames)", "Total %d  |  empty %d" % [total, empty], "Isolation may differ from combined draws because batching and occlusion change."]
	for i in mini(10, rows.size()): lines.append("%2d. %-25s %3d draws  %d visuals" % [i + 1, str(rows[i].source), int(rows[i].draws), int(rows[i].visuals)])
	var output := "/home/jess/projects/tw-logs/w29/phone29/draw-top10.txt"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	print("\n".join(lines))
	game.queue_free()
	quit(0)
