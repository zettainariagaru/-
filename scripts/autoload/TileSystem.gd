# TileSystem.gd - オートロードとして使用
extends Node

# タイルシステムの定数
const TILE_SIZE: int = 64
const LANE_COUNT: int = 3
const TILES_PER_LANE: int = 20
const LANE_HEIGHT: int = 64  # タイルを正方形にする
const LANE_OFFSET: int = 200  # 画面上部に余白を作る

# レーンのY座標を取得
func get_lane_y(lane: int) -> float:
	return LANE_OFFSET + (lane * LANE_HEIGHT)

# タイル座標からワールド座標へ
func tile_to_world(tile_x: int, lane: int) -> Vector2:
	if not is_valid_lane(lane):
		push_error("Invalid lane: " + str(lane))
		return Vector2.ZERO
	
	return Vector2(
		tile_x * TILE_SIZE + TILE_SIZE / 2,
		get_lane_y(lane)
	)

# ワールド座標からタイル座標へ
func world_to_tile(world_pos: Vector2) -> Dictionary:
	var tile_x = int(world_pos.x / TILE_SIZE)
	var lane = get_nearest_lane(world_pos.y)
	return {"tile_x": tile_x, "lane": lane}

# 最も近いレーンを取得
func get_nearest_lane(y_pos: float) -> int:
	var nearest_lane = 0
	var min_distance = abs(y_pos - get_lane_y(0))
	
	for i in range(1, LANE_COUNT):
		var distance = abs(y_pos - get_lane_y(i))
		if distance < min_distance:
			min_distance = distance
			nearest_lane = i
	
	return nearest_lane

# レーンが有効か確認
func is_valid_lane(lane: int) -> bool:
	return lane >= 0 and lane < LANE_COUNT

# タイル位置が有効か確認
func is_valid_tile(tile_x: int) -> bool:
	return tile_x >= 0 and tile_x < TILES_PER_LANE

# 位置が有効か確認
func is_valid_position(tile_x: int, lane: int) -> bool:
	return is_valid_tile(tile_x) and is_valid_lane(lane)

# レーン変更が可能か確認
func can_change_lane(from_lane: int, to_lane: int) -> bool:
	if not is_valid_lane(from_lane) or not is_valid_lane(to_lane):
		return false
	return abs(from_lane - to_lane) == 1
