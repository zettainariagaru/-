extends Node2D

# グリッドの色
const GRID_COLOR = Color(0.3, 0.3, 0.3, 0.3)
const GRID_LINE_WIDTH = 1.0

func _draw():
	# 縦線を描画（タイルの境界）
	for i in range(TileSystem.TILES_PER_LANE + 1):
		var x = i * TileSystem.TILE_SIZE
		var start_y = TileSystem.get_lane_y_position(0) - TileSystem.LANE_HEIGHT / 2
		var end_y = TileSystem.get_lane_y_position(TileSystem.LANE_COUNT - 1) + TileSystem.LANE_HEIGHT / 2
		
		draw_line(
			Vector2(x, start_y),
			Vector2(x, end_y),
			GRID_COLOR,
			GRID_LINE_WIDTH
		)
	
	# 横線を描画（レーンの境界）
	for i in range(TileSystem.LANE_COUNT + 1):
		var y = TileSystem.get_lane_y_position(min(i, TileSystem.LANE_COUNT - 1))
		if i == 0:
			y -= TileSystem.LANE_HEIGHT / 2
		elif i == TileSystem.LANE_COUNT:
			y += TileSystem.LANE_HEIGHT / 2
		else:
			y += TileSystem.LANE_HEIGHT / 2
		
		draw_line(
			Vector2(0, y),
			Vector2(TileSystem.TILES_PER_LANE * TileSystem.TILE_SIZE, y),
			GRID_COLOR,
			GRID_LINE_WIDTH
		)
