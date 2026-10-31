extends Control

const UI = preload("res://scripts/campaign/ui.gd")
const Settings = preload("res://scripts/settings.gd")
var picked := "normal"
var buttons: Dictionary = {}

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("101826")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(460, 0)
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var title := Label.new()
	title.text = "Temple Watch"
	title.add_theme_color_override("font_color", UI.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "COMMAND THE ORDER  ·  CHOOSE YOUR DIFFICULTY"
	subtitle.add_theme_color_override("font_color", UI.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var choices := Settings.all()
	for id in ["story", "normal", "hard", "legend"]:
		var entry: Dictionary = choices[id]
		var button := Button.new()
		button.text = "%s — %s" % [entry.name, entry.description]
		button.toggle_mode = true
		button.button_pressed = id == picked
		button.custom_minimum_size.y = 54
		button.pressed.connect(_pick.bind(id))
		column.add_child(button)
		buttons[id] = button
	var flow = get_node("/root/CampaignFlow")
	var new_button := Button.new()
	new_button.text = "New Campaign"
	new_button.custom_minimum_size.y = 52
	new_button.pressed.connect(func(): flow.new_campaign(picked))
	column.add_child(new_button)
	var resume := Button.new()
	resume.text = "Continue Campaign"
	resume.custom_minimum_size.y = 48
	var saved = preload("res://scripts/campaign/state.gd").new()
	resume.disabled = not saved.load_save(flow.save_path)
	resume.pressed.connect(flow.continue_campaign)
	column.add_child(resume)
	var start := Button.new()
	start.text = "Direct Rescue Mission"
	start.custom_minimum_size.y = 58
	start.pressed.connect(_start)
	column.add_child(start)
	for child in column.get_children():
		if child is Button: UI.style_button(child)

func _pick(id: String) -> void:
	picked = id
	for key in buttons: buttons[key].button_pressed = key == id

func _start() -> void:
	Settings.difficulty = picked
	get_node("/root/CampaignFlow").direct_rescue(picked)
