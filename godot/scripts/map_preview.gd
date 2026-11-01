extends SceneTree
## Real-window mission inspection. Run -s scripts/map_preview.gd -- archive [--capture].
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Presentation = preload("res://scripts/map_presentation.gd")
const Settings = preload("res://scripts/settings.gd")
const Shot = preload("res://scripts/shot.gd")
var m: RefCounted
var renderer: Node3D
var camera: Camera3D
var status: Label
var unit_root: Node3D

func _initialize() -> void:
	call_deferred("show_map")

func show_map() -> void:
	Settings.difficulty = "normal"
	var args := OS.get_cmdline_user_args(); var id := args[0] if not args.is_empty() else "archive"
	m = Mission.new(17,Maps.resolve(id) if not id.begins_with("web_") else "res://data/maps/%s.json" % id)
	if "--inbound" in args: m.queue_reinforcement(["trooper","heavy"],1,"Patrol support")
	var world := Node3D.new(); root.add_child(world)
	renderer = Presentation.new(); world.add_child(renderer); renderer.build(m)
	var environment := WorldEnvironment.new(); world.add_child(environment)
	var sun := DirectionalLight3D.new(); world.add_child(sun)
	renderer.apply_environment(environment,sun,str(m.spec.theme))
	camera = Camera3D.new(); world.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(float(m.spec.width),float(m.spec.height))*1.12
	var center := Vector3(float(m.spec.width)/2.0,0,float(m.spec.height)/2.0)
	camera.position = center+Vector3(22,42,32); camera.look_at(center+Vector3(3,0,0)); camera.current = true
	unit_root = Node3D.new(); world.add_child(unit_root); draw_units()
	var hud := CanvasLayer.new(); root.add_child(hud)
	var panel := PanelContainer.new(); panel.position = Vector2(24,22); panel.size = Vector2(360,0); hud.add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.035,0.06,0.08,0.94); style.set_content_margin_all(18); panel.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",12); panel.add_child(column)
	label(column,"T E M P L E   W A T C H",15,Color("7ccedd"))
	label(column,str(m.spec.name),25,Color("f1e9d9"))
	label(column,"%s  /  %s" % [str(m.spec.theme).to_upper(),str(m.spec.family).replace("_"," ").to_upper()],13,Color("b7c8d0"))
	status = label(column,"",16,Color("e3bd73")); refresh()
	label(column,"BLUE  Squad / evacuation\nGOLD  Objective tiles\nRED  Hostile pods / inbound lanes",14,Color("b7c8d0"))
	var end := Button.new(); end.text = "End turn"; end.pressed.connect(end_turn); column.add_child(end)
	label(column,"Mission inspection view\nMovement and Interact UI: combat integration",12,Color("849ba5"))
	if "--capture" in args:
		for i in 12: await process_frame
		await RenderingServer.frame_post_draw
		var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave7-missions-%s.png" % id)
		var error := root.get_texture().get_image().save_png(path)
		print("MISSION SCREENSHOT: ",path," ",error); quit(0 if error == OK else 1)

func label(parent: Node, text: String, size: int, color: Color) -> Label:
	var node := Label.new(); node.text = text; node.add_theme_font_size_override("font_size",size); node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; node.custom_minimum_size.x = 320; parent.add_child(node); return node

func draw_units() -> void:
	for child in unit_root.get_children(): unit_root.remove_child(child); child.queue_free()
	for u in m.units:
		if int(u.hp) <= 0: continue
		var node := MeshInstance3D.new(); var mesh := CapsuleMesh.new(); mesh.radius = 0.25; mesh.height = 1.2; node.mesh = mesh
		node.material_override = renderer.material(Color("66c5ff") if u.side == "player" else Color("ef7563"),0.6)
		node.position = Vector3(int(u.x),Shot.elevation(m,Shot.pos(u))*0.7+0.6,int(u.y)); unit_root.add_child(node)
	if bool(m.prisoner.get("active",false)):
		renderer.box(Vector3(int(m.prisoner.x),0.5,int(m.prisoner.y)),Vector3(0.4,1,0.4),renderer.material(Color("e9c875"),0.5),unit_root)

func refresh() -> void:
	var state: Dictionary = m.objective_status()
	status.text = "%s\nTurn %d · %s\n%s" % [state.label,m.turn,"No deadline" if int(state.turns_left)<0 else "%d turns left" % int(state.turns_left),"\n".join(m.log_lines.slice(maxi(0,m.log_lines.size()-2)))]

func end_turn() -> void:
	m.end_turn(); renderer.refresh_markers(m); draw_units(); refresh()
