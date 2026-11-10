extends Node

var player: AudioStreamPlayer
var sounds: Dictionary = {}
var volume := 0.55
var muted := false
var _voices: Array[AudioStreamPlayer] = []
var _voice_levels: Array[float] = []
var _voice_cursor := 0
var _ambience: AudioStreamPlayer
var _music: Array[AudioStreamPlayer] = []
var _music_slot := 0
var _music_state := "calm"
var _music_fade := 1.0
const MUSIC_FADE_SECONDS := 0.42
const MUSIC_STATES := ["calm", "contact", "enemy", "victory", "off"]

func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14.0
		add_child(voice)
		_voices.append(voice)
		_voice_levels.append(0.0)
	player = _voices[0]
	for kind in ["shot", "saber", "push", "hit", "death", "click", "turn", "step", "whiz", "clash", "ignite", "crit", "kill", "blast", "saber_clash", "alert", "villain", "radio", "objective_hit", "victory", "defeat"]:
		sounds[kind] = _synthesize(kind)
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = _synthesize("ambience")
	_ambience.volume_db = -34.0
	add_child(_ambience)
	_ambience.finished.connect(func() -> void:
		if not muted and is_inside_tree(): _ambience.play())
	_ambience.play()
	for i in 2:
		var music := AudioStreamPlayer.new()
		music.stream = _synthesize_music("calm") if i == 0 else null
		add_child(music)
		_music.append(music)
	_music[0].play()
	_update_mix()

func _process(delta: float) -> void:
	if _music_fade < 1.0:
		_music_fade = minf(1.0, _music_fade + delta / MUSIC_FADE_SECONDS)
		if _music_fade >= 1.0: _music[1 - _music_slot].stop()
	_update_mix()

func _update_mix() -> void:
	if _music.is_empty(): return
	var gain := 0.0 if muted else volume
	_ambience.volume_linear = gain * 0.035
	if gain > 0.0 and not _ambience.playing: _ambience.play()
	for i in _voices.size(): _voices[i].volume_linear = gain * _voice_levels[i]
	_music[_music_slot].volume_linear = gain * 0.13 * _music_fade
	_music[1 - _music_slot].volume_linear = gain * 0.13 * (1.0 - _music_fade)

func cue(kind: String) -> void:
	play(kind)

func set_music_state(state: String) -> void:
	if state not in MUSIC_STATES or state == _music_state: return
	_music_state = state
	_music_slot = 1 - _music_slot
	_music_fade = 0.0
	_music[_music_slot].stop()
	if state != "off":
		_music[_music_slot].stream = _synthesize_music(state)
		_music[_music_slot].play()
	_update_mix()

