class_name TileSystem
extends Resource

# タイルシステムの定数
const TILE_SIZE = 64  # タイルのサイズ（ピクセル）
const LANE_COUNT = 3  # レーンの数
const TILES_PER_LANE = 20  # 各レーンのタイル数
const LANE_HEIGHT = 80  # レーンの高さ
const LANE_OFFSET = 120  # レーンのY座標開始位置

# レーンの高さ位置を動的に計算
static func get_lane_y_position(lane: int) -> float:
	return LANE_OFFSET + (lane * LANE_HEIGHT)

# タイル座標をワールド座標に変換
static func tile_to_world(tile_x: int, lane: int) -> Vector2:
	if lane < 0 or lane >= LANE_COUNT:
		push_error("Invalid lane: " + str(lane))
		return Vector2.ZERO
	
	var world_x = tile_x * TILE_SIZE + TILE_SIZE / 2  # タイルの中心
	var world_y = get_lane_y_position(lane)
	return Vector2(world_x, world_y)

# ワールド座標をタイル座標に変換
static func world_to_tile(world_pos: Vector2) -> Dictionary:
	var tile_x = int(world_pos.x / TILE_SIZE)
	
	# 最も近いレーンを見つける
	var lane = 0
	var min_distance = abs(world_pos.y - get_lane_y_position(0))
	
	for i in range(1, LANE_COUNT):
		var distance = abs(world_pos.y - get_lane_y_position(i))
		if distance < min_distance:
			min_distance = distance
			lane = i
	
	return {"tile_x": tile_x, "lane": lane}

# レーン間の移動が可能かチェック
static func can_change_lane(from_lane: int, to_lane: int) -> bool:
	if from_lane < 0 or from_lane >= LANE_COUNT:
		return false
	if to_lane < 0 or to_lane >= LANE_COUNT:
		return false
	
	# 隣接レーンへの移動のみ許可
	return abs(from_lane - to_lane) == 1

# タイル位置が有効範囲内かチェック
static func is_valid_position(tile_x: int, lane: int) -> bool:
	return tile_x >= 0 and tile_x < TILES_PER_LANE and lane >= 0 and lane < LANE_COUNT
