extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Queue = preload("res://scripts/campaign/research_queue.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Theme13 = preload("res://scripts/armory13_theme.gd")

static func action_button(label: String, action: Callable, enabled: bool = true) -> Button:
	var control := UI.button(label, action, enabled)
	control.custom_minimum_size.y = 44
	return control

static func _queue(view, id: String) -> void:
	if Queue.enqueue(view.campaign, id):
		view.set_meta("w32c_research_id", "")
		view.get_node("/root/CampaignFlow").save()
		view._refresh_shell()

static func _review(view, id: String) -> void:
	view.set_meta("w32c_research_id", id)
	view._show_page()

static func _dismiss(view) -> void:
	view.campaign.state.research.last = ""
	view.get_node("/root/CampaignFlow").save()
	view._show_page()

static func _remove(view, id: String) -> void:
	if Queue.dequeue(view.campaign, id):
		view.get_node("/root/CampaignFlow").save()
		view._show_page()

static func render(view) -> void:
	if view.room_picker != null: view.room_picker.hide()
	var c = view.campaign
	Queue.ensure(c.state)
	var data: Dictionary = Data.get_table("research", "RESEARCH")
	var position := 0
	var last := str(c.state.research.last)
	var active := str(c.state.research.cur)
	var progress := "No active study"
	if active != "" and data.has(active):
		var p: Dictionary = data[active]
		progress = "%s · %.0f / %d work days" % [p.n, float(c.state.research.prog), int(p.days)]
	var queue_names := []
	for id in c.state.research.queue: queue_names.append(str(data[id].n))
	var top: VBoxContainer = view._card("RESEARCH", "%s · Next: %s" % [progress, " → ".join(queue_names) if not queue_names.is_empty() else "none"])
	var workers := []
	for worker in c.state.facility.workers:
		if str(worker.wing) == "archives": workers.append(str(worker.n))
	if c.state.staff.has("archives"):
		var soldier: Dictionary = c.soldier(str(c.state.staff.archives))
		if not soldier.is_empty(): workers.append(str(soldier.n))
	var team := ", ".join(workers) if not workers.is_empty() else "No archivist assigned"
	if active != "" and data.has(active):
		if Base.operational(c.state, "archives"):
			var speed := (1.5 if int(c.state.wings.archives) >= 2 else 1.0) * (1.0 + 0.5 * Base.staff_count(c.state, "archives"))
			if "scholarship" in c.state.strategy.edict: speed *= 1.5
			var eta := ceili((float(data[active].days) - float(c.state.research.prog)) / speed)
			top.add_child(UI.label("Working: %s · %d days left" % [team, maxi(0, eta)], 14, UI.GOLD))
		else:
			top.add_child(UI.label("Paused: %s · restore power for ETA" % team, 14, UI.DANGER))
		top.add_child(UI.label("Unlocks: %s" % str(data[active].desc), 14, UI.ACCENT))
	else:
		top.add_child(UI.label("Lab idle · %s" % team, 14, UI.GOLD))
	var first := ""
	for branch in Data.get_table("research", "RES_TREE"):
		for id in branch.ids:
			if Queue.can_queue(c, str(id)):
				first = str(id)
				break
		if first != "": break
	if first != "":
		var study := action_button("Review %s" % str(data[first].n), _review.bind(view, first))
		study.name = "FirstStudyButton"; study.custom_minimum_size.y = 44
		top.add_child(study)
	else: top.add_child(UI.label("No study available. Check the requirements below.", 14, UI.MUTED))
	for id in c.state.research.queue:
		top.add_child(action_button("Remove queued: " + str(data[id].n), _remove.bind(view, str(id))))
	view.page_content.move_child(top.get_parent(), position); position += 1
	var selected := str(view.get_meta("w32c_research_id", ""))
	if data.has(selected) and Queue.can_queue(c, selected):
		var study_data: Dictionary = data[selected]
		var cost := "%d Cr" % int(study_data.cost.get("credits", 0))
		if int(study_data.cost.get("intel", 0)) > 0: cost += " + %d Intel" % int(study_data.cost.intel)
		var confirm_card: VBoxContainer = view._card("CONFIRM RESEARCH · " + str(study_data.n), "%s when study starts · %d work days · Power +0 · month end +0 Cr" % [cost, int(study_data.days)])
		confirm_card.add_child(UI.label("Unlocks: " + str(study_data.desc), 14, UI.ACCENT))
		confirm_card.add_child(action_button("Confirm study", _queue.bind(view, selected), c.can_afford(study_data.cost)))
		view.page_content.move_child(confirm_card.get_parent(), position); position += 1
	if last != "" and data.has(last):
		var unlock: Dictionary = data[last]
		var toast: VBoxContainer = view._card("UNLOCKED  ·  " + str(unlock.n), str(unlock.desc))
		toast.add_child(action_button("Dismiss", _dismiss.bind(view)))
		view.page_content.move_child(toast.get_parent(), position); position += 1
	for branch in Data.get_table("research", "RES_TREE"):
		var card: VBoxContainer = view._card(str(branch.n).to_upper())
		view.page_content.move_child(card.get_parent(), position); position += 1
		for id in branch.ids:
			var p: Dictionary = data[id]
			var row := HBoxContainer.new(); card.add_child(row)
			var status := "✓" if c.researched(str(id)) else "●" if active == id else "…" if id in c.state.research.queue else "○"
			var deps := []
			for need in p.get("need", []): deps.append(str(data[need].n))
			var cost := "%d Cr" % int(p.cost.get("credits", 0))
			if int(p.cost.get("intel", 0)) > 0: cost += " + %d Intel" % int(p.cost.intel)
			var schedule := " · day %d+" % int(p.min_day) if p.has("min_day") else ""
			var line := "%s %s · %d d · %s%s" % [status, p.n, int(p.days), cost, schedule]
			if not deps.is_empty() and not Queue.can_queue(c, str(id)): line += " · needs %s" % ", ".join(deps)
			var label := UI.label(line, 14, UI.ACCENT if c.researched(str(id)) else UI.MUTED)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(label)
			var can := Queue.can_queue(c, str(id))
			row.add_child(action_button("Review", _review.bind(view, str(id)), can))
	Theme13.apply_tree(view.page_content)
