extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Scene = preload("res://scenes/temple.tscn")
const Rooms = preload("res://scripts/campaign/temple_rooms.gd")
const Badges = preload("res://scripts/campaign/home_badges.gd")
const Resources = preload("res://scripts/campaign/home_resources.gd")
const UI = preload("res://scripts/campaign/ui.gd")
var checks := 0
var failures := 0
var flow: Node
var temple: Control
var path := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func frames() -> void:
	for i in 4: await process_frame

func fixture(state: Dictionary, label: String) -> Campaign:
	var source := Campaign.new(); source.state = state.duplicate(true)
	check(source.save(path), "save fixture " + label)
	var loaded := Campaign.new(); check(loaded.load_save(path), "reload fixture " + label)
	return loaded

func display(c: Campaign) -> void:
	flow.campaign = c; flow.story = c.story
	temple.campaign = c; temple._refresh_shell()
	await frames()

func badge(name: String) -> Label:
	return temple.nav_buttons[name].get_node("Badge")

func run() -> void:
	root.size = Vector2i(1920, 1080) if "--large" in OS.get_cmdline_user_args() else Vector2i(1366, 768)
	flow = root.get_node("CampaignFlow")
	path = "user://home-ui-test-%d.json" % OS.get_process_id()
	flow.save_path = path
	var fresh := fixture(Campaign.new().state, "arrival")
	flow.campaign = fresh; flow.story = fresh.story
	temple = Scene.instantiate(); root.add_child(temple); current_scene = temple
	await frames()
	for row in Rooms.ROOMS:
		var id: String = row[0]
		check(temple.temple_view.buttons.has(id), "room reachable " + id)
		var button: Button = temple.temple_view.buttons[id]
		check(button.get_node("RoomName").visible and button.get_node("RoomDetail").visible, "room plate visible " + id)
		check(button.get_node("RoomName").text == str(temple.temple_view.rooms[id].name).to_upper(), "room plate names " + id)
		if not temple.temple_view.rooms[id].built:
			check(button.get_children().any(func(n): return n.get_script() == preload("res://scripts/campaign/home_room_outline.gd")), "outlined unbuilt room " + id)
	var found_planet_label := false
	for child in temple.temple_view.galaxy.get_children():
		if child is Label3D: found_planet_label = true
	check(not found_planet_label and temple.temple_view.art.planets.size() == 14, "home hides planet names but keeps planets")
	for name in ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy", "Codex", "Galaxy"]:
		check(temple.nav_buttons.has(name), "tab reachable " + name)
		check(temple.nav_buttons[name].has_node("Icon") and temple.nav_buttons[name].has_node("Badge"), "tab icon and badge " + name)
		var icon: Control = temple.nav_buttons[name].get_node("Icon")
		check(icon.get_global_rect().position.y >= temple.nav_buttons[name].get_global_rect().position.y and icon.get_global_rect().end.y <= temple.nav_buttons[name].get_global_rect().end.y, "icon inside tab " + name)
	for item in Resources.ITEMS:
		var node: Label = temple.find_child("Resource_" + str(item[1]), true, false)
		check(node != null and node.text.begins_with(str(item[0])), "full resource name " + str(item[0]))
		check(node != null and node.tooltip_text != "", "resource guidance " + str(item[0]))
	check(badge("Galaxy").visible and badge("Command").visible, "mission and council badges live")
	check(not badge("Research").visible, "unbuilt Archives has no idle research badge")
	if "--capture-home-badges" in OS.get_cmdline_user_args():
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://../docs/godot/shots/home-badges.png") == OK, "badge screenshot")
	var study := fixture(fresh.state, "research idle")
	study.state.wings.archives = 1; study.state.research.cur = ""
	study = fixture(study.state, "research idle built")
	await display(study)
	check(badge("Research").visible and "idle" in temple.nav_buttons.Research.tooltip_text.to_lower(), "idle research badge explains why")
	study.state.research.cur = "ataru"
	study = fixture(study.state, "active research")
	await display(study)
	check(not badge("Research").visible, "active research clears badge")
	var build := fixture(fresh.state, "build ready")
	await display(build)
	check(badge("Build").visible, "free slot or ready module badge")
	build.state.facility.clear = build.state.slots.keys()
	build.state.modules.cd = {"medical":2, "barracks":2}
	build = fixture(build.state, "build quiet")
	await display(build)
	check(not badge("Build").visible, "no build or module prompt clears badge")
	var roster := fixture(build.state, "roster quiet")
	roster.state.roster[0].wound = 3
	roster.state.roster[1].fatigue = 40
	roster = fixture(roster.state, "roster injured")
	await display(roster)
	check(badge("Roster").visible and int(Badges.collect(roster).Roster.count) == 2, "wounded and tired soldier count")
	for soldier in roster.state.roster: soldier.wound = 0; soldier.fatigue = 0
	roster = fixture(roster.state, "roster recovered")
	await display(roster)
	check(not badge("Roster").visible, "recovery clears roster badge")
	var votes: Dictionary = preload("res://scripts/campaign/data.gd").get_table("temple", "VOTES")
	var vote_id: String = votes.keys()[(int(roster.state.month) - 1) % votes.size()]
	roster.state.strategy.votes["%d:%s" % [roster.state.month, vote_id]] = 0
	roster = fixture(roster.state, "council voted")
	await display(roster)
	check(not badge("Command").visible, "cast vote clears council badge")
	roster.state.options = []
	await display(roster)
	check(not badge("Galaxy").visible and not Badges.collect(roster).has("Galaxy"), "no missions clears Galaxy badge")
	var power := fixture(fresh.state, "power overload")
	power.state.wings.archives = 1; power.state.wings.armory = 1; power.state.wings.forge = 1
	power = fixture(power.state, "power overload built")
	await display(power)
	var label: Label = temple.find_child("PowerStatus", true, false)
	check(label != null and label.get_theme_color("font_color") == UI.DANGER and "stop operating" in label.tooltip_text, "over-limit power is red with effect")
	var shortfall := fixture(fresh.state, "monthly shortfall")
	shortfall.state.res.credits = 0; shortfall.state.res.favor = 0
	for wing in shortfall.state.wings: shortfall.state.wings[wing] = 1
	shortfall = fixture(shortfall.state, "monthly shortfall saved")
	await display(shortfall)
	var credits: Label = temple.find_child("Resource_credits", true, false)
	check(Resources.projected_balance(shortfall) < 0 and credits.get_theme_color("font_color") == UI.DANGER and "upkeep" in credits.tooltip_text, "monthly credit shortfall is red with effect")
	temple._change_page("Research"); await frames()
	check(temple.nav_buttons.Research.get_theme_stylebox("normal").border_color == UI.GOLD, "active Research tab has gold edge")
	temple._change_page("Build"); await frames()
	check(temple.nav_buttons.Build.get_theme_stylebox("normal").border_color == UI.GOLD and temple.nav_buttons.Research.get_theme_stylebox("normal").border_color != UI.GOLD, "highlight follows open page")
	temple._close_station(); await frames()
	check(temple.nav_buttons.Build.get_theme_stylebox("normal").border_color != UI.GOLD, "closed station clears highlight")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("HOME UI TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
