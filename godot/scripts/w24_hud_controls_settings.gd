extends VBoxContainer
## Shared Controls section; ConfigFile is the cross-lane controls contract.
const PATH := "user://controls24.cfg"
var source: Object
var config := ConfigFile.new()
var keymap: Dictionary = {}
var remap_action := ""
var key_buttons: Dictionary = {}
var binding_source: Object

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	config.load(PATH)
	var defaults := {"cam_sensitivity": 1.0, "invert_pan": false, "invert_rotate": false, "edge_pan": true, "confirm_move": preload("res://scripts/phone_layout.gd").touch_device(), "keymap": {}}
	for key in defaults:
		if not config.has_section_key("controls", key): config.set_value("controls", key, defaults[key])
	config.save(PATH)
	keymap = config.get_value("controls", "keymap", {})
	var title := Label.new(); title.text = "CONTROLS"; title.add_theme_font_size_override("font_size", 20); add_child(title)
	var sensitivity := HSlider.new(); sensitivity.name = "CameraSensitivity"
	sensitivity.min_value = 0.5; sensitivity.max_value = 2.0; sensitivity.step = 0.1
	sensitivity.custom_minimum_size = Vector2(100, 44)
	sensitivity.value = clampf(float(config.get_value("controls", "cam_sensitivity", 1.0)), 0.5, 2.0)
	var sensitivity_label := Label.new(); sensitivity_label.text = "Camera sensitivity  %.1f" % sensitivity.value
	add_child(sensitivity_label); add_child(sensitivity)
	sensitivity.value_changed.connect(func(value: float) -> void:
		sensitivity_label.text = "Camera sensitivity  %.1f" % value
		_save("cam_sensitivity", value))
	_toggle("Invert pan", "invert_pan", false)
	_toggle("Invert rotate", "invert_rotate", false)
	_toggle("Edge pan", "edge_pan", true)
	_toggle("Confirm move", "confirm_move", preload("res://scripts/phone_layout.gd").touch_device())
	var keys := Label.new(); keys.text = "KEY BINDINGS"; keys.add_theme_font_size_override("font_size", 16); add_child(keys)
	var bindings: Dictionary = {}
	if source != null and (source.has_method("get_bindings24") or source.has_method("bindings24")):
		binding_source = source
		bindings = source.call("get_bindings24" if source.has_method("get_bindings24") else "bindings24")
	else:
		for path in ["res://scripts/input_controls.gd", "res://scripts/combat_targeting.gd"]:
			var script: Script = load(path)
			if script == null: continue
			var candidate: Object = script.new()
			if candidate.has_method("get_bindings24") or candidate.has_method("bindings24"):
				binding_source = candidate
				bindings = candidate.call("get_bindings24" if candidate.has_method("get_bindings24") else "bindings24")
				break
	if bindings.is_empty():
		var fallback := {"Move": "1", "Shoot": "2", "Strike": "3", "Push": "4", "Overwatch": "6", "Hunker": "7", "Confirm": "Enter", "Cancel": "Esc", "Next unit": "Tab", "Rotate": "Q / E", "Pan": "W / A / S / D"}
		for action in fallback:
			var row := Label.new(); row.text = "%s   %s" % [action, fallback[action]]
			row.custom_minimum_size.y = 44; row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(row)
		return
	for action in bindings:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8); add_child(row)
		var name_label := Label.new(); name_label.text = str(action).capitalize(); name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(name_label)
		var button := Button.new(); button.custom_minimum_size = Vector2(120, 44)
		button.text = _keys_text(keymap.get(action, bindings[action])); row.add_child(button)
		key_buttons[action] = button
		button.pressed.connect(_begin_remap.bind(str(action), button))

func _toggle(title: String, key: String, default: bool) -> void:
	var button := CheckButton.new(); button.name = key.to_pascal_case()
	button.text = title; button.custom_minimum_size.y = 44
	button.button_pressed = bool(config.get_value("controls", key, default))
	button.toggled.connect(func(value: bool) -> void: _save(key, value))
	add_child(button)

func _save(key: String, value: Variant) -> void:
	config.set_value("controls", key, value)
	config.save(PATH)

func _keys_text(value: Variant) -> String:
	if value is Array:
		var names: PackedStringArray = []
		for entry in value: names.append(OS.get_keycode_string(int(entry)) if entry is int else str(entry))
		return ", ".join(names)
	return OS.get_keycode_string(int(value)) if value is int else str(value)

func _begin_remap(action: String, button: Button) -> void:
	remap_action = action; button.text = "Press a key…"
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if remap_action == "" or not event is InputEventKey or not event.pressed or event.echo: return
	var action := remap_action; remap_action = ""
	var key := OS.get_keycode_string(event.keycode)
	if key == "": return
	keymap[action] = [key]
	if binding_source != null and binding_source.has_method("set_binding24"):
		binding_source.call("set_binding24", action, key)
	_save("keymap", keymap)
	key_buttons[action].text = key
	get_viewport().set_input_as_handled()
	set_process_input(false)
