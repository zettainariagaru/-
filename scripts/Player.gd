extends CharacterBody2D

# 状態
enum State { IDLE, MOVING, HIT, DEAD }

# 設定
const MOVE_SPEED: float = 500.0
const INVULNERABLE_TIME: float = 1.5
const PLAYER_SIZE: Vector2 = Vector2(56, 56)  # タイルより少し小さく

# 状態変数
var state: State = State.IDLE
var tile_x: int = 2
var lane: int = 1
var target_pos: Vector2
var invulnerable: bool = false

# 移動制御
var move_cooldown: float = 0.0
const MOVE_COOLDOWN_TIME: float = 0.1

# コンポーネント
var sprite: Sprite2D
var collision: CollisionShape2D
var area: Area2D
var shadow: Sprite2D

# シグナル
signal hit()
signal moved(new_tile_x, new_lane)
signal tile_entered(tile_x, lane)

func _ready():
	# コンポーネントを作成
	_create_components()
	
	# 初期位置設定
	reset_position()

func _create_components():
	# 影を作成
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.z_index = -1
	add_child(shadow)
	
	# 影のテクスチャ
	var shadow_image = Image.create(60, 60, false, Image.FORMAT_RGBA8)
	for x in range(60):
		for y in range(60):
			var dist = Vector2(x - 30, y - 30).length()
			if dist < 28:
				var alpha = 0.3 * (1.0 - dist / 28.0)
				shadow_image.set_pixel(x, y, Color(0, 0, 0, alpha))
	shadow.texture = ImageTexture.create_from_image(shadow_image)
	shadow.position = Vector2(4, 4)
	
	# スプライト作成
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	# 白い四角形のテクスチャ作成
	var image = Image.create(int(PLAYER_SIZE.x), int(PLAYER_SIZE.y), false, Image.FORMAT_RGBA8)
	
	for x in range(int(PLAYER_SIZE.x)):
		for y in range(int(PLAYER_SIZE.y)):
			# ベースは白
			var color = Color.WHITE
			
			# 外枠（1ピクセル）
			if x == 0 or x == PLAYER_SIZE.x - 1 or y == 0 or y == PLAYER_SIZE.y - 1:
				color = Color(0.7, 0.7, 0.7)
			# 2層目の枠
			elif x == 1 or x == PLAYER_SIZE.x - 2 or y == 1 or y == PLAYER_SIZE.y - 2:
				color = Color(0.85, 0.85, 0.85)
			# 3層目の枠
			elif x == 2 or x == PLAYER_SIZE.x - 3 or y == 2 or y == PLAYER_SIZE.y - 3:
				color = Color(0.92, 0.92, 0.92)
			# 内側のハイライト
			elif x == 3 or x == PLAYER_SIZE.x - 4 or y == 3 or y == PLAYER_SIZE.y - 4:
				color = Color(0.98, 0.98, 0.98)
			
			image.set_pixel(x, y, color)
	
	# 中央に小さな四角を追加（プレイヤーの向きを示す）
	var center_x = int(PLAYER_SIZE.x / 2)
	var center_y = int(PLAYER_SIZE.y / 2)
	for x in range(-4, 5):
		for y in range(-4, 5):
			if abs(x) <= 3 and abs(y) <= 3:
				var px = center_x + x
				var py = center_y + y - 10  # 上寄りに配置
				if px >= 0 and px < PLAYER_SIZE.x and py >= 0 and py < PLAYER_SIZE.y:
					image.set_pixel(px, py, Color(0.8, 0.8, 0.8))
	
	sprite.texture = ImageTexture.create_from_image(image)
	
	# コリジョン作成
	collision = CollisionShape2D.new()
	collision.name = "Collision"
	var shape = RectangleShape2D.new()
	shape.size = PLAYER_SIZE * 0.9
	collision.shape = shape
	add_child(collision)
	
	# ヒットエリア作成
	area = Area2D.new()
	area.name = "HitArea"
	area.collision_layer = 2
	area.collision_mask = 4
	add_child(area)
	
	var area_col = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = PLAYER_SIZE * 0.8
	area_col.shape = area_shape
	area.add_child(area_col)
	
	# シグナル接続
	area.connect("area_entered", _on_area_entered)

func _physics_process(delta):
	# クールダウン処理
	if move_cooldown > 0:
		move_cooldown -= delta
	
	match state:
		State.IDLE:
			_handle_input()
		State.MOVING:
			_update_movement(delta)

