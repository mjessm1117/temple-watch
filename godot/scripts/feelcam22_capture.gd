extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const OUT := "/home/jess/projects/tw-logs/w22/feelcam/"
var game: Node3D

func _initialize() -> void: run.call_deferred()

func save(name: String) -> void:
	await process_frame
	var image: Image = root.get_texture().get_image()
	print("CAPTURE %s %s" % [name, image.save_png(OUT + name + ".png")])

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var portrait := "--portrait" in OS.get_cmdline_user_args()
	var desktop := "--desktop" in OS.get_cmdline_user_args()
	root.size = Vector2i(390,844) if portrait else Vector2i(1366,768) if desktop else Vector2i(844,390)
	root.content_scale_size = root.size
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://w22-feelcam-capture-%d.json" % OS.get_process_id()
	var campaign = Campaign.new("normal")
	campaign.select_mission(0)
	campaign.state.flow_stage = "battle"
	flow.campaign = campaign; flow.story = campaign.story; flow.active = true
	game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in range(16): await process_frame
	flow.active = false
	game.demo_mode = true
	game.animate_headless = true
	var gate_mission: RefCounted = game.mission
	game.mission = Combat.adopt(Mission.new(7,"res://data/maps/shrine.json"))
	game._build_terrain(); game._refresh_figures()
	var actor: Dictionary = game.mission.living("player")[0]
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
	var enemy: Dictionary = game.mission.living("enemy")[0]
	enemy.awake = true; enemy.spotted = true
	for offset in [Vector2i(2,-2),Vector2i(3,-1),Vector2i(2,1),Vector2i(-2,-1),Vector2i(1,2)]:
		enemy.x = int(actor.x) + offset.x; enemy.y = int(actor.y) + offset.y
		if game.mission.in_bounds(Vector2i(enemy.x,enemy.y)) and not InputControls.valid_targets(game.mission,actor,"shoot").is_empty(): break
	game._refresh_figures()
	game._select(int(actor.id)); game._choose_action("shoot")
	for i in range(24): await process_frame
	await save("after-shrine-aim-portrait" if portrait else "after-shrine-aim-desktop" if desktop else "after-shrine-aim")
	if portrait or desktop: quit(0); return
	game.cam.end_preview()
	game.mission = gate_mission
	game.action = "move"; game.target_id = -1
	game._build_terrain(); game._refresh_figures(); game._refresh()
	var attacker: Dictionary = game.mission.living("enemy")[0]
	var gate := Vector2i(int(game.mission.spec.objective.points[0][0]), int(game.mission.spec.objective.points[0][1]))
	attacker.awake = true; attacker.spotted = true
	attacker.x = gate.x + 4; attacker.y = gate.y
	game._refresh_figures()
	game.playing_enemy_events = true
	game.mission.damage_objective(2)
	game.battle_event.connect(func(kind: String, _actor: String, _target: String, _context: Dictionary) -> void:
		if kind == "objective_hit": save.call_deferred("after-gate-hit"))
	await Presentation.show_event(game,{"kind":"objective_attack","actor":int(attacker.id),"from":Vector2i(attacker.x,attacker.y),"to":gate,"damage":2})
	for i in range(3): await process_frame
	print("CAPTURE DONE")
	quit(0)
