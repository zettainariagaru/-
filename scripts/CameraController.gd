extends Camera2D

# カメラ設定
const FOLLOW_SPEED: float = 5.0
const LOOK_AHEAD_DISTANCE: float = 100.0
const VERTICAL_OFFSET: float = 0.0

# スクロールモード
enum ScrollMode { NONE, FOLLOW_PLAYER, AUTO_SCROLL }
var scroll_mode: ScrollMode = ScrollMode.FOLLOW_PLAYER

# 自動スクロール設定
var auto_scroll_speed: float = 100.0
var is_auto_scrolling: bool = false

# 参照
var player: CharacterBody2D
var tile_system

func _ready():
	# プレイヤーの参照を取得
	player = get_node_or_null("../Player")
	tile_system = get_node_or_null("/root/TileSystem")
	
	# カメラの初期設定
	_setup_camera()

func _setup_camera():
	# カメラの設定
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = FOLLOW_SPEED
	
	# 画面の中心に配置
	if tile_system:
		var center_y = tile_system.get_lane_y(1)  # 中央レーン
		position = Vector2(640, center_y + VERTICAL_OFFSET)
	
	# リミット設定（プレイエリア内に制限）
	if tile_system:
		limit_left = 0
		limit_right = tile_system.TILES_PER_LANE * tile_system.TILE_SIZE
		limit_top = int(tile_system.get_lane_y(0) - tile_system.LANE_HEIGHT)
		limit_bottom = int(tile_system.get_lane_y(tile_system.LANE_COUNT - 1) + tile_system.LANE_HEIGHT)

func _physics_process(delta):
	match scroll_mode:
		ScrollMode.FOLLOW_PLAYER:
			_follow_player(delta)
		ScrollMode.AUTO_SCROLL:
			_auto_scroll(delta)

func _follow_player(delta):
	if not player:
		return
	
	# プレイヤーの少し前方を見るようにする
	var target_x = player.position.x + LOOK_AHEAD_DISTANCE
	var target_y = player.position.y + VERTICAL_OFFSET
	
	# カメラをスムーズに移動
	position = position.lerp(Vector2(target_x, target_y), FOLLOW_SPEED * delta)

func _auto_scroll(delta):
	if not is_auto_scrolling:
		return
	
	# 自動スクロール
	position.x += auto_scroll_speed * delta
	
	# プレイヤーが画面外に出ないようにする
	if player:
		var screen_left = position.x - get_viewport_rect().size.x / 2
		if player.position.x < screen_left + 50:
			# プレイヤーを強制的に前進させる
			player.try_move(player.tile_x + 1, player.lane)

func set_scroll_mode(mode: ScrollMode):
	scroll_mode = mode
	if mode == ScrollMode.AUTO_SCROLL:
		is_auto_scrolling = true
	else:
		is_auto_scrolling = false

func set_auto_scroll_speed(speed: float):
	auto_scroll_speed = speed

func shake(duration: float = 0.2, strength: float = 10.0):
	# カメラシェイク効果
	var original_offset = offset
	var shake_tween = create_tween()
	
	for i in range(int(duration * 60)):  # 60FPSと仮定
		var random_offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		shake_tween.tween_property(self, "offset", random_offset, 1.0/60.0)
	
	shake_tween.tween_property(self, "offset", original_offset, 0.1)

# デバッグ用：カメラモードを切り替え
func toggle_scroll_mode():
	if scroll_mode == ScrollMode.FOLLOW_PLAYER:
		set_scroll_mode(ScrollMode.AUTO_SCROLL)
		print("Camera: Auto-scroll mode")
	else:
		set_scroll_mode(ScrollMode.FOLLOW_PLAYER)
		print("Camera: Follow player mode")
