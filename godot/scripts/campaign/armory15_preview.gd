extends RefCounted
const S = preload("res://scripts/campaign/loadout_style.gd")
const Gear = preload("res://scripts/campaign/gear.gd")

static func make(c, r: Dictionary, slot: Button, phone: bool) -> PanelContainer:
	var card := S.panel(); card.name = "Armory15Preview"
	card.custom_minimum_size.x = 128 if phone else 220
	card.add_theme_stylebox_override("panel", S.box(Color("172b34"), S.CYAN, 4 if phone else 8))
	var col := S.column(3); card.add_child(col)
	var title := S.label(slot.name.trim_prefix("Slot_").replace("_", " ").to_upper() if phone else "SELECTED  /  " + slot.name.trim_prefix("Slot_").to_upper(), 10, S.CYAN)
	title.clip_text = true; col.add_child(title)
	var stats: Dictionary = Gear.battle_stats(c, str(r.id))
	var damage: Array = stats.get("dmg", [0, 0])
	var stat_text := "DMG %d-%d · A%d" % [int(damage[0]), int(damage[1]), int(stats.get("armor", 0))] if phone else "DMG %s  ·  ARM %d" % [str(damage), int(stats.get("armor", 0))]
	var stat_line := S.label(stat_text, 9 if phone else 11, S.GOLD)
	stat_line.clip_text = true; col.add_child(stat_line)
	var icon := TextureRect.new(); icon.name = "LargeGearArt"
	icon.texture = slot.get_node("GearArt").texture
	icon.custom_minimum_size = Vector2(120, 120) if phone else Vector2(200, 200)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	col.add_child(icon)
	if not phone:
		var name_label := S.label(slot.get_node("ItemName").text, 15, S.TEXT)
		name_label.clip_text = true; col.add_child(name_label)
	return card
