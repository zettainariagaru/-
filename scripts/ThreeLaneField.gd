class_name ThreeLaneField
extends Node3D

# フィールド設定
@export var lane_width: float = 4.0  # 各レーンの幅
@export var tile_size: float = 2.0   # タイルのサイズ
@export var scroll_speed: float = 5.0 # スクロール速度
@export var field_length: int = 50   # フィールドの長さ（タイル数）

# レーン定義
enum Lane { LEFT = 0, CENTER = 1, RIGHT = 2 }
const LANE_COUNT = 3

# タイル管理
var tiles: Array[Array] = []  # [lane][tile_index] = tile_node
var field_offset: float = 0.0  # スクロールオフセット

# レーン位置計算
var lane_positions: Array[float] = []

signal field_scrolled(offset: float)

func _ready():
	_initialize_lanes()
	_generate_initial_field()

func _process(delta):
	_update_field_scroll(delta)

# レーン位置の初期化
func _initialize_lanes():
	lane_positions.clear()
	var start_x = -(lane_width * (LANE_COUNT - 1)) / 2.0
	
	for i in LANE_COUNT:
		lane_positions.append(start_x + i * lane_width)

# 初期フィールドの生成
func _generate_initial_field():
	tiles.clear()
	
	for lane in LANE_COUNT:
		tiles.append([])
		for tile_index in field_length:
			var tile = _create_tile(lane, tile_index)
			tiles[lane].append(tile)
			add_child(tile)

# タイル作成
func _create_tile(lane: int, tile_index: int) -> Node3D:
	var tile = MeshInstance3D.new()
	tile.name = "Tile_L%d_T%d" % [lane, tile_index]
	
	# 白い四角のメッシュ
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size * 0.9, 0.1, tile_size * 0.9)
	tile.mesh = box_mesh
	
	# マテリアル（レーンごとに色を変える）
	var material = StandardMaterial3D.new()
	match lane:
		Lane.LEFT:
			material.albedo_color = Color.LIGHT_BLUE
		Lane.CENTER:
			material.albedo_color = Color.WHITE
		Lane.RIGHT:
			material.albedo_color = Color.LIGHT_GREEN
	tile.material_override = material
	
	# 位置設定
	var world_pos = get_tile_world_position(lane, tile_index)
	tile.position = world_pos
	
	return tile

# タイルのワールド座標を計算
func get_tile_world_position(lane: int, tile_index: int) -> Vector3:
	var x = lane_positions[lane]
	var z = tile_index * tile_size - field_offset
	return Vector3(x, 0, z)

# レーン座標からワールド座標への変換
func get_lane_world_x(lane: int) -> float:
	return lane_positions[lane]

# ワールド座標からレーン番号への変換
func world_x_to_lane(world_x: float) -> int:
	var closest_lane = 0
	var min_distance = abs(world_x - lane_positions[0])
	
	for i in range(1, LANE_COUNT):
		var distance = abs(world_x - lane_positions[i])
		if distance < min_distance:
			min_distance = distance
			closest_lane = i
	
	return closest_lane

# Z座標からタイルインデックスへの変換
func world_z_to_tile_index(world_z: float) -> int:
	return int((world_z + field_offset) / tile_size)

# フィールドスクロール更新
func _update_field_scroll(delta):
	field_offset += scroll_speed * delta
	
	# タイル位置更新
	for lane in LANE_COUNT:
		for tile_index in tiles[lane].size():
			var tile = tiles[lane][tile_index]
			if tile:
				tile.position = get_tile_world_position(lane, tile_index)
	
	field_scrolled.emit(field_offset)

# 指定座標が有効なタイル位置かチェック
func is_valid_position(lane: int, tile_z: float) -> bool:
	return lane >= 0 and lane < LANE_COUNT and tile_z >= -field_offset

# デバッグ用：レーン番号とタイル位置を取得
func get_position_info(world_pos: Vector3) -> Dictionary:
	return {
		"lane": world_x_to_lane(world_pos.x),
		"tile_index": world_z_to_tile_index(world_pos.z),
		"world_position": world_pos
	}
