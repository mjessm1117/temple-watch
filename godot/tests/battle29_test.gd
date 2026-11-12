extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const AI = preload("res://scripts/ai.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Cover = preload("res://scripts/w29c_cover.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Bot = preload("res://tests/campaign_bot.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("BATTLE29 FAIL: ",label)

func clear_area(m: RefCounted, left: int, top: int, right: int, bottom: int) -> void:
	for y in range(top,bottom+1):
		for x in range(left,right+1): m.set_tile(Vector2i(x,y),".")

func height_and_cover() -> void:
	var m = Mission.new(1)
	m.modern = true
	var a: Dictionary = m.living("player")[0]
	var t: Dictionary = m.living("enemy")[0]
	clear_area(m,7,7,20,16)
	a.x = 10; a.y = 10; t.x = 15; t.y = 10
	var level: Dictionary = Shot.calculate(m,a,t)
	m.set_tile(Vector2i(10,10),"M")
	var high: Dictionary = Shot.calculate(m,a,t)
	check(int(high.height_delta) == 2 and int(high.hit) > int(level.hit),"high ground raises aim and reports two levels")
	m.set_tile(Vector2i(10,10),"."); m.set_tile(Vector2i(15,10),"M")
	var low: Dictionary = Shot.calculate(m,a,t)
	check(int(low.height_delta) == -2 and int(low.hit) < int(level.hit),"target height grants defense in preview")
	m.set_tile(Vector2i(15,10),"."); m.set_tile(Vector2i(14,10),"#")
	var preview: Dictionary = Shot.calculate(m,a,t)
	check(preview.has_all(["flanked","height_delta","cover_after_shot"]) and preview.cover_after_shot.get("on_miss","") == "#","shot preview exposes cover risk")
	var at := Vector2i(14,10)
	Cover.shot_chip(m,a,t,"shoot","misses")
	check(int(m.cover_hp[at]) == 7 and m.action_events.any(func(event): return event.kind == "cover_damage" and event.at == at and event.cause == "shot_miss"),"miss chips cover and emits HP change")
	Cover.shot_chip(m,a,t,"shoot","hits")
	Cover.shot_chip(m,a,t,"shoot","hits")
	Cover.shot_chip(m,a,t,"shoot","hits")
	Cover.shot_chip(m,a,t,"shoot","hits")
	check(m.tile(at) == "c" and m.terrain_revision > 0,"sustained fire cracks full cover")
	m.explode(at,1,0,{"kind":"explosion"})
	check(m.tile(at) == "r" and m.action_events.any(func(event): return event.kind == "cover_break" and event.cause == "explosion"),"explosion destroys cover")
	m.set_tile(at,"#")
	m.damage_cover(at,4,{"kind":"grenade"})
	check(m.tile(at) == "r","campaign grenade destroys full cover")

func overwatch_flank() -> void:
	var m = Mission.new(2)
	m.modern = true
	clear_area(m,9,8,20,15)
	var p: Dictionary = m.living("player")[0]
	for other in m.living("player"):
		if other.id != p.id: other.hp = 0
	p.x = 10; p.y = 10
	m.set_tile(Vector2i(11,10),"c")
	var enemies: Array[Dictionary] = m.living("enemy")
	for i in enemies.size():
		if i >= 2: enemies[i].hp = 0
	var guard: Dictionary = enemies[0]; var flanker: Dictionary = enemies[1]
	guard.x = 17; guard.y = 10; flanker.x = 17; flanker.y = 12
	guard.group = 0; flanker.group = 0
	guard.awake = true; flanker.awake = true
	guard.ap = 2; flanker.ap = 2; m.phase = "enemy"
	var origin := Shot.pos(flanker)
	AI.act(m,guard,{})
	AI.act(m,flanker,{})
	check(bool(guard.overwatch) and m.action_events.any(func(event): return event.kind == "overwatch" and event.reason24 == "Covering flank setup"),"ranged guard deliberately holds Overwatch")
	check(Shot.pos(flanker) != origin and bool(flanker.get("setup29_done",false)),"partner moves for a flank")
	m.set_tile(Vector2i(11,10),"#")
	guard.overwatch = true
	m._enemy_reaction_fire(p)
	check(bool(guard.overwatch),"enemy Overwatch cannot fire through full cover")

func procedural_maps() -> void:
	for id in ["rescue","archive"]:
		var source: Dictionary = Maps.read("res://data/maps/%s.json" % id)
		source.procedural = true
		var path := "user://battle29-%s.json" % id
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(JSON.stringify(source)); file.close()
		var unique := {}
		for seed_value in range(1,21):
			var data: Dictionary = Maps.load_map(path,seed_value)
			var validation: Dictionary = data.layout29.validation
			check(bool(validation.ok),"%s seed %d routes and start cover: %s" % [id,seed_value,str(validation.errors)])
			unique[hash(data.rows)] = true
		check(unique.size() >= 10,"%s has at least ten distinct layouts" % id)
		var authored: Dictionary = Maps.load_map("res://data/maps/%s.json" % id,1)
		check(not authored.has("layout29"),"%s procedural layout is off by default" % id)

func relay_benchmark() -> void:
	var wins := 0
	for seed_value in range(1,21):
		var c = Campaign.new("normal")
		c.select_mission(0)
		var m = Battle.create(c,seed_value)
		for step in 60:
			if m.result != "": break
			Bot.turn(m)
		if m.result == "win": wins += 1
		check(m.result != "","relay benchmark seed %d terminates" % seed_value)
	print("BATTLE29 RELAY CAMPAIGN: %d/20 wins" % wins)

func capture_data() -> void:
	var m = Mission.new(3)
	m.modern = true
	clear_area(m,8,8,21,16)
	var a: Dictionary = m.living("enemy")[0]
	var t: Dictionary = m.living("player")[0]
	a.x = 18; a.y = 11; t.x = 11; t.y = 11
	var cover := Vector2i(12,11)
	m.set_tile(cover,"#")
	var before: Array[String] = m.board.duplicate()
	Cover.shot_chip(m,a,t,"shoot","misses")
	var partner: Dictionary = m.living("enemy")[1]
	for other in m.living("enemy"):
		if other.id not in [a.id,partner.id]: other.hp = 0
	for other in m.living("player"):
		if other.id != t.id: other.hp = 0
	partner.x = 18; partner.y = 13
	a.group = 0; partner.group = 0
	m.modern = true; m.phase = "enemy"; a.awake = true; partner.awake = true; a.ap = 2; partner.ap = 2
	AI.act(m,a,{})
	var after: Array[String] = m.board.duplicate()
	var layouts := []
	for seed_value in [1,2]:
		var data: Dictionary = Maps.load_map("user://battle29-rescue.json",seed_value)
		layouts.append({"rows":data.rows,"seed":seed_value,"validation":data.layout29.validation})
	var payload := {"before":before,"after":after,"cover":[cover.x,cover.y],"cover_hp_before":8,"cover_hp_after":int(m.cover_hp[cover]),"watcher":[a.x,a.y],"target":[t.x,t.y],"overwatch_event":m.action_events[-1],"layouts":layouts}
	var file := FileAccess.open("/home/jess/projects/tw-logs/w29/battle29/capture-data.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(payload)); file.close()

func capture_screen(size: Vector2i, damaged: bool) -> void:
	root.size = size; root.content_scale_size = size
	DisplayServer.window_set_size(size)
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	game.set_process(false)
	var m: RefCounted = game.mission
	var cover := Vector2i(9,19)
	m.set_tile(cover,"#"); m.cover_hp[cover] = 5; m.terrain_revision += 1
	if damaged: m.damage_cover(cover,1,{"kind":"shot_miss","actor":0})
	game.pivot = Vector3(9,0,19); game.zoom = 8.0; game.yaw = 0.2; game.pitch = 0.83
	game._build_terrain(); game._refresh(); game._update_camera()
	game.phase_banner.hide(); game.hud_controls.night.phase_plate.hide()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var prefix := "/home/jess/projects/tw-logs/w29/battle29/2026-11-12-battle29-%dx%d-low" % [size.x,size.y]
	check(root.get_texture().get_image().save_png(prefix+("-after.png" if damaged else "-before.png")) == OK,"%s window capture" % size)
	if damaged: check(m.tile(cover) == "c" and int(m.cover_hp[cover]) == 4,"%s miss cracks full into half cover" % size)
	game.queue_free(); await process_frame

func run() -> void:
	height_and_cover(); overwatch_flank(); procedural_maps()
	if "--relay-benchmark" in OS.get_cmdline_user_args(): relay_benchmark()
	if "--capture" in OS.get_cmdline_user_args(): capture_data()
	if "--screen" in OS.get_cmdline_user_args():
		var damaged := "--after" in OS.get_cmdline_user_args()
		await capture_screen(Vector2i(844,390),damaged)
		await capture_screen(Vector2i(390,844),damaged)
	print("BATTLE29 RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
