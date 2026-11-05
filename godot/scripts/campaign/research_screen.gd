extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Queue = preload("res://scripts/campaign/research_queue.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Theme13 = preload("res://scripts/armory13_theme.gd")

static func _queue(view, id: String) -> void:
	if Queue.enqueue(view.campaign, id):
		view.get_node("/root/CampaignFlow").save()
		view._refresh_shell()

static func _dismiss(view) -> void:
	view.campaign.state.research.last = ""
	view.get_node("/root/CampaignFlow").save()
	view._show_page()

static func _remove(view, id: String) -> void:
	if Queue.dequeue(view.campaign, id):
		view.get_node("/root/CampaignFlow").save()
		view._show_page()

static func render(view) -> void:
	var c = view.campaign
	Queue.ensure(c.state)
	var data: Dictionary = Data.get_table("research", "RESEARCH")
	var position := 1
	var last := str(c.state.research.last)
	if last != "" and data.has(last):
		var unlock: Dictionary = data[last]
		var toast: VBoxContainer = view._card("UNLOCKED  ·  " + str(unlock.n), str(unlock.desc))
		toast.add_child(UI.button("Dismiss", _dismiss.bind(view)))
		view.page_content.move_child(toast.get_parent(), position); position += 1
	var active := str(c.state.research.cur)
	var progress := "No active study"
	if active != "" and data.has(active):
		var p: Dictionary = data[active]
		progress = "%s · %.0f / %d work days" % [p.n, float(c.state.research.prog), int(p.days)]
	var queue_names := []
	for id in c.state.research.queue: queue_names.append(str(data[id].n))
	var top: VBoxContainer = view._card("ARCHIVES  /  RESEARCH TREE", "%s\nNext: %s" % [progress, " → ".join(queue_names) if not queue_names.is_empty() else "queue empty"])
	top.add_child(UI.label("Select studies in prerequisite order. The queued project starts when its costs are available; Archives power is required.", 13, UI.MUTED))
	for id in c.state.research.queue:
		top.add_child(UI.button("Remove queued: " + str(data[id].n), _remove.bind(view, str(id))))
	view.page_content.move_child(top.get_parent(), position); position += 1
	for branch in Data.get_table("research", "RES_TREE"):
		var card: VBoxContainer = view._card(str(branch.n).to_upper(), "Prerequisites flow left → right. Completed studies are marked ✓.")
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
			var line := "%s %s  ← %s\n    %d d · %s%s · %s" % [status, p.n, " + ".join(deps) if not deps.is_empty() else "start", int(p.days), cost, schedule, p.desc]
			var label := UI.label(line, 13, UI.ACCENT if c.researched(str(id)) else UI.MUTED)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(label)
			var can := Queue.can_queue(c, str(id))
			row.add_child(UI.button("Queue", _queue.bind(view, str(id)), can))
	Theme13.apply_tree(view.page_content)
