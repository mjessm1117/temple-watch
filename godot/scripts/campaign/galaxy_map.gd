extends Control
signal mission_selected(index: int)
signal planet_selected(planet: String)
signal region_selected(region: String)
signal field_selected(key: String)
const Data = preload("res://scripts/campaign/data.gd")
const Art = preload("res://scripts/campaign/galaxy_art.gd")
const Intel = preload("res://scripts/campaign/galaxy_intel.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var campaign
var selected := 0
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var planets: Dictionary = {}
var regions: Dictionary = {}
var offers: Array = []
var ships: Array[Node3D] = []
var operations: Array = []
var focused := ""
var hovered := ""
var target := Vector3(0,0,-1.7)
var look_at_point := Vector3.ZERO
var zoom := 79.0
var elapsed := 0.0
var dragging := false
var drag_distance := 0.0
var press_position := Vector2.ZERO
var pointer_inside := false
var overview_target := Vector3(0,0,-1.7)
var overview_zoom := 79.0
var haze_timer := 0.0
var mini := false

func _ready() -> void:
	custom_minimum_size = Vector2.ZERO if mini else Vector2(400, 330)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if mini else Control.MOUSE_FILTER_STOP
	var container := SubViewportContainer.new(); container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true; container.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(container)
	viewport = SubViewport.new(); viewport.own_world_3d = true; viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	world = Node3D.new(); viewport.add_child(world); Art.space(world)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH; camera.size = zoom; camera.far = 250; world.add_child(camera)
	_update_camera(1.0)
	var index := 0
	for title in Data.get_table("galaxy", "PLANETS"):
		var planet := Art.planet(world, title, index); planet.position = planet_position(title)
		planet.set_meta("origin", planet.position); planets[title] = planet; index += 1
	for row in Data.get_table("galaxy", "REGIONS"):
		var region := Node3D.new(); region.name = "Region_" + str(row[0]); world.add_child(region)
		if float(row[2]) > 0: Art.ring(region, float(row[2])*0.11)
		var plane := PlaneMesh.new(); plane.size = Vector2(20,20)
		var haze := Art.mesh(region, plane, Art.material("haze")); haze.name = "Darkness"
		var radius := float(row[2])*0.085; var angle := float(regions.size())*1.13
		haze.position = Vector3(cos(angle)*radius, -0.9, sin(angle)*radius)
		if row[0] == "unknown": haze.position = Vector3(-27,-0.9,-3)
		haze.material_override.set_shader_parameter("phase", float(regions.size())*5.3)
		regions[row[0]] = region
	refresh_signals()
	gui_input.connect(_on_input)
	mouse_entered.connect(func(): pointer_inside = true)
	mouse_exited.connect(func(): pointer_inside = false; hovered = "")

func planet_position(title: String) -> Vector3:
	var p: Dictionary = Data.get_table("galaxy", "PLANETS").get(title, {"x":185,"y":265})
	return Vector3((float(p.x)-300)*0.11,0.8,(float(p.y)-190)*0.155)

func refresh_signals() -> void:
	offers.clear()
	for i in campaign.state.options.size():
		var option: Dictionary = campaign.state.options[i]; var m: Dictionary = campaign.story.mission(str(option.mission))
		offers.append({"index":i, "planet":Intel.planet_for(m), "name":str(option.get("n",m.get("n",option.mission))), "risk":Intel.risk(campaign,m,option)})
	operations.clear()
	for op in campaign.sith.operations():
		if op.status in ["open","team"]:
			var offer: Dictionary = campaign.state.sith.missions.get(op.mission_id,{})
			operations.append({"planet":Intel.planet_for(campaign.story.mission(str(offer.get("mission","archive")))),"name":op.n,"id":op.id})
	for active in campaign.state.crises11.active:
		var crisis: Dictionary = preload("res://scripts/campaign/crisis11_engine.gd").definition(str(active.id))
		operations.append({"planet":str(crisis.planet),"name":"%s · %d days" % [crisis.title,maxi(0,int(active.deadline)-int(campaign.state.elapsed_days))],"id":active.id})
	for ship in ships: ship.queue_free()
	ships.clear()
	for op in campaign.state.field.list:
		if str(op.get("st", "")) != "team": continue
		var ship: Node3D = load("res://assets/galaxy/shuttle.glb").instantiate()
		world.add_child(ship); ship.name = "Field_" + str(op.id); ship.scale = Vector3.ONE * 0.35
		var destination := Intel.operation_planet(campaign,op)
		ship.set_meta("key",str(op.k))
		ship.set_meta("destination",planet_position(destination)); ship.set_meta("phase",float(ships.size())*0.32)
		ship.set_meta("label", str(Data.get_table("galaxy","FIELD_OPS").get(op.k,{}).get("n",op.k)))
		ships.append(ship)
	_update_haze()

func _update_haze() -> void:
	for region in regions:
		var haze: MeshInstance3D = regions[region].get_node("Darkness")
		var amount := clampf(float(Intel.unrest(campaign,region))/5.0 + float(Intel.darkness(campaign))/180.0,0,1)
		haze.material_override.set_shader_parameter("danger",amount)

func focus_planet(title: String) -> void:
	if not planets.has(title): return
	if focused.is_empty(): overview_target = target; overview_zoom = zoom
	focused = title; target = planets[title].position; zoom = 23.0

func focus_offer(index: int) -> void:
	selected = index
	if index >= 0 and index < offers.size(): focus_planet(str(offers[index].planet))

func return_to_overview() -> void:
	focused = ""; target = overview_target; zoom = overview_zoom

func _process(delta: float) -> void:
	elapsed += delta; haze_timer += delta
	if haze_timer > 1: _update_haze(); haze_timer = 0
	if pointer_inside and not Input.is_key_pressed(KEY_CTRL):
		var pan := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		target += pan * delta * zoom * 0.3; _clamp_target()
	_update_camera(1.0-exp(-delta*5.0))
	var i := 0
	for title in planets:
		var planet: Node3D = planets[title]; var origin: Vector3 = planet.get_meta("origin")
		planet.position = origin + Vector3(sin(elapsed*0.10+i)*0.16,sin(elapsed*0.26+i)*0.12,cos(elapsed*0.10+i)*0.12)
		planet.get_node("Surface").rotation.y += delta*(0.035+float(i%3)*0.008)
		planet.get_node("Atmosphere").material_override.set_shader_parameter("strength",1.3 if title == hovered or title == focused else 0.65)
		i += 1
	for ship in ships:
		var t := fposmod(elapsed*0.025 + float(ship.get_meta("phase")),1.0)
		var start := planet_position("Coruscant"); var destination: Vector3 = ship.get_meta("destination")
		ship.position = start.lerp(destination,t)+Vector3(0,sin(t*PI)*3.0+1.2,0)
		ship.look_at(destination+Vector3(0,1.2,0),Vector3.UP)
	queue_redraw()

func _clamp_target() -> void:
	target.x = clampf(target.x,-38,38); target.z = clampf(target.z,-32,32)

func _update_camera(weight: float) -> void:
	look_at_point = look_at_point.lerp(target,weight); camera.size = lerpf(camera.size,zoom,weight)
	camera.position = look_at_point + Vector3(sin(elapsed*0.025)*0.3,48,34)
	camera.look_at(look_at_point,Vector3.UP)

func projected(position_3d: Vector3) -> Vector2:
	return camera.unproject_position(position_3d) * size / Vector2(viewport.size)

func marker_position(index: int) -> Vector2:
	var offer: Dictionary = offers[index]; var same := []
	for o in offers:
		if o.planet == offer.planet: same.append(int(o.index))
	var slot := same.find(index); var shift := (float(slot)-float(same.size()-1)*0.5)*42.0
	return projected(planets[offer.planet].position)+Vector2(shift,-35.0-absf(shift)*0.18)

func _draw() -> void:
	if camera == null: return
	# SubViewport renders as a child; overlays are drawn by a topmost child below.
	if not has_node("Labels"):
		var overlay := Control.new(); overlay.name = "Labels"; overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.draw.connect(_draw_labels.bind(overlay)); add_child(overlay)
	get_node("Labels").queue_redraw()

func _draw_labels(overlay: Control) -> void:
	var font := ThemeDB.fallback_font
	if mini:
		for title in planets:
			var p := projected(planets[title].position)
			if not Rect2(Vector2(5, 5), size - Vector2(10, 10)).has_point(p): continue
			var threat := preload("res://scripts/campaign/events11_engine.gd").threat(campaign.state, title)
			if threat >= 2:
				overlay.draw_arc(p, 8, 0, TAU, 16, Color("ef6a5d"), 2, true)
		for offer in offers:
			var p := projected(planets[offer.planet].position)
			overlay.draw_circle(p + Vector2(7, -7), 3, Color("f6bf67"))
		return
	var bounds := Rect2(Vector2(12,28),size-Vector2(24,54))
	var compact := Phone.narrow(Phone.window_size())
	var selected_planet := str(offers[selected].planet) if selected < offers.size() else "Coruscant"
	for title in planets:
		if compact and title != focused and title != selected_planet and title != "Coruscant": continue
		var p := projected(planets[title].position)
		if not bounds.has_point(p): continue
		var active: bool = title == hovered or title == focused
		var label_size := 16 if active else 14 if Phone.narrow(Phone.window_size()) else 12
		var color := Color("dbe7e4") if active else Color("91afb9")
		var threat := preload("res://scripts/campaign/events11_engine.gd").threat(campaign.state, title)
		var offset := Vector2(14,18)
		if p.x > size.x-125: offset.x = -font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size).x-14
		if active:
			overlay.draw_arc(p,20,0,TAU,48,Color("79d3e2"),1.5,true)
			var text_size := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size)
			overlay.draw_style_box(_plate(),Rect2(p+offset-Vector2(5,16),text_size+Vector2(10,3)))
		overlay.draw_string_outline(font,p+offset,title,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size,4,Color("061017"))
		overlay.draw_string(font,p+offset,title,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size,color)
		if threat >= 2:
			overlay.draw_string(font,p+offset+Vector2(0,15),"THREAT %d/5" % threat,HORIZONTAL_ALIGNMENT_LEFT,-1,12 if Phone.narrow(Phone.window_size()) else 10,Color("ef6a5d"))
	for offer in offers:
		var p := marker_position(offer.index)
		if not bounds.has_point(p): continue
		var color: Color = offer.risk.color; var pulse := 1.0+sin(elapsed*3.2+offer.index)*0.12
		overlay.draw_line(projected(planets[offer.planet].position),p,Color(color,0.65),1.2,true)
		overlay.draw_circle(p,15*pulse,Color(color,0.12))
		overlay.draw_arc(p,11*pulse,0,TAU,40,Color(color,0.7),1.2,true)
		overlay.draw_circle(p,6,color)
		overlay.draw_string(font,p+Vector2(-4,4),str(int(offer.index)+1),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("081317"))
		if compact or offer.index != selected and hovered != offer.planet: continue
		var text_width := font.get_string_size(offer.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		var label_pos := p+Vector2(18,4)
		if label_pos.x+text_width > size.x-10: label_pos.x = p.x-18-text_width
		overlay.draw_string_outline(font,label_pos,offer.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,4,Color("061017"))
		overlay.draw_string(font,label_pos,offer.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
	for op in operations:
		var p := projected(planets[op.planet].position)+Vector2(-26,-25)
		if not bounds.has_point(p): continue
		var diamond := PackedVector2Array([p+Vector2(0,-8),p+Vector2(8,0),p+Vector2(0,8),p+Vector2(-8,0),p+Vector2(0,-8)])
		overlay.draw_colored_polygon(diamond,Color("ef6a5d"))
		if hovered != op.planet: continue
		overlay.draw_string_outline(font,p+Vector2(12,-4),str(op.name),HORIZONTAL_ALIGNMENT_LEFT,-1,12,4,Color("061017"))
		overlay.draw_string(font,p+Vector2(12,-4),str(op.name),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ef6a5d"))
	for ship in ships:
		var p := projected(ship.position)
		if bounds.has_point(p):
			overlay.draw_arc(p,6,0,TAU,16,Color("a7c7cc"),1,true)
			if not compact: overlay.draw_string(font,p+Vector2(10,-5),str(ship.get_meta("label")),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("a7c7cc"))
	overlay.draw_string(font,Vector2(18,25),"LIVE HOLOMAP  /  " + (focused.to_upper() if not focused.is_empty() else "REPUBLIC SPACE"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("79d3e2"))
	overlay.draw_string(font,Vector2(18,size.y-15),"DRAG to pan · TAP a signal" if compact else "SCROLL zoom   ·   DRAG / WASD pan   ·   CLICK inspect",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("8aa2a5"))

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom = clampf(zoom*(0.88 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.12),12,100); accept_event()
		if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]:
			dragging = event.pressed
			if event.pressed: press_position = event.position; drag_distance = 0
			elif event.button_index == MOUSE_BUTTON_LEFT and drag_distance < 6: _pick(event.position)
	elif event is InputEventMouseMotion:
		if dragging:
			drag_distance += event.relative.length()
			target += Vector3(-event.relative.x,0,-event.relative.y*1.22)*zoom/maxf(size.x,1); _clamp_target()
		else:
			hovered = ""
			for title in planets:
				if projected(planets[title].position).distance_to(event.position) < 22: hovered = title; break

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed and not pointer_inside: dragging = false

func _pick(point: Vector2) -> void:
	for ship in ships:
		if projected(ship.position).distance_to(point) < 14: field_selected.emit(str(ship.get_meta("key"))); return
	for op in operations:
		if (projected(planets[op.planet].position)+Vector2(-26,-25)).distance_to(point) < 14:
			region_selected.emit(str(Data.get_table("galaxy","PLANETS")[op.planet].reg)); return
	for offer in offers:
		if marker_position(offer.index).distance_to(point) < 18:
			mission_selected.emit(offer.index); return
	for title in planets:
		if projected(planets[title].position).distance_to(point) < 24:
			planet_selected.emit(title); return
	var from := camera.project_ray_origin(point*Vector2(viewport.size)/size)
	var ray := camera.project_ray_normal(point*Vector2(viewport.size)/size)
	var hit := from + ray*(-from.y/ray.y); var radius := Vector2(hit.x,hit.z).length()
	for row in Data.get_table("galaxy","REGIONS"):
		if float(row[2]) > 0 and radius <= float(row[2])*0.11: region_selected.emit(str(row[0])); return
	region_selected.emit("unknown")

func _plate() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.02,0.07,0.09,0.92)
	style.border_color = Color("477b86"); style.set_border_width_all(1); style.set_corner_radius_all(3)
	return style
