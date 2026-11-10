extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func settle() -> void:
	for i in 6: await process_frame

func run() -> void:
	var phone := "--phone" in OS.get_cmdline_user_args()
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://home14-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	var temple: Control = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple); current_scene = temple
	await settle()
	check(temple.temple_view != null, "Temple cutaway exists")
	var built := 0; var empty := 0
	for id in temple.temple_view.rooms:
		var info: Dictionary = temple.temple_view.rooms[id]
		var button: Button = temple.temple_view.buttons[id]
		if info.built: built += 1
		else: empty += 1
		var name_label: Label = button.get_node("RoomName")
		check(name_label.visible or phone and temple.temple_view.phone_names != null, "Room name visible: " + id)
		check(button.get_global_rect().intersects(Rect2(Vector2.ZERO, root.size)), "Room target on screen: " + id)
	if phone:
		var names: Control = temple.temple_view.phone_names
		var glyph_font: Font = names.get_theme_default_font()
		var cap_height: float = glyph_font.get_glyph_size(0, Vector2i(names.FONT_SIZE, names.FONT_SIZE), glyph_font.get_glyph_index(names.FONT_SIZE, 65, 0)).y
		# 16 px face produces 14 px uppercase ink in the 844x390 capture.
		check(names.FONT_SIZE >= 16 and cap_height >= 11, "Phone room type keeps 11 px minimum")
		check(names.labels.size() < built and temple.temple_view.buttons.war.get_node("RoomName").visible, "Phone limits simultaneous names while keeping the mission room labeled")
		for i in names.labels.size():
			var row: Dictionary = names.labels[i]
			check(cap_height >= 11.0, "Phone caps at least 11 px: " + str(row.id))
			for j in range(i + 1, names.labels.size()):
				check(not row.area.intersects(names.labels[j].area), "Phone names do not overlap: " + str(row.id) + "/" + str(names.labels[j].id))
			var target: Button = temple.temple_view.buttons[row.id]
			check(not target.get_node("RoomDetail").visible, "Phone name clear of state plate: " + str(row.id))
	check(built > 0 and empty > 0, "Built and empty rooms both appear")
	check(temple.temple_view.temple.find_children("*", "MeshInstance3D", true, false).size() > 0, "Lit cutaway geometry exists")
	var galaxy: Control = load("res://scenes/galaxy.tscn").instantiate()
	root.add_child(galaxy); current_scene = galaxy
	temple.queue_free(); await settle()
	check(galaxy.map_view.planets.size() == 14, "Planet art exists")
	check(galaxy.map_view.world.has_node("TravelLines"), "Travel routes exist")
	check(galaxy.map_view.get_global_rect().end.x <= root.size.x + 1, "Galaxy map fits width")
	if phone:
		check(galaxy.excerpt != null and galaxy.excerpt.visible, "Phone briefing excerpt visible")
		check(galaxy.excerpt.text.length() <= 55, "Phone excerpt is short")
		check(galaxy.detail.get_child_count() == 2, "Phone mission title has no clipped detail below")
		check(galaxy.excerpt.get_parent().get_global_rect().end.y <= root.size.y, "Excerpt fits height")
	else: check(galaxy.excerpt == null, "Desktop keeps full briefing")
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		check(root.get_node("Graphics").effective == "low", "Low tier unchanged")
	galaxy.queue_free()
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	var squad: Control = load("res://scenes/squad.tscn").instantiate()
	root.add_child(squad); current_scene = squad; await settle()
	squad.inspect(0); await settle()
	check(squad.focus_index == 0 and squad.drawer.visible, "Armory inspection opens")
	check(squad.card_scroll.get_global_rect().end.y <= root.size.y + 1, "Roster fits height")
	if phone: check(squad.card_scroll.position.y >= squad.stage_container.position.y + squad.stage_container.size.y - 1, "Roster sits below hero stage")
	for title in ["SABER MOD", "ARMOR MOD"]:
		var expected: String = {"SABER MOD":"SAB MOD", "ARMOR MOD":"ARM MOD"}.get(title, title) if phone else title
		var found := false
		for label in squad.arsenal.find_children("*", "Label", true, false):
			if label.text != expected: continue
			found = true
			if phone: check(label.get_theme_font_size("font_size") >= 14, title + " phone heading is readable")
			var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
			check(label.position.x + text_width <= label.get_parent().size.x - 4, title + " heading fits")
		check(found, title + " heading exists")
	squad.queue_free()
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu); current_scene = menu; await settle()
	check(menu.buttons.size() == 4, "Title difficulty choices fit")
	if phone:
		var body: VBoxContainer = menu.get_child(menu.get_child_count() - 1).get_child(0)
		menu._phone_settings(body); await settle()
		check(body.has_node("PhoneGraphics"), "Phone settings opens")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("HOME14 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
