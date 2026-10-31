extends Control
const UI = preload("res://scripts/campaign/ui.gd")
var flow: Node
var selected: Array = []
var deploy: Button
var counter: Label
var choices: Dictionary = {}

func _ready() -> void:
	flow = get_node("/root/CampaignFlow")
	var c = flow.session()
	selected = c.state.pending_mission.get("squad", c.default_squad().slice(0, 4)).duplicate()
	var bg := ColorRect.new(); bg.color = UI.BG; bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(margin)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 30)
	var box := UI.column(12); margin.add_child(box)
	box.add_child(UI.label("DEPLOYMENT  /  SELECT FOUR", 32, UI.ACCENT))
	box.add_child(UI.label("Choose four fit soldiers. Rank bonuses apply to every soldier. Select a Medic for ranged recovery.", 18, UI.MUTED))
	var id: String = c.state.get("launch_option", {}).get("mission", "rescue")
	if preload("res://scripts/campaign/battle_bridge.gd").map_path(id).ends_with("rescue.json") and id != "rescue":
		box.add_child(UI.label("Current battlefield: Detention Line. Free Mira and escort her to evacuation to resolve this operation.", 16, UI.GOLD))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = SIZE_EXPAND_FILL; box.add_child(scroll)
	var list := UI.column(8); list.size_flags_horizontal = SIZE_EXPAND_FILL; scroll.add_child(list)
	for r in c.state.roster:
		var fit: bool = r.status == "active" and int(r.wound) == 0 and r.assign == ""
		var label := "%s  ·  %s  ·  Rank %d" % [r.n, r.cls, int(r.rank)]
		if r.cls not in ["Guardian", "Consular", "Soldier", "Scout", "Medic"]:
			label += "  ·  shared Jedi kit" if preload("res://scripts/campaign/progression.gd").is_jedi(r) else "  ·  shared troop kit"
		if not fit: label += "  ·  %d recovery days / %s" % [int(r.wound), str(r.assign) if r.assign != "" else str(r.status)]
		var button := UI.button(label, _toggle.bind(str(r.id)), fit)
		button.toggle_mode = true; button.button_pressed = selected.has(r.id)
		list.add_child(button); choices[r.id] = button
	counter = UI.label("", 20, UI.GOLD); box.add_child(counter)
	var row := HBoxContainer.new(); box.add_child(row)
	row.add_child(UI.button("← Temple", func(): flow.go("temple")))
	deploy = UI.button("DEPLOY →", _deploy); row.add_child(deploy)
	_refresh()

func _toggle(id: String) -> void:
	if selected.has(id): selected.erase(id)
	elif selected.size() < 4: selected.append(id)
	_refresh()

func _refresh() -> void:
	for id in choices: choices[id].button_pressed = selected.has(id)
	counter.text = "%d / 4 soldiers selected" % selected.size()
	deploy.disabled = selected.size() != 4

func _deploy() -> void:
	flow.launch_squad(selected)
