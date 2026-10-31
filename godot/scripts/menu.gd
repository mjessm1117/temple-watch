extends Control

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
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Break the Detention Line · Rescue Aide Mira Tal"
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
	var start := Button.new()
	start.text = "Start Mission"
	start.custom_minimum_size.y = 58
	start.pressed.connect(_start)
	column.add_child(start)

func _pick(id: String) -> void:
	picked = id
	for key in buttons: buttons[key].button_pressed = key == id

func _start() -> void:
	Settings.difficulty = picked
	get_tree().change_scene_to_file("res://scenes/rescue.tscn")
