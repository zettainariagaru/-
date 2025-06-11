class_name GameManager
extends Node

# ゲーム状態
enum State { MENU, STARTING, PLAYING, PAUSED, CLEAR, OVER, RESULT }

# 設定
const INITIAL_LIVES: int = 3
const POINTS_PER_ENEMY: int = 100
const POINTS_PER_STAGE: int = 1000

# 状態変数
var current_state: State = State.MENU
var score: int = 0
var stage: int = 1
var lives: int = INITIAL_LIVES

# ノード参照（_readyで取得）
var player: CharacterBody2D
var enemies: Node2D
var ui: CanvasLayer
var lanes: Node2D

# シグナル
signal state_changed(new_state)
signal score_changed(new_score)
signal lives_changed(new_lives)
signal stage_changed(new_stage)

func _ready():
	# ノード参照を取得
	_get_node_references()
	
	# 1フレーム待ってから開始
	await get_tree().process_frame
	start_game()

func _get_node_references():
	# 安全にノードを取得
	player = get_node_or_null("../Game/Player")
	enemies = get_node_or_null("../Game/Enemies")
	ui = get_node_or_null("../UI")
	lanes = get_node_or_null("../Game/Lanes")
	
	# プレイヤーのシグナルに接続
	if player and player.has_signal("hit"):
		player.connect("hit", _on_player_hit)

func _process(_delta):
	# 状態に応じた処理
	match current_state:
		State.PLAYING:
			_process_playing()
		State.RESULT:
			if Input.is_action_just_pressed("ui_accept"):
				start_game()

func start_game():
	print("Starting new game")
	score = 0
	stage = 1
	lives = INITIAL_LIVES
	_update_all_ui()
	set_state(State.STARTING)

func set_state(new_state: State):
	if current_state == new_state:
		return
	
	print("State change: %s -> %s" % [State.keys()[current_state], State.keys()[new_state]])
	current_state = new_state
	emit_signal("state_changed", new_state)
	
	# 状態別の処理
	match new_state:
		State.STARTING:
			_handle_stage_start()
		State.PLAYING:
			_handle_playing_start()
		State.CLEAR:
			_handle_stage_clear()
		State.OVER:
			_handle_game_over()

func _handle_stage_start():
	# ステージ準備
	_reset_stage()
	
	# UI表示
	if ui and ui.has_method("show_message"):
		ui.call("show_message", "Stage %d" % stage, 2.0)
	
	# 2秒後にプレイ開始
	await get_tree().create_timer(2.0).timeout
	set_state(State.PLAYING)

func _handle_playing_start():
	print("Playing stage %d" % stage)
	# 敵の生成開始
	if enemies and enemies.has_method("start_spawning"):
		enemies.call("start_spawning")

func _process_playing():
	# クリア判定
	if score >= stage * POINTS_PER_STAGE:
		set_state(State.CLEAR)

func _handle_stage_clear():
	# 敵の生成停止
	if enemies and enemies.has_method("stop_spawning"):
		enemies.call("stop_spawning")
	
	# メッセージ表示
	if ui and ui.has_method("show_message"):
		ui.call("show_message", "Stage Clear!", 2.0)
	
	# ステージ進行
	stage += 1
	emit_signal("stage_changed", stage)
	
	# 次のステージへ
	await get_tree().create_timer(2.0).timeout
	set_state(State.STARTING)

func _handle_game_over():
	# 敵の生成停止
	if enemies and enemies.has_method("stop_spawning"):
		enemies.call("stop_spawning")
	
	# メッセージ表示
	if ui and ui.has_method("show_message"):
		ui.call("show_message", "Game Over", 2.0)
	
	# リザルトへ
	await get_tree().create_timer(2.0).timeout
	set_state(State.RESULT)

func _reset_stage():
	# プレイヤーをリセット
	if player:
		if player.has_method("reset_position"):
			player.call("reset_position")
		else:
			# デフォルト位置
			var tile_system = get_node_or_null("/root/TileSystem")
			if tile_system:
				player.position = tile_system.tile_to_world(2, 1)
	
	# 敵をクリア
	if enemies:
		for enemy in enemies.get_children():
			enemy.queue_free()

func _on_player_hit():
	if current_state != State.PLAYING:
		return
	
	lives -= 1
	emit_signal("lives_changed", lives)
	
	if lives <= 0:
		set_state(State.OVER)

func add_score(points: int):
	score += points
	emit_signal("score_changed", score)

func _update_all_ui():
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)
	emit_signal("stage_changed", stage)
