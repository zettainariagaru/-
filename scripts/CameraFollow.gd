extends Camera2D

# カメラ制御スクリプト

@export var follow_player: bool = true
@export var smooth_speed: float = 5.0
@export var offset_ahead: float = 100.0  # プレイヤーの前方を見る距離

var player: CharacterBody2D
var tilemap: TileMap

func _ready() -> void:
	# プレイヤーを取得
	player = get_tree().current_scene.get_node_or_null("Player")
	tilemap = get_tree().current_scene.get_node_or_null("Field/TileMap")
	
	# カメラの基本設定
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	
	# 画面の中央に配置
	if tilemap:
		var center_y = tilemap.TILE_SIZE * tilemap.LANE_COUNT / 2.0
		position.y = center_y

func _process(_delta: float) -> void:
	if not follow_player or not player:
		return
		
	# プレイヤーの位置を追跡
	var target_x = player.global_position.x + offset_ahead
	
	# Y座標は3レーンの中央付近に固定
	if tilemap:
		var center_y = tilemap.TILE_SIZE * tilemap.LANE_COUNT / 2.0
		position = Vector2(target_x, center_y)
	else:
		position.x = target_x
