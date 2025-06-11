extends Node

# ゲーム状態
enum GameState {
	MENU,
	STAGE_START,
	PLAYING,
	STAGE_CLEAR,
	GAME_OVER,
	RESULT
}

var current_state = GameState.MENU
var score = 0
var stage_number = 1
var player_lives = 3

# ノード参照
@onready var player = $"../Player"
@onready var enemy_manager = $"../EnemyManager"
@onready var ui = $"../UI"

# TileSystemクラスをプリロード
const TileSystem = preload("res://scripts/TileSystem.gd")

func _ready():
	print("GameController ready")
	# ゲーム開始
	start_game()

func _process(delta):
	match current_state:
		GameState.MENU:
			handle_menu()
		GameState.STAGE_START:
			handle_stage_start()
		GameState.PLAYING:
			handle_playing(delta)
		GameState.STAGE_CLEAR:
			handle_stage_clear()
		GameState.GAME_OVER:
			handle_game_over()
		GameState.RESULT:
			handle_result()

func start_game():
	score = 0
	stage_number = 1
	player_lives = 3
	update_ui()
	transition_to_state(GameState.STAGE_START)

func transition_to_state(new_state: GameState):
	print("Transitioning from ", GameState.keys()[current_state], " to ", GameState.keys()[new_state])
	current_state = new_state
	
	# UI更新
	if ui:
		ui.update_game_state(GameState.keys()[current_state])
	
	match new_state:
		GameState.STAGE_START:
			prepare_stage()
		GameState.PLAYING:
			start_stage()
		GameState.STAGE_CLEAR:
			if ui:
				ui.show_message("Stage Clear!", 2.0)
		GameState.GAME_OVER:
			if ui:
				ui.show_message("Game Over", 2.0)

func handle_menu():
	# メニュー処理（今は自動的にゲーム開始）
	pass

func handle_stage_start():
	# ステージ開始演出
	if ui:
		ui.show_message("Stage " + str(stage_number), 1.5)
	await get_tree().create_timer(1.5).timeout
	transition_to_state(GameState.PLAYING)

func handle_playing(delta):
	# ゲームプレイ中の処理
	# TODO: 敵の生成、衝突判定など
	
	# テスト用：Spaceキーでスコア追加
	if Input.is_action_just_pressed("ui_select"):
		add_score(100)
	
	# テスト用：Escキーでゲームオーバー
	if Input.is_action_just_pressed("ui_cancel"):
		player_hit()

func handle_stage_clear():
	# ステージクリア処理
	stage_number += 1
	update_ui()
	# 次のステージへ
	await get_tree().create_timer(2.0).timeout
	transition_to_state(GameState.STAGE_START)

func handle_game_over():
	# ゲームオーバー処理
	# 少し待ってからリザルトへ
	await get_tree().create_timer(2.0).timeout
	transition_to_state(GameState.RESULT)

func handle_result():
	# リザルト表示処理
	if ui:
		ui.show_message("Final Score: " + str(score) + "\nPress Enter to restart", 10.0)
	
	# Enterキーでメニューに戻る
	if Input.is_action_just_pressed("ui_accept"):
		start_game()

func prepare_stage():
	print("Preparing stage ", stage_number)
	# ステージの準備
	# プレイヤーを初期位置に配置
	if player:
		player.position = TileSystem.tile_to_world(2, 1)  # 中央レーンの3タイル目
		player.current_tile_x = 2
		player.current_lane = 1

func start_stage():
	print("Starting stage ", stage_number)
	# ステージ開始

func player_hit():
	# プレイヤーが敵に当たった時の処理
	player_lives -= 1
	update_ui()
	
	if player_lives <= 0:
		transition_to_state(GameState.GAME_OVER)
	else:
		# 無敵時間などの処理
		if ui:
			ui.show_message("Hit! Lives: " + str(player_lives), 1.0)

func add_score(points: int):
	score += points
	update_ui()

func update_ui():
	if ui:
		ui.update_score(score)
		ui.update_lives(player_lives)
		ui.update_stage(stage_number)
