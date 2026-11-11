extends VBoxContainer
## One settings component for title, Temple and battle entry points.
const UI = preload("res://scripts/campaign/ui.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
const StylePrefs = preload("res://scripts/campaign/style21_preferences.gd")
const RescueSettings = preload("res://scripts/settings.gd")
var choices: OptionButton
var status: Label

static func build_settings_panel() -> Control:
	var panel: Control = (load("res://scripts/graphics_options.gd") as Script).new()
	panel.name = "SettingsPanel"
	return panel

func _ready() -> void:
	visibility_changed.connect(_maybe_open_shared)
	_maybe_open_shared.call_deferred()
	AudioServer.set_bus_mute(0, not bool(StylePrefs.get_value("sound")))
	add_theme_constant_override("separation", 6)
	add_child(UI.label("SETTINGS", 20, UI.GOLD))
	add_child(UI.label("Graphics tier", 14, UI.ACCENT))
	choices = OptionButton.new(); choices.name = "GraphicsTier"
	choices.custom_minimum_size.y = 44
	UI.style_button(choices)
	for tier in ["Low", "Medium", "High"]: choices.add_item(tier)
	add_child(choices)
	status = UI.label("", 14, UI.MUTED); status.name = "GraphicsStatus"
	add_child(status)
	choices.item_selected.connect(_select)
	get_node("/root/Graphics").changed.connect(refresh)
	_option("Sound", "Sound", ["On", "Off"], bool(StylePrefs.get_value("sound")), func(value: int): StylePrefs.set_value("sound", value == 0))
	_option("TextSize", "Text size", ["Standard", "Large", "Extra large"], [1.0, 1.15, 1.3].find(float(StylePrefs.get_value("text_scale"))), func(value: int): StylePrefs.set_value("text_scale", [1.0, 1.15, 1.3][value]))
	_option("ActionCamera", "Action camera", ["On", "Off"], bool(Prefs.get_value("cine")), func(value: int): Prefs.set_value("cine", value == 0))
	_option("CameraMotion", "Camera motion", ["Full", "Reduced"], not bool(Prefs.get_value("motion")), func(value: int): Prefs.set_value("motion", value == 1))
	_option("AutoSelect", "Auto select next unit", ["On", "Off"], bool(RescueSettings.battle_value("auto_select")), func(value: int): RescueSettings.set_battle_value("auto_select", value == 0))
	var controls := preload("res://scripts/w24_hud_controls_settings.gd").new()
	controls.name = "ControlsSection"
	add_child(controls)
	refresh()

func _maybe_open_shared() -> void:
	if not is_inside_tree() or not is_visible_in_tree(): return
	var scene := get_tree().current_scene
	if scene == null or not scene.scene_file_path.ends_with("rescue.tscn"): return
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.name == "SharedSettings": return
		ancestor = ancestor.get_parent()
	var flow := get_node_or_null("/root/CampaignFlow")
	if flow != null and not is_instance_valid(flow.settings_panel): flow.open_settings.call_deferred()

func _option(key: String, title: String, labels: Array, value: Variant, save: Callable) -> void:
	var row := HBoxContainer.new(); row.name = key + "Row"
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var heading := UI.label(title, 14); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(heading)
	var choice := OptionButton.new(); choice.name = key
	choice.custom_minimum_size = Vector2(132, 44)
	UI.style_button(choice)
	for entry in labels: choice.add_item(str(entry))
	choice.select((0 if value else 1) if value is bool else maxi(0, int(value)))
	choice.item_selected.connect(save)
	row.add_child(choice)

func refresh() -> void:
	var graphics = get_node("/root/Graphics")
	choices.select(graphics.TIERS.find(graphics.requested))
	status.text = graphics.status_text()

func _select(index: int) -> void:
	var graphics = get_node("/root/Graphics")
	var error: Error = graphics.select_tier(graphics.TIERS[index])
	if error != OK:
		refresh(); status.text = "Could not save graphics: " + error_string(error)
