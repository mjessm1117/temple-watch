extends RefCounted
## Keeps the desktop battle actions in one short tray.
var g
var buttons: Dictionary
var row: HBoxContainer
var copies: Dictionary = {}
var more: Button
var popup: PanelContainer
var list: VBoxContainer
var popup_scroll

func setup(game, root: Control, action_row: HFlowContainer, action_buttons: Dictionary) -> void:
	g = game; buttons = action_buttons
	var source_scroll: ScrollContainer = action_row.get_parent()
	var bottom_box: VBoxContainer = source_scroll.get_parent()
	row = HBoxContainer.new(); row.name = "CompactActions"
	row.add_theme_constant_override("separation", 4)
	bottom_box.add_child(row)
	bottom_box.move_child(row, source_scroll.get_index())
	source_scroll.hide()
	for mode in buttons:
		var copy = preload("res://scripts/hud_ability_button.gd").new()
		copy.custom_minimum_size = Vector2(108, 58)
		copy.focus_mode = Control.FOCUS_NONE
		copy.compact = true
		copy.visible = false
		copy.pressed.connect(func() -> void: g._choose_action(mode))
		row.add_child(copy)
		copies[mode] = copy
	more = Button.new(); more.name = "MoreActions"; more.text = "MORE ▴"
	more.custom_minimum_size = Vector2(88, 58); more.focus_mode = Control.FOCUS_NONE
	more.pressed.connect(func() -> void: popup.visible = not popup.visible)
	row.add_child(more)
	popup = PanelContainer.new(); popup.name = "MoreActionsPopup"; popup.visible = false
	popup.anchor_left = 0.5; popup.anchor_right = 0.5
	popup.anchor_top = 1.0; popup.anchor_bottom = 1.0
	popup.offset_left = -255; popup.offset_right = 255
	popup.offset_top = -500; popup.offset_bottom = -132
	var style := StyleBoxFlat.new(); style.bg_color = Color("0b1924f2")
	style.border_color = Color("79c7d9"); style.set_border_width_all(1)
	style.set_content_margin_all(8); popup.add_theme_stylebox_override("panel", style)
	root.add_child(popup)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup_scroll = scroll
	popup.add_child(scroll)
	list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(list)

func refresh() -> void:
	if row == null: return
	var available: Array[String] = []
	for mode in buttons:
		if bool(buttons[mode].get_meta("battle13_available", false)): available.append(str(mode))
	var primary: Array[String] = []
	for mode in ["move", "shoot", "strike", "push", "overwatch", "reload", "hunker", "medpac"]:
		if mode in available and primary.size() < 5: primary.append(mode)
	for mode in available:
		if primary.size() >= 5: break
		if mode not in primary: primary.append(mode)
	for mode in buttons:
		var source: Button = buttons[mode]
		var copy: Button = copies[mode]
		copy.visible = mode in primary
		if copy.visible:
			copy.call("configure", mode, source.display_name, "", source.cost, source.cooldown, "", g.action == mode)
			copy.call("set_chain", g.mission.abilities.get(mode, {}), g.mission.unit_by_id(g.target_id))
			copy.tooltip_text = source.tooltip_text
	for i in range(primary.size()): row.move_child(copies[primary[i]], i)
	var overflow: Array[String] = []
	for mode in available:
		if mode not in primary: overflow.append(mode)
	more.visible = not overflow.is_empty()
	if overflow.is_empty(): popup.visible = false
	if popup_scroll.touch_dragging: return
	var saved_scroll: int = popup_scroll.scroll_vertical
	for child in list.get_children(): child.queue_free()
	for mode in overflow:
		var source: Button = buttons[mode]
		var item := Button.new(); item.text = "%s %s  ·  %s AP" % [source.display_name, preload("res://scripts/hud18_icon.gd").marks(g.mission.abilities.get(mode, {})), source.cost]
		item.custom_minimum_size.y = 42; item.focus_mode = Control.FOCUS_NONE
		item.pressed.connect(func() -> void: popup.hide(); g._choose_action(mode))
		list.add_child(item)
	popup_scroll.set_deferred("scroll_vertical", saved_scroll)
