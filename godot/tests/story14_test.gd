extends SceneTree

const Story = preload("res://scripts/story/story_engine.gd")
const Portraits = preload("res://scripts/story14_portraits.gd")
const Comms = preload("res://scripts/story14_comms.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(reason)

func run() -> void:
	var engine := Story.new()
	var heroes: Array = ["Kira Venn","Tor Saalen","Sgt. Rhal Dax","Ilsa Myr","Doc Bren","Grak Ordo","Satele Shan","Jace Malcom","Varra Ordo","Lord Ressa Vaun","Kell Darrow","Sgt. Bo Hallan","Mira Tesk","Doc Ilo Venn","Rusk Abernath","Knight Sava Orrin","Tem Ruhl","Sgt. Dace Morrow","Kiri Vass","Doc Halden Pree","Bruk Tannar"]
	var names: Array = heroes + ["Darth Malgus","Lord Kaan","Darth Bane","Marchion Ro"]
	for name in names: check(Portraits.texture(name) != null,"baked portrait " + name)
	var hashes := {}
	for id in Portraits.NAMES.values():
		var path := "res://assets/story/portraits14/%s.png" % id
		var hash := FileAccess.get_md5(path)
		check(not hashes.has(hash),"portrait md5 unique: " + id)
		hashes[hash] = id
	check(hashes.size() == 26,"26 unique portrait files")
	var barks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story14-barks.json")).heroes
	for name in heroes:
		for event in ["contact","ally_down","objective_done","villain","last_enemy"]:
			check(barks[name][event].size() >= 3,"three %s barks for %s" % [event,name])
	var temple: Array = engine.table("W11_SCENES")
	for id in ["s14_kira_tor","s14_rhal_ilsa"]:
		check(temple.any(func(row): return row.id == id and int(row.bond) == 1 and row.lines.size() >= 4),"bond gated Temple talk " + id)
	var debrief: Dictionary = engine.start_debrief({"mission_id":"relay","won":true,"units":[{"id":"kira","kills":2,"hp":5,"max_hp":5}]})
	check(str(debrief.get("text","")).contains("Kira Venn"),"debrief has a named character beat")
	var low := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if low: check(root.get_node("Graphics").effective == "low","Low tier remains active")
	for size in [Vector2i(844,390),Vector2i(1366,768)]:
		root.size = size
		root.content_scale_size = size
		var scene: Control = preload("res://scenes/briefing.tscn").instantiate()
		root.add_child(scene)
		for i in 5: await process_frame
		await create_timer(0.6).timeout
		var frame: Rect2 = scene.outer_frame.get_global_rect()
		check(frame.position.x >= 0 and frame.position.y >= 0 and frame.end.x <= size.x + 1 and frame.end.y <= size.y + 1,"story frame fits %s" % size)
		var plate: Rect2 = scene.speaker_plate.get_global_rect()
		check(plate.position.x >= 0 and plate.end.x <= size.x + 1 and plate.end.y <= size.y + 1,"speaker name fits %s" % size)
		check(not scene.choices_box.visible and scene.narrative != null,"tap through dialogue exists %s" % size)
		scene._skip_dialogue()
		check(scene.choices_box.visible and scene.narrative.visible_characters == -1,"skip reveals choices %s" % size)
		var portraits: Array = scene.find_children("*","TextureRect",true,false)
		check(portraits.any(func(p): return p.texture != null and p.is_visible_in_tree()),"speaker portrait visible %s" % size)
		if size.x > 900:
			check(scene.big_speaker_portrait != null and not scene.speaker_portrait.is_visible_in_tree() if is_instance_valid(scene.speaker_portrait) else scene.big_speaker_portrait != null,"desktop has one speaker portrait")
			var skip_buttons: Array = scene.find_children("*","Button",true,false).filter(func(b): return b.text == "SKIP")
			check(skip_buttons.size() == 1 and skip_buttons[0].size.x < 150,"desktop skip is compact")
		var stub := Node.new()
		root.add_child(stub)
		var comms := Comms.new(stub)
		comms._show(stub,"contact",[{"name":"Kira Venn","hp":1}])
		await process_frame
		check(comms.card != null and comms.card.visible and comms.card.mouse_filter == Control.MOUSE_FILTER_IGNORE,"nonblocking combat bark exists %s" % size)
		check(comms.card.position.x >= 0 and comms.card.position.y >= 0 and comms.card.position.x + comms.card.size.x <= size.x and comms.card.position.y + comms.card.size.y <= size.y,"combat bark fits %s" % size)
		stub.queue_free()
		scene.queue_free()
		await process_frame
	print("Story14: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
