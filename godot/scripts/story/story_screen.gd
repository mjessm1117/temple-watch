extends Control
## Shared visual controller for briefing, dialogue, and Codex scenes.

const StoryEngine = preload("res://scripts/story/story_engine.gd")
@export_enum("briefing", "dialogue", "codex") var mode := "briefing"
var engine: RefCounted
var campaign_state: Dictionary = {}
var scene_data: Dictionary = {}
var codex_category := "planet"
var demo_mode := true
var body: VBoxContainer
var result_label: Label

func set_campaign_state(value: Dictionary) -> void:
	demo_mode = false
	campaign_state = value
	engine = StoryEngine.new(campaign_state)
	if is_node_ready(): _build()

func show_scene(value: Dictionary) -> void:
	scene_data = value
	if is_node_ready(): _build()

func _ready() -> void:
	if engine == null: engine = StoryEngine.new(campaign_state)
	if campaign_state.is_empty(): campaign_state = engine.state
	if demo_mode and mode == "briefing" and scene_data.is_empty(): scene_data = engine.start_briefing("relay")
	if demo_mode and mode == "dialogue" and scene_data.is_empty():
		campaign_state.story.done = 1
		scene_data = engine.next_temple_talk(campaign_state)
	if demo_mode and mode == "codex" and campaign_state.codex.is_empty():
		for pair in [["planet","coruscant"],["planet","dantooine"],["character","malgus"],["character","gnost"],["mission","relay"],["mission","dock"]]:
			engine.unlock_codex(campaign_state,pair[0],pair[1])
	_build()

func _build() -> void:
	for child in get_children(): child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("101826")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color("18283a")
	wash.anchor_right = 1
	wash.offset_bottom = 120
	add_child(wash)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 64)
	outer.add_theme_constant_override("margin_right", 64)
	outer.add_theme_constant_override("margin_top", 38)
	outer.add_theme_constant_override("margin_bottom", 34)
	add_child(outer)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	outer.add_child(body)
	if mode == "codex": _build_codex()
	else: _build_story()

func _label(text: String, size: int, color: Color = Color("ecf0f5")) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text: String, description: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 56
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color",Color("f3f2ec"))
	button.add_theme_color_override("font_hover_color",Color("f6d796"))
	button.add_theme_stylebox_override("normal",_style(Color("23364c"),Color("49647d")))
	button.add_theme_stylebox_override("hover",_style(Color("314960"),Color("cba96b")))
	button.add_theme_stylebox_override("pressed",_style(Color("435970"),Color("eac78c")))
	return button

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 11
	box.content_margin_bottom = 11
	return box

