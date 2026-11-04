extends Control
const UI = preload("res://scripts/campaign/ui.gd")
const Settings = preload("res://scripts/settings.gd")
const World = preload("res://scripts/ui_world.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var picked := "normal"
var buttons: Dictionary = {}

func _ready() -> void:
	if Phone.narrow(Phone.window_size()):
		_build_phone(); return
	var backdrop := World.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var overlay := preload("res://scripts/ui_atmosphere.gd").new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: outer.add_theme_constant_override("margin_"+side,36)
	add_child(outer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",48)
	outer.add_child(row)
	var identity := UI.column(12)
	identity.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(identity)
	identity.add_child(UI.label("JEDI COUNCIL  /  CORUSCANT  /  3,660 BBY",14,UI.GOLD))
	identity.add_child(UI.label("TEMPLE\nWATCH",64,UI.TEXT))
	identity.add_child(UI.label("COMMAND THE ORDER.\nBEND WHAT IS COMING.",18,UI.ACCENT))
	var space := Control.new()
	space.size_flags_vertical = SIZE_EXPAND_FILL
	identity.add_child(space)
	var legend := UI.panel(Color(0.04,0.07,0.08,0.88))
	identity.add_child(legend)
	var lore := UI.column(8)
	legend.add_child(lore)
	lore.add_child(UI.label("A VISION OF FIRE",23,UI.ACCENT))
	lore.add_child(UI.label("In meditation, the whole Council saw the same thing: the Temple burning, clone soldiers on its steps, a hooded figure in a red-lit office. Nobody knows when. Grand Master Zym orders it sealed in the Archives.",16))
	lore.add_child(UI.label("Run the Temple, send squads where they matter, and bend what’s coming.",16,UI.MUTED))
	var frame := UI.panel(Color(0.04,0.075,0.09,0.96))
	frame.custom_minimum_size.x = 490
	row.add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	var column := UI.column(12)
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(column)
	column.add_child(preload("res://scripts/graphics_options.gd").new())
	column.add_child(UI.label("THE SEALED RECORD",26,UI.ACCENT))
	column.add_child(UI.label("NEW CAMPAIGN  /  CHOOSE YOUR DIFFICULTY",13,UI.MUTED))
	var descriptions := {
		"story":"Weaker enemies, 6 turns to bleed out, an extra medkit, more Senate money.",
		"normal":"The intended fight. 4 turns to bleed out. Misses in a row get a hidden aim boost.",
		"hard":"Sharper enemies, an extra trooper per wave, 3 turns to bleed out, no aim help.",
		"legend":"Tougher, sharper enemies and 2 turns to bleed out. Expect losses."}
	var choices := Settings.all()
	for id in ["story", "normal", "hard", "legend"]:
		var entry: Dictionary = choices[id]
		var button := UI.button("%s\n%s" % [entry.name,descriptions[id]],_pick.bind(id))
		button.toggle_mode = true
		button.button_pressed = id == picked
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 83
		button.add_theme_font_size_override("font_size",14)
		column.add_child(button)
		buttons[id] = button
	var flow = get_node("/root/CampaignFlow")
	column.add_child(UI.button("New Campaign",func(): flow.new_campaign(picked)))
	var saved = preload("res://scripts/campaign/state.gd").new()
	column.add_child(UI.button("Continue Campaign",flow.continue_campaign,saved.load_save(flow.save_path)))
	column.add_child(UI.button("Direct Rescue Mission",_start))
	column.add_child(UI.label("THE ARCHIVE REMEMBERS EVERY CHOICE",12,UI.MUTED))
	UI.slide(outer)

func _build_phone() -> void:
	var backdrop := World.new(); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(backdrop)
	var shade := ColorRect.new(); shade.color = Color("071116c9")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(shade)
	var outer := MarginContainer.new(); outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: outer.add_theme_constant_override("margin_" + side, 10)
	add_child(outer)
	var body := UI.column(5); outer.add_child(body)
	var head := HBoxContainer.new(); body.add_child(head)
	var title := UI.label("TEMPLE WATCH", 32, UI.TEXT); title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var settings := UI.button("GRAPHICS", func() -> void: _phone_settings(body))
	head.add_child(settings)
	body.add_child(UI.label("COMMAND THE ORDER. BEND WHAT IS COMING.", 14, UI.ACCENT))
	if Phone.window_size().x < Phone.window_size().y:
		body.add_child(UI.label("Rotate your phone for the battle map.", 14, UI.GOLD))
	var choices := HFlowContainer.new(); choices.add_theme_constant_override("h_separation", 4); body.add_child(choices)
	for id in ["story", "normal", "hard", "legend"]:
		var button := UI.button(id.capitalize(), _pick.bind(id)); button.toggle_mode = true
		button.button_pressed = id == picked; choices.add_child(button); buttons[id] = button
	var actions := HFlowContainer.new(); actions.add_theme_constant_override("h_separation", 5); body.add_child(actions)
	var flow = get_node("/root/CampaignFlow")
	var start := UI.button("START", func(): flow.new_campaign(picked)); start.name = "StartButton"
	actions.add_child(start)
	var saved = preload("res://scripts/campaign/state.gd").new()
	var continuing := UI.button("CONTINUE", flow.continue_campaign, saved.load_save(flow.save_path))
	continuing.name = "ContinueButton"; actions.add_child(continuing)
	actions.add_child(UI.button("DIRECT RESCUE", _start))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; body.add_child(scroll)
	var lore := UI.column(5); lore.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(lore)
	lore.add_child(UI.label("A VISION OF FIRE", 18, UI.GOLD))
	lore.add_child(UI.label("In meditation, the whole Council saw the same thing: the Temple burning, clone soldiers on its steps, a hooded figure in a red-lit office. Nobody knows when. Grand Master Zym orders it sealed in the Archives.", 14))
	lore.add_child(UI.label("Run the Temple, send squads where they matter, and bend what’s coming.", 14, UI.MUTED))

func _phone_settings(body: VBoxContainer) -> void:
	if body.has_node("PhoneGraphics"):
		body.get_node("PhoneGraphics").queue_free(); return
	var settings := preload("res://scripts/graphics_options.gd").new()
	settings.name = "PhoneGraphics"; body.add_child(settings)

func _pick(id: String) -> void:
	picked = id
	for key in buttons: buttons[key].button_pressed = key == id

func _start() -> void:
	Settings.difficulty = picked
	get_node("/root/CampaignFlow").direct_rescue(picked)
