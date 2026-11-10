extends RefCounted
## Battle narrative cards and legacy state barks.
const Portraits = preload("res://scripts/story14_portraits.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Beats = preload("res://scripts/story/story14_beats.gd")
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

func _init(g: Node) -> void:
	game = weakref(g)
	g.set_meta("story_comms", self)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story14-barks.json"))
	lines = parsed.get("heroes",{}) if parsed is Dictionary else {}
	var story_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-story.json"))
	var records: Dictionary = story_data.get("records",{}) if story_data is Dictionary else {}
	legacy_barks = records.get("BARKS",{})
	hero_barks = records.get("HERO_BARKS",{})

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
	if g.mission == null or g.demo_mode or event_mode: return
	var players: Array = g.mission.units.filter(func(u): return str(u.get("side","")) == "player")
	var enemies: Array = g.mission.living("enemy")
	var triggers: Array[String] = []
	var visible := false
	var boss_visible := false
	for foe in enemies:
		if bool(foe.get("awake",false)) or bool(foe.get("spotted",false)): visible = true
		if (bool(foe.get("boss",false)) or bool(foe.get("duel_boss",false)) or bool(foe.get("villain11",false)) or str(foe.get("kind","")) in ["sith_lord","marchion_ro","lourna_dee"]) and (bool(foe.get("awake",false)) or bool(foe.get("spotted",false))): boss_visible = true
	if visible and not contact:
		contact = true
		triggers.append("contact")
	if boss_visible and not villain:
		villain = true
		triggers.append("villain")
	for ally in players:
		var id := str(ally.get("id",""))
		if str(ally.get("status","")) == "down" or int(ally.get("hp",1)) <= 0:
			if not seen.has(id):
				seen[id] = true
				triggers.append("ally_down")
	var completed: int = g.mission.objective_state.get("done",{}).size()
	if completed > previous_objectives: triggers.append("objective_done")
	previous_objectives = completed
	if enemies.size() == 1 and previous_enemy_count > 1: triggers.append("last_enemy")
	previous_enemy_count = enemies.size()
	for event in triggers: pending.append(event)
	if now >= next_bark_at and not pending.is_empty():
		_show(g,pending.pop_front(),players)
		next_bark_at = now + 4000

func fallback(kind: String, actor_id: String, target_id: String) -> Dictionary:
	var g: Node = game.get_ref()
	if g == null or g.mission == null: return {}
	var key: String = {"reveal":"contact", "reinforce":"contact", "flank":"contact", "hit":"contact", "miss":"contact", "crit":"last_enemy", "hurt":"ally_down", "kill":"last_enemy", "objective_hit":"objective_done", "villain_reveal":"villain"}.get(kind,kind)
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
	var name: String = heroes[bark_number % heroes.size()]
	var options: Array = lines[name].get(event,[])
	if options.size() < 3: return
	var sentence: String = options[bark_number % options.size()]
	var portrait_key := name
	var kind: String = {"contact":"reveal", "ally_down":"hurt", "villain":"villain_reveal"}.get(event, "")
	if not kind.is_empty():
		var actor_id := ""
		var target_id := ""
		for ally in players:
			var story_id: Variant = Beats.NAMES.find_key(str(ally.get("name", "")))
			var id := str(story_id) if story_id != null else str(ally.get("rid", ally.get("id", "")))
			if str(ally.get("name", "")) == name: actor_id = id
			if event == "ally_down" and (str(ally.get("status", "")) == "down" or int(ally.get("hp", 1)) <= 0): target_id = id
		var context := {"villain_name":str(g.mission.objective_state.get("villain_name", ""))}
		var bark: Dictionary = Beats.pick_bark(kind, actor_id, target_id, context)
		if not bark.is_empty():
			name = str(bark.get("speaker", name)); portrait_key = str(bark.get("portrait_key", name)); sentence = str(bark.get("text", sentence))
	bark_number += 1
	show_radio(name,portrait_key,sentence,1)

func show_radio(speaker: String, portrait_key: String, text: String, priority: int) -> void:
	var g: Node = game.get_ref()
	if g == null or not is_instance_valid(g) or text.is_empty(): return
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
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed or event is InputEventScreenTouch and event.pressed: dismiss())
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
	text_label.max_lines_visible = 2
	text_label.clip_text = true
	text_label.custom_minimum_size.y = 36
	column.add_child(text_label)
