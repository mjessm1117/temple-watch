extends Control
## Standalone dossier. bind_state() opts into a host campaign; no autosave or combat dependency.
signal mission_requested(offer: Dictionary)
signal state_changed
signal close_requested
const Layer = preload("res://scripts/campaign/sith_layer.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Art = preload("res://scripts/campaign/sith_art.gd")
const RED = Color("ec8593")
const GOLD = Color("dec28e")
var layer: RefCounted
var page := "operations"
var body: VBoxContainer
var page_content: VBoxContainer
var status_line: Label
var message := "Choose where to push back. The remaining operations will proceed at month end."
var selected_id := ""

func bind_state(campaign_state: Dictionary) -> void:
	layer = Layer.new(campaign_state)
	if is_node_ready(): show_page(page)

func _ready() -> void:
	if layer == null: layer = preview_layer()
	show_page(page)

static func preview_layer():
	var state: Dictionary = preload("res://scripts/campaign/state.gd").new().state
	var preview = Layer.new(state, 731)
	for day in 65:
		for m in preview.mission_options():
			if m.kind == "ambush" and m.get("rival_id", "") == "veyra": preview.resolve_mission(m.id, true)
			elif m.kind == "project" and day in [12, 43]: preview.resolve_mission(m.id, true)
		preview.advance_day()
	state.roster[1].dark = 7
	state.res.intel = 5
	return preview

func show_page(value: String) -> void:
	page = value
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("090f17")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 34)
	for edge in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 22)
	add_child(margin)
	body = UI.column(14)
	margin.add_child(body)
	_header()
	_project()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	body.add_child(tabs)
	for entry in [["operations", "01   SITH OPERATIONS"], ["rivals", "02   RIVAL DOSSIERS"], ["report", "03   COUNCIL REPORT"]]:
		var key: String = entry[0]
		var button := UI.button(entry[1], func(): show_page(key))
		button.custom_minimum_size.x = 240
		if key == page: button.add_theme_stylebox_override("normal", UI.style(Color("29212e"), RED))
		tabs.add_child(button)
	var scroll := preload("res://scripts/touch_scroll.gd").new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	page_content = UI.column(12)
	page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page_content)
	if page == "rivals": _rivals()
	elif page == "report": _report()
	else: _operations()
	status_line = UI.label(message, 14, UI.MUTED)
	body.add_child(status_line)

