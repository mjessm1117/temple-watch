extends Control
## Portrait context map: all active markers stay visible in the shallow drawer.
const Data = preload("res://scripts/campaign/data.gd")
const Intel = preload("res://scripts/campaign/galaxy_intel.gd")
const Strategy = preload("res://scripts/w25_galaxy_strategy.gd")
var campaign
var selected := 0
var offers: Array = []
var scans: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 88
	refresh()
	resized.connect(queue_redraw)

func refresh() -> void:
	offers.clear()
	for option in campaign.state.options:
		offers.append({"planet": Intel.planet_for(campaign.story.mission(str(option.mission)))})
	scans = Strategy.active_scans(campaign.state) if campaign.has_method("advance_strategy_day25") else []
	queue_redraw()

func selected_planet() -> String:
	return str(offers[selected].planet) if selected >= 0 and selected < offers.size() else ""

func point_for(title: String) -> Vector2:
	var planet: Dictionary = Data.get_table("galaxy", "PLANETS").get(title, {})
	return Vector2(14.0 + (float(planet.get("x", 300)) - 72.0) / 443.0 * maxf(1.0, size.x - 28.0),
		18.0 + (float(planet.get("y", 182)) - 50.0) / 250.0 * maxf(1.0, size.y - 36.0))

func _draw() -> void:
	if size.x < 40 or size.y < 40: return
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1d24"))
	for row in Data.get_table("galaxy", "REGIONS"):
		var key := str(row[0])
		var points: Array[Vector2] = []
		for title in Data.get_table("galaxy", "PLANETS"):
			if str(Data.get_table("galaxy", "PLANETS")[title].reg) == key: points.append(point_for(title))
		for i in points.size() - 1: draw_line(points[i], points[i + 1], Color("31505b"), 1.0, true)
	var chosen := selected_planet()
	for title in Data.get_table("galaxy", "PLANETS"):
		var p := point_for(title)
		draw_circle(p, 2.0, Color("5a7880"))
		if Strategy.contacted(campaign.state, str(Data.get_table("galaxy", "PLANETS")[title].reg)):
			draw_circle(p + Vector2(-5, 4), 2.0, Color("7fd99a"))
	for offer in offers:
		draw_circle(point_for(str(offer.planet)) + Vector2(5, -4), 2.5, Color("f6bf67"))
	for scan in scans:
		var p := point_for(str(scan.planet)) + Vector2(7, 5)
		draw_arc(p, 4.0, 0, TAU, 16, Color("79d3e2"), 1.5, true)
	if chosen != "":
		var p := point_for(chosen)
		draw_arc(p, 9.0, 0, TAU, 24, Color("dbe7e4"), 2.0, true)
		var font := ThemeDB.fallback_font
		var label_x := clampf(p.x + 12, 4.0, size.x - 120.0)
		draw_string_outline(font, Vector2(label_x, 15), chosen, HORIZONTAL_ALIGNMENT_LEFT, 116, 13, 3, Color("071217"))
		draw_string(font, Vector2(label_x, 15), chosen, HORIZONTAL_ALIGNMENT_LEFT, 116, 13, Color("dbe7e4"))
