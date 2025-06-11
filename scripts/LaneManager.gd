extends Node2D

# レーンとタイルの色設定
const TILE_COLOR_LIGHT = Color(0.25, 0.25, 0.25)
const TILE_COLOR_DARK = Color(0.2, 0.2, 0.2)
const TILE_BORDER_COLOR = Color(0.4, 0.4, 0.4)
const GRID_COLOR = Color(0.3, 0.3, 0.3, 0.5)
const PLAYER_TILE_COLOR = Color(0.3, 0.3, 0.5, 0.3)

# レーンノード
var lane_nodes: Array = []
var tile_sprites: Array = []  # タイルのビジュアル保存用
var current_player_highlight: ColorRect = null

func _ready():
	# レーンとタイルを作成
	_create_lanes_and_tiles()
	
	# プレイヤーの移動シグナルに接続
	var player = get_node_or_null("../../Game/Player")
	if player and player.has_signal("tile_entered"):
		player.connect("tile_entered", _on_player_tile_entered)

func _create_lanes_and_tiles():
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system:
		push_error("TileSystem not found!")
		return
	
	# 各レーンを作成
	for lane_idx in range(tile_system.LANE_COUNT):
		var lane = Node2D.new()
		lane.name = "Lane%d" % lane_idx
		lane.position.y = tile_system.get_lane_y(lane_idx)
		add_child(lane)
		lane_nodes.append(lane)
		
		# このレーンのタイルを作成
		var lane_tiles = []
		for tile_idx in range(tile_system.TILES_PER_LANE):
			var tile = _create_tile(tile_idx, lane_idx, tile_system)
			lane.add_child(tile)
			lane_tiles.append(tile)
		
		tile_sprites.append(lane_tiles)

func _create_tile(tile_x: int, lane: int, tile_system) -> Node2D:
	var tile_container = Node2D.new()
	tile_container.name = "Tile_%d_%d" % [tile_x, lane]
	tile_container.position.x = tile_x * tile_system.TILE_SIZE
	
	# タイルの背景
	var tile_bg = ColorRect.new()
	tile_bg.name = "Background"
	tile_bg.size = Vector2(tile_system.TILE_SIZE - 2, tile_system.LANE_HEIGHT - 2)
	tile_bg.position = Vector2(1, -tile_system.LANE_HEIGHT / 2 + 1)
	
	# チェッカーボードパターン
	var is_dark = (tile_x + lane) % 2 == 0
	tile_bg.color = TILE_COLOR_DARK if is_dark else TILE_COLOR_LIGHT
	tile_bg.z_index = -3
	tile_container.add_child(tile_bg)
	
	# タイルの境界線（上）
	var border_top = ColorRect.new()
	border_top.size = Vector2(tile_system.TILE_SIZE, 1)
	border_top.position = Vector2(0, -tile_system.LANE_HEIGHT / 2)
	border_top.color = TILE_BORDER_COLOR
	border_top.z_index = -2
	tile_container.add_child(border_top)
	
	# タイルの境界線（下）
	var border_bottom = ColorRect.new()
	border_bottom.size = Vector2(tile_system.TILE_SIZE, 1)
	border_bottom.position = Vector2(0, tile_system.LANE_HEIGHT / 2 - 1)
	border_bottom.color = TILE_BORDER_COLOR
	border_bottom.z_index = -2
	tile_container.add_child(border_bottom)
	
	# タイルの境界線（左）
	var border_left = ColorRect.new()
	border_left.size = Vector2(1, tile_system.LANE_HEIGHT)
	border_left.position = Vector2(0, -tile_system.LANE_HEIGHT / 2)
	border_left.color = TILE_BORDER_COLOR
	border_left.z_index = -2
	tile_container.add_child(border_left)
	
	# タイルの境界線（右）
	var border_right = ColorRect.new()
	border_right.size = Vector2(1, tile_system.LANE_HEIGHT)
	border_right.position = Vector2(tile_system.TILE_SIZE - 1, -tile_system.LANE_HEIGHT / 2)
	border_right.color = TILE_BORDER_COLOR
	border_right.z_index = -2
	tile_container.add_child(border_right)
	
	# タイル番号（デバッグ用）
	if OS.is_debug_build() and tile_x % 5 == 0:  # 5タイルごとに番号表示
		var label = Label.new()
		label.text = str(tile_x)
		label.add_theme_font_size_override("font_size", 12)
		label.position = Vector2(tile_system.TILE_SIZE / 2 - 10, -5)
		label.modulate = Color(0.6, 0.6, 0.6, 0.5)
		tile_container.add_child(label)
	
	return tile_container

