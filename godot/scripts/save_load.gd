extends Control
const UI = preload("res://scripts/campaign/ui.gd")
const Slots = preload("res://scripts/campaign/save_slots.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var pending_slot := -1
var pending_action := ""
var message: Label
var list: VBoxContainer
var confirm_host: VBoxContainer
var leaving := false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()

func _ready() -> void:
	_build()

func _build() -> void:
	UI.clear(self)
	var background := ColorRect.new()
	background.color = UI.BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var safe := Phone.safe_margins(get_viewport_rect().size)
	for side in ["left", "right"]: outer.add_theme_constant_override("margin_" + side, 12 + int(safe.x if side == "left" else safe.z))
	for side in ["top", "bottom"]: outer.add_theme_constant_override("margin_" + side, 12 + int(safe.y if side == "top" else safe.w))
	add_child(outer)
	var content := UI.column(8)
	outer.add_child(content)
	var head := HBoxContainer.new()
	content.add_child(head)
	var title := UI.label("SAVE / LOAD", 23, UI.ACCENT)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var back := UI.button("BACK", _back)
	back.name = "SaveBack"
	head.add_child(back)
	message = UI.label("Choose a save.", 14, UI.GOLD)
	content.add_child(message)
	confirm_host = UI.column(4)
	content.add_child(confirm_host)
	var scroll := preload("res://scripts/touch_scroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(scroll)
	list = UI.column(8)
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list)
	_refresh()

func _refresh() -> void:
	UI.clear(list)
	UI.clear(confirm_host)
	var flow := get_node("/root/CampaignFlow")
	for slot in 4:
		var current: bool = flow.active and slot == int(flow.w25_current_slot)
		var row := UI.panel(UI.PANEL_ALT if current else UI.PANEL)
		list.add_child(row)
		var col := UI.column(4)
		row.add_child(col)
		col.add_child(UI.label(("CURRENT  ·  " if current else "") + ("AUTOSAVE" if slot == 0 else "SLOT %d" % slot), 16, UI.GOLD if current else UI.ACCENT))
		col.add_child(UI.label(Slots.description(slot), 14, UI.TEXT))
		var actions := HBoxContainer.new()
		col.add_child(actions)
		if slot > 0: actions.add_child(UI.button("SAVE", _request.bind("save", slot), flow.active))
		actions.add_child(UI.button("LOAD", _request.bind("load", slot), not Slots.metadata(slot).is_empty()))
		var mission := _mission_name(slot)
		if not mission.is_empty(): col.add_child(UI.label("MISSION  /  " + mission, 14, UI.MUTED))
	if pending_slot >= 0:
		var confirm := UI.panel()
		confirm_host.add_child(confirm)
		var buttons := UI.column(6)
		confirm.add_child(buttons)
		buttons.add_child(UI.label("%s %s?" % [pending_action.to_upper(), "AUTOSAVE" if pending_slot == 0 else "SLOT %d" % pending_slot], 16, UI.GOLD))
		buttons.add_child(UI.button("CONFIRM", _confirm))
		buttons.add_child(UI.button("CANCEL", _cancel))

func _mission_name(slot: int) -> String:
	var path := Slots.path(slot)
	if not FileAccess.file_exists(path): return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.get("C") is Dictionary: return ""
	var state: Dictionary = parsed.C
	var mission: Dictionary = state.get("pending_mission", {})
	if mission.is_empty(): mission = state.get("launch_option", {})
	if mission.is_empty() and state.get("options", []) is Array and int(state.get("chosen", -1)) >= 0 and int(state.chosen) < state.options.size(): mission = state.options[int(state.chosen)]
	if mission.is_empty() and state.get("options", []) is Array and not state.options.is_empty(): mission = state.options[0]
	if not mission.is_empty(): return str(mission.get("n", mission.get("mission", mission.get("mission_id", "")))).capitalize()
	return "After mission %d" % int(state.get("step", 0))

func _request(action: String, slot: int) -> void:
	pending_action = action
	pending_slot = slot
	message.text = "Confirm %s for slot %d." % [action, slot]
	_refresh()

func _confirm() -> void:
	var flow := get_node("/root/CampaignFlow")
	var ok: bool = flow.save_slot(pending_slot) if pending_action == "save" else flow.load_slot(pending_slot)
	if not ok: message.text = "Save operation failed."
	else: message.text = "Saved slot %d." % pending_slot
	pending_slot = -1
	pending_action = ""
	if is_inside_tree(): _refresh()

func _cancel() -> void:
	pending_slot = -1
	pending_action = ""
	message.text = "Cancelled."
	_refresh()

func _back() -> void:
	if pending_slot >= 0:
		_cancel()
		return
	if leaving: return
	leaving = true
	get_node("/root/CampaignFlow").go(get_node("/root/CampaignFlow").launch_origin)
