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
var zoom := 46.0 if Phone.narrow(Phone.window_size()) else 79.0
var elapsed := 0.0
var dragging := false
var drag_distance := 0.0
var press_position := Vector2.ZERO
var pointer_inside := false
var overview_target := Vector3(0,0,-1.7)
var overview_zoom := 46.0 if Phone.narrow(Phone.window_size()) else 79.0
var haze_timer := 0.0
var mini := false
var ui_safe_rect := Rect2()

func set_ui_safe_rect(rect: Rect2) -> void:
	if ui_safe_rect == rect: return
	ui_safe_rect = rect
	if camera != null: _update_camera(1.0)

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

func _ready() -> void:
	custom_minimum_size = Vector2.ZERO if mini or Phone.narrow(Phone.window_size()) else Vector2(400, 330)
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
	Art.travel_lines(world, planets)
	var territory := Art.mesh(world, PlaneMesh.new(), Art.material("haze"))
	territory.name = "SithTerritory"
	territory.mesh.size = Vector2(15, 12)
	territory.position = planet_position("Sith frontier") + Vector3(0,-1.1,0)
	territory.material_override.set_shader_parameter("danger",0.85)
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
		var urgency := "NO LIMIT" if option.get("story", false) else "LAST" if option.get("adv", false) and campaign.state.options.size() == 1 else "NEXT" if option.get("adv", false) else "OPEN"
		var reward: Dictionary = m.get("reward", {})
		var reward_key := str(reward.keys()[0]).capitalize() if not reward.is_empty() else "Intel"
		offers.append({"index":i, "planet":Intel.planet_for(m), "name":str(option.get("n",m.get("n",option.mission))), "risk":Intel.risk(campaign,m,option), "type":str(m.get("type", option.get("kind", "Mission"))).replace("_", " ").to_upper(), "urgency":urgency, "reward":reward_key})
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
	focused = title; target = planets[title].position; zoom = 18.0 if Phone.narrow(Phone.window_size()) else 23.0

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
	var area := _clear_area()
	var center := area.get_center() / size if size.x > 0 and size.y > 0 else Vector2(0.5, 0.5)
	var height := camera.size * size.y / maxf(size.x, 1.0)
	var offset := -camera.global_transform.basis.x * ((center.x - 0.5) * camera.size) + camera.global_transform.basis.y * ((center.y - 0.5) * height)
	camera.position = look_at_point + Vector3(sin(elapsed*0.025)*0.3,48,34) + offset
	camera.look_at(camera.position - Vector3(0,48,34),Vector3.UP)

func projected(position_3d: Vector3) -> Vector2:
	return camera.unproject_position(position_3d) * size / Vector2(viewport.size)

func marker_position(index: int) -> Vector2:
	var offer: Dictionary = offers[index]; var same := []
	for o in offers:
		if o.planet == offer.planet: same.append(int(o.index))
	var slot := same.find(index); var shift := (float(slot)-float(same.size()-1)*0.5)*42.0
	return projected(planets[offer.planet].position)+Vector2(shift,-35.0-absf(shift)*0.18)

