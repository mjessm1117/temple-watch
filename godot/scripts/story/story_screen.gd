extends Control
signal completed
## All story modes retain the campaign-owned engine and completion contract.
const StoryEngine = preload("res://scripts/story/story_engine.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const World = preload("res://scripts/ui_world.gd")
const Portraits14 = preload("res://scripts/story14_portraits.gd")
@export_enum("briefing", "dialogue", "codex") var mode := "briefing"
var engine: RefCounted
var campaign_state: Dictionary = {}
var scene_data: Dictionary = {}
var codex_category := "planet"
var demo_mode := true
var outer_frame: MarginContainer
var body: VBoxContainer
var result_label: Label
var narrative: Label
var bond_meter: ProgressBar
var bond_label: Label
var choices_box: VBoxContainer
var choice_buttons: Array[Button] = []
var typed := 0.0
var decision_recorded := false
var completed_once := false
var portrait_count := 0
var dialogue_lines: PackedStringArray
var dialogue_index := 0
var speaker_plate: Label
var speaker_portrait: TextureRect
var big_speaker_portrait: TextureRect
var big_speaker_caption: Label

func set_campaign_state(value: Dictionary) -> void:
	demo_mode = false
	campaign_state = value
	engine = StoryEngine.new(campaign_state)
	if is_node_ready(): _build()

func show_scene(value: Dictionary) -> void:
	scene_data = value
	decision_recorded = false
	completed_once = false
	if is_node_ready(): _build()

func _ready() -> void:
	var flow = get_node_or_null("/root/CampaignFlow")
	if flow != null and flow.active and demo_mode:
		demo_mode = false
		campaign_state = flow.session().state
		engine = StoryEngine.new(campaign_state)
		scene_data = flow.screen
		completed.connect(flow.story_finished)
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
	UI.clear(self)
	choice_buttons.clear()
	narrative = null
	bond_meter = null
	portrait_count = 0
	big_speaker_portrait = null
	big_speaker_caption = null
	var bg := World.new()
	bg.stage = "archive" if mode == "codex" else "temple"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color(0.02,0.05,0.06,0.4 if mode == "codex" else 0.78)
	wash.mouse_filter = MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wash)
	var dust := preload("res://scripts/ui_atmosphere.gd").new()
	dust.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dust)
	var outer := MarginContainer.new()
	outer_frame = outer
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var phone := get_viewport_rect().size.x < 900
	for side in ["left","right"]: outer.add_theme_constant_override("margin_"+side,10 if phone else 36)
	for side in ["top","bottom"]: outer.add_theme_constant_override("margin_"+side,8 if phone else 24)
	add_child(outer)
	body = UI.column(16)
	outer.add_child(body)
	if mode == "codex": _build_codex()
	else: _build_story()
	UI.slide(outer)

func _header(title: String, detail: String) -> void:
	var head := HBoxContainer.new()
	body.add_child(head)
	head.add_child(UI.icon("holocron",32))
	var mark := UI.label(title,18 if get_viewport_rect().size.x < 900 else 24,UI.ACCENT)
	mark.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(mark)
	var date := UI.label(detail,14,UI.GOLD)
	date.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(date)
	body.add_child(HSeparator.new())

