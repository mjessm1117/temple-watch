extends Control
## Live, compact view of the same galaxy signals used by the full map.
signal opened
const Map = preload("res://scripts/campaign/galaxy_map.gd")
const UI = preload("res://scripts/campaign/ui.gd")
var map: Control

func setup(campaign, compact: bool) -> void:
	name = "MiniGalaxy"
	custom_minimum_size = Vector2(164, 82) if compact else Vector2(192, 136)
	var backing := UI.panel(Color(0.025, 0.065, 0.09, 0.94))
	add_child(backing); backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map = Map.new(); map.mini = true; map.campaign = campaign
	add_child(map); map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.offset_top = 16; map.offset_bottom = -17
	var button := Button.new(); button.name = "OpenGalaxy"
	button.flat = true; button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(button); button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func(): opened.emit())
	var title := UI.label("GALAXY  ↗", 11, UI.ACCENT)
	add_child(title); title.position = Vector2(8, 2); title.size.x = 145; title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var threats := 0
	for planet in map.planets:
		if preload("res://scripts/campaign/events11_engine.gd").threat(campaign.state, planet) >= 2: threats += 1
	var badge := UI.label("%d missions  ·  %d threats" % [map.offers.size(), threats], 10, UI.GOLD)
	add_child(badge); badge.position = Vector2(8, custom_minimum_size.y - 17)
	badge.size.x = custom_minimum_size.x - 16
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
