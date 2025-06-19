extends CharacterBody2D

# プレイヤーの動作制御スクリプト（タイルベース移動対応）

# 基本パラメータ
@export_group("Movement")
@export var move_speed: float = 300.0  # タイル間の移動速度
@export var tile_based_movement: bool = true  # タイルベース移動の有効/無効

@export_group("Throwing")
@export var throw_power: float = 600.0
@export var max_throw_distance: float = 400.0
@export var aim_rotation_speed: float = 5.0

@export_group("Stats")
@export var max_health: int = 100
@export var max_carry_stack: int = 5

# タイルベース移動用
var current_tile: Vector2i = Vector2i(5, 1)  # 開始位置（中央レーン）
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_cooldown: float = 0.0
const MOVE_COOLDOWN_TIME: float = 0.15  # 移動間のクールダウン

# 内部変数
var current_health: int
var carried_monsters: Array[MonsterData] = []
var is_aiming: bool = false
var aim_direction: Vector2 = Vector2.RIGHT
var can_pick_up: bool = true
var invulnerable: bool = false

# ノード参照
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var state_machine: Node = $StateMachine
@onready var carry_stack: Node2D = $CarryStack
@onready var throw_guide: Line2D = $ThrowGuide
@onready var pick_range: Area2D = $PickRange
@onready var hurtbox: Area2D = $Hurtbox

# タイルマップ参照
var tilemap: TileMap

func _ready() -> void:
	current_health = max_health
	_setup_connections()
	_initialize_state_machine()
	
	# タイルマップを取得
	tilemap = get_tree().current_scene.get_node("Field/TileMap")
	if tilemap and tile_based_movement:
		# 開始位置を設定
		target_position = tilemap.get_tile_center_position(current_tile)
		global_position = target_position
	
