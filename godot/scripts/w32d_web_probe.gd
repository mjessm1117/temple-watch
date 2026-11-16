extends Node
## Local phone proof, enabled only with ?w32d_probe=1.
var war: Control
var last_update := 0
var action_callback: JavaScriptObject

func _ready() -> void:
	get_node("/root/CampaignFlow").active = true
	action_callback = JavaScriptBridge.create_callback(_action)
	JavaScriptBridge.get_interface("window").w32dAction = action_callback
	set_process(true)

func _action(args: Array) -> void:
	if args.is_empty(): return
	var action := str(args[0])
	var scene := get_tree().current_scene
	if action == "sith":
		war = preload("res://scripts/campaign/sith_screen.gd").new()
		war.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		get_tree().root.add_child(war)
		war.close_requested.connect(func(): war.queue_free(); war = null)
	elif war != null and action == "close":
		war.queue_free(); war = null
	elif scene == null: return
	elif action == "select" and scene.has_method("_select"): scene.call("_select", int(args[1]))
	elif action == "scroll" and scene.get("scroll") != null: scene.get("scroll").scroll_vertical = int(args[1])
	elif action == "refresh" and scene.has_method("_show_details"): scene.call("_show_details")
	elif action == "back" and scene.has_method("_overview"): scene.call("_overview")
	elif action == "ready" and scene.has_method("_launch"): scene.call("_launch")
	elif action == "ready_back": get_node("/root/CampaignFlow").back_from_ready25()

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - last_update < 150: return
	last_update = Time.get_ticks_msec()
	var scene := get_tree().current_scene
	var screen: Control = war if is_instance_valid(war) else scene as Control
	if screen == null: return
	var controls: Array = []
	for button in screen.find_children("*", "Button", true, false):
		if not button.is_visible_in_tree(): continue
		var rect: Rect2 = button.get_global_rect()
		controls.append({"name":button.name,"text":button.text,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
	for label in screen.find_children("*", "Label", true, false):
		if label.name != "ThreatCountdown25" or not label.is_visible_in_tree(): continue
		var rect: Rect2 = label.get_global_rect()
		controls.append({"name":label.name,"text":label.text,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
	var data := {"screen":screen.name,"size":[screen.get_viewport_rect().size.x,screen.get_viewport_rect().size.y],"controls":controls}
	if screen.has_method("_show_details"):
		var scroll: ScrollContainer = screen.get("scroll")
		var drawer: Control = screen.get("drawer_map")
		var map_view: Control = screen.get("map_view")
		data.selected = screen.get("selected")
		data.scroll = scroll.scroll_vertical
		data.scroll_max = scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
		data.edge = [scroll.get("edge").x, scroll.get("edge").y]
		data.map_strip = drawer != null and drawer.visible and drawer.size.y >= 80
		var card: Control = screen.get("selected_card")
		if card != null:
			var card_rect := card.get_global_rect()
			data.drag_rect = [card_rect.position.x, card_rect.position.y, card_rect.size.x, card_rect.size.y]
		data.signals = map_view.get("offers").size()
		data.scans = map_view.get("scans").size()
	JavaScriptBridge.eval("window.w32dState = " + JSON.stringify(data))