func _draw():
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system:
		return
	
	# レーン番号を描画（左端）
	if OS.is_debug_build():
		var font = ThemeDB.fallback_font
		var lane_names = ["Lane 0", "Lane 1", "Lane 2"]
		for i in range(tile_system.LANE_COUNT):
			var y = tile_system.get_lane_y(i)
			draw_string(font, Vector2(-50, y + 5), lane_names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5))

func highlight_tile(tile_x: int, lane: int, color: Color = Color.YELLOW, duration: float = 0.5):
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system or lane >= lane_nodes.size() or tile_x >= tile_system.TILES_PER_LANE:
		return
	
	var lane_node = lane_nodes[lane]
	
	# ハイライト作成
	var highlight = ColorRect.new()
	highlight.size = Vector2(tile_system.TILE_SIZE - 4, tile_system.LANE_HEIGHT - 4)
	highlight.position = Vector2(
		tile_x * tile_system.TILE_SIZE + 2,
		-tile_system.LANE_HEIGHT / 2 + 2
	)
	highlight.color = Color(color.r, color.g, color.b, 0.4)
	highlight.name = "Highlight"
	highlight.z_index = -1
	lane_node.add_child(highlight)
	
	# パルスアニメーション
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(highlight, "modulate:a", 0.5, 0.2)
	tween.tween_property(highlight, "modulate:a", 1.0, 0.2)
	
	# 自動削除
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		highlight.queue_free()

func _on_player_tile_entered(tile_x: int, lane: int):
	# 古いハイライトを削除
	if current_player_highlight and is_instance_valid(current_player_highlight):
		current_player_highlight.queue_free()
	
	# 新しいハイライトを作成
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system or lane >= lane_nodes.size():
		return
	
	var lane_node = lane_nodes[lane]
	
	current_player_highlight = ColorRect.new()
	current_player_highlight.size = Vector2(tile_system.TILE_SIZE - 6, tile_system.LANE_HEIGHT - 6)
	current_player_highlight.position = Vector2(
		tile_x * tile_system.TILE_SIZE + 3,
		-tile_system.LANE_HEIGHT / 2 + 3
	)
	current_player_highlight.color = PLAYER_TILE_COLOR
	current_player_highlight.name = "PlayerHighlight"
	current_player_highlight.z_index = -1
	lane_node.add_child(current_player_highlight)
	
	# パルスアニメーション
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(current_player_highlight, "modulate:a", 0.3, 0.6)
	tween.tween_property(current_player_highlight, "modulate:a", 0.8, 0.6)

# 特定のタイルの色を変更（ゲーム要素用）
func set_tile_color(tile_x: int, lane: int, color: Color):
	if lane >= tile_sprites.size() or tile_x >= tile_sprites[lane].size():
		return
	
	var tile = tile_sprites[lane][tile_x]
	var bg = tile.get_node_or_null("Background")
	if bg:
		bg.color = color

# タイルをアニメーション（エフェクト用）
func animate_tile(tile_x: int, lane: int):
	if lane >= tile_sprites.size() or tile_x >= tile_sprites[lane].size():
		return
	
	var tile = tile_sprites[lane][tile_x]
	var original_scale = tile.scale
	
	var tween = create_tween()
	tween.tween_property(tile, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(tile, "scale", original_scale, 0.1)
