extends Control
## A persistent 3D viewport with projected, keyboard-accessible room hit targets.
signal room_selected(id: String, tab: String)
signal room_hovered(description: String)
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
const Rooms = preload("res://scripts/campaign/temple_rooms.gd")
const Geometry = preload("res://scripts/campaign/temple_geometry.gd")
const Plates = preload("res://scripts/campaign/home13_room_plates.gd")
const PhoneNames = preload("res://scripts/home14_room_names.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Show16Rooms = preload("res://scripts/show16_rooms.gd")
const Stage25 = preload("res://scripts/w25_temple_stage.gd")
var viewport: SubViewport
var camera: Camera3D
var world: Node3D
var temple: Node3D
var galaxy: Node3D
var art: RefCounted
var rooms: Dictionary = {}
var buttons: Dictionary = {}
var cell_nodes: Dictionary = {}
var time := 0.0
var hovered := ""
var sound: AudioStreamPlayer
var phone_names: Control
var state: Dictionary
var badges: Dictionary = {}
var priority_key := ""
var focused_room := ""
var highlighted_room := ""
var last_highlight_usec := 0
var camera_tween: Tween
var camera_home := Vector3(0, 17.3, 42)
var camera_home_size := 21.0
var ui_safe_rect := Rect2()
var stage25: RefCounted
var edge_badges: Dictionary = {}

func set_ui_safe_rect(rect: Rect2) -> void:
	if ui_safe_rect == rect: return
	ui_safe_rect = rect
	if camera == null: return
	if focused_room != "": focus_room(focused_room)
	else: restore_camera()

func _clear_area() -> Rect2:
	var area := Rect2(Vector2.ZERO, size)
	if ui_safe_rect.size.x <= 0 or ui_safe_rect.size.y <= 0: return area
	var covered := area.intersection(ui_safe_rect)
	if not covered.has_area(): return area
	var strips := [Rect2(Vector2.ZERO, Vector2(size.x, covered.position.y)),
		Rect2(Vector2(0, covered.end.y), Vector2(size.x, size.y - covered.end.y)),
		Rect2(Vector2.ZERO, Vector2(covered.position.x, size.y)),
		Rect2(Vector2(covered.end.x, 0), Vector2(size.x - covered.end.x, size.y))]
	var best := Rect2()
	for strip in strips:
		if strip.get_area() > best.get_area(): best = strip
	return best if best.has_area() else area

func _framed_position(at: Vector3, framing_size: float) -> Vector3:
	var area := _clear_area()
	var center := area.get_center() / size if size.x > 0 and size.y > 0 else Vector2(0.5, 0.5)
	var aspect := size.x / maxf(size.y, 1.0)
	var base := Vector3(at.x, camera_home.y + (at.y - 5.8), camera_home.z)
	return base - camera.global_transform.basis.x * ((center.x - 0.5) * framing_size * aspect) + camera.global_transform.basis.y * ((center.y - 0.5) * framing_size)

func setup(save_state: Dictionary, room_badges: Dictionary = {}) -> void:
	state = save_state
	badges = room_badges
	for key in ["Galaxy", "Research", "Roster", "Build", "Command"]:
		if badges.has(key): priority_key = key; break
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true; container.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(container)
	viewport = SubViewport.new(); viewport.size = Vector2i(1366, 768)
	viewport.own_world_3d = true; viewport.msaa_3d = Viewport.MSAA_2X; container.add_child(viewport)
	world = Node3D.new(); viewport.add_child(world)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("060e14")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("a6bfc9"); env.environment.ambient_light_energy = 0.32
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.glow_enabled = true; env.environment.glow_intensity = 0.6
	world.add_child(env)
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_color = Color("b5d7e6"); key.light_energy = 1.0; world.add_child(key)
	var rim := DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-15, 155, 0)
	rim.light_color = Color("d6b68a"); rim.light_energy = 0.6; world.add_child(rim)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = (76.0 if size.x < size.y else 21.0) if Phone.narrow(Phone.window_size()) else 31.5; camera_home_size = camera.size
	world.add_child(camera); camera.current = true
	camera.position = camera_home; camera.look_at(Vector3(0, 5.8, 0))
	art = Geometry.new(); galaxy = art.galaxy(world, false)
	temple = Node3D.new(); temple.name = "TempleCutaway"; world.add_child(temple)
	art.architecture(temple)
	for row in Rooms.ROOMS:
		if row[0] == "war" and state.get("slots", {}).has("t0"): continue
		if row[3] != "" and preload("res://scripts/campaign/strat_base.gd").slot_of(state, row[3]) == "":
			var home: String = preload("res://scripts/campaign/data.gd").get_table("temple", "WING_HOME")[row[3]]
			if state.get("slots", {}).has(home) and state.slots[home] != row[3]: continue
		var info: Dictionary = Rooms.describe(row, state); rooms[info.id] = info
		if info.id in ["a0", "a1"] and state.get("slots", {}).has(info.id):
			rooms.erase(info.id); continue
		if Prefs.get_value("cb"): info.color = Color("70baff") if info.built else Color("eeac65")
		cell_nodes[info.id] = art.room(temple, info)
		_make_button(info)
	_make_edge_badges()
	if Phone.narrow(Phone.window_size()):
		phone_names = PhoneNames.new(); phone_names.buttons = buttons; phone_names.rooms = rooms; add_child(phone_names)
		phone_names.hide()
	art.batch_static(temple)
	var jedi_actors: Array[Node3D] = Show16Rooms.populate(cell_nodes, rooms, state, RenderingServer.get_current_rendering_method() == "gl_compatibility")
	stage25 = Stage25.new()
	stage25.setup(art, cell_nodes, rooms, state, jedi_actors)
	if Phone.narrow(Phone.window_size()):
		for actor in jedi_actors:
			var room_id := actor.get_parent().name
			var portrait := TextureRect.new()
			portrait.name = "JediFace_" + str(actor.get_meta("show16_jedi"))
			portrait.texture = load("res://assets/portraits/jedi/%s.png" % actor.get_meta("show16_jedi"))
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			portrait.position = Vector2(2, 0)
			portrait.size = Vector2(19, 23)
			buttons[room_id].add_child(portrait)
	sound = AudioStreamPlayer.new(); sound.volume_db = -30; add_child(sound)
	var synth := preload("res://scripts/audio.gd").new()
	sound.stream = synth._synthesize("click"); synth.free()
	resized.connect(_project_rooms)
	_project_rooms()