func _build_story() -> void:
	var kind: String = scene_data.get("kind","briefing")
	var is_talk := kind in ["talk","beat","grief","scene11"]
	var phone := get_viewport_rect().size.x < 900
	_header("TEMPLE WATCH", "%s  /  %s BBY" % ["OLD REPUBLIC" if int(campaign_state.era)==1 else "RUUSAN" if int(campaign_state.era)==2 else "HIGH REPUBLIC",str(campaign_state.story.bby)])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(row)
	var who: String = scene_data.get("who","")
	var speaker: String = scene_data.get("name",engine.table("CAST").get(who,{}).get("n","Jedi Council"))
	if speaker.is_empty(): speaker = "Jedi Council"
	if speaker.contains(" & "): speaker = speaker.get_slice(" & ",0)
	if not phone:
		var visual := UI.column(12)
		visual.custom_minimum_size.x = 330
		row.add_child(visual)
		# --- wave10 story ---
		visual.add_child(UI.label("BATTLE COMMS" if kind == "beat" else "TEMPLE CONVERSATION" if is_talk else "HOLOLINK  /  MISSION CONTROL",13,UI.GOLD))
		if is_talk:
			var portraits := HBoxContainer.new()
			portraits.add_theme_constant_override("separation",8)
			visual.add_child(portraits)
			var pair_names: PackedStringArray = str(scene_data.get("name","")).split(" & ") if scene_data.has("pair") or kind == "scene11" else PackedStringArray()
			_portrait(portraits,str(pair_names[0]) if pair_names.size() >= 2 else speaker,1.0,Vector2(158,230))
			_portrait(portraits,str(pair_names[1]) if pair_names.size() >= 2 else "COMMANDER",-1.0,Vector2(158,230))
			if who != "" or scene_data.has("pair") or kind == "scene11": _bond(visual,who)
		else:
			var holo_frame := UI.panel()
			visual.add_child(holo_frame)
			var holo := World.new()
			holo.stage = "holo"
			holo.planet_key = str(engine.mission(scene_data.get("id","")).get("where",scene_data.get("eyebrow","coruscant")))
			holo.custom_minimum_size = Vector2(290,225)
			holo_frame.add_child(holo)
			visual.add_child(UI.label(str(engine.mission(scene_data.get("id","")).get("where",scene_data.get("eyebrow","TARGET PROJECTION"))).to_upper(),14,UI.ACCENT))
			big_speaker_portrait = _portrait(visual,speaker,1.0,Vector2(290,180))
		visual.add_child(UI.label("TEMPLE RECORD\nJEDI ARCHIVE · SQUAD 06" if kind == "scene11" else "SECURE TRANSMISSION\nJEDI ARCHIVE · CHANNEL 06",12,UI.MUTED))
	var frame := UI.panel(Color(0.04,0.075,0.085,0.96))
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(frame)
	var content := UI.column(6 if phone else 12)
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	var scroll := preload("res://scripts/touch_scroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	scroll.add_child(content)
	var speaking := HBoxContainer.new()
	speaking.add_theme_constant_override("separation",12)
	content.add_child(speaking)
	if phone:
		speaker_portrait = Portraits14.picture(speaker,Vector2(44,54))
		speaking.add_child(speaker_portrait)
	speaker_plate = UI.label("SPEAKER  " + speaker.to_upper(),14,UI.ACCENT)
	speaker_plate.size_flags_horizontal = SIZE_EXPAND_FILL
	speaking.add_child(speaker_plate)
	var skip := UI.button("SKIP",_skip_dialogue)
	skip.custom_minimum_size = Vector2(64,44 if phone else 34)
	skip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skip.add_theme_font_size_override("font_size",14 if phone else 11)
	speaking.add_child(skip)
	content.add_child(UI.label(str(scene_data.get("eyebrow","TEMPLE")).to_upper(),13,UI.GOLD))
	content.add_child(UI.label(scene_data.get("title","The Temple"),23 if phone else 32,UI.ACCENT))
	dialogue_lines = str(scene_data.get("text","")).split("\n",false)
	if dialogue_lines.is_empty(): dialogue_lines = PackedStringArray([""])
	dialogue_index = 0
	narrative = UI.label(_dialogue_text(dialogue_lines[0]),16 if phone else 18)
	content.add_child(narrative)
	typed = 0
	narrative.visible_characters = 0
	var reveal := UI.button("TAP TO ADVANCE  ›",_advance_dialogue)
	reveal.custom_minimum_size.y = 56 if phone else 30
	reveal.add_theme_font_size_override("font_size",14 if phone else 12)
	content.add_child(reveal)
	if scene_data.get("goal","") != "":
		var goal := str(scene_data.goal)
		if phone: goal = goal.get_slice(".",0)
		content.add_child(UI.label("OBJECTIVE  /  " + goal,12 if phone else 16,UI.GOLD))
	content.add_child(UI.label("YOUR DECISION",13,UI.MUTED))
	choices_box = UI.column(8)
	content.add_child(choices_box)
	choices_box.visible = false
	for choice in scene_data.get("choices",[]):
		var card := UI.column(3)
		choices_box.add_child(card)
		var label: String = choice.get("label","Continue")
		if kind == "arc_resolution": label += "\n" + str(choice.get("effect", ""))
		var button := UI.button(label,_choose.bind(choice.get("id",""),true))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 64 if kind == "arc_resolution" else 56 if phone else 44
		card.add_child(button)
		choice_buttons.append(button)
		var preview := _preview(choice)
		if not preview.is_empty(): card.add_child(UI.label(preview,13,UI.MUTED))
		if choice.get("text","") != "": card.add_child(UI.label(choice.text,14,UI.MUTED))
	if scene_data.get("choices",[]).is_empty():
		choices_box.add_child(UI.button("Return to Temple" if kind == "debrief" else "Continue",_finish))
	result_label = UI.label("",15,UI.ACCENT)
	content.add_child(result_label)
	var foot := HBoxContainer.new()
	body.add_child(foot)
	var hint := UI.label("Every choice leaves a record in the Temple archive.",13,UI.MUTED)
	hint.size_flags_horizontal = SIZE_EXPAND_FILL
	foot.add_child(hint)
	var vision := UI.label("THE VISION  %d / 10" % int(campaign_state.story.shadow),14,UI.GOLD)
	vision.autowrap_mode = TextServer.AUTOWRAP_OFF
	foot.add_child(vision)

func _portrait(parent: Node, caption: String, facing: float, dimensions: Vector2) -> TextureRect:
	var frame := UI.panel()
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(frame)
	var column := UI.column(6)
	frame.add_child(column)
	var portrait := Portraits14.picture(caption,dimensions)
	column.add_child(portrait)
	var caption_label := UI.label(caption.to_upper(),12,UI.ACCENT)
	column.add_child(caption_label)
	if dimensions.x > 200: big_speaker_caption = caption_label
	portrait_count += 1
	return portrait

func _bond(parent: Node, who: String) -> void:
	# --- wave10 story ---
	var pair: Dictionary = campaign_state.bonds.get(scene_data.get("pair",""),{})
	bond_label = UI.label("BOND %d / 8  ·  %d cohesion" % [int(pair.get("lvl",0)),int(pair.get("n",0))] if scene_data.has("pair") else "BOND / TRUST  %d" % int(campaign_state.saga.t.get(who,0)),14,UI.GOLD)
	parent.add_child(bond_label)
	bond_meter = ProgressBar.new()
	bond_meter.min_value = 0 if scene_data.has("pair") else -3
	bond_meter.max_value = 8 if scene_data.has("pair") else 3
	bond_meter.value = float(pair.get("lvl",0)) if scene_data.has("pair") else float(campaign_state.saga.t.get(who,0))
	bond_meter.show_percentage = false
	bond_meter.custom_minimum_size.y = 8
	var track := UI.style(UI.PANEL_ALT)
	track.set_content_margin_all(0)
	bond_meter.add_theme_stylebox_override("background",track)
	var fill := UI.style(UI.ACCENT,UI.ACCENT)
	fill.set_content_margin_all(0)
	bond_meter.add_theme_stylebox_override("fill",fill)
	parent.add_child(bond_meter)

func _preview(choice: Dictionary) -> String:
	var parts: Array[String] = []
	if int(choice.get("bond_points",0)) != 0: parts.append("Bond cohesion +%d" % int(choice.bond_points))
	for key in choice.get("cost",{}): parts.append("Cost: %s %s" % [_number(choice.cost[key]),str(key).capitalize()])
	for key in choice.get("fx",{}):
		var value = choice.fx[key]
		# --- wave10 story ---
		if key == "flag": parts.append("Recorded in the Temple archive")
		elif key in ["mission","personal"]: parts.append("Mission lead unlocked")
		elif key == "unitDark": parts.append("Jedi Darkness changes")
		if key == "trust" and value is Dictionary:
			for person in value:
				var name: String = engine.table("CAST").get(person,{}).get("n",person)
				parts.append("%s trust %s%s" % [name,"+" if value[person] > 0 else "",_number(value[person])])
		elif key == "loyalty" and value is Dictionary:
			parts.append("%s loyalty %s" % [str(value.get("seat","Council")).capitalize(),_number(value.get("n",0))])
		elif value is int or value is float:
			var title: String = {"t":"Trust","mob":"Mobility","orderDark":"Order Darkness","favor":"Senate Favor","bond_points":"Bond cohesion"}.get(key,str(key).capitalize())
			parts.append("%s %s%s" % [title,"+" if value > 0 else "",_number(value)])

	return " · ".join(parts)

func _number(value: Variant) -> String:
	return str(int(value)) if (value is float or value is int) and float(value) == int(value) else str(value)

func _process(delta: float) -> void:
	# Autowrapped archive entries can temporarily enlarge a container during layout.
	if is_instance_valid(outer_frame) and outer_frame.size != size:
		outer_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if is_instance_valid(narrative) and narrative.visible_characters >= 0:
		typed += delta*65
		narrative.visible_characters = int(typed)
		if narrative.visible_characters >= narrative.text.length(): narrative.visible_characters = -1

func _reveal() -> void:
	if is_instance_valid(narrative): narrative.visible_characters = -1

func _dialogue_text(line: String) -> String:
	var cut := line.find(": ")
	return line.substr(cut+2) if cut > 0 and cut < 40 else line

func _advance_dialogue() -> void:
	if narrative.visible_characters != -1:
		_reveal()
		return
	if dialogue_index + 1 >= dialogue_lines.size():
		choices_box.visible = true
		return
	dialogue_index += 1
	var line := dialogue_lines[dialogue_index]
	var cut := line.find(": ")
	if cut > 0 and cut < 40:
		var name := line.substr(0,cut)
		_set_speaker(name)
	narrative.text = _dialogue_text(line)
	narrative.visible_characters = 0
	typed = 0
	if dialogue_index + 1 == dialogue_lines.size(): choices_box.visible = true

func _skip_dialogue() -> void:
	dialogue_index = dialogue_lines.size()-1
	var line := dialogue_lines[dialogue_index]
	var cut := line.find(": ")
	if cut > 0 and cut < 40: _set_speaker(line.substr(0,cut))
	narrative.text = _dialogue_text(line)
	_reveal()
	choices_box.visible = true

func _set_speaker(name: String) -> void:
	speaker_plate.text = "SPEAKER  " + name.to_upper()
	if is_instance_valid(speaker_portrait): speaker_portrait.texture = Portraits14.display_texture(name)
	if is_instance_valid(big_speaker_portrait): big_speaker_portrait.texture = Portraits14.display_texture(name)
	if is_instance_valid(big_speaker_caption): big_speaker_caption.text = name.to_upper()

func _choose(id: String, animate: bool = false) -> void:
	if decision_recorded: return
	var result: Dictionary = engine.apply_choice(campaign_state,id)
	if not result.get("ok",false):
		result_label.text = result.get("reason","Unavailable")
		return
	decision_recorded = true
	_reveal()
	for button in choice_buttons: button.disabled = true
	result_label.text = "Decision recorded: %s" % result.choice.get("label","")
	if is_instance_valid(bond_meter):
		# --- wave10 story ---
		var pair: Dictionary = campaign_state.bonds.get(scene_data.get("pair",""),{})
		var value := float(pair.get("lvl",0)) if scene_data.has("pair") else float(campaign_state.saga.t.get(scene_data.get("who",""),0))
		bond_label.text = "BOND %d / 8  ·  %d cohesion" % [int(pair.get("lvl",0)),int(pair.get("n",0))] if scene_data.has("pair") else "BOND / TRUST  %d" % int(value)
		create_tween().tween_property(bond_meter,"value",value,0.45)
	# Button activation lets the player see the bond settle before departure.
	# Direct callers retain the immediate completion contract.
	if animate and is_instance_valid(bond_meter):
		await get_tree().create_timer(0.55).timeout
	_finish()

func _finish() -> void:
	if completed_once: return
	completed_once = true
	completed.emit()

func _build_codex() -> void:
	var found := 0
	for category in campaign_state.codex.values(): found += category.size()
	_header("TEMPLE ARCHIVE", "%d ENTRIES FOUND  /  %s BBY" % [found,str(campaign_state.story.bby)])
	body.add_child(UI.label("History survives because someone remembered it.",24,UI.ACCENT))
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation",6)
	body.add_child(tabs)
	var journal_button := UI.button("JOURNAL",_category.bind("journal"))
	journal_button.toggle_mode = true
	journal_button.button_pressed = codex_category == "journal"
	tabs.add_child(journal_button)
	for item in engine.table("KINDS"):
		var category: String = item[0]
		var all: Array = engine.codex_entries(campaign_state,category,false)
		var met: Array = engine.codex_entries(campaign_state,category)
		var button := UI.button("%s  %d/%d" % [item[1],met.size(),all.size()],_category.bind(category))
		button.add_theme_font_size_override("font_size",13)
		button.toggle_mode = true
		button.button_pressed = category == codex_category
		tabs.add_child(button)
	var panel := UI.panel(Color(0.04,0.075,0.085,0.88))
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(panel)
	var scroll := preload("res://scripts/touch_scroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var list := UI.column(12)
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list)
	if codex_category == "journal":
		_build_journal(list)
		body.add_child(UI.button("← Return to Temple",_finish))
		return
	list.add_child(UI.label(codex_category.to_upper() + "  /  ARCHIVE RECORDS",14,UI.GOLD))
	var entries: Array = engine.codex_entries(campaign_state,codex_category,false)
	entries.sort_custom(func(a,b): return int(campaign_state.codex.get(codex_category,{}).get(a.id,false)) > int(campaign_state.codex.get(codex_category,{}).get(b.id,false)))
	if entries.is_empty(): list.add_child(UI.label("No records in this archive yet.",18,UI.MUTED))
	for entry in entries:
		var unlocked: bool = campaign_state.codex.get(codex_category,{}).get(entry.id,false)
		var card := UI.panel(UI.PANEL_ALT if unlocked else UI.PANEL)
		card.set_meta("unlocked",unlocked)
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",18)
		card.add_child(row)
		row.add_child(UI.icon("holocron" if unlocked else "locked",48,UI.ACCENT if unlocked else UI.MUTED))
		var content := UI.column(5)
		content.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(content)
		content.add_child(UI.label(str(entry.name).replace("_"," ").capitalize() if unlocked else "Sealed holocron",23,UI.ACCENT if unlocked else UI.MUTED))
		content.add_child(UI.label(entry.lore if unlocked else "UNDISCOVERED · Encounter this record’s subject to unlock its history.",16,UI.TEXT if unlocked else UI.MUTED))
	body.add_child(UI.label("New records unlock as missions, people and places become known to your Order.",13,UI.MUTED))
	body.add_child(UI.button("← Return to Temple",_finish))

func _build_journal(list: VBoxContainer) -> void:
	var record: Dictionary = engine.journal(campaign_state)
	list.add_child(UI.label("ERA %d  /  THE TEMPLE JOURNAL" % int(record.era),22,UI.GOLD))
	for section in [["CHOICES REMEMBERED",record.choices],["PERSONAL ARCS",record.arcs],["VILLAIN TRANSMISSIONS",record.get("villain",[])],["SQUAD SCENES",record.get("squad",[])],["FALLEN",record.fallen]]:
		list.add_child(UI.label(str(section[0]),16,UI.ACCENT))
		if section[1].is_empty(): list.add_child(UI.label("No entries yet.",14,UI.MUTED))
		for line in section[1]: list.add_child(UI.label(str(line),16,UI.TEXT))

func _category(category: String) -> void:
	codex_category = category
	_build()
