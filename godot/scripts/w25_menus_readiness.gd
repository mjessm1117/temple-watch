extends Control
const UI = preload("res://scripts/campaign/ui.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var flow: Node
var squad: Array = []
var choice_made := false
var confirm_box: VBoxContainer
var deploy_button: Button
var message: Label
var choice_buttons: Array[Button] = []

func _ready() -> void:
	name = "Readiness25"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	flow = get_node("/root/CampaignFlow")
	var option: Dictionary = flow.campaign.state.get("launch_option", {})
	squad = flow.campaign.default_squad(option)
	_build(option)

func _build(option: Dictionary) -> void:
	var background := ColorRect.new()
	background.color = UI.BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var safe := Phone.safe_margins(get_viewport_rect().size)
	for side in ["left", "right", "top", "bottom"]:
		var extra := safe.x if side == "left" else safe.z if side == "right" else safe.y if side == "top" else safe.w
		outer.add_theme_constant_override("margin_" + side, 10 + int(extra))
	add_child(outer)
	var col := UI.column(6)
	outer.add_child(col)
	var head := HBoxContainer.new()
	head.size_flags_vertical = SIZE_SHRINK_BEGIN
	col.add_child(head)
	var title := UI.label("MISSION READY", 20, UI.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var back := UI.button("BACK", flow.back_from_ready25)
	back.name = "ReadyBack"
	back.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(back)
	var scroll := preload("res://scripts/touch_scroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	col.add_child(scroll)
	var body := UI.column(8)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(UI.label(str(flow.screen.get("title", option.get("n", "Mission briefing"))), 18, UI.ACCENT))
	var full_brief := str(flow.screen.get("text", "Complete the operation."))
	var first_line := full_brief.get_slice("\n", 0)
	body.add_child(UI.label(first_line, 15, UI.TEXT))
	if full_brief != first_line:
		var details := UI.label(full_brief, 14, UI.TEXT)
		details.visible = false
		var expand := UI.button("FULL BRIEFING", func(): details.visible = not details.visible)
		body.add_child(expand)
		body.add_child(details)
	if not str(flow.screen.get("goal", "")).is_empty(): body.add_child(UI.label("OBJECTIVE / " + str(flow.screen.goal).get_slice(".", 0), 14, UI.GOLD))
	var choices: Array = flow.screen.get("choices", [])
	if not choices.is_empty():
		body.add_child(UI.label("YOUR DECISION", 14, UI.ACCENT))
		for choice in choices:
			var button := UI.button(str(choice.get("label", "Continue")), _choose.bind(str(choice.get("id", ""))))
			button.name = "ReadyChoice%d" % choice_buttons.size()
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(button)
			choice_buttons.append(button)
	else: choice_made = true
	body.add_child(UI.label("SQUAD / %d READY" % squad.size(), 16, UI.ACCENT))
	for id in squad:
		var person: Dictionary = flow.campaign.soldier(str(id))
		var status := "WOUNDED" if int(person.get("wound", 0)) > 0 else "TIRED" if int(person.get("fatigue", 0)) > 60 else "READY"
		body.add_child(UI.label("%s  ·  %s" % [str(person.get("n", id)), status], 14, UI.TEXT))
	confirm_box = UI.column(4)
	col.add_child(confirm_box)
	message = UI.label("Choose a briefing response." if not choice_made else "Ready to deploy.", 14, UI.MUTED)
	confirm_box.add_child(message)
	deploy_button = UI.button("DEPLOY", _confirm)
	deploy_button.name = "ReadyDeploy"
	deploy_button.disabled = not choice_made or squad.is_empty()
	confirm_box.add_child(deploy_button)
	# The phone route uses one confirm card after the briefing choice.
	if Phone.window_size().x < 420 and Phone.mobile_device() and choice_made: _confirm()

func _choose(id: String) -> void:
	if choice_made: return
	var result: Dictionary = flow.story.apply_choice(flow.campaign.state, id)
	if not result.get("ok", false):
		message.text = str(result.get("reason", "Unavailable"))
		return
	choice_made = true
	for button in choice_buttons: button.disabled = true
	message.text = "Decision recorded. Ready to deploy."
	deploy_button.disabled = squad.is_empty()
	flow.save()
	if Phone.window_size().x < 420 and Phone.mobile_device(): _confirm()

func _confirm() -> void:
	if not choice_made: return
	if confirm_box.has_node("ReadyConfirm"): return
	var confirm := UI.button("CONFIRM DEPLOY", _launch)
	confirm.name = "ReadyConfirm"
	confirm_box.add_child(confirm)
	deploy_button.hide()
	message.text = "Deploy this squad?"

func _launch() -> void:
	if not flow.launch_squad(squad): message.text = "Squad unavailable. Return to Galaxy."
