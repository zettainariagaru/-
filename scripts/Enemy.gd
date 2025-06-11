extends Area2D

# 設定
const MOVE_SPEED: float = 150.0
const POINTS: int = 100

# 状態
var tile_x: int
var lane: int
var direction: int = -1

# コンポーネント
var sprite: Sprite2D

func _ready():
	# enemyグループに追加
	add_to_group("enemy")
	
	# レイヤー設定
	collision_layer = 4  # Enemy layer
	collision_mask = 2   # Player layer
	
	# ビジュアル作成
	_create_visual()

func _create_visual():
	# スプライト
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	# テクスチャ
	var image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color.CRIMSON)
	# 枠を追加（DARK_REDの代わりに濃い赤色をRGBで指定）
	for x in range(40):
		for y in range(40):
			if x < 3 or x > 36 or y < 3 or y > 36:
				image.set_pixel(x, y, Color(0.5, 0, 0))  # 濃い赤色 (Dark Red相当)
	sprite.texture = ImageTexture.create_from_image(image)
	
	# コリジョン
	var col = CollisionShape2D.new()
	col.name = "Collision"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(36, 36)
	col.shape = shape
	add_child(col)

func initialize(start_tile: int, start_lane: int, move_direction: int = -1):
	tile_x = start_tile
	lane = start_lane
	direction = move_direction
	
	var tile_system = get_node_or_null("/root/TileSystem")
	if tile_system:
		position = tile_system.tile_to_world(tile_x, lane)

func _physics_process(delta):
	# 移動
	position.x += direction * MOVE_SPEED * delta
	
	# 画面外チェック
	var tile_system = get_node_or_null("/root/TileSystem")
	if tile_system:
		if position.x < -50 or position.x > tile_system.TILES_PER_LANE * tile_system.TILE_SIZE + 50:
			queue_free()

func defeat():
	# GameManagerに通知
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm and gm.has_method("add_score"):
		gm.add_score(POINTS)
	
	queue_free()
