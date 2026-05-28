extends Node
## 程序化生成的 BGM/SFX 总线。原版 sound.js 也用 WebAudio 合成音效。
## 通过 AudioStreamGenerator 实时合成，避免依赖外部音频资产。

const SR := 44100.0

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _bgm_thread_active := false
var _bgm_phase := 0.0
var _bgm_step := 0
var _bgm_speed := 1.0
var _muted := false

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = AudioStreamGenerator.new()
	(bgm_player.stream as AudioStreamGenerator).mix_rate = SR
	(bgm_player.stream as AudioStreamGenerator).buffer_length = 0.2
	bgm_player.bus = "Master"
	bgm_player.volume_db = linear_to_db(0.4)
	add_child(bgm_player)

	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

	var s: Dictionary = GameStore.get_settings()
	_muted = bool(s.get("muted", false))

func set_muted(v: bool) -> void:
	_muted = v
	var s: Dictionary = GameStore.get_settings()
	s["muted"] = v
	GameStore.save_settings(s)
	if v:
		stop_bgm()

func is_muted() -> bool:
	return _muted

# ===== BGM =====
func play_bgm(speed: float = 1.0) -> void:
	if _muted:
		return
	_bgm_speed = speed
	if bgm_player.playing:
		return
	_bgm_phase = 0.0
	_bgm_step = 0
	bgm_player.play()
	_bgm_thread_active = true
	_pump_bgm.call_deferred()

func speed_up_bgm() -> void:
	_bgm_speed = 1.6

func stop_bgm() -> void:
	_bgm_thread_active = false
	bgm_player.stop()

func _pump_bgm() -> void:
	if not _bgm_thread_active:
		return
	var pb: AudioStreamGeneratorPlayback = bgm_player.get_stream_playback()
	if pb == null:
		_bgm_thread_active = false
		return
	# C 大调上扬节奏：c-e-g-a-g-e
	var notes := [261.63, 329.63, 392.00, 440.0, 392.0, 329.63, 261.63, 329.63]
	var beat_dur: float = 0.30 / max(_bgm_speed, 0.5)
	var frames_total: int = int(beat_dur * SR)
	var frames := pb.get_frames_available()
	while frames > 0:
		var batch := mini(frames, 1024)
		for i in batch:
			@warning_ignore("integer_division")
			var note_idx: int = (_bgm_step / frames_total) % notes.size()
			var freq: float = notes[note_idx]
			var t: float = float(_bgm_step % frames_total) / float(frames_total)
			var env: float = pow(1.0 - t, 0.6)
			var v: float = sin(_bgm_phase) * 0.18 * env
			# 加和声
			v += sin(_bgm_phase * 2.0) * 0.05 * env
			pb.push_frame(Vector2(v, v))
			_bgm_phase += TAU * freq / SR
			if _bgm_phase > TAU:
				_bgm_phase -= TAU
			_bgm_step += 1
		frames -= batch
	get_tree().create_timer(0.05).timeout.connect(_pump_bgm)

# ===== SFX (短促合成音) =====
func _pick_sfx() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func _play_synth(freq: float, dur: float, vol: float = 0.5, wave: String = "sine") -> void:
	if _muted:
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SR
	stream.buffer_length = max(dur + 0.05, 0.1)
	var p := _pick_sfx()
	p.stream = stream
	p.volume_db = linear_to_db(vol)
	p.play()
	var pb: AudioStreamGeneratorPlayback = p.get_stream_playback()
	if pb == null:
		return
	var total := int(dur * SR)
	var phase := 0.0
	var i := 0
	while i < total:
		var batch: int = mini(pb.get_frames_available(), mini(total - i, 1024))
		for j in batch:
			var t: float = float(i) / float(total)
			var env: float = pow(1.0 - t, 0.7)
			var v: float = 0.0
			match wave:
				"square": v = (1.0 if sin(phase) > 0.0 else -1.0) * 0.6
				"saw":    v = fposmod(phase / TAU, 1.0) * 2.0 - 1.0
				"noise":  v = randf_range(-1.0, 1.0)
				_:        v = sin(phase)
			v *= env
			pb.push_frame(Vector2(v, v))
			phase += TAU * freq / SR
			i += 1
		if batch == 0:
			await get_tree().create_timer(0.01).timeout

func play_dice() -> void:
	_play_synth(440.0, 0.08, 0.4, "square")

func play_step() -> void:
	_play_synth(880.0, 0.04, 0.3, "sine")

func play_coin() -> void:
	_play_synth(880.0, 0.10, 0.45, "sine")
	await get_tree().create_timer(0.06).timeout
	_play_synth(1320.0, 0.10, 0.45, "sine")

func play_star() -> void:
	for f in [880, 1175, 1568]:
		_play_synth(float(f), 0.12, 0.45, "sine")
		await get_tree().create_timer(0.07).timeout

func play_event() -> void:
	_play_synth(660.0, 0.18, 0.5, "saw")

func play_loss() -> void:
	_play_synth(220.0, 0.25, 0.5, "saw")

func play_game_over() -> void:
	for f in [523, 659, 784, 1046]:
		_play_synth(float(f), 0.18, 0.5, "sine")
		await get_tree().create_timer(0.13).timeout

func play_click() -> void:
	_play_synth(1200.0, 0.04, 0.3, "square")
