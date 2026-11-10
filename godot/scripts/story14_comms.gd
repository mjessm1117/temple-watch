extends RefCounted
## Battle-only portrait barks. Observes presentation state without changing mission logic.

const Portraits = preload("res://scripts/story14_portraits.gd")
var game: WeakRef
var lines: Dictionary
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

func _init(g: Node) -> void:
	game = weakref(g)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story14-barks.json"))
	lines = parsed.get("heroes",{}) if parsed is Dictionary else {}

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
		next_bark_at = now + 2800

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
	bark_number += 1
	if layer == null: _build(g)
	who_label.text = name.to_upper()
	text_label.text = sentence
	face.texture = Portraits.texture(name)
	card.visible = true
	card.modulate.a = 1.0
	if fade != null and fade.is_running(): fade.kill()
	fade = g.create_tween()
	fade.tween_interval(1.8)
	fade.tween_property(card,"modulate:a",0.0,0.9)
	fade.tween_callback(func(): card.visible = false)

func _build(g: Node) -> void:
	var phone := preload("res://scripts/phone_layout.gd").narrow(preload("res://scripts/phone_layout.gd").window_size())
	layer = CanvasLayer.new()
	layer.layer = 15
	g.add_child(layer)
	card = PanelContainer.new()
	card.position = Vector2(8,50) if phone else Vector2(16,70)
	card.custom_minimum_size = Vector2(252,58) if phone else Vector2(338,82)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.075,0.095,0.9)
	style.border_color = Color("62b8c9")
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	card.add_theme_stylebox_override("panel",style)
	layer.add_child(card)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",7)
	card.add_child(row)
	face = Portraits.picture("Jedi Council",Vector2(34,44) if phone else Vector2(52,68))
	row.add_child(face)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	who_label = Label.new()
	who_label.add_theme_font_size_override("font_size",11 if phone else 13)
	who_label.add_theme_color_override("font_color",Color("6ed0dc"))
	who_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(who_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size",11 if phone else 13)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(text_label)