func _make_button(info: Dictionary) -> void:
	var b := Button.new(); b.name = "Room_" + str(info.id); b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if Phone.narrow(Phone.window_size()): b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.tooltip_text = "%s\n%s%s\nOpen %s" % [info.name, info.detail, " · " + str(info.module) if info.module != "" else "", info.tab]
	if not Prefs.get_value("tips"): b.tooltip_text = ""
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new(); style.bg_color = Color(0.1, 0.4, 0.46, 0.16 if style_name != "normal" else 0)
		style.border_color = Color("7bdce4") if style_name != "normal" else Color("a68c64" if not info.built else "386873")
		style.set_border_width_all(1); style.set_corner_radius_all(2); b.add_theme_stylebox_override(style_name, style)
	add_child(b); buttons[info.id] = b
	if not info.built: b.add_child(preload("res://scripts/campaign/home_room_outline.gd").new())
	var name_label := Label.new(); name_label.text = str(PhoneNames.SHORT.get(str(info.id), str(info.name).to_upper())) if Phone.narrow(Phone.window_size()) else str(info.name).to_upper()
	name_label.add_theme_font_size_override("font_size", 12 if Phone.narrow(Phone.window_size()) else 10 if info.kind in ["spire", "council"] else 11)
	name_label.add_theme_color_override("font_color", info.color if info.built else Color("e0c49a"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = 2; name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(name_label)
	var line := Label.new()
	line.text = str(info.status) if info.built else "BUILDING" if info.status == "Under construction" else "SEALED · EXCAVATE" if info.kind == "vault" else "BUILD HERE" if info.kind in ["spire", "annex"] or info.wing != "" else str(info.status)
	if info.wing != "" and info.built: line.text += " · %d staff" % int(info.staff)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 10)
	line.add_theme_color_override("font_color", Color("e3c384") if info.built else Color("c5ae88"))
	line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	line.offset_top = -17
	line.offset_bottom = -1; line.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(line)
	if info.built and str(info.battle_plate) != "":
		var battle_line := Label.new(); battle_line.name = "BattleBonus"
		battle_line.text = str(info.battle_plate)
		battle_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		battle_line.add_theme_font_size_override("font_size", 9)
		battle_line.add_theme_color_override("font_color", Color("88dfbd"))
		battle_line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		battle_line.offset_top = -32; battle_line.offset_bottom = -17
		var battle_plate := StyleBoxFlat.new(); battle_plate.bg_color = Color(0.018, 0.045, 0.057, 0.96)
		battle_plate.set_corner_radius_all(2); battle_line.add_theme_stylebox_override("normal", battle_plate)
		battle_line.add_theme_color_override("font_shadow_color", Color("02090c"))
		battle_line.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(battle_line)
		battle_line.hide()
	for label in [name_label, line]:
		var plate := StyleBoxFlat.new(); plate.bg_color = Color(0.018, 0.045, 0.057, 0.82)
		plate.set_corner_radius_all(2); label.add_theme_stylebox_override("normal", plate)
	for label in [name_label, line]:
		label.add_theme_color_override("font_shadow_color", Color("02090c"))
		label.add_theme_constant_override("shadow_offset_x", 1); label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.name = "RoomName"; line.name = "RoomDetail"
	if str(info.id) == "war" or "NO POWER" in str(info.status) or "construction" in str(info.status):
		var alert := Label.new(); alert.name = "RoomAlert"
		alert.text = str(state.options.size()) if str(info.id) == "war" else "!"
		alert.add_theme_font_size_override("font_size", 12)
		alert.add_theme_color_override("font_color", Color("f6bf67"))
		alert.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		alert.offset_left = -20; alert.offset_right = -2
		alert.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(alert)
	var key := badge_key(str(info.id))
	if badges.has(key):
		if key == priority_key:
			for style_name in ["normal", "hover", "pressed", "focus"]:
				var focus_style: StyleBoxFlat = b.get_theme_stylebox(style_name).duplicate()
				focus_style.border_color = Color("ffe2a0"); focus_style.set_border_width_all(3)
				focus_style.bg_color = Color(0.28, 0.20, 0.06, 0.32)
				b.add_theme_stylebox_override(style_name, focus_style)
		var badge := Label.new(); badge.name = "ActionBadge"
		badge.text = "%d %s" % [int(badges[key].count), {"Galaxy":"G", "Research":"R", "Build":"B", "Roster":"P", "Command":"C"}.get(key, "!")]
		badge.add_theme_font_size_override("font_size", 14)
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_color_override("font_color", Color("102126") if key == priority_key else Color("ffe4a4"))
		var badge_style := StyleBoxFlat.new(); badge_style.bg_color = Color("ffe2a0") if key == priority_key else Color("183039"); badge_style.border_color = Color("ffe2a0") if key == priority_key else Color("e3bd72")
		badge_style.set_border_width_all(1); badge_style.set_content_margin_all(3)
		badge.add_theme_stylebox_override("normal", badge_style)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(badge)
	name_label.visible = not Phone.narrow(Phone.window_size())
	line.visible = not Phone.narrow(Phone.window_size())
	b.mouse_entered.connect(_hover.bind(str(info.id)))
	b.focus_entered.connect(_hover.bind(str(info.id)))
	b.mouse_exited.connect(_unhover.bind(str(info.id)))
	b.focus_exited.connect(_unhover.bind(str(info.id)))
	b.pressed.connect(activate_room.bind(str(info.id)))

func activate_room(id: String) -> void:
	if rooms.has(id): room_selected.emit(id, str(rooms[id].tab))

func _make_edge_badges() -> void:
	var order := ["Galaxy", "Research", "Build", "Roster", "Command"]
	var glyphs := {"Galaxy":"G", "Research":"R", "Build":"B", "Roster":"P", "Command":"C"}
	var rail := ColorRect.new(); rail.name = "EdgeBadgeRail"
	rail.color = Color("071821"); rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.position = Vector2(8, 56); rail.size = Vector2(48, 252)
	rail.visible = Phone.narrow(Phone.window_size())
	add_child(rail)
	var letters := PackedStringArray()
	for key in order:
		if not badges.has(key): continue
		letters.append("%s %d" % [glyphs[key], int(badges[key].count)])
		var badge := Button.new()
		badge.name = "EdgeBadge_" + key
		badge.text = ""
		badge.visible = Phone.narrow(Phone.window_size())
		badge.tooltip_text = str(badges[key].why)
		badge.custom_minimum_size = Vector2(48, 44)
		badge.add_theme_font_size_override("font_size", 14)
		badge.z_index = 2
		badge.add_theme_color_override("font_color", Color("ffe2a0") if key == priority_key else Color("ffe4a4"))
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.set_content_margin_all(0)
		for kind in ["normal", "hover", "pressed", "focus"]: badge.add_theme_stylebox_override(kind, style)
		add_child(badge); edge_badges[key] = badge
		badge.pressed.connect(activate_room.bind({"Galaxy":"war", "Research":"archives", "Build":"works", "Roster":"barracks", "Command":"council"}[key]))
	var rail_text := Label.new(); rail_text.name = "EdgeBadgeText"
	rail_text.text = "\n".join(letters)
	rail_text.position = Vector2(8, 56); rail_text.size = Vector2(48, float(letters.size()) * 52.0)
	rail_text.z_index = 3
	rail_text.add_theme_font_size_override("font_size", 14)
	rail_text.add_theme_color_override("font_color", Color("ffe4a4"))
	rail_text.add_theme_constant_override("line_spacing", 33)
	rail_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rail_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail_text.visible = Phone.narrow(Phone.window_size())
	add_child(rail_text)

static func badge_key(id: String) -> String:
	return {"war":"Galaxy", "archives":"Research", "works":"Build", "barracks":"Roster", "council":"Command"}.get(id, "")

func focus_room(id: String) -> void:
	if not rooms.has(id): return
	_set_highlight(id)
	focused_room = id
	if camera_tween != null: camera_tween.kill()
	var at: Vector3 = rooms[id].position
	var focus_size := 15.0 if Phone.narrow(Phone.window_size()) else 14.0
	if Phone.narrow(Phone.window_size()) and size.x > 0 and size.y > 0:
		var area := _clear_area()
		focus_size = maxf(maxf(focus_size, 6.0 * size.y / maxf(area.size.x, 1.0)), 3.5 * size.y / maxf(area.size.y, 1.0))
	var target := _framed_position(at, focus_size)
	if size.x < size.y: target += camera.global_transform.basis.y * (focus_size * 0.16)
	if not Phone.narrow(Phone.window_size()) and ui_safe_rect.size == Vector2.ZERO: target.x += 4.5
	if Prefs.get_value("motion"):
		camera.position = target; camera.size = focus_size; return
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera, "position", target, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "size", focus_size, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func restore_camera() -> void:
	_set_highlight("")
	focused_room = ""
	if camera_tween != null: camera_tween.kill()
	var home := _framed_position(Vector3(0, 5.8, 0), camera_home_size)
	if Prefs.get_value("motion"):
		camera.position = home; camera.size = camera_home_size; return
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera, "position", home, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "size", camera_home_size, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _set_highlight(id: String) -> void:
	if highlighted_room == id: return
	if stage25 != null: stage25.focus(id, cell_nodes, rooms)
	last_highlight_usec = Time.get_ticks_usec()
	for room_id in [highlighted_room, id]:
		if room_id == "" or not buttons.has(room_id): continue
		var button: Button = buttons[room_id]
		for kind in ["normal", "hover", "pressed", "focus"]:
			var style: StyleBoxFlat = button.get_theme_stylebox(kind).duplicate()
			style.border_color = Color("ffe2a0") if room_id == id else Color("a68c64") if not rooms[room_id].built else Color("386873")
			style.set_border_width_all(3 if room_id == id else 1)
			button.add_theme_stylebox_override(kind, style)
	highlighted_room = id

func _hover(id: String) -> void:
	hovered = id
	buttons[id].get_node("RoomName").visible = true
	buttons[id].get_node("RoomDetail").visible = not Phone.narrow(Phone.window_size())
	var info: Dictionary = rooms[id]
	room_hovered.emit("%s  /  %s%s  →  %s" % [info.name, info.detail, " · " + str(info.module) if info.built and info.module != "" else "", info.tab])
	if sound != null: sound.play()

func _unhover(id: String) -> void:
	if hovered == id:
		buttons[id].get_node("RoomName").visible = true
		buttons[id].get_node("RoomDetail").visible = not Phone.narrow(Phone.window_size())
		hovered = ""; room_hovered.emit("Select a room to manage the Order.  •  Gold: module ready  •  Dark: awaiting construction")

func _process(delta: float) -> void:
	if camera == null: return
	if get_parent() != null and get_parent().get("selected_room") == "forge":
		preload("res://scripts/campaign/forge_screen.gd").render(get_parent())
	if Prefs.get_value("motion"):
		_project_rooms(); return
	time += delta * float(Prefs.get_value("speed"))
	galaxy.rotation.y = time * 0.012
	art.animate(time)
	if stage25 != null: stage25.animate(time)
	if focused_room == "" and (camera_tween == null or not camera_tween.is_running()):
		camera.position = _framed_position(Vector3(0, 5.8, 0), camera_home_size) + Vector3(sin(time * 0.12) * 0.3, sin(time * 0.16) * 0.12, 0)
	_project_rooms()

func _project_rooms() -> void:
	if camera == null or size.x < 1: return
	var badge_y := 56.0
	for key in ["Galaxy", "Research", "Build", "Roster", "Command"]:
		if not edge_badges.has(key): continue
		var edge: Button = edge_badges[key]
		edge.position = Vector2(8, badge_y)
		edge.size = Vector2(48, 44)
		badge_y += 52
	var portrait := size.x < size.y
	var picker: Control = get_parent().get("room_picker") if get_parent() != null else null
	var stage_open := not portrait or picker == null or not picker.visible
	for id in rooms:
		var info: Dictionary = rooms[id]
		var at: Vector3 = info.position
		var width := 3.5 if info.kind in ["spire", "council"] else 4.9
		var height := 1.8 if info.kind == "vault" else 2.5
		var a := camera.unproject_position(at + Vector3(-width / 2, height, 1.8))
		var b := camera.unproject_position(at + Vector3(width / 2, 0.0, 1.8))
		var ratio := size / Vector2(viewport.size)
		var projected_size := (b - a) * ratio
		var target_size := projected_size.max(Vector2(44, 44)) if Phone.narrow(Phone.window_size()) else projected_size
		buttons[id].position = a * ratio - (target_size - projected_size) * 0.5
		buttons[id].size = target_size
		Plates.layout(buttons[id], info, Phone.narrow(Phone.window_size()))
		buttons[id].visible = stage_open
		var key := badge_key(str(id))
		var focal: bool = id == focused_room or id == hovered
		var name_label: Label = buttons[id].get_node("RoomName")
		name_label.visible = buttons[id].visible and (not Phone.narrow(Phone.window_size()) or id == "war")
		if Phone.narrow(Phone.window_size()) and id == "war":
			name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			name_label.position = Vector2(64, 127) - buttons[id].position
			name_label.size = Vector2(64, 20)
		if Phone.narrow(Phone.window_size()) and focal:
			name_label.add_theme_font_size_override("font_size", 14)
			if buttons[id].has_node("ActionBadge"):
				name_label.offset_top = -17; name_label.offset_bottom = 0
		buttons[id].get_node("RoomDetail").visible = buttons[id].visible and not Phone.narrow(Phone.window_size())
		if buttons[id].has_node("RoomAlert"): buttons[id].get_node("RoomAlert").hide()
		if buttons[id].has_node("ActionBadge"):
			var badge: Label = buttons[id].get_node("ActionBadge")
			badge.visible = false
			if buttons[id].has_node("RoomAlert"): buttons[id].get_node("RoomAlert").hide()