func _setup_connections() -> void:
	# Area2Dのシグナル接続
	pick_range.body_entered.connect(_on_pick_range_body_entered)
	pick_range.body_exited.connect(_on_pick_range_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# EventBusへの接続
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.game_state_changed.connect(_on_game_state_changed)

func _initialize_state_machine() -> void:
	# ステートマシンの初期化（実装は別途）
	pass

func _physics_process(delta: float) -> void:
	# クールダウンを更新
	if move_cooldown > 0:
		move_cooldown -= delta
	
	if is_aiming:
		_update_aim(delta)
		_update_throw_guide()
	elif tile_based_movement and tilemap:
		_handle_tile_based_movement(delta)
	else:
		_handle_free_movement(delta)
	
	move_and_slide()

func _handle_tile_based_movement(delta: float) -> void:
        var input_vector = Vector2i.ZERO
        velocity = Vector2.ZERO
	
	# 入力を取得（移動中でなく、クールダウンが終わっている場合のみ）
	if not is_moving and move_cooldown <= 0:
		if Input.is_action_pressed("move_right"):
			input_vector.x = 1
		elif Input.is_action_pressed("move_left"):
			input_vector.x = -1
		elif Input.is_action_pressed("move_down"):  # レーン変更（下へ）
			input_vector.y = 1
		elif Input.is_action_pressed("move_up"):    # レーン変更（上へ）
			input_vector.y = -1
		
		# 入力があれば移動を開始
		if input_vector != Vector2i.ZERO:
			var new_tile = current_tile + input_vector
			
			# タイルが有効範囲内かチェック
			if tilemap.is_valid_tile(new_tile):
				current_tile = new_tile
				target_position = tilemap.get_tile_center_position(current_tile)
				is_moving = true
				move_cooldown = MOVE_COOLDOWN_TIME
				
				# アニメーション更新
				if input_vector.x != 0:
					sprite.flip_h = input_vector.x < 0
	
	# スムーズな移動
	if is_moving:
		global_position = global_position.move_toward(target_position, move_speed * delta)
		sprite.play("run")
		
		# 目標位置に到達したかチェック
		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			is_moving = false
	else:
		sprite.play("idle")

func _handle_free_movement(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector * move_speed
		sprite.play("run")
		sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")

func _update_aim(delta: float) -> void:
	# マウスまたは右スティックで狙いを定める
        var mouse_pos = get_global_mouse_position()
        var target_direction = (mouse_pos - global_position).normalized()
        aim_direction = aim_direction.lerp(target_direction, aim_rotation_speed * delta).normalized()

func _update_throw_guide() -> void:
	if carried_monsters.is_empty():
		throw_guide.visible = false
		return
		
	throw_guide.visible = true
	throw_guide.clear_points()
	
	# 投擲軌道の計算
        var points: Array[Vector2] = []
        var velocity = aim_direction * throw_power
        var gravity = 980.0 # 重力加速度
        var time_step = 0.05

        for i in range(20):
                var t = i * time_step
                var pos = Vector2(velocity.x * t, velocity.y * t + 0.5 * gravity * t * t)
                if pos.length() > max_throw_distance:
                        break
                points.append(pos)
	
	throw_guide.points = points

func _input(event: InputEvent) -> void:
	# 投げる動作
	if event.is_action_pressed("throw") and not carried_monsters.is_empty():
		is_aiming = true
		is_moving = false  # タイルベース移動を中断
		sprite.play("aim")
	elif event.is_action_released("throw") and is_aiming:
		_throw_monster()
		is_aiming = false
	
	# 拾う動作
	if event.is_action_pressed("pick_up") and can_pick_up:
		_try_pick_up_monster()

func _throw_monster() -> void:
	if carried_monsters.is_empty():
		return
	
	var monster_data = carried_monsters.pop_back()
        var dir := aim_direction.normalized()
        var thrown_position = global_position + dir * 50
	
	# EventBusを通じて投擲イベントを発信
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.monster_thrown.emit(monster_data, global_position, thrown_position)
	
	# 投擲物の生成（ObjectPoolsを使用）
	if has_node("/root/ObjectPools"):
		var object_pools = get_node("/root/ObjectPools")
                var projectile = object_pools.get_projectile("thrown_monster")
                if projectile:
                        projectile.setup(monster_data, thrown_position, dir * throw_power)
			get_tree().current_scene.get_node("Field/YSort/ThrownObjects").add_child(projectile)
	
	_update_carry_stack_display()
	sprite.play("throw")

func _try_pick_up_monster() -> void:
	if carried_monsters.size() >= max_carry_stack:
		return
	
	# 範囲内のモンスターを探す
	var bodies = pick_range.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("can_be_picked_up") and body.can_be_picked_up():
			_pick_up_monster(body)
			break

func _pick_up_monster(monster: Node) -> void:
	if not monster.has_method("get_monster_data"):
		return
		
	var monster_data = monster.get_monster_data()
	carried_monsters.append(monster_data)
	monster.queue_free()
	
	_update_carry_stack_display()
	
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.effect_requested.emit("pick_up", monster.global_position)

func _update_carry_stack_display() -> void:
	# スタック表示の更新
	for child in carry_stack.get_children():
		child.queue_free()
	
	var stack_offset = Vector2(0, -20)
	for i in range(carried_monsters.size()):
		var stack_sprite = Sprite2D.new()
		# ここでモンスターのスプライトを設定
		stack_sprite.position = stack_offset * i
		carry_stack.add_child(stack_sprite)
	
	# UIの更新
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.combo_updated.emit(carried_monsters.size())

func take_damage(amount: int) -> void:
	if invulnerable:
		return
		
	current_health = max(0, current_health - amount)
	
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.player_health_changed.emit(current_health)
	
	if current_health <= 0:
		_die()
	else:
		_start_invulnerability()

func _start_invulnerability() -> void:
	invulnerable = true
	sprite.modulate.a = 0.5
	
	await get_tree().create_timer(1.0).timeout
	
	invulnerable = false
	sprite.modulate.a = 1.0

func _die() -> void:
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.game_state_changed.emit("game_over")
	queue_free()

# 現在のタイル情報を取得
func get_current_tile_info() -> Dictionary:
	if not tilemap:
		return {"tile": Vector2i.ZERO, "lane": -1}
		
	return {
		"tile": current_tile,
		"lane": current_tile.y,
		"position_in_lane": current_tile.x
	}

# シグナルコールバック
func _on_pick_range_body_entered(body: Node2D) -> void:
	if body.has_method("highlight"):
		body.highlight(true)

func _on_pick_range_body_exited(body: Node2D) -> void:
	if body.has_method("highlight"):
		body.highlight(false)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		take_damage(area.get_damage())

func _on_game_state_changed(new_state: String) -> void:
	set_physics_process(new_state == "playing")