func _build_story() -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 25)
	body.add_child(head)
	var mark := _label("TEMPLE WATCH",21,Color("d6ac70"))
	mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	mark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(mark)
	var year := _label("%s  ·  %s BBY" % ["OLD REPUBLIC" if int(campaign_state.era)==1 else "RUUSAN" if int(campaign_state.era)==2 else "HIGH REPUBLIC",str(campaign_state.story.bby)],19,Color("9eb0c5"))
	year.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(year)
	var divider := HSeparator.new()
	body.add_child(divider)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 38)
	body.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 430
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 27)
	columns.add_child(left)
	left.add_child(_label("MISSION FILE  /  %s" % scene_data.get("eyebrow","TEMPLE"),20,Color("d6ac70")))
	left.add_child(_label(scene_data.get("title","The Temple"),50))
	if scene_data.has("who") and scene_data.who != "":
		var name: String = scene_data.get("name",engine.table("CAST").get(scene_data.who,{}).get("n",scene_data.who))
		left.add_child(_label(name.to_upper(),25,Color("a9d1d8")))
	var narrative := _label(scene_data.get("text",""),27,Color("dce5ec"))
	narrative.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(narrative)
	if scene_data.get("goal","") != "":
		left.add_child(_label("OBJECTIVE",19,Color("d6ac70")))
		left.add_child(_label(scene_data.goal,24,Color("b8c7d3")))
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 500
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 16)
	columns.add_child(right)
	right.add_child(_label("YOUR DECISION",20,Color("d6ac70")))
	if scene_data.get("kind","") == "briefing":
		right.add_child(_label("Choose an approach before deployment.",24,Color("b8c7d3")))
	for choice in scene_data.get("choices",[]):
		var button := _button(choice.get("label","Continue"))
		button.pressed.connect(_choose.bind(choice.get("id","")))
		right.add_child(button)
		if choice.get("text","") != "": right.add_child(_label(choice.text,18,Color("a9bdcf")))
	if scene_data.get("choices",[]).is_empty():
		right.add_child(_label("The record is complete.",25,Color("b8c7d3")))
	result_label = _label("",20,Color("b9dca9"))
	result_label.custom_minimum_size.y = 50
	right.add_child(result_label)
	var foot := HBoxContainer.new()
	body.add_child(foot)
	var hint := _label("Every choice leaves a record in the Temple archive.",19,Color("8398ad"))
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(hint)
	var vision := _label("THE VISION  %d / 10" % int(campaign_state.story.shadow),20,Color("d6ac70"))
	vision.autowrap_mode = TextServer.AUTOWRAP_OFF
	foot.add_child(vision)

func _choose(id: String) -> void:
	var result: Dictionary = engine.apply_choice(campaign_state,id)
	if not result.get("ok",false):
		result_label.text = result.get("reason","Unavailable")
		return
	result_label.text = "Decision recorded: %s" % result.choice.get("label","")
	for node in result_label.get_parent().get_children():
		if node is Button: node.disabled = true

func _build_codex() -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation",25)
	body.add_child(head)
	var title := _label("TEMPLE ARCHIVE",48)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var year := _label("CODEX  /  %s BBY" % str(campaign_state.story.bby),21,Color("d6ac70"))
	year.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(year)
	body.add_child(_label("History survives because someone remembered it.",23,Color("a9bdcf")))
	body.add_child(HSeparator.new())
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",36)
	body.add_child(columns)
	var rail := VBoxContainer.new()
	rail.custom_minimum_size.x = 290
	rail.add_theme_constant_override("separation",4)
	columns.add_child(rail)
	for item in engine.table("KINDS"):
		var category: String = item[0]
		var button := _button(str(item[1]))
		button.custom_minimum_size.y = 39
		button.add_theme_font_size_override("font_size",18)
		for style_name in ["normal","hover","pressed"]:
			var style: StyleBoxFlat = button.get_theme_stylebox(style_name).duplicate()
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			button.add_theme_stylebox_override(style_name,style)
		button.pressed.connect(_category.bind(category))
		rail.add_child(button)
	var entries_panel := PanelContainer.new()
	entries_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries_panel.add_theme_stylebox_override("panel",_style(Color("192a3d"),Color("445c73")))
	columns.add_child(entries_panel)
	var scroll := ScrollContainer.new()
	entries_panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",20)
	scroll.add_child(list)
	var category_name := codex_category.capitalize()
	list.add_child(_label(category_name.to_upper() + "  /  DISCOVERED",20,Color("d6ac70")))
	var entries: Array = engine.codex_entries(campaign_state,codex_category)
	if entries.is_empty(): list.add_child(_label("No entries discovered yet.",26,Color("a9bdcf")))
	for entry in entries:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",_style(Color("23364c"),Color("49647d")))
		list.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation",10)
		card.add_child(content)
		content.add_child(_label(str(entry.name).replace("_"," ").capitalize(),29,Color("f2e6cd")))
		content.add_child(_label(entry.lore,22,Color("d0dce6")))
	body.add_child(_label("New entries appear as missions, people and places become known to your Order.",18,Color("8398ad")))

func _category(category: String) -> void:
	codex_category = category
	_build()
