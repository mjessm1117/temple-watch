extends SceneTree
const Facing = preload("res://scripts/w34b_facing.gd")
const Mission = preload("res://scripts/combat_mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func forward_to(view: Node3D, point: Vector2i) -> bool:
	var expected := Facing.yaw_to(view.global_position, Vector3(point.x, view.global_position.y, point.y))
	return absf(wrapf(view.model.rotation.y + view.rotation.y - expected, -PI, PI)) < 0.12

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var capture := "--capture-before" in args or "--capture-after" in args
	Facing.enabled = "--capture-before" not in args
	for map_path in ["res://data/rescue.json", "res://data/maps/rescue.json", "res://data/maps/relay.json", "res://data/maps/archive.json"]:
		var mission: RefCounted = Mission.new(1, map_path)
		var players: Array[Dictionary] = mission.living("player")
		check(not players.is_empty(), map_path + " squad exists")
		if players.is_empty(): continue
		var player := players[0]
		var from := Facing.position_of(player)
		var spawn := Facing.spawn_side(mission, from)
		var chosen := Facing.target(mission, player, [])
		check(spawn != Vector2i(-1, -1) and chosen == spawn, map_path + " spawn faces enemy side")
		check((Vector2(spawn - from)).dot(Vector2(spawn - from)) > 0, map_path + " no edge default")
		var enemy: Dictionary = mission.living("enemy")[0]
		var allies: Array[Vector2i] = []
		for ally in players: allies.append(Facing.position_of(ally))
		check(Facing.target(mission, enemy, []) == Facing.nearest(Facing.position_of(enemy), allies), map_path + " enemy faces nearest player")
	var m: RefCounted = Mission.new(1, "res://data/rescue.json")
	var soldier: Dictionary = m.living("player")[0]
	var foes: Array[Dictionary] = m.living("enemy")
	for foe in foes: foe.spotted = false
	var fallback := Facing.target(m, soldier, [])
	check(fallback == Facing.spawn_side(m, Facing.position_of(soldier)), "no visible enemy uses spawn side")
	var memory: Array[Vector2i] = [Vector2i(11, 12)]
	check(Facing.target(m, soldier, memory) == memory[0], "last known beats spawn side")
	foes[0].spotted = true
	check(Facing.target(m, soldier, memory) == Facing.position_of(foes[0]), "nearest visible beats last known")
	var start := Facing.position_of(soldier)
	var destination := Vector2i(-1, -1)
	for tile in m.reach_tiles(soldier, 1).costs:
		if tile != start: destination = tile; break
	check(destination != Vector2i(-1, -1) and m.move(int(soldier.id), destination), "player move completes")
	check(Facing.target(m, soldier, []) == Facing.nearest(destination, Facing.visible_enemies(m)) if not Facing.visible_enemies(m).is_empty() else Facing.target(m, soldier, []) == Facing.spawn_side(m, destination), "after move faces nearest visible threat or spawn side")
	if capture:
		root.size = Vector2i(844, 390)
		root.content_scale_size = root.size
		var flow: Node = root.get_node("CampaignFlow")
		flow.save_path = "user://w34b-%d.json" % OS.get_process_id()
		flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
		var game: Node = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		for i in 12: await process_frame
		root.get_node("Graphics").apply_all()
		await create_timer(0.5).timeout
		var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
		var view: Node3D = game.views[int(actor.id)]
		if Facing.enabled:
			var wanted := Facing.target(game.mission, actor, [])
			check(forward_to(view, wanted), "live rescue model faces threat")
			var old_yaw: float = view.model.rotation.y
			view.travel24([view.position + Vector3(0, 0, -1)], false)
			check(not Facing.idle_ready(view), "no idle facing during walk")
			Facing.update(view)
			check(is_equal_approx(old_yaw, view.model.rotation.y), "idle turn does not rotate walking model")
			view.motion.kill()
		var name := "before" if not Facing.enabled else "after"
		var path := "/home/jess/projects/tw-logs/w34/b34-%s.png" % name
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(path) == OK, "rescue screenshot " + name)
		if Facing.enabled:
			var enemy: Dictionary = game.mission.living("enemy")[0]
			enemy.spotted = true; enemy.detected = true; enemy.awake = true
			var live_start := Facing.position_of(actor)
			var dest := Vector2i(-1, -1)
			for tile in game.mission.reach_tiles(actor, 1).costs:
				if tile != live_start: dest = tile; break
			check(dest != Vector2i(-1, -1) and game.mission.move(int(actor.id), dest), "live player move completes")
			if dest != Vector2i(-1, -1):
				view.travel24([Vector3(dest.x, view.position.y, dest.y)], false)
				await view.motion.finished
				await create_timer(0.5).timeout
				check(forward_to(view, Facing.target(game.mission, actor, view.last_known_w34b)), "model faces visible enemy after move")
		game.queue_free(); await process_frame
	print("w34b facing: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
