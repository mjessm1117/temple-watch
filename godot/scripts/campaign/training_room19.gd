extends VBoxContainer
## Temple station view; the parent station supplies touch-safe scrolling.
signal changed
const UI = preload("res://scripts/campaign/ui.gd")
const Mentor = preload("res://scripts/campaign/mentor17.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
var campaign
var selected_master := ""

func setup(value) -> void:
	campaign = value
	name = "TrainingRoom19"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 9)
	_refresh()

func _button(text_value: String, action: Callable, enabled := true) -> Button:
	var button := UI.button(text_value, action, enabled)
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return button

func _panel(title: String, detail: String) -> VBoxContainer:
	var frame := UI.panel(UI.PANEL_ALT); add_child(frame)
	var box := UI.column(7); frame.add_child(box)
	box.add_child(UI.label(title, 19, UI.GOLD))
	if detail != "": box.add_child(UI.label(detail, 14, UI.MUTED))
	return box

func _refresh() -> void:
	UI.clear(self)
	var slots := Mentor.room_slots(campaign)
	var active := []
	for pupil in campaign.state.roster:
		if str(pupil.get("mentor_id", "")) != "" and int(pupil.get("rank", 0)) <= 2 and str(pupil.get("status", "")) == "active": active.append(pupil)
	add_child(UI.label("TRAINING ROOM", 22, UI.ACCENT))
	add_child(UI.label("%d / %d slots · Level 2 opens another · +3 XP/day" % [active.size(), slots], 13, UI.GOLD))
	if slots == 0:
		_panel("SALLE OFFLINE", "Build and power the Training Salle to begin mentoring.")
		return
	add_child(UI.label("MENTOR SLOTS", 14, UI.MUTED))
	for pupil in active:
		var master: Dictionary = campaign.soldier(str(pupil.mentor_id))
		var next_rank := mini(int(pupil.rank) + 1, Classes.ranks("jedi").size())
		var target := int(Classes.rank_data("jedi", next_rank).get("xp", int(pupil.xp)))
		var line := "%s  →  %s  ·  %d / %d XP" % [master.get("n", "Master"), pupil.n, int(pupil.xp), target]
		add_child(_button(line + "    ✕", _unassign.bind(str(pupil.id))))
	if active.is_empty(): add_child(UI.label("An empty circle waits for a Master and Padawan.", 14, UI.MUTED))
	if active.size() >= slots: return
	var masters := _panel("CHOOSE A MASTER", "Tap a Master, then tap a Padawan.")
	for unit in campaign.state.roster:
		if str(unit.get("status", "")) != "active" or not Progression.is_jedi(unit) or int(unit.get("rank", 0)) < 5: continue
		var count := 0
		for pupil in active:
			if str(pupil.mentor_id) == str(unit.id): count += 1
		var label := ("●  " if selected_master == str(unit.id) else "○  ") + str(unit.n) + "  ·  " + str(unit.get("title", "Master")) + "  ·  %d / 2 active" % count
		masters.add_child(_button(label, _select_master.bind(str(unit.id)), count < 2))
	var padawans := _panel("CHOOSE A PADAWAN", "Training becomes part of the Master's lasting record.")
	for unit in campaign.state.roster:
		if str(unit.get("status", "")) != "active" or not Progression.is_jedi(unit) or int(unit.get("rank", 0)) > 2 or str(unit.get("mentor_id", "")) != "": continue
		var next_rank := int(Classes.rank_data("jedi", int(unit.rank) + 1).get("xp", 0))
		padawans.add_child(_button("%s  ·  %d / %d XP" % [unit.n, int(unit.xp), next_rank], _assign.bind(str(unit.id)), selected_master != ""))

func _select_master(id: String) -> void:
	selected_master = id
	_refresh()

func _assign(id: String) -> void:
	if Mentor.room_assign(campaign, selected_master, id):
		selected_master = ""
		changed.emit()
		_refresh()

func _unassign(id: String) -> void:
	if Mentor.unassign(campaign, id):
		changed.emit()
		_refresh()
