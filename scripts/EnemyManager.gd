extends Node2D

# 設定
const BASE_SPAWN_INTERVAL: float = 2.0
const MIN_SPAWN_INTERVAL: float = 0.5
const INTERVAL_DECREASE: float = 0.1

# 敵のスクリプト
const EnemyScript = preload("res://scripts/Enemy.gd")

# 状態
var spawning: bool = false
var spawn_timer: float = 0.0
var current_interval: float = BASE_SPAWN_INTERVAL

func _ready():
	# GameManagerのシグナルに接続
	var gm = get_node_or_null("../../GameManager")
	if gm and gm.has_signal("state_changed"):
		gm.connect("state_changed", _on_game_state_changed)

func _process(delta):
	if not spawning:
		return
	
	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		_spawn_enemy()

func start_spawning():
	spawning = true
	spawn_timer = 0.0
	
	# 難易度調整
	var gm = get_node_or_null("../../GameManager")
	if gm:
		var stage = gm.stage if gm.get("stage") != null else 1
		current_interval = max(
			MIN_SPAWN_INTERVAL,
			BASE_SPAWN_INTERVAL - (stage - 1) * INTERVAL_DECREASE
		)

func stop_spawning():
	spawning = false

func clear_enemies():
	for child in get_children():
		child.queue_free()

func _spawn_enemy():
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system:
		return
	
	# ランダムなレーン
	var lane = randi() % tile_system.LANE_COUNT
	
	# 敵を作成
	var enemy = Area2D.new()
	enemy.set_script(EnemyScript)
	enemy.name = "Enemy"
	add_child(enemy)
	
	# 初期化
	enemy.call_deferred("initialize", tile_system.TILES_PER_LANE - 1, lane, -1)

func _on_game_state_changed(state: GameManager.State):
	# GameManager.Stateの値をチェック
	match state:
		GameManager.State.PLAYING:
			start_spawning()
		GameManager.State.CLEAR, GameManager.State.OVER:
			stop_spawning()
		GameManager.State.STARTING:
			clear_enemies()
