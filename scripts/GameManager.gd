extends Node

# ゲームの状態管理とコアシステム

# ゲーム状態
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }
var current_state: GameState = GameState.MENU

# ゲーム設定
@export var time_scale_slow: float = 0.3
@export var time_scale_normal: float = 1.0

# 内部変数
var is_slow_motion: bool = false
var slow_motion_duration: float = 0.0

# スコアとコンボ
var total_score: int = 0
var highest_combo: int = 0

# 参照
@onready var spawner: Node = $"../Field/Spawner"
@onready var ui_manager: CanvasLayer = $"../UIManager"

func _ready() -> void:
	# EventBusが存在する場合のみ接続
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.game_state_changed.connect(_on_game_state_changed_request)
	
	# ゲーム開始時は一時的にプレイ状態に
	change_game_state(GameState.PLAYING)

func _process(delta: float) -> void:
	# スローモーション処理
	if is_slow_motion:
		slow_motion_duration -= delta
		if slow_motion_duration <= 0:
			_end_slow_motion()

func _input(event: InputEvent) -> void:
	# ポーズ処理
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			change_game_state(GameState.PAUSED)
		elif current_state == GameState.PAUSED:
			change_game_state(GameState.PLAYING)
	
	# デバッグ用スローモーション
	if event.is_action_pressed("debug_slow_motion"):
		activate_slow_motion(2.0)

func change_game_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	var old_state = current_state
	current_state = new_state
		
	# 状態に応じた処理
	match new_state:
		GameState.MENU:
			get_tree().paused = true
			
		GameState.PLAYING:
			get_tree().paused = false
			if old_state == GameState.MENU:
				_start_new_game()
			
		GameState.PAUSED:
			get_tree().paused = true
			
		GameState.GAME_OVER:
			_handle_game_over()
			
		GameState.VICTORY:
			_handle_victory()
	# EventBusが存在する場合のみ通知
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		var state_name = _get_state_name(new_state)
		event_bus.game_state_changed.emit(state_name)

func _get_state_name(state: GameState) -> String:
	match state:
		GameState.MENU: return "menu"
		GameState.PLAYING: return "playing"
		GameState.PAUSED: return "paused"
		GameState.GAME_OVER: return "game_over"
		GameState.VICTORY: return "victory"
		_: return "unknown"

func _start_new_game() -> void:
	# ゲーム初期化
	total_score = 0
	highest_combo = 0
	
	# スポーナーを開始
	if spawner:
		spawner.start_spawning()
	
	print("New game started!")

func _handle_game_over() -> void:
	# ゲームオーバー処理
	get_tree().paused = true
	
	# スコアの保存など
	_save_high_score()
	
	print("Game Over! Final Score: ", total_score)

func _handle_victory() -> void:
	# 勝利処理
	get_tree().paused = true
	
	# ボーナススコアの計算
	var time_bonus = _calculate_time_bonus()
	total_score += time_bonus
	
	_save_high_score()
	
	print("Victory! Final Score: ", total_score)

func activate_slow_motion(duration: float) -> void:
	if is_slow_motion:
		slow_motion_duration = max(slow_motion_duration, duration)
		return
	
	is_slow_motion = true
	slow_motion_duration = duration
	Engine.time_scale = time_scale_slow
	
	# EventBusが存在する場合のみエフェクト要求
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.effect_requested.emit("slow_motion_start", Vector2.ZERO)

func _end_slow_motion() -> void:
	is_slow_motion = false
	Engine.time_scale = time_scale_normal
	
	# EventBusが存在する場合のみエフェクト要求
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.effect_requested.emit("slow_motion_end", Vector2.ZERO)

func add_score(points: int) -> void:
	total_score += points
	# EventBusが存在する場合のみ通知
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.score_updated.emit(points)

func update_combo(new_combo: int) -> void:
	highest_combo = max(highest_combo, new_combo)

func _calculate_time_bonus() -> int:
	# 時間ボーナスの計算ロジック
	return 1000 # 仮の値

func _save_high_score() -> void:
	# ハイスコアの保存
	var save_data = {
		"high_score": total_score,
		"highest_combo": highest_combo,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# 実際の保存処理は省略

func _on_game_state_changed_request(state_name: String) -> void:
	# 文字列からGameStateに変換
	match state_name:
		"menu": change_game_state(GameState.MENU)
		"playing": change_game_state(GameState.PLAYING)
		"paused": change_game_state(GameState.PAUSED)
		"game_over": change_game_state(GameState.GAME_OVER)
		"victory": change_game_state(GameState.VICTORY)
