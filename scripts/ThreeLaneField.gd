extends TileMap

# 三レーン・タイルベースフィールドの管理

# レーン設定
const LANE_COUNT: int = 3
const LANE_WIDTH: int = 30  # 各レーンの横幅（タイル数）
const TILE_SIZE: int = 64

# レーン定義
enum Lane { TOP = 0, MIDDLE = 1, BOTTOM = 2 }

# ビジュアル設定
@export var show_grid: bool = true
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var lane_separator_color: Color = Color(0.5, 0.5, 0.5, 0.8)

func _ready() -> void:
	# タイルセットの設定
	if not tile_set:
		tile_set = TileSet.new()
		tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# デバッグ用の仮タイルを作成
	_create_debug_tiles()
	
	# レーンを初期化
	_initialize_lanes()

func _create_debug_tiles() -> void:
	# ソースを作成（アトラステクスチャ用）
	var source = TileSetAtlasSource.new()
	
	# 仮のテクスチャを作成（実際のゲームでは適切なテクスチャを使用）
	var image = Image.create(TILE_SIZE * 3, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	# 各レーン用の色を設定
	var lane_colors = [
		Color(0.8, 0.3, 0.3, 0.3),  # 上レーン - 赤っぽい
		Color(0.3, 0.8, 0.3, 0.3),  # 中レーン - 緑っぽい
		Color(0.3, 0.3, 0.8, 0.3)   # 下レーン - 青っぽい
	]
	
	# 各色でタイルを塗る
	for i in range(3):
		for x in range(TILE_SIZE):
			for y in range(TILE_SIZE):
				# タイルの境界線を描く
				if x == 0 or x == TILE_SIZE - 1 or y == 0 or y == TILE_SIZE - 1:
					image.set_pixel(i * TILE_SIZE + x, y, Color(0.5, 0.5, 0.5, 1))
				else:
					image.set_pixel(i * TILE_SIZE + x, y, lane_colors[i])
	
	var texture = ImageTexture.create_from_image(image)
	source.texture = texture
	
	# アトラスグリッドを設定
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# 各タイルを作成
	for i in range(3):
		source.create_tile(Vector2i(i, 0))
	
	# ソースをタイルセットに追加
	tile_set.add_source(source)

func _initialize_lanes() -> void:
	# 各レーンにタイルを配置
	for lane in range(LANE_COUNT):
		for x in range(LANE_WIDTH):
			# タイルを配置（レーンごとに異なるタイルを使用）
			set_cell(0, Vector2i(x, lane), 0, Vector2i(lane, 0))

func _draw() -> void:
	if not show_grid:
		return
		
	# レーン間の区切り線を描画
	for i in range(LANE_COUNT + 1):
		var y_pos = i * TILE_SIZE
		draw_line(
			Vector2(0, y_pos),
			Vector2(LANE_WIDTH * TILE_SIZE, y_pos),
			lane_separator_color,
			2.0
		)
	
	# 縦のグリッド線を描画
	if show_grid:
		for i in range(LANE_WIDTH + 1):
			var x_pos = i * TILE_SIZE
			draw_line(
				Vector2(x_pos, 0),
				Vector2(x_pos, LANE_COUNT * TILE_SIZE),
				grid_color,
				1.0
			)

# タイル座標からワールド座標への変換（中心点）
func get_tile_center_position(tile_coords: Vector2i) -> Vector2:
	return map_to_local(tile_coords)

# ワールド座標からタイル座標への変換
func get_tile_coords(world_position: Vector2) -> Vector2i:
	return local_to_map(to_local(world_position))

# レーンの取得
func get_lane(world_position: Vector2) -> int:
	var tile_coords = get_tile_coords(world_position)
	return clamp(tile_coords.y, 0, LANE_COUNT - 1)

# タイルが有効な範囲内かチェック
func is_valid_tile(tile_coords: Vector2i) -> bool:
	return tile_coords.x >= 0 and tile_coords.x < LANE_WIDTH and \
		   tile_coords.y >= 0 and tile_coords.y < LANE_COUNT

# レーン変更が可能かチェック
func can_change_lane(current_lane: int, direction: int) -> bool:
	var target_lane = current_lane + direction
	return target_lane >= 0 and target_lane < LANE_COUNT
