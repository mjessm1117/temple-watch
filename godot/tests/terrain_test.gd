extends SceneTree
## Campaign elevation contract, independent walk/ramp graph, three broad approaches.
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")
const Validator = preload("res://scripts/map_validator.gd")
const Art = preload("res://scripts/map_presentation.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func ramp_flood(m, art, start: Vector2i) -> Dictionary:
	var seen := {start:true}; var queue: Array[Vector2i] = [start]; var index := 0
	while index < queue.size():
		var p := queue[index]; index += 1
		for d in Shot.DIRS:
			var q: Vector2i = p+d
			if seen.has(q) or not m.passable(q): continue
			var equal := Shot.elevation(m,p) == Shot.elevation(m,q)
			var ramp: bool = q in art.access_tiles.get(p,[]) or p in art.access_tiles.get(q,[])
			if not equal and not ramp: continue
			seen[q] = true; queue.append(q)
	return seen

func validate(m, art, id: String) -> void:
	var tiers := {}; var raised := 0; var walk := 0; var authored := true
	var start := Maps.point(m.spec.route_validation.start)
	var reach := ramp_flood(m,art,start)
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			var tile := Vector2i(x,y)
			if not m.passable(tile): continue
			var tier := Shot.elevation(m,tile)
			tiers[tier] = int(tiers.get(tier,0))+1; walk += 1
			if tier > 0: raised += 1
			check(reach.has(tile),id+": every walkable tile ramp-connected %s" % tile)
			if tier != int(str(m.spec.elevation[y])[x]): authored = false
	check(authored,id+": authored elevation must be loaded by MapCatalog before mission creation")
	check(tiers.size() >= 2,id+": at least two tiers")
	check(float(raised)/walk >= 0.15,id+": raised coverage >=15%")
	var anchors: Array = m.spec.objective.points + m.spec.entries + m.spec.evac
	anchors.append_array(m.spec.objective.get("civilians",[]))
	for u in m.spec.squad: anchors.append([u[1],u[2]])
	for pod in m.spec.groups:
		for u in pod: anchors.append([u[1],u[2]])
	anchors.append([m.spec.prisoner.x,m.spec.prisoner.y])
	for at in anchors: check(reach.has(Maps.point(at)),id+": spawn/objective/evac/entry reachable %s" % str(at))
	var topo := Validator.topology(m.board)
	check(topo.components == 1 and topo.cuts.is_empty(),id+": connected, no chokepoints")
	# Three physically separate north/south corridors, linked by broad spawn/goal plazas.
	var goal := Maps.point(m.spec.route_validation.goal); var routes := 0; var used: Array[int] = []
	for lane in m.spec.plot.lanes:
		var x := int(lane); var clear := true
		for previous in used:
			if absi(x-previous) < 3: clear = false
		for y in range(mini(start.y,goal.y),maxi(start.y,goal.y)+1):
			if not Validator.wide(m.board,Vector2i(x,y)): clear = false
		var a := Vector2i(x,start.y); var z := Vector2i(x,goal.y)
		if Validator.path(m.board,start,a,3).is_empty() or Validator.path(m.board,z,goal,3).is_empty(): clear = false
		if clear: routes += 1; used.append(x)
	check(routes >= 3,id+": three routes at least three tiles wide")
	for tile in art.access_tiles:
		for lower: Vector2i in art.access_tiles[tile]:
			check(m.passable(lower),id+": stair lower landing walkable")
			check(Shot.elevation(m,lower)<Shot.elevation(m,tile),id+": stair rises toward tile center")
	for record in art.batch.records:
		if record.role == "scenery":
			for bounds: AABB in record.parts:
				check(bounds.end.x <= -0.5 or bounds.position.x >= float(m.spec.width)-0.5 or bounds.end.z <= -0.5 or bounds.position.z >= float(m.spec.height)-0.5,id+": edge dressing outside board")
			continue
		var tile: Vector2i = record.tile; var bounds: AABB = record.bounds
		check(bounds.position.x >= tile.x-0.5001 and bounds.end.x <= tile.x+0.5001 and bounds.position.z >= tile.y-0.5001 and bounds.end.z <= tile.y+0.5001,id+": prop fits its tile")
		check(absf(bounds.position.y-Shot.elevation(m,tile)*0.7)<0.001,id+": prop rests on its floor")
		if record.role == "cover":
			check(tile.x>0 and tile.y>0 and tile.x<int(m.spec.width)-1 and tile.y<int(m.spec.height)-1,id+": no perimeter wall")
	print("TERRAIN %s: tiers %s; raised %d/%d (%.2f%%); wide routes %d; ramp graph %d" % [id,tiers,raised,walk,100.0*raised/walk,routes,reach.size()])

func run() -> void:
	if "--campaign" in OS.get_cmdline_user_args():
		campaign_sample(); quit(1 if failures else 0); return
	var art = Art.new(); root.add_child(art)
	for id in Maps.manifest().missions:
		var m = Mission.new(17,Maps.resolve(id))
		if "--authored" in OS.get_cmdline_user_args():
			# Explicit authoring validation before the catalog integration; default tests require live data.
			preload("res://scripts/map_art_elevation.gd").apply(m.board,m.spec.elevation)
		art.build(m)
		validate(m,art,id)
		await process_frame
	art.queue_free(); await process_frame
	print("TERRAIN TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func campaign_sample() -> void:
	# Same seeds, factory and turn policy as campaign_bot; only authoring mode applies proposed data.
	var bot = preload("res://tests/campaign_bot.gd")
	var campaign = preload("res://scripts/campaign/state.gd")
	var bridge = preload("res://scripts/campaign/battle_bridge.gd")
	var args := OS.get_cmdline_user_args()
	for family in bot.FAMILIES:
		if "--family" in args and family != args[-1]: continue
		var wins := 0; var turns := 0; var losses := {}
		for seed_value in range(1,21):
			var c = campaign.new("normal")
			c.state.options = [{"mission":bot.FAMILIES[family],"map_variant":0,"adv":false}]
			c.select_mission(0)
			var m = bridge.create(c,seed_value)
			if "--authored" in args: preload("res://scripts/map_art_elevation.gd").apply(m.board,m.spec.elevation)
			for step in 60:
				if m.result != "": break
				bot.turn(m)
			check(m.result != "",family+": campaign finishes")
			turns += m.turn
			if m.result == "win": wins += 1
			else:
				var why: String = m.log_lines[-1] if m.result != "" else "turn safety limit"
				losses[why] = int(losses.get(why,0))+1
			c.apply_mission_result(bridge.result(c,m))
		check(wins >= 6 and wins <= 16,family+": campaign Normal 30–80% band")
		print("TERRAIN %s CAMPAIGN %s: %d/20 wins (%d%%); mean turns %.1f; losses %s" % ["AUTHORING" if "--authored" in args else "LIVE",family,wins,wins*5,float(turns)/20,JSON.stringify(losses)])