func marker_label_layout() -> Array:
	# Place urgent/selected cards first; each later card searches a free lane near its marker.
	var result := []
	var order := offers.duplicate()
	order.sort_custom(func(a, b):
		var pa := (4 if a.urgency == "LAST" else 3 if a.urgency == "NEXT" else 1) + (2 if a.index == selected else 0)
		var pb := (4 if b.urgency == "LAST" else 3 if b.urgency == "NEXT" else 1) + (2 if b.index == selected else 0)
		return pa > pb if pa != pb else a.index < b.index)
	var width := minf(150.0 if Phone.narrow(Phone.window_size()) else 174.0, maxf(120.0, size.x - 36.0))
	var height := 48.0 if Phone.narrow(Phone.window_size()) else 44.0
	var clear := _clear_area()
	var area := Rect2(clear.position + Vector2(12, 42), clear.size - Vector2(24, 78))
	for offer in order:
		var marker := marker_position(int(offer.index))
		if not Rect2(Vector2.ZERO, size).has_point(marker): continue
		var candidates := [marker + Vector2(20, -height * 0.5), marker + Vector2(-width - 20, -height * 0.5)]
		for step in 14:
			var y := area.position.y + float(step) * maxf(1.0, (area.size.y - height) / 13.0)
			candidates.append(Vector2(12, y))
			candidates.append(Vector2(size.x - 12 - width, y))
		for point in candidates:
			var rect := Rect2(Vector2(clampf(point.x, area.position.x, area.end.x - width), clampf(point.y, area.position.y, area.end.y - height)), Vector2(width, height))
			var free := true
			for placed in result:
				if rect.grow(3).intersects(placed.rect): free = false; break
			if free:
				result.append({"index":offer.index, "rect":rect, "marker":marker, "offer":offer})
				break
	return result

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
	var clear := _clear_area()
	var bounds := Rect2(clear.position + Vector2(12,28),clear.size-Vector2(24,54))
	var compact := Phone.narrow(Phone.window_size())
	var selected_planet := str(offers[selected].planet) if selected < offers.size() else "Coruscant"
	var signal_layout := marker_label_layout()
	for title in planets:
		if compact and title != focused and title != selected_planet and title != "Coruscant": continue
		var p := projected(planets[title].position)
		if not bounds.has_point(p): continue
		var in_signal := false
		for label in signal_layout:
			if label.rect.grow(8).has_point(p): in_signal = true; break
		if in_signal and title != focused: continue
		var active: bool = title == hovered or title == focused
		var label_size := 16 if active else 14
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
			overlay.draw_string(font,p+offset+Vector2(0,15),"THREAT %d/5" % threat,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ef6a5d"))
	for offer in offers:
		var p := marker_position(offer.index)
		if not bounds.has_point(p): continue
		var color: Color = offer.risk.color; var pulse := 1.0+sin(elapsed*3.2+offer.index)*0.12
		overlay.draw_line(projected(planets[offer.planet].position),p,Color(color,0.65),1.2,true)
		overlay.draw_circle(p,15*pulse,Color(color,0.12))
		overlay.draw_arc(p,11*pulse,0,TAU,40,Color(color,0.7),1.2,true)
		overlay.draw_circle(p,6,color)
		overlay.draw_string(font,p+Vector2(-5,5),str(int(offer.index)+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("081317"))
	for label in signal_layout:
		var rect: Rect2 = label.rect
		var offer: Dictionary = label.offer
		var standout: bool = int(label.index) == selected or offer.urgency in ["LAST", "NEXT"]
		var ink: Color = offer.risk.color if standout else Color("9ec1c9")
		overlay.draw_line(label.marker, rect.get_center(), Color(ink, 0.55), 1, true)
		var plate := _plate(); plate.border_color = ink; plate.bg_color = Color("11252c") if standout else Color("0a171b")
		overlay.draw_style_box(plate, rect)
		overlay.draw_string(font, rect.position + Vector2(8, 17), "%s · %s" % [str(offer.type).substr(0, 9), offer.urgency], HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 16), 14, ink)
		overlay.draw_string(font, rect.position + Vector2(8, 36), "◆ %s" % offer.reward, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 16), 14, Color("dbe7e4"))
	for op in operations:
		var p := projected(planets[op.planet].position)+Vector2(-26,-25)
		if not bounds.has_point(p): continue
		var diamond := PackedVector2Array([p+Vector2(0,-8),p+Vector2(8,0),p+Vector2(0,8),p+Vector2(-8,0),p+Vector2(0,-8)])
		overlay.draw_colored_polygon(diamond,Color("ef6a5d"))
		if hovered != op.planet: continue
		overlay.draw_string_outline(font,p+Vector2(12,-4),str(op.name),HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,Color("061017"))
		overlay.draw_string(font,p+Vector2(12,-4),str(op.name),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ef6a5d"))
	for ship in ships:
		var p := projected(ship.position)
		if bounds.has_point(p):
			overlay.draw_arc(p,6,0,TAU,16,Color("a7c7cc"),1,true)
			if not compact: overlay.draw_string(font,p+Vector2(10,-5),str(ship.get_meta("label")),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("a7c7cc"))
	if not focused.is_empty():
		var card_width := minf(188.0,size.x-36.0)
		var card := Rect2(Vector2(16,38),Vector2(card_width,67))
		overlay.draw_style_box(_plate(),card)
		overlay.draw_string(font,card.position+Vector2(10,19),focused.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,int(card_width-20),14,Color("dbe7e4"))
		var biome := str(Art.BIOMES.get(focused,["Uncharted"])[0])
		overlay.draw_string(font,card.position+Vector2(10,39),biome,HORIZONTAL_ALIGNMENT_LEFT,int(card_width-20),14,Color("79d3e2"))
		var risk: Dictionary = offers[selected].risk if selected < offers.size() and str(offers[selected].planet) == focused else {}
		var threat := preload("res://scripts/campaign/events11_engine.gd").threat(campaign.state,focused)
		var scan := "RISK %d / 4  ·  %s" % [int(risk.level), str(risk.name).to_upper()] if not risk.is_empty() else "REGION THREAT %d / 5" % threat
		overlay.draw_string(font,card.position+Vector2(10,57),scan,HORIZONTAL_ALIGNMENT_LEFT,int(card_width-20),14,risk.color if not risk.is_empty() else Color("8aa2a5"))
	overlay.draw_string(font,Vector2(18,25),"LIVE HOLOMAP  /  " + (focused.to_upper() if not focused.is_empty() else "REPUBLIC SPACE"),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("79d3e2"))
	overlay.draw_string(font,Vector2(18,size.y-15),"DRAG to pan · TAP a signal" if compact else "SCROLL zoom   ·   DRAG / WASD pan   ·   CLICK inspect",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("8aa2a5"))

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
	# The map is a single touch surface; choose the closest marker inside a thumb radius.
	if Phone.narrow(Phone.window_size()):
		var nearest := 28.0
		var choice: Callable
		for ship in ships:
			var distance := projected(ship.position).distance_to(point)
			if distance < nearest: nearest = distance; choice = field_selected.emit.bind(str(ship.get_meta("key")))
		for op in operations:
			var distance := (projected(planets[op.planet].position) + Vector2(-26, -25)).distance_to(point)
			if distance < nearest:
				nearest = distance
				choice = region_selected.emit.bind(str(Data.get_table("galaxy", "PLANETS")[op.planet].reg))
		for offer in offers:
			var distance := marker_position(offer.index).distance_to(point)
			if distance < nearest: nearest = distance; choice = mission_selected.emit.bind(offer.index)
		for title in planets:
			var distance := projected(planets[title].position).distance_to(point)
			if distance < nearest: nearest = distance; choice = planet_selected.emit.bind(title)
		if choice.is_valid(): choice.call(); return
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
