extends RefCounted
const UI = preload("res://scripts/campaign/ui.gd")
const Badges = preload("res://scripts/campaign/home_badges.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")

static func add_task_rail(view, compact: bool, safe: Vector4) -> void:
	var badges: Dictionary = Badges.collect(view.campaign)
	var priority: Dictionary = {}
	if view.campaign.has_method("strategic_snapshot25"):
		var snapshot: Dictionary = view.campaign.call("strategic_snapshot25")
		priority = snapshot.get("top_priority", {})
	view.priority_room = str(priority.get("room_id", ""))
	var label := str(priority.get("label", ""))
	var reason := str(priority.get("reason", ""))
	if view.priority_room == "" or label == "":
		for key in ["Galaxy", "Research", "Roster", "Build", "Command"]:
			if badges.has(key):
				view.priority_room = {"Galaxy":"war", "Research":"archives", "Roster":"barracks", "Build":"works", "Command":"council"}[key]
				label = str(badges[key].action)
				reason = str(badges[key].why)
				break
	if view.priority_room == "": return
	var rail := UI.button("", func(): view.temple_view.activate_room(view.priority_room))
	rail.name = "TaskRailCard"; rail.tooltip_text = reason
	rail.custom_minimum_size.y = 44
	rail.position = Vector2(safe.x + 65 if compact else view.get_viewport_rect().size.x * 0.85, safe.y + (55 if compact else 116))
	rail.size = Vector2(minf(290 if view.get_viewport_rect().size.x < view.get_viewport_rect().size.y else 210, view.get_viewport_rect().size.x - rail.position.x - safe.z - 12), 68)
	rail.add_theme_font_size_override("font_size", 14)
	var caption := UI.label("NEXT  ·  " + label + "\n" + reason, 14, UI.TEXT)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(caption)
	view.add_child(rail)

static func medical_status(campaign: RefCounted) -> String:
	return medical_status_state(campaign.state)

static func defer_story_route(view, id: String, target: String) -> bool:
	if not bool(view.room_story_played.get(id, false)): return false
	var scene: Node = view.get_tree().current_scene
	if scene == null: return false
	var story := scene.find_child("RoomStory25", true, false)
	if story == null: return false
	story.tree_exited.connect(func():
		if is_instance_valid(view) and view.is_inside_tree(): view._open_room(id, target), CONNECT_ONE_SHOT)
	return true

static func medical_status_state(state: Dictionary) -> String:
	var count := 0; var soonest := 999
	for soldier in state.roster:
		if str(soldier.status) != "active" or int(soldier.wound) <= 0: continue
		count += 1
		if str(soldier.assign).begins_with("field:") or state.pending_mission.get("squad", []).has(soldier.id) or soldier.id in state.strategy.team_deployed: continue
		var left := int(soldier.wound); var days := 0
		while left > 0 and days < 120:
			days += 1
			var healing := 1
			if Base.operational(state, "medical") and (int(state.elapsed_days) + days) % 3 == 0: healing += Base.staff_count(state, "medical")
			if "bacta" in state.strategy.projects: healing += 1
			if "relief" in state.strategy.edict: healing += 2
			left -= healing * (2 if str(soldier.assign) == "rest" else 1)
		soonest = mini(soonest, days)
	return "%d wounded · soonest return %s" % [count, "%d days" % soonest if soonest < 999 else "pending"]