func _header() -> void:
	var row := HBoxContainer.new()
	body.add_child(row)
	var title := UI.column(2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	title.add_child(UI.label("TEMPLE WATCH     /     COUNCIL INTELLIGENCE", 13, GOLD))
	title.add_child(UI.label("THE SHADOW WAR", 34))
	var dates := UI.column(4)
	dates.custom_minimum_size.x = 245
	row.add_child(dates)
	dates.add_child(UI.label("MONTH %02d  /  DAY %02d" % [int(layer.s.month), int(layer.s.day) % 30 + 1], 18, GOLD))
	dates.add_child(UI.label("%d Intel available" % int(layer.state.get("res", {}).get("intel", 0)), 14, UI.MUTED))
	row.add_child(UI.button("Close", _close))

func _close() -> void:
	if close_requested.get_connections().is_empty(): get_tree().quit()
	else: close_requested.emit()

func _project() -> void:
	var card := UI.panel(Color("201a27"))
	body.add_child(card)
	var box := UI.column(8)
	card.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title := UI.label("DARKNESS   /   %02d OF 12 SEGMENTS" % int(layer.s.segments), 17, RED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var deadline := "Next escalation: " + date_label(int(layer.s.next_escalation))
	if int(layer.s.collapse_day) >= 0: deadline = "ORDER FALLS: " + date_label(int(layer.s.collapse_day))
	if layer.s.defeated: deadline = "THE ORDER HAS FALLEN"
	var date := UI.label(deadline, 15, GOLD)
	date.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(date)
	var segments := HBoxContainer.new()
	segments.add_theme_constant_override("separation", 6)
	box.add_child(segments)
	for i in 12:
		var pip := ColorRect.new()
		pip.custom_minimum_size.y = 12
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pip.color = RED if i < int(layer.s.segments) else Color("39313f")
		segments.add_child(pip)
	box.add_child(UI.label("Destroy a shadow conduit: −2 segments   ·   Breach a stronghold: −1   ·   End a final pursuit: −2", 14, UI.MUTED))

func _operations() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	page_content.add_child(row)
	var left := UI.column(12)
	left.custom_minimum_size.x = 590
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	row.add_child(left)
	left.add_child(UI.label("ENEMY OPERATIONS", 21, GOLD))
	left.add_child(UI.label("Counter one by mission this month. Intel can stop additional threats.", 15, UI.MUTED))
	var active_ops: Array = layer.operations()
	if active_ops.is_empty(): left.add_child(UI.label("No Sith movements detected yet.", 16, UI.MUTED))
	for op in active_ops:
		var box := _card(left)
		box.add_child(UI.label(str(op.status).to_upper() + "   /   " + date_label(int(op.deadline)), 12, RED))
		box.add_child(UI.label(str(op.n), 23))
		box.add_child(UI.label(str(op.desc), 16, UI.MUTED))
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		box.add_child(buttons)
		var available: bool = op.status == "open" and not layer.s.defeated
		var chosen: String = str(layer.s.counters.get(str(int(layer.s.month)), ""))
		buttons.add_child(UI.button("Choose counter mission", func(): _choose(str(op.mission_id)), available and chosen in ["", str(op.mission_id)]))
		if op.revealed:
			buttons.add_child(UI.button("Stop · %d Intel" % int(op.intel), func(): _intel(str(op.id)), available and int(layer.state.res.intel) >= int(op.intel)))
		else:
			buttons.add_child(UI.button("Reveal · 1 Intel", func(): _reveal(str(op.id)), available and int(layer.state.res.intel) >= 1))
	var right := UI.column(12)
	right.custom_minimum_size.x = 590
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	row.add_child(right)
	right.add_child(UI.label("WAYS TO FIGHT BACK", 21, GOLD))
	var options: Array = layer.mission_options()
	var shown := 0
	# Recovery routes precede ordinary crises and rival ambushes.
	for kind in ["project", "stronghold", "pursuit", "rescue_rival", "retaliation", "redemption", "kidnap", "ambush", "crisis"]:
		for m in options:
			if m.kind != kind: continue
			var box := _card(right)
			box.add_child(UI.label(str(m.kind).replace("_", " ").to_upper() + ("   /   " + date_label(int(m.deadline)) if int(m.deadline) >= 0 else "   /   NO EXPIRY"), 12, GOLD))
			box.add_child(UI.label(str(m.n), 19))
			if m.has("risk"): box.add_child(UI.label(str(m.risk), 14, UI.MUTED))
			if m.has("reward"): box.add_child(UI.label(str(m.reward), 14, UI.MUTED))
			box.add_child(UI.button("Select mission", func(): _choose(str(m.id)), not layer.s.defeated))
			shown += 1
	if shown == 0: right.add_child(UI.label("No outstanding missions.", 16, UI.MUTED))

func _rivals() -> void:
	page_content.add_child(UI.label("They remember every encounter. Each victory reveals a countermeasure.", 15, UI.MUTED))
	if layer.rivals().is_empty():
		page_content.add_child(UI.label("No Sith movements detected yet.", 16, UI.MUTED))
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	page_content.add_child(row)
	var index := 0
	for r in layer.rivals():
		var box := _card(row)
		box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var portrait := Art.new()
		portrait.variant = index
		portrait.ink = Color(str(r.color))
		portrait.custom_minimum_size.y = 180
		box.add_child(portrait)
		box.add_child(UI.label(str(r.title).to_upper(), 12, Color(str(r.color))))
		box.add_child(UI.label(str(r.n), 26))
		box.add_child(UI.label(str(r.domain), 14, UI.MUTED))
		box.add_child(UI.label("KNOWLEDGE %d%%   /   %s" % [int(r.knowledge), str(r.phase).to_upper()], 13, GOLD))
		var progress := ProgressBar.new()
		progress.value = float(r.knowledge)
		progress.show_percentage = false
		progress.custom_minimum_size.y = 5
		progress.add_theme_stylebox_override("background", UI.style(Color("252b35")))
		progress.add_theme_stylebox_override("fill", UI.style(Color(str(r.color))))
		box.add_child(progress)
		box.add_child(UI.label("STRENGTHS", 12, RED))
		box.add_child(UI.label(" · ".join(r.strengths), 15))
		box.add_child(UI.label("WEAKNESSES", 12, UI.ACCENT))
		box.add_child(UI.label(" · ".join(r.weaknesses), 15))
		box.add_child(UI.label("COUNTERMEASURES   /   %d REVEALED" % r.revealed.size(), 12, GOLD))
		if r.revealed.is_empty(): box.add_child(UI.label("Defeat this rival to learn how to break their advantage.", 15, UI.MUTED))
		for counter in r.revealed:
			box.add_child(UI.label(str(counter.n) + " — " + str(counter.text), 15, UI.MUTED))
		index += 1

func _report() -> void:
	if layer.s.reports.is_empty():
		page_content.add_child(UI.label("The Council will convene at the end of this month.", 24, GOLD))
		return
	var report: Dictionary = layer.s.reports.back()
	page_content.add_child(UI.label("MONTH %02d   /   %s" % [int(report.month), str(report.assessment).to_upper()], 28, GOLD))
	page_content.add_child(UI.label("The Council records our victories, the cost of unanswered calls, and the enemy's growing knowledge.", 16, UI.MUTED))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 14)
	page_content.add_child(stats)
	for entry in [["won", "MISSIONS WON"], ["operations_countered", "OPERATIONS STOPPED"], ["crises_ignored", "UNANSWERED CRISES"], ["rivals_defeated", "RIVALS REPULSED"]]:
		var box := _card(stats)
		box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(UI.label("%02d" % int(report.metrics.get(entry[0], 0)), 40, GOLD))
		box.add_child(UI.label(entry[1], 13, UI.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	page_content.add_child(row)
	var ops := _card(row)
	ops.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ops.add_child(UI.label("WHAT THE ENEMY ACHIEVED", 18, RED))
	if report.operations.is_empty(): ops.add_child(UI.label("No Sith movements detected yet.", 16, UI.MUTED))
	for op in report.operations:
		ops.add_child(UI.label(str(op.n) + "   /   " + str(op.status).to_upper(), 18))
		ops.add_child(UI.label(str(op.desc), 15, UI.MUTED))
	ops.add_child(UI.label("Darkness at council: %d / 12\nNext escalation: %s" % [int(report.segments), date_label(int(report.next_escalation))], 17, GOLD))
	var rivals_box := _card(row)
	rivals_box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rivals_box.add_child(UI.label("THE SITH ARE LEARNING", 18, RED))
	if report.rivals.is_empty(): rivals_box.add_child(UI.label("No rival movements detected yet.", 16, UI.MUTED))
	for r in report.rivals:
		rivals_box.add_child(UI.label("%s   /   %d%% knowledge" % [r.n, int(r.knowledge)], 18))
		rivals_box.add_child(UI.label("%s · %d defeats · %d countermeasures" % [str(r.phase).capitalize(), int(r.defeats), r.revealed.size()], 15, UI.MUTED))
	for change in report.mentorship:
		page_content.add_child(UI.label("%s: Darkness %+d through %s's counsel." % [change.n, int(change.delta), change.mentor], 16, UI.ACCENT))

func _card(parent: Node) -> VBoxContainer:
	var card := UI.panel(Color("131c27"))
	parent.add_child(card)
	var box := UI.column(8)
	card.add_child(box)
	return box

func _choose(id: String) -> void:
	var m: Dictionary = layer.s.missions.get(id, {})
	if m.is_empty() or m.status != "open" or layer.s.defeated: return
	if m.kind == "counter" and not layer.counter(str(m.op_id), id): return
	selected_id = id
	var chosen: Dictionary = {}
	for option in layer.mission_options():
		if option.id == id: chosen = option
	message = "Selected: " + str(chosen.get("n", "Mission"))
	state_changed.emit()
	mission_requested.emit(chosen.duplicate(true))
	show_page(page)

func _intel(id: String) -> void:
	if layer.counter_with_intel(id):
		message = "Operation stopped. The Sith network has lost its opening."
		state_changed.emit()
	show_page(page)

func _reveal(id: String) -> void:
	if layer.reveal_operation(id):
		message = "Operation identified. Choose a response before its deadline."
		state_changed.emit()
	show_page(page)

static func date_label(day: int) -> String:
	return "Month %02d · Day %02d" % [day / 30 + 1, day % 30 + 1]
