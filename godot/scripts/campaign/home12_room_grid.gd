extends Control
## A readable touch overlay for the existing Temple cutaway.
signal room_selected(id: String, tab: String)
signal galaxy_selected
const UI = preload("res://scripts/campaign/ui.gd")
var room_buttons: Dictionary = {}
var galaxy_button: Button

func setup(rooms: Dictionary, state: Dictionary) -> void:
	name = "PhoneRoomGrid"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 8; offset_right = -8; offset_top = 84; offset_bottom = -110
	var column := UI.column(4); add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	galaxy_button = UI.button("GALAXY MAP  ·  %d missions and threats  →" % state.options.size(), func(): galaxy_selected.emit())
	galaxy_button.name = "GalaxyOverview"; galaxy_button.custom_minimum_size.y = 44
	galaxy_button.add_theme_font_size_override("font_size", 15)
	column.add_child(galaxy_button)
	var scroll := ScrollContainer.new(); scroll.name = "RoomScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new(); grid.name = "RoomGrid"; grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	for id in rooms:
		var info: Dictionary = rooms[id]
		var status: String = str(info.status)
		if info.wing != "": status += " · %d staff" % int(info.staff)
		var alert := "  !" if "NO POWER" in status or "construction" in status else ""
		var button := UI.button("%s%s\n%s" % [info.name, alert, status], func(): room_selected.emit(str(id), str(info.tab)))
		button.name = "GridRoom_" + str(id)
		button.custom_minimum_size = Vector2(0, 55)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", Color("e7c88d") if not info.built else Color("d7f1ee"))
		button.tooltip_text = str(info.detail)
		grid.add_child(button); room_buttons[id] = button
