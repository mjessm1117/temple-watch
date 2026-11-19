extends RefCounted
## Battle narrative cards and legacy state barks.
const Portraits = preload("res://scripts/story14_portraits.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Beats = preload("res://scripts/story/story14_beats.gd")
const Objectives = preload("res://scripts/mission_objectives.gd")
var game: WeakRef
var lines: Dictionary
var legacy_barks: Dictionary
var hero_barks: Dictionary
var layer: CanvasLayer
var card: PanelContainer
var who_label: Label
var text_label: Label
var face: TextureRect
var fade: Tween
var last_sample := 0
var seen: Dictionary = {}
var previous_enemy_count := -1
var previous_objectives := 0
var contact := false
var villain := false
var bark_number := 0
var pending: Array[String] = []
var next_bark_at := 0
var event_mode := false
var unit_snapshots: Dictionary = {}
var triggered_named := 0
var cue_seen: Dictionary = {}

func _init(g: Node) -> void:
	game = weakref(g)
	g.set_meta("story_comms", self)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story14-barks.json"))
	lines = parsed.get("heroes",{}) if parsed is Dictionary else {}
	var story_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-story.json"))
	var records: Dictionary = story_data.get("records",{}) if story_data is Dictionary else {}
	legacy_barks = records.get("BARKS",{})
	hero_barks = records.get("HERO_BARKS",{})
	if g.has_signal("battle_event"): g.connect("battle_event", _battle_event)

func _battle_event(kind: String, actor_id: String, target_id: String, _context: Dictionary) -> void:
	var g: Node = game.get_ref()
	if g == null or g.mission == null: return
	if kind == "reveal":
		_action_cue(g, "contact")
		_suppress_flow_bark(g, actor_id)
		return
	if kind == "ally_down":
		_action_cue(g, "casualty")
		_suppress_flow_bark(g, actor_id)
		return
	var event: String = {"flank":"flanked", "hurt":"first_wound", "kill":"kill", "heal":"recovery", "revive":"recovery", "promotion":"promotion"}.get(kind, "")
	if event.is_empty(): return
	var id := target_id if kind in ["hurt", "heal", "revive", "ally_down", "flank"] else actor_id
	for unit in g.mission.units:
		if str(unit.get("side", "")) != "player" or id not in [str(unit.get("id", "")), str(unit.get("rid", ""))]: continue
		if kind == "hurt":
			if seen.has("wound:" + id): return
			seen["wound:" + id] = true
		pending.append("%s|%s" % [event, str(unit.get("name", ""))])
		return
	if kind == "kill":
		for unit in g.mission.units:
			if str(unit.get("side", "")) == "player" and target_id in [str(unit.get("id", "")), str(unit.get("rid", ""))]:
				_action_cue(g, "casualty")
				_suppress_flow_bark(g, actor_id)
				return
	if kind == "flank":
		for unit in g.mission.units:
			if str(unit.get("side", "")) == "player" and actor_id in [str(unit.get("id", "")), str(unit.get("rid", ""))]:
				pending.append("flanked|" + str(unit.get("name", "")))
				return

func sample() -> void:
	var g: Node = game.get_ref()
	if g == null or not is_instance_valid(g):
		if is_instance_valid(layer): layer.queue_free()
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.process_frame.is_connected(sample): tree.process_frame.disconnect(sample)
		return
	var now := Time.get_ticks_msec()
	if now - last_sample < 100: return
	last_sample = now
	if g.mission == null or g.demo_mode: return
	var players: Array = g.mission.units.filter(func(u): return str(u.get("side","")) == "player")
	_sample_action_cues(g, players)
	if event_mode:
		for ally in players:
			var id := str(ally.get("id", ""))
			var hp := int(ally.get("hp", 0))
			if unit_snapshots.has(id) and hp > int(unit_snapshots[id].hp) and lines.has(str(ally.get("name", ""))): pending.append("recovery|" + str(ally.get("name", "")))
			unit_snapshots[id] = {"hp":hp}
		if now >= next_bark_at and not pending.is_empty():
			_show(g, pending.pop_front(), players)
			next_bark_at = now + 4000
		return
	var enemies: Array = g.mission.living("enemy")
	var triggers: Array[String] = []
	var visible := false
	var boss_visible := false
	for foe in enemies:
		if bool(foe.get("awake",false)) or bool(foe.get("spotted",false)): visible = true
		if (bool(foe.get("boss",false)) or bool(foe.get("duel_boss",false)) or bool(foe.get("villain11",false)) or str(foe.get("kind","")) in ["sith_lord","marchion_ro","lourna_dee"]) and (bool(foe.get("awake",false)) or bool(foe.get("spotted",false))): boss_visible = true
	if visible and not contact:
		contact = true
		_action_cue(g, "contact")
	if boss_visible and not villain:
		villain = true
		triggers.append("villain")
	for ally in players:
		var id := str(ally.get("id",""))
		var name := str(ally.get("name", ""))
		var hp := int(ally.get("hp", 0))
		var kills := int(ally.get("kills", 0))
		var rank := int(ally.get("rank", 1))
		if unit_snapshots.has(id):
			var before: Dictionary = unit_snapshots[id]
			if hp < int(before.hp) and hp > 0 and not seen.has("wound:" + id):
				seen["wound:" + id] = true; triggers.append("first_wound|" + name)
			if hp > int(before.hp): triggers.append("recovery|" + name)
			if kills > int(before.kills): triggers.append("kill|" + name)
			if rank > int(before.rank): triggers.append("promotion|" + name)
		unit_snapshots[id] = {"hp":hp,"kills":kills,"rank":rank}
		if str(ally.get("status","")) == "down" or int(ally.get("hp",1)) <= 0:
			if not seen.has(id):
				seen[id] = true
				_action_cue(g, "casualty")
	var completed: int = g.mission.objective_state.get("done",{}).size()
	if completed > previous_objectives: _action_cue(g, "objective")
	previous_objectives = completed
	if enemies.size() == 1 and previous_enemy_count > 1: triggers.append("last_enemy")
	previous_enemy_count = enemies.size()
	for event in triggers: pending.append(event)
	if now >= next_bark_at and not pending.is_empty():
		_show(g,pending.pop_front(),players)
		next_bark_at = now + 4000

func _sample_action_cues(g: Node, players: Array) -> void:
	if not cue_seen.has("contact"):
		for enemy in g.mission.living("enemy"):
			if bool(enemy.get("awake", false)) or bool(enemy.get("spotted", false)):
				_action_cue(g, "contact")
				break
	if not cue_seen.has("casualty"):
		for ally in players:
			if str(ally.get("status", "")) == "down" or int(ally.get("hp", 1)) <= 0:
				_action_cue(g, "casualty")
				break
	if cue_seen.has("objective"): return
	var mission: RefCounted = g.mission
	if Objectives.mira_rescue(mission):
		var target := Vector2i(int(mission.prisoner.x), int(mission.prisoner.y))
		if bool(mission.prisoner.get("freed", false)) or players.any(func(u): return int(u.get("hp", 0)) > 0 and maxi(absi(int(u.x)-target.x), absi(int(u.y)-target.y)) <= 1):
			_action_cue(g, "objective")
	elif mission.objective_state.get("done", {}).size() > 0 or str(mission.objective_state.get("phase", "primary")) == "evac" or str(mission.result) == "win":
		_action_cue(g, "objective")

func _action_cue(g: Node, kind: String) -> void:
	if cue_seen.has(kind): return
	var heroes: Array = g.mission.living("player")
	var name := "Jace Malcom"
	var preferred := ""
	if Objectives.mira_rescue(g.mission): preferred = str({"contact":"Ilsa Myr", "objective":"Tor Saalen", "casualty":"Doc Bren"}.get(kind, ""))
	for ally in heroes:
		if lines.has(str(ally.get("name", ""))):
			if name == "Jace Malcom": name = str(ally.name)
			if str(ally.name) == preferred:
				name = preferred
				break
	var key := ("opening_contact" if str(g.mission.spec.get("id", "")) == "relay" else "contact") if kind == "contact" else "ally_down" if kind == "casualty" else "objective_done"
	var options: Array = lines.get(name, {}).get(key, [])
	var sentence := str(options[0]) if not options.is_empty() else "Contact. Hold the line." if kind == "contact" else "One of ours is down. Get to them." if kind == "casualty" else "Objective reached. Move to evac."
	if Objectives.mira_rescue(g.mission):
		var rescue_key := "rescue_contact" if kind == "contact" else "rescue_casualty" if kind == "casualty" else "mira_freed" if bool(g.mission.prisoner.get("freed", false)) else "mira_reached"
		var rescue_options: Array = lines.get(name, {}).get(rescue_key, [])
		sentence = str(rescue_options[0]) if not rescue_options.is_empty() else "Contact. Mark them." if kind == "contact" else "One down. Get to them." if kind == "casualty" else "Mira Tal is free." if bool(g.mission.prisoner.get("freed", false)) else "Mira Tal, we are here."
	cue_seen[kind] = true
	triggered_named += 1
	show_radio(name, name, sentence, 2)

func _suppress_flow_bark(g: Node, actor_id: String) -> void:
	var flow: Node = g.get_node_or_null("/root/CampaignFlow")
	if flow == null or not flow.get("active"): return
	flow.set("last_bark_at", Time.get_ticks_msec())
	var actor_turn: Dictionary = flow.get("actor_bark_turn")
	actor_turn[actor_id] = g.mission.turn
	flow.set("actor_bark_turn", actor_turn)

func fallback(kind: String, actor_id: String, target_id: String) -> Dictionary:
	var g: Node = game.get_ref()
	if g == null or g.mission == null: return {}
	var key: String = {"reveal":"opening_contact", "reinforce":"contact", "flank":"flanked", "hit":"contact", "miss":"contact", "crit":"last_enemy", "hurt":"first_wound", "heal":"recovery", "revive":"recovery", "kill":"kill", "objective_hit":"objective_done", "villain_reveal":"villain"}.get(kind,kind)
	for id in [actor_id,target_id]:
		for unit in g.mission.units:
			if (str(unit.get("id","")) != id and str(unit.get("rid","")) != id) or str(unit.get("side","")) != "player": continue
			var name := str(unit.get("name",""))
			if kind in ["kill","crit","hurt"]:
				var event_key := "down" if kind == "hurt" else kind
				var owned: Array = hero_barks.get(name,{}).get(event_key,[])
				var category := "jedi" if int(unit.get("focus",0)) > 0 else "troop"
				var authored: Array = owned if not owned.is_empty() else legacy_barks.get(category,{}).get(event_key,[])
				if not authored.is_empty(): return {"speaker":name,"portrait_key":name,"text":str(authored[bark_number % authored.size()]),"priority":1}
			var options: Array = lines.get(name,{}).get(key,[])
			if not options.is_empty():
				return {"speaker":name,"portrait_key":name,"text":str(options[bark_number % options.size()]),"priority":1}
	for unit in g.mission.living("player"):
		var name := str(unit.get("name",""))
		var options: Array = lines.get(name,{}).get(key,[])
		if not options.is_empty(): return {"speaker":name,"portrait_key":name,"text":str(options[bark_number % options.size()]),"priority":1}
	return {}

func _show(g: Node, event: String, players: Array) -> void:
	var heroes: Array[String] = []
	for ally in players:
		var name := str(ally.get("name",""))
		if lines.has(name) and int(ally.get("hp",0)) > 0: heroes.append(name)
	if heroes.is_empty(): return
	var parts := event.split("|", false, 1)
	event = parts[0]
	var name: String = parts[1] if parts.size() > 1 and heroes.has(parts[1]) else heroes[bark_number % heroes.size()]
	var options: Array = lines[name].get(event,[])
	if options.is_empty(): return
	var sentence: String = options[bark_number % options.size()]
	var portrait_key := name
	var kind: String = {"contact":"reveal", "villain":"villain_reveal"}.get(event, "")
	if not kind.is_empty():
		var actor_id := ""
		var target_id := ""
		for ally in players:
			var story_id: Variant = Beats.NAMES.find_key(str(ally.get("name", "")))
			var id := str(story_id) if story_id != null else str(ally.get("rid", ally.get("id", "")))
			if str(ally.get("name", "")) == name: actor_id = id
			if event == "ally_down" and (str(ally.get("status", "")) == "down" or int(ally.get("hp", 1)) <= 0): target_id = id
		var context := {}
		if event == "villain" and g is Node3D and g.get("mission") != null:
			context.villain_name = str(g.mission.objective_state.get("villain_name", ""))
		var bark: Dictionary = Beats.pick_bark(kind, actor_id, target_id, context)
		if not bark.is_empty():
			name = str(bark.get("speaker", name)); portrait_key = str(bark.get("portrait_key", name)); sentence = str(bark.get("text", sentence))
	bark_number += 1
	triggered_named += 1
	show_radio(name,portrait_key,sentence,1)

func show_radio(speaker: String, portrait_key: String, text: String, priority: int) -> void:
	var g: Node = game.get_ref()
	if g == null or not is_instance_valid(g) or text.is_empty(): return
	if g.get("hud_controls") != null and g.hud_controls.phone != null and g.hud_controls.phone.has_method("queue_radio") and g.get_viewport().get_visible_rect().size.y > g.get_viewport().get_visible_rect().size.x:
		g.hud_controls.phone.queue_radio(speaker, text, priority)
		return
	if layer == null: _build(g)
	who_label.text = speaker.to_upper()
	text_label.text = text
	face.texture = Portraits.display_texture(portrait_key if not portrait_key.is_empty() else speaker)
	card.visible = true
	card.modulate.a = 1.0
	var width := float(g.get_viewport().get_visible_rect().size.x)
	var height := float(g.get_viewport().get_visible_rect().size.y)
	var selected_x := width * 0.5
	var selected_y := height * 0.5
	if g is Node3D and g.get("selected_id") != null and g.get("mission") != null:
		for unit in g.mission.units:
			if int(unit.get("id",-1)) == int(g.selected_id) and g.get("camera") is Camera3D:
				var world_pos := Vector3(float(unit.get("x",0)),0,float(unit.get("y",0)))
				if g.camera.global_position.distance_to(world_pos) > 0.01 and not g.camera.is_position_behind(world_pos):
					var projected: Vector2 = g.camera.unproject_position(world_pos)
					selected_x = projected.x
					selected_y = projected.y
				break
	card.position = Vector2(maxf(12.0,width-card.custom_minimum_size.x-12.0) if selected_x < width*0.5 else 12.0, 12.0)
	if selected_x >= card.position.x-24.0 and selected_x <= card.position.x+card.custom_minimum_size.x+24.0 and selected_y >= 0.0 and selected_y < 130.0:
		card.position.y = maxf(12.0,minf(150.0,height-190.0))
	if fade != null and fade.is_running(): fade.kill()
	fade = g.create_tween()
	fade.tween_interval(2.2 if priority < 2 else 3.0)
	fade.tween_property(card,"modulate:a",0.0,0.7)
	fade.tween_callback(func(): card.visible = false)

func dismiss() -> void:
	if is_instance_valid(card): card.visible = false
	if fade != null and fade.is_running(): fade.kill()

func _build(g: Node) -> void:
	var width := float(g.get_viewport().get_visible_rect().size.x)
	layer = CanvasLayer.new()
	layer.layer = 15
	g.add_child(layer)
	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(minf(312.0,width-24.0),68)
	card.add_theme_stylebox_override("panel",UI.style(Color(0.04,0.075,0.085,0.96),UI.ACCENT))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	card.add_child(row)
	face = Portraits.picture("Jedi Council",Vector2(42,52))
	row.add_child(face)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	who_label = UI.label("",14,UI.ACCENT)
	column.add_child(who_label)
	text_label = UI.label("",14,UI.TEXT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.max_lines_visible = 2
	text_label.clip_text = true
	text_label.custom_minimum_size.y = 36
	column.add_child(text_label)
	for child in card.find_children("*", "Control", true, false): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
