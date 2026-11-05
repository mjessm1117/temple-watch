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

func setup(save_state: Dictionary) -> void:
	state = save_state
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
	env.environment.ambient_light_color = Color("a6bfc9"); env.environment.ambient_light_energy = 0.45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.glow_enabled = true; env.environment.glow_intensity = 0.6
	world.add_child(env)
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_color = Color("b5d7e6"); key.light_energy = 1.0; world.add_child(key)
	var rim := DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-15, 155, 0)
	rim.light_color = Color("d6b68a"); rim.light_energy = 0.6; world.add_child(rim)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 31.5; world.add_child(camera); camera.current = true
	camera.position = Vector3(0, 17.3, 42); camera.look_at(Vector3(0, 5.8, 0))
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
	if Phone.narrow(Phone.window_size()):
		phone_names = PhoneNames.new(); phone_names.buttons = buttons; add_child(phone_names)
	art.batch_static(temple)
	sound = AudioStreamPlayer.new(); sound.volume_db = -30; add_child(sound)
	var synth := preload("res://scripts/audio.gd").new()
	sound.stream = synth._synthesize("click"); synth.free()
	resized.connect(_project_rooms)
	_project_rooms()

func _make_button(info: Dictionary) -> void:
	var b := Button.new(); b.name = "Room_" + str(info.id); b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "%s\n%s%s\nOpen %s" % [info.name, info.detail, " · " + str(info.module) if info.module != "" else "", info.tab]
	if not Prefs.get_value("tips"): b.tooltip_text = ""
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new(); style.bg_color = Color(0.1, 0.4, 0.46, 0.16 if style_name != "normal" else 0)
		style.border_color = Color("7bdce4") if style_name != "normal" else Color("a68c64" if not info.built else "386873")
		style.set_border_width_all(1); style.set_corner_radius_all(2); b.add_theme_stylebox_override(style_name, style)
	add_child(b); buttons[info.id] = b
	if not info.built: b.add_child(preload("res://scripts/campaign/home_room_outline.gd").new())
	var name_label := Label.new(); name_label.text = str(info.name).to_upper()
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
		if Phone.narrow(Phone.window_size()): battle_line.hide()
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
	name_label.visible = not Phone.narrow(Phone.window_size())
	line.visible = not Phone.narrow(Phone.window_size())
	b.mouse_entered.connect(_hover.bind(str(info.id)))
	b.focus_entered.connect(_hover.bind(str(info.id)))
	b.mouse_exited.connect(_unhover.bind(str(info.id)))
	b.focus_exited.connect(_unhover.bind(str(info.id)))
	b.pressed.connect(activate_room.bind(str(info.id)))

func activate_room(id: String) -> void:
	if rooms.has(id): room_selected.emit(id, str(rooms[id].tab))

func _hover(id: String) -> void:
	hovered = id
	buttons[id].get_node("RoomName").visible = not Phone.narrow(Phone.window_size())
	buttons[id].get_node("RoomDetail").visible = not Phone.narrow(Phone.window_size())
	var info: Dictionary = rooms[id]
	room_hovered.emit("%s  /  %s%s  →  %s" % [info.name, info.detail, " · " + str(info.module) if info.built and info.module != "" else "", info.tab])
	if sound != null: sound.play()

func _unhover(id: String) -> void:
	if hovered == id:
		buttons[id].get_node("RoomName").visible = not Phone.narrow(Phone.window_size())
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
	camera.position = Vector3(sin(time * 0.12) * 0.3, 17.3 + sin(time * 0.16) * 0.12, 42)
	camera.look_at(Vector3(0, 5.8, 0))
	_project_rooms()

func _project_rooms() -> void:
	if camera == null or size.x < 1: return
	for id in rooms:
		var info: Dictionary = rooms[id]
		var at: Vector3 = info.position
		var width := 3.5 if info.kind in ["spire", "council"] else 4.9
		var height := 1.8 if info.kind == "vault" else 2.5
		var a := camera.unproject_position(at + Vector3(-width / 2, height, 1.8))
		var b := camera.unproject_position(at + Vector3(width / 2, 0.0, 1.8))
		var ratio := size / Vector2(viewport.size)
		buttons[id].position = a * ratio
		buttons[id].size = (b - a) * ratio
		Plates.layout(buttons[id], info, Phone.narrow(Phone.window_size()))
	if phone_names != null: phone_names.queue_redraw()
