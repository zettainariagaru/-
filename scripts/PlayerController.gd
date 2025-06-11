class_name PlayerController
extends CharacterBody3D

# 移動パラメータ
@export var move_speed: float = 6.0
@export var lane_switch_speed: float = 8.0
@export var pickup_range: float = 1.5

# レーン移動制御
var current_lane: int = 1  # 中央レーンから開始
var target_lane: int = 1
var is_switching_lanes: bool = false

# モンスター管理
var carried_monster: ThrowableMonster = null
var nearby_monsters: Array[ThrowableMonster] = []

# フィールド参照
@onready var field: ThreeLaneField = get_node("../ThreeLaneField")

# 入力制御
var input_buffer: Dictionary = {}

# シグナル
signal monster_picked_up(monster: ThrowableMonster)
signal monster_thrown(monster: ThrowableMonster, direction: Vector3)

func _ready():
	# プレイヤーの見た目（白い丸）
	_setup_player_visual()
	
	# 初期位置設定（中央レーン）
	if field:
		position.x = field.get_lane_world_x(current_lane)
		position.y = 0.5  # 地面より少し上

func _setup_player_visual():
	# メッシュインスタンス追加
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	sphere_mesh.height = 0.6
	mesh_instance.mesh = sphere_mesh
	
	# プレイヤー用マテリアル
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	# コリジョン追加
	var collision = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.3
	capsule_shape.height = 0.6
	collision.shape = capsule_shape
	add_child(collision)

func _physics_process(delta):
	_handle_input()
	_update_movement(delta)
	_update_monster_detection()
	move_and_slide()

# 入力処理
func _handle_input():
	input_buffer.clear()
	
	# レーン移動（左右）
	if Input.is_action_just_pressed("move_left"):
		input_buffer["lane_left"] = true
	if Input.is_action_just_pressed("move_right"):
		input_buffer["lane_right"] = true
	
	# 前進・後退
	input_buffer["move_forward"] = Input.is_action_pressed("move_forward")
	input_buffer["move_backward"] = Input.is_action_pressed("move_backward")
	
	# モンスター操作
	if Input.is_action_just_pressed("pickup_carry"):
		input_buffer["pickup_carry"] = true
	if Input.is_action_just_pressed("throw_monster"):
		input_buffer["throw_monster"] = true

# 移動更新
func _update_movement(delta):
	# レーン移動処理
	_handle_lane_movement(delta)
	
	# 前進・後退処理
	_handle_forward_backward_movement()

# レーン移動処理
func _handle_lane_movement(delta):
	# レーン切り替え入力
	if input_buffer.get("lane_left", false) and not is_switching_lanes:
		_switch_to_lane(max(0, current_lane - 1))
	elif input_buffer.get("lane_right", false) and not is_switching_lanes:
		_switch_to_lane(min(2, current_lane + 1))
	
	# レーン切り替え中の補間移動
	if is_switching_lanes:
		var target_x = field.get_lane_world_x(target_lane)
		var current_x = position.x
		
		# 補間移動
		var new_x = move_toward(current_x, target_x, lane_switch_speed * delta)
		position.x = new_x
		
		# 目標到達チェック
		if abs(new_x - target_x) < 0.1:
			position.x = target_x
			current_lane = target_lane
			is_switching_lanes = false

# レーン変更開始
func _switch_to_lane(new_lane: int):
	if new_lane != current_lane and new_lane >= 0 and new_lane < 3:
		target_lane = new_lane
		is_switching_lanes = true

# 前進・後退移動
func _handle_forward_backward_movement():
	var movement_input = Vector3.ZERO
	
	if input_buffer.get("move_forward", false):
		movement_input.z += 1.0
	if input_buffer.get("move_backward", false):
		movement_input.z -= 1.0
	
	# 移動速度適用
	velocity.z = movement_input.z * move_speed
	
	# X軸の移動は重力とレーン移動のみ
	velocity.x = 0
	
	# 重力適用
	if not is_on_floor():
		velocity.y += get_gravity().y

# 近くのモンスター検出
func _update_monster_detection():
	nearby_monsters.clear()
	
	# 全てのThrowableMonsterを検索
	var monsters = get_tree().get_nodes_in_group("throwable_monsters")
	
	for monster in monsters:
		if monster is ThrowableMonster:
			var distance = global_position.distance_to(monster.global_position)
			if distance <= pickup_range and monster.is_available_for_pickup():
				nearby_monsters.append(monster)

# モンスター操作処理
func _handle_monster_actions():
	if input_buffer.get("pickup_carry", false):
		if carried_monster == null:
			_try_pickup_monster()
		else:
			# 既に担いでいる場合は投げる準備？
			pass
	
	if input_buffer.get("throw_monster", false):
		_try_throw_monster()

# モンスターを拾う/担ぐ
func _try_pickup_monster():
	if nearby_monsters.size() > 0:
		var target_monster = nearby_monsters[0]  # 最も近いモンスター
		
		if target_monster.pick_up(self):
			carried_monster = target_monster
			# 担ぐ位置に移動
			var carry_position = global_position + Vector3(0, 1.0, -0.5)
			target_monster.carry(self, carry_position)
			monster_picked_up.emit(target_monster)

# モンスターを投げる
func _try_throw_monster():
	if carried_monster != null:
		# 投擲方向（とりあえず前方）
		var throw_direction = Vector3(0, 0.3, 1).normalized()
		var throw_power = 1.0
		
		if carried_monster.throw_monster(throw_direction, throw_power):
			monster_thrown.emit(carried_monster, throw_direction)
			carried_monster = null

# デバッグ用：現在位置情報
func get_position_info() -> Dictionary:
	if field:
		return field.get_position_info(global_position)
	return {}

# ユーティリティメソッド
func get_current_lane() -> int:
	return current_lane

func is_carrying_monster() -> bool:
	return carried_monster != null

func get_carried_monster() -> ThrowableMonster:
	return carried_monster
