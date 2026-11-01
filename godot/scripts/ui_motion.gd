extends Node
## Shared, node-owned transitions and quiet procedural UI feedback.
static var tones: Dictionary = {}
var target: Control

func _ready() -> void:
	target = get_parent() as Control
	if target is BaseButton:
		target.mouse_entered.connect(_hover)
		target.focus_entered.connect(_hover)
		target.pressed.connect(func(): _sound(true))
	else:
		target.modulate.a = 0.0
		target.create_tween().tween_property(target, "modulate:a", 1.0, 0.28)
		_enter.call_deferred()
		if target is PanelContainer:
			target.draw.connect(_trim)
			target.resized.connect(target.queue_redraw)

func _trim() -> void:
	var s := target.size
	for p in [Vector2.ZERO, Vector2(s.x,0), Vector2(0,s.y), s]:
		var d := Vector2(1 if p.x == 0 else -1, 1 if p.y == 0 else -1)
		target.draw_line(p,p+Vector2(d.x*12,0),Color("79d3e2"),1.4)
		target.draw_line(p,p+Vector2(0,d.y*9),Color("79d3e2"),1.4)

func _hover() -> void:
	if target.disabled: return
	_sound(false)
	target.modulate = Color(1.18, 1.24, 1.26)
	target.create_tween().tween_property(target, "modulate", Color.WHITE, 0.28)

func _sound(pressed: bool) -> void:
	if not is_inside_tree() or DisplayServer.get_name() == "headless": return
	if not tones.has(pressed):
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		var bytes := PackedByteArray()
		var count := 1800 if pressed else 1000
		bytes.resize(count * 2)
		for i in count:
			var t := float(i) / 22050.0
			var envelope := sin(PI * float(i) / count) * exp(-t * 45.0)
			bytes.encode_s16(i * 2, int(sin(t * TAU * (660 if pressed else 880)) * envelope * 2600))
		wav.data = bytes
		tones[pressed] = wav
	var player := AudioStreamPlayer.new()
	player.stream = tones[pressed]
	player.volume_db = -12
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _enter() -> void:
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_instance_valid(target) or not target.is_inside_tree(): return
	var destination := target.position.x
	target.position.x += 10
	target.create_tween().tween_property(target,"position:x",destination,0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