func _handle_input():
	# クールダウン中は入力を受け付けない
	if move_cooldown > 0:
		return
	
	# 移動入力の優先順位を設定
	var input_vector = Vector2.ZERO
	
	# 左右移動（タイル移動）
	if Input.is_action_pressed("ui_right"):
		input_vector.x = 1
	elif Input.is_action_pressed("ui_left"):
		input_vector.x = -1
	
	# 上下移動（レーン変更）
	if Input.is_action_pressed("ui_up"):
		input_vector.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_vector.y = 1
	
	# 入力があれば移動を試みる
	if input_vector != Vector2.ZERO:
		if input_vector.x != 0:
			try_move(tile_x + int(input_vector.x), lane)
		elif input_vector.y != 0:
			try_move(tile_x, lane + int(input_vector.y))

func try_move(new_tile_x: int, new_lane: int):
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system:
		push_error("TileSystem not found!")
		return
	
	# 移動可能かチェック
	var can_move = false
	
	# 横移動の場合
	if new_lane == lane:
		if tile_system.is_valid_tile(new_tile_x):
			can_move = true
	# レーン変更の場合
	elif new_tile_x == tile_x:
		if tile_system.can_change_lane(lane, new_lane):
			can_move = true
	
	# 移動実行
	if can_move:
		move_to(new_tile_x, new_lane)
		move_cooldown = MOVE_COOLDOWN_TIME

func move_to(new_tile_x: int, new_lane: int):
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system:
		return
	
	# 移動前の位置を記録
	var old_tile_x = tile_x
	var old_lane = lane
	
	tile_x = new_tile_x
	lane = new_lane
	target_pos = tile_system.tile_to_world(tile_x, lane)
	state = State.MOVING
	
	# 移動方向に応じてスプライトを少し傾ける
	if sprite:
		var tween = create_tween()
		if new_tile_x > old_tile_x:  # 右移動
			tween.tween_property(sprite, "rotation", 0.05, 0.1)
			tween.tween_property(sprite, "rotation", 0.0, 0.1)
		elif new_tile_x < old_tile_x:  # 左移動
			tween.tween_property(sprite, "rotation", -0.05, 0.1)
			tween.tween_property(sprite, "rotation", 0.0, 0.1)
		elif new_lane < old_lane:  # 上移動
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.1), 0.1)
			tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
		elif new_lane > old_lane:  # 下移動
			tween.tween_property(sprite, "scale", Vector2(1.0, 0.9), 0.1)
			tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
	
	emit_signal("moved", tile_x, lane)
	
	# タイルをハイライト
	var lanes = get_node_or_null("../../Lanes")
	if lanes and lanes.has_method("animate_tile"):
		lanes.animate_tile(tile_x, lane)

func _update_movement(_delta):
	var distance = position.distance_to(target_pos)
	if distance < 2.0:
		position = target_pos
		velocity = Vector2.ZERO
		state = State.IDLE
		emit_signal("tile_entered", tile_x, lane)
	else:
		var direction = (target_pos - position).normalized()
		velocity = direction * MOVE_SPEED
		move_and_slide()

func reset_position():
	var tile_system = get_node_or_null("/root/TileSystem")
	if tile_system:
		tile_x = 2
		lane = 1
		position = tile_system.tile_to_world(tile_x, lane)
		target_pos = position
		state = State.IDLE
		invulnerable = false
		move_cooldown = 0

func take_damage():
	if invulnerable or state == State.DEAD:
		return
	
	state = State.HIT
	invulnerable = true
	emit_signal("hit")
	
	# ダメージエフェクト
	_damage_effect()
	
	# 無敵時間
	await get_tree().create_timer(INVULNERABLE_TIME).timeout
	invulnerable = false
	if state == State.HIT:
		state = State.IDLE

func _damage_effect():
	if not sprite:
		return
	
	# 赤くフラッシュ
	var original_modulate = sprite.modulate
	var tween = create_tween()
	
	for i in range(5):
		tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.5), 0.1)
		tween.tween_property(sprite, "modulate", original_modulate, 0.1)
	
	# ノックバック演出
	var knockback_tween = create_tween()
	knockback_tween.tween_property(sprite, "position:x", -10, 0.05)
	knockback_tween.tween_property(sprite, "position:x", 0, 0.1)

func _on_area_entered(other_area: Area2D):
	if other_area.is_in_group("enemy"):
		take_damage()

func get_current_position() -> Dictionary:
	return {"tile_x": tile_x, "lane": lane}

func get_available_moves() -> Dictionary:
	var tile_system = get_node_or_null("/root/TileSystem")
	if not tile_system:
		return {}
	
	return {
		"can_move_right": tile_system.is_valid_tile(tile_x + 1),
		"can_move_left": tile_system.is_valid_tile(tile_x - 1),
		"can_move_up": tile_system.can_change_lane(lane, lane - 1),
		"can_move_down": tile_system.can_change_lane(lane, lane + 1)
	}
