extends Control
signal mission_selected(index: int)
const Data = preload("res://scripts/campaign/data.gd")
const UI = preload("res://scripts/campaign/ui.gd")
var campaign
var selected := 0
const CENTER = Vector2(300, 190)

func _ready() -> void:
	custom_minimum_size = Vector2(640, 500)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)

func _draw() -> void:
	var scale_value: float = minf(size.x / 600.0, size.y / 410.0)
	var origin := Vector2((size.x - 600.0 * scale_value) / 2.0, (size.y - 410.0 * scale_value) / 2.0)
	var center := origin + CENTER * scale_value
	draw_rect(Rect2(Vector2.ZERO, size), Color("101d2b"))
	for radius in [255.0, 185.0, 130.0, 95.0, 62.0, 30.0]:
		var pts := PackedVector2Array()
		for i in range(65):
			var a := float(i) / 64.0 * TAU
			pts.append(center + Vector2(cos(a) * radius, sin(a) * radius * 0.6) * scale_value)
		draw_polyline(pts, Color("35566d"), 1.0, true)
	for name in Data.get_table("galaxy", "PLANETS"):
		var p: Dictionary = Data.get_table("galaxy", "PLANETS")[name]
		var pos := origin + Vector2(float(p.x), float(p.y)) * scale_value
		draw_circle(pos, 2.6 * scale_value, Color("8daab6"))
		if name in ["Coruscant", "Alderaan", "Balmorra", "Ord Mantell", "Dantooine", "Ossus", "Nar Shaddaa", "Ilum", "Ruusan"]:
			draw_string(ThemeDB.fallback_font, pos + Vector2(6, -5), str(name), HORIZONTAL_ALIGNMENT_LEFT, -1, 13 * scale_value, UI.MUTED)
	for i in range(campaign.state.options.size()):
		var option: Dictionary = campaign.state.options[i]
		var mission: Dictionary = Data.get_table("missions", "MISSIONS").get(str(option.mission), {})
		var planet := str(mission.get("where", "")).split("·")[-1].strip_edges()
		var point: Dictionary = Data.get_table("galaxy", "PLANETS").get(planet, {"x": 300, "y": 190})
		var pos := origin + Vector2(float(point.x), float(point.y)) * scale_value
		var color: Color = UI.ACCENT if bool(option.get("story", false)) else UI.GOLD
		if i == selected: draw_circle(pos, 15.0 * scale_value, Color(color, 0.25))
		draw_circle(pos, (9.0 if i == selected else 7.0) * scale_value, color)
		draw_string(ThemeDB.fallback_font, pos + Vector2(15, 18), str(option.get("n", mission.get("n", option.mission))), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * scale_value, UI.TEXT)

func _on_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	var scale_value: float = minf(size.x / 600.0, size.y / 410.0)
	var origin := Vector2((size.x - 600.0 * scale_value) / 2.0, (size.y - 410.0 * scale_value) / 2.0)
	for i in range(campaign.state.options.size()):
		var option: Dictionary = campaign.state.options[i]
		var mission: Dictionary = Data.get_table("missions", "MISSIONS").get(str(option.mission), {})
		var planet := str(mission.get("where", "")).split("·")[-1].strip_edges()
		var point: Dictionary = Data.get_table("galaxy", "PLANETS").get(planet, {"x": 300, "y": 190})
		var pos := origin + Vector2(float(point.x), float(point.y)) * scale_value
		if pos.distance_to(event.position) <= 20.0 * scale_value:
			mission_selected.emit(i)
			accept_event()
			return