func _synthesize_music(state: String) -> AudioStreamWAV:
	var rate := 11025
	var count := rate * 4
	var data := PackedByteArray()
	data.resize(count * 2)
	var root := 65.5 if state == "victory" else 55.0
	var pulse := 0.0 if state == "calm" else 0.22 if state == "contact" else 0.31
	for i in count:
		var t := float(i) / rate
		var beat := fposmod(t, 0.5)
		var chord := 1.0 if state == "victory" else 0.75 if state == "contact" else 0.5
		var wave := sin(TAU * root * t) * 0.38 + sin(TAU * root * 1.5 * t) * 0.14
		wave += sin(TAU * root * 2.0 * t) * chord * 0.14
		wave += sin(TAU * 42.0 * beat) * pulse * exp(-beat * 18.0)
		var sample := int(clampf(wave * 9800.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func _synthesize(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var seconds := 0.13
	match kind:
		"saber", "push", "turn", "ignite": seconds = 0.38
		"death": seconds = 0.58
		"blast": seconds = 0.62
		"crit", "kill", "alert", "villain", "radio", "objective_hit", "victory", "defeat": seconds = 0.42
		"hum": seconds = 0.5
		"ambience": seconds = 3.0
		"step": seconds = 0.085
	var count := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var filtered := 0.0
	for i in range(count):
		var t := float(i) / rate
		var phase := t / seconds
		var noise := rng.randf_range(-1.0, 1.0)
		filtered = lerpf(filtered, noise, 0.07)
		var envelope := pow(1.0 - phase, 1.8) * minf(1.0, t * 120.0)
		var wave := 0.0
		match kind:
			"shot": wave = sin(TAU * (1100.0 * t - 560.0 * t * t)) * 0.46 + noise * 0.2
			"saber": wave = sin(TAU * (145.0 * t + 30.0 * t * t)) * 0.4 + sin(TAU * 370.0 * t) * 0.18 + filtered * 0.42
			"push": wave = sin(TAU * (72.0 * t + 360.0 * t * t)) * 0.42 + filtered * 0.75
			"hit", "clash": wave = noise * 0.42 + sin(TAU * 120.0 * t) * 0.35
			"saber_clash": wave = noise * 0.3 + sin(TAU * 630.0 * t) * 0.4
			"crit": wave = sin(TAU * (430.0 + 170.0 * phase) * t) * 0.42 + filtered * 0.2
			"kill": wave = sin(TAU * (220.0 - 90.0 * phase) * t) * 0.48 + sin(TAU * 660.0 * t) * 0.18 + filtered * 0.2
			"blast": wave = sin(TAU * (55.0 - 16.0 * phase) * t) * 0.7 + filtered * 0.5 + noise * 0.1
			"hum": envelope = 0.85; wave = sin(TAU * 96.0 * t) * 0.25 + sin(TAU * 192.0 * t) * 0.12
			"alert": wave = sin(TAU * (430.0 - 160.0 * phase) * t) * 0.5 + filtered * 0.12
			"villain": wave = sin(TAU * (165.0 - 55.0 * phase) * t) * 0.5 + sin(TAU * 220.0 * t) * 0.16
			"radio": wave = sin(TAU * (520.0 if phase < 0.5 else 680.0) * t) * 0.4 + filtered * 0.08
			"objective_hit": wave = sin(TAU * 260.0 * t) * 0.35 + sin(TAU * 65.0 * t) * 0.26
			"victory": wave = sin(TAU * 330.0 * t) * 0.34 + sin(TAU * 495.0 * t) * 0.26
			"defeat": wave = sin(TAU * (190.0 - 65.0 * phase) * t) * 0.46 + filtered * 0.2
			"death": wave = sin(TAU * (240.0 * t - 130.0 * t * t)) * 0.35 + filtered * 0.55
			"step": wave = filtered * 0.9 + sin(TAU * 82.0 * t) * 0.25
			"whiz": wave = sin(TAU * (500.0 * t + 1600.0 * t * t)) * 0.35 + noise * 0.12
			"ignite": wave = sin(TAU * (90.0 * t + 450.0 * t * t)) * 0.32 + filtered * 0.4
			"click": wave = noise * 0.38
			"turn": wave = sin(TAU * (330.0 * t + 200.0 * t * t)) * 0.35
			"ambience":
				envelope = 0.5 - 0.5 * cos(TAU * phase)
				wave = sin(TAU * 48.0 * t) * 0.2 + sin(TAU * 72.0 * t) * 0.12 + filtered * 0.11
		var sample := int(clampf(wave * envelope * 13000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if kind == "hum":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func play(kind: String) -> void:
	if muted or not sounds.has(kind): return
	var index := _voice_cursor
	var voice := _voices[index]
	_voice_levels[index] = 0.48 if kind in ["step", "whiz"] else 0.7
	_voice_cursor = (_voice_cursor + 1) % _voices.size()
	voice.stop()
	voice.stream = sounds[kind]
	voice.volume_linear = volume * _voice_levels[index]
	voice.pitch_scale = randf_range(0.96, 1.04)
	voice.play()

func _exit_tree() -> void:
	for voice in _voices: voice.stop()
	if _ambience != null: _ambience.stop()
	for music in _music: music.stop()
	sounds.clear()
