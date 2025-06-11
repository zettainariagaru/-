extends Node2D
class_name FieldManager

# フィールド設定
const TILE_SIZE = 64
const LANES = 3
const FIELD_WIDTH = 20  # タイル数
const SCROLL_SPEED = 50  # ピクセル/秒

# レーン位置 (Y座標)
var lane_positions: Array[float] = []
var scroll_offset: float = 0.0

# タイルデータ (x, lane_index -> tile_type)
var field_tiles: Dictionary = {}

func _ready():
	setup_lanes()
	generate_initial_field()

func setup_lanes():
	# 三レーンの位置を設定
	for i in range(LANES):
		var y_pos = (i - 1) * TILE_SIZE * 1.5  # レーン間隔
		lane_positions.append(y_pos)
	
	print("Lane positions: ", lane_positions)

func generate_initial_field():
	# 初期フィールドを生成
	for x in range(FIELD_WIDTH):
		for lane in range(LANES):
			create_field_tile(x, lane, "ground")

func create_field_tile(x: int, lane: int, tile_type: String):
	var tile_key = str(x) + "," + str(lane)
	field_tiles[tile_key] = tile_type
	
	# 視覚的なタイル表示
	var tile = ColorRect.new()
	tile.name = "Tile_" + tile_key
	tile.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
	tile.position = Vector2(x * TILE_SIZE, lane_positions[lane] - TILE_SIZE/2)
	
	# タイルタイプによる色分け
	match tile_type:
		"ground":
			tile.color = Color.DARK_GRAY
		"wall":
			tile.color = Color.GRAY
		_:
			tile.color = Color.WHITE
	
	add_child(tile)

func _process(delta):
	# フィールドスクロール
	scroll_offset += SCROLL_SPEED * delta
	position.x = -scroll_offset

func get_lane_position(lane_index: int) -> float:
	if lane_index >= 0 and lane_index < LANES:
		return lane_positions[lane_index]
	return 0.0

func world_to_tile(world_pos: Vector2) -> Vector2i:
	var tile_x = int((world_pos.x + scroll_offset) / TILE_SIZE)
	var closest_lane = 0
	var min_distance = abs(world_pos.y - lane_positions[0])
	
	for i in range(1, LANES):
		var distance = abs(world_pos.y - lane_positions[i])
		if distance < min_distance:
			min_distance = distance
			closest_lane = i
	
	return Vector2i(tile_x, closest_lane)

func tile_to_world(tile_pos: Vector2i) -> Vector2:
	var world_x = tile_pos.x * TILE_SIZE - scroll_offset
	var world_y = lane_positions[tile_pos.y]
	return Vector2(world_x, world_y)
