extends RefCounted
const Gear = preload("res://scripts/campaign/gear.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Theme13 = preload("res://scripts/armory13_theme.gd")

static func _upgrade(view, kind: String) -> void:
	var c = view.campaign
	var ok := Gear.upgrade_armor(c, str(view.selected_id)) if kind == "a" else Gear.upgrade_base(c, str(view.selected_id), kind)
	if ok:
		view.get_node("/root/CampaignFlow").save()
		view._refresh_shell()
		render(view)
	else: view.notice_label.text = "Forge upgrade unavailable: check research and credits."

static func render(view) -> void:
	if view.page != "Arsenal" or view.selected_room != "forge" or view.page_content.find_child("Wave10Forge", true, false) != null: return
	var c = view.campaign
	var r: Dictionary = c.soldier(str(view.selected_id))
	if r.is_empty(): return
	var card: VBoxContainer = view._card("KYBER FORGE  /  MARK UPGRADES", "%s · %s. Select another soldier in the Arsenal roster below. Each mark needs research and credits." % [r.n, r.cls])
	card.name = "Wave10Forge"
	view.page_content.move_child(card.get_parent(), 1)
	var primary := "s" if Progression.is_jedi(r) else "w"
	for kind in [primary, "a"]:
		if kind == "a" and not Data.get_table("gear", "ARMOR").get(str(r.gear.armor), {}).has("mk"): continue
		var lv := int(r.gear.mk.get("armor:" + str(r.gear.armor), 1)) if kind == "a" else int(r.gear.mk.get(kind, 1))
		var label := "Armor" if kind == "a" else "Saber" if kind == "s" else "Weapon"
		if lv >= 3:
			card.add_child(UI.label("%s · Mk III complete" % label, 14, UI.ACCENT))
			continue
		var res: String = Data.get_table("gear", "MK_RES")[kind][lv - 1]
		var cost := Gear.price(c, int(Data.get_table("gear", "MK_COST")[lv]))
		var unlocked: bool = c.researched(res) and preload("res://scripts/campaign/strat_base.gd").operational(c.state, "forge")
		var preview := Gear.preview(c, str(r.id), "armor_mark" if kind == "a" else "base_mark", kind)
		card.add_child(UI.label("%s Mk %s → Mk %s · %d Cr · %s" % [label, ["I", "II", "III"][lv - 1], ["I", "II", "III"][lv], cost, "READY" if unlocked else "Research: " + str(Data.get_table("research", "RESEARCH")[res].n)], 14, UI.GOLD))
		card.add_child(UI.label(preview, 13, UI.ACCENT))
		card.add_child(UI.button("Forge " + label + " Mk " + ["I", "II", "III"][lv], _upgrade.bind(view, kind), unlocked and int(c.state.res.credits) >= cost))
	Theme13.apply_tree(card.get_parent())
