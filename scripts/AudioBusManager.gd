extends Node

# BGM、SE、ボイスなどのサウンド全体を管理

# オーディオバスの名前
const BUS_MASTER = "Master"
const BUS_BGM = "BGM"
const BUS_SFX = "SFX"
const BUS_VOICE = "Voice"

# オーディオプレイヤー
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var voice_player: AudioStreamPlayer

# 設定
@export var sfx_pool_size: int = 8
@export var default_bgm_volume: float = -10.0
@export var default_sfx_volume: float = -5.0
@export var default_voice_volume: float = -5.0

# 現在のBGM
var current_bgm: AudioStream = null
var bgm_fade_tween: Tween

func _ready() -> void:
	_setup_audio_players()
	_setup_audio_buses()
	_connect_signals()

func _setup_audio_players() -> void:
	# BGMプレイヤー
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = BUS_BGM
	bgm_player.volume_db = default_bgm_volume
	add_child(bgm_player)
	
	# SFXプレイヤープール
	for i in sfx_pool_size:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = BUS_SFX
		sfx_player.volume_db = default_sfx_volume
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	
	# ボイスプレイヤー
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = BUS_VOICE
	voice_player.volume_db = default_voice_volume
	add_child(voice_player)

func _setup_audio_buses() -> void:
	# オーディオバスが存在しない場合は作成
	var bus_layout = AudioServer.bus_count
	
	# BGMバスの確認/作成
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_BGM)
		AudioServer.set_bus_send(idx, BUS_MASTER)
	
	# SFXバスの確認/作成
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, BUS_MASTER)
	
	# Voiceバスの確認/作成
	if AudioServer.get_bus_index(BUS_VOICE) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_VOICE)
		AudioServer.set_bus_send(idx, BUS_MASTER)

func _connect_signals() -> void:
	# EventBusが存在する場合のみ接続
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.effect_requested.connect(_on_effect_requested)
		event_bus.game_state_changed.connect(_on_game_state_changed)

# BGM制御
func play_bgm(stream: AudioStream, fade_in: bool = true, fade_time: float = 1.0) -> void:
	if current_bgm == stream and bgm_player.playing:
		return
	
	current_bgm = stream
	
	if fade_in and bgm_player.playing:
		fade_out_bgm(fade_time / 2.0)
		await bgm_player.finished
	
	bgm_player.stream = stream
	bgm_player.play()
	
	if fade_in:
		bgm_player.volume_db = -80.0
		if bgm_fade_tween:
			bgm_fade_tween.kill()
		bgm_fade_tween = get_tree().create_tween()
		bgm_fade_tween.tween_property(bgm_player, "volume_db", default_bgm_volume, fade_time)

func stop_bgm(fade_out: bool = true, fade_time: float = 1.0) -> void:
	if not bgm_player.playing:
		return
	
	if fade_out:
		fade_out_bgm(fade_time)
		await bgm_fade_tween.finished
	
	bgm_player.stop()
	current_bgm = null

func fade_out_bgm(fade_time: float = 1.0) -> void:
	if bgm_fade_tween:
		bgm_fade_tween.kill()
	bgm_fade_tween = get_tree().create_tween()
	bgm_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_time)

# SFX制御
func play_sfx(stream: AudioStream, volume_offset: float = 0.0) -> void:
	var available_player = _get_available_sfx_player()
	if available_player:
		available_player.stream = stream
		available_player.volume_db = default_sfx_volume + volume_offset
		available_player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	# すべて使用中の場合は最初のものを使う
	return sfx_players[0]

# ボイス制御
func play_voice(stream: AudioStream, volume_offset: float = 0.0) -> void:
	voice_player.stream = stream
	voice_player.volume_db = default_voice_volume + volume_offset
	voice_player.play()

# ボリューム制御
func set_master_volume(volume_percent: float) -> void:
	var db = linear_to_db(volume_percent / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), db)

func set_bgm_volume(volume_percent: float) -> void:
	var db = linear_to_db(volume_percent / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_BGM), db)

func set_sfx_volume(volume_percent: float) -> void:
	var db = linear_to_db(volume_percent / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), db)

func set_voice_volume(volume_percent: float) -> void:
	var db = linear_to_db(volume_percent / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_VOICE), db)

# ミュート制御
func mute_bus(bus_name: String, muted: bool) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)

# シグナルコールバック
func _on_effect_requested(effect_type: String, position: Vector2) -> void:
	# エフェクトタイプに応じた音を再生
	match effect_type:
		"hit":
			# play_sfx(hit_sound)
			pass
		"death":
			# play_sfx(death_sound)
			pass
		"pick_up":
			# play_sfx(pickup_sound)
			pass
		"explosion":
			# play_sfx(explosion_sound)
			pass

func _on_game_state_changed(state: String) -> void:
	match state:
		"menu":
			# play_bgm(menu_bgm)
			pass
		"playing":
			# play_bgm(game_bgm)
			pass
		"game_over":
			# play_bgm(gameover_bgm)
			pass
		"victory":
			# play_bgm(victory_bgm)
			pass
