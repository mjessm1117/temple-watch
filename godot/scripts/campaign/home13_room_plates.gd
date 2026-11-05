extends RefCounted
## Short state plates and measured type keep every cutaway room readable.

static func state_text(info: Dictionary) -> String:
	if str(info.status) in ["Under construction", "Upgrading"]: return "BUILDING"
	if not bool(info.built): return "EMPTY"
	if str(info.wing) != "": return "BUILT · %d staff" % int(info.staff)
	return "BUILT"

static func fit(label: Label, width: float, preferred: int) -> void:
	var font := label.get_theme_font("font")
	var size := preferred
	while size > 5 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width - 4.0:
		size -= 1
	label.add_theme_font_size_override("font_size", size)
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

static func layout(button: Button, info: Dictionary, phone: bool) -> void:
	var name_label: Label = button.get_node("RoomName")
	var detail: Label = button.get_node("RoomDetail")
	detail.text = state_text(info)
	var preferred := 8 if info.kind in ["spire", "council"] else 9
	var name_width := name_label.get_theme_font("font").get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, preferred).x
	if name_width > button.size.x - 4.0 and " " in name_label.text:
		name_label.add_theme_font_size_override("font_size", preferred)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	else:
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		fit(name_label, button.size.x, preferred)
	# Keep all three lines in the upper part of each target. Adjacent floors
	# project only about 57 pixels apart at desktop resolution.
	name_label.offset_top = 2
	name_label.offset_bottom = 28
	name_label.clip_text = false
	fit(detail, button.size.x, 9)
	detail.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	detail.offset_top = 30
	detail.offset_bottom = 43
	name_label.visible = not phone
	detail.visible = not phone
	if button.has_node("BattleBonus"):
		var bonus: Label = button.get_node("BattleBonus")
		fit(bonus, button.size.x, 8)
		bonus.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		bonus.offset_top = 44
		bonus.offset_bottom = 57
		bonus.visible = not phone
	if button.has_node("RoomAlert"):
		# Desktop names own the top strip; the command bar and teaser show alerts.
		button.get_node("RoomAlert").visible = phone
