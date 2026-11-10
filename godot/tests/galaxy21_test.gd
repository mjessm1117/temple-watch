extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(reason)

func frames(n: int = 8) -> void:
	for i in n: await process_frame

func text_floor(node: Node) -> void:
	if node is Label and node.visible and node.text != "":
		check(node.get_theme_font_size("font_size") >= 14, "Phone label size: " + node.text.substr(0, 24))
	if node is BaseButton and node.visible:
		check(node.get_theme_font_size("font_size") >= 14, "Phone button size: " + node.text)
	for child in node.get_children(): text_floor(child)

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://galaxy21-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	for dims in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1366, 768)]:
		Phone.test_scale = 3.0 if dims.x != 1366 else 1.0
		Phone.test_touch = 1 if dims.x != 1366 else 0
		Phone.test_mobile = 1 if dims.x != 1366 else 0
		var stage := SubViewport.new()
		stage.size = Vector2i(Vector2(dims) / (1.2 if dims.x != 1366 else 1.0))
		stage.render_target_update_mode = SubViewport.UPDATE_DISABLED
		root.add_child(stage)
		var view = load("res://scenes/galaxy.tscn").instantiate()
		stage.add_child(view)
		await frames(12)
		check(view != null, "Galaxy loads at %s" % dims)
		var map = view.map_view
		if dims.x == 390:
			check(map.size.x >= stage.size.x - 24, "Portrait map fits screen")
			var labels: Array = map.marker_label_layout()
			check(labels.size() == map.offers.size(), "Every mission has a visible map label")
			for label in labels:
				check(str(label.offer.type) != "" and str(label.offer.urgency) != "" and str(label.offer.reward) != "", "Marker includes type, urgency, reward")
				for other in labels:
					if label.index != other.index: check(not label.rect.intersects(other.rect), "Map labels do not overlap")
			view._select(0)
			await frames(10)
			check(view.detail_panel.visible, "Portrait detail opens")
			var bounds: Rect2 = view.detail_panel.get_global_rect()
			check(bounds.position.x >= 12 and bounds.end.x <= stage.size.x - 12 and bounds.size.x >= stage.size.x - 24, "Portrait drawer fits full width")
			for label in view.detail.get_children():
				if label is Label: check(label.size.x >= 35, "Detail has no one-character lines")
			check(view.launch_button.visible, "Launch bridge remains available")
			text_floor(view)
			var back: Button = view.find_child("CloseSite", true, false)
			check(back != null and back.text.contains("MAP"), "Clear map Back button")
			back.pressed.emit()
			await frames()
			check(not view.detail_panel.visible, "Back restores map-only view")
		elif dims.x == 844:
			view._select(0)
			await frames(10)
			check(view.detail_panel.size.x <= float(stage.size.x) * 0.30, "Landscape drawer leaves at least 70 percent for map")
			text_floor(view)
		else:
			check(map.size.x > 400, "Desktop map stays visible")
		view.queue_free()
		await process_frame
		if dims.x != 390:
			stage.free()
			continue
		var war = load("res://scenes/sith_report.tscn").instantiate()
		stage.add_child(war)
		await frames(8)
		var tabs: Container = war.find_child("WarTabs", true, false)
		check(tabs != null and tabs.get_child_count() == 3, "Shadow War has three tabs")
		for button in tabs.get_children():
			var rect: Rect2 = button.get_global_rect()
			check(rect.position.x >= 12 and rect.end.x <= stage.size.x - 12 and rect.size.y >= 44, "Portrait tab fits and is touch sized")
		text_floor(war)
		for page in ["rivals", "report"]:
			war.show_page(page)
			await frames(4)
			check(war.page_content.size.x <= stage.size.x - 24, "Shadow War %s content fits portrait" % page)
		stage.free()
		await frames(4)
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("Galaxy21: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
