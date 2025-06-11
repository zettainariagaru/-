class_name ThrowableMonster
extends RigidBody3D

# モンスターデータ
@export var monster_data: MonsterData
var runtime_data: Dictionary = {}  # 実行時データ（体力、状態異常など）

# 状態管理
enum MonsterState {
	FREE,      # 自由状態（地面に落ちている）
	PICKED_UP, # プレイヤーに拾われた状態
	CARRIED,   # プレイヤーが担いでいる状態
	THROWN     # 投擲された状態
}

var current_state: MonsterState = MonsterState.FREE
var carrier: Node3D = null
var stack_position: int = -1  # スタック内での位置

# 物理パラメータ（MonsterDataから取得）
var effective_throw_power: float
var effective_bounce_factor: float

# 状態異常管理
var active_status_effects: Array[Dictionary] = []

# シグナル
signal monster_picked_up(monster: ThrowableMonster)
signal monster_thrown(monster: ThrowableMonster, velocity: Vector3)
signal monster_hit_target(monster: ThrowableMonster, target: Node3D, damage: float)
signal monster_skill_triggered(monster: ThrowableMonster, skill: MonsterSkill)

func _ready():
	_initialize_from_data()
	_setup_physics()
	_setup_visuals()
	
	# 衝突検出
	body_entered.connect(_on_body_entered)
	set_state(MonsterState.FREE)

func _initialize_from_data():
	if not monster_data:
		monster_data = _create_default_data()
	
	effective_throw_power = monster_data.throw_power_multiplier
	effective_bounce_factor = monster_data.bounce_factor
	
	# 実行時データ初期化
	runtime_data = {
		"current_health": monster_data.base_damage * 2,  # 仮の体力設定
		"max_health": monster_data.base_damage * 2,
		"is_stunned": false,
		"speed_modifier": 1.0
	}

func _create_default_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_id = "basic_monster"
	data.monster_name = "Basic Monster"
	data.weight = 1.0
	data.base_damage = 10.0
	return data

func _setup_physics():
	gravity_scale = monster_data.weight  # 重いモンスターは早く落ちる
	linear_damp = 0.1 * monster_data.weight
	angular_damp = 0.1

func _setup_visuals():
	# 既存の子ノードをクリア
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	# MonsterDataに基づいて見た目を設定
	var mesh_instance = MeshInstance3D.new()
	
	match monster_data.mesh_type:
		MonsterData.MeshType.CUBE:
			var box_mesh = BoxMesh.new()
			var size_factor = monster_data.size
			box_mesh.size = Vector3(size_factor, size_factor, size_factor)
			mesh_instance.mesh = box_mesh
		MonsterData.MeshType.SPHERE:
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = monster_data.size * 0.5
			mesh_instance.mesh = sphere_mesh
		_:
			# デフォルトは立方体
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(monster_data.size, monster_data.size, monster_data.size)
			mesh_instance.mesh = box_mesh
	
	# 色設定（属性に応じて）
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_element_color(monster_data.element_type)
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func _get_element_color(element: MonsterData.ElementType) -> Color:
	match element:
		MonsterData.ElementType.FIRE:
			return Color.RED
		MonsterData.ElementType.WATER:
			return Color.BLUE
		MonsterData.ElementType.EARTH:
			return Color.BROWN
		MonsterData.ElementType.WIND:
			return Color.LIGHT_GREEN
		MonsterData.ElementType.ELECTRIC:
			return Color.YELLOW
		MonsterData.ElementType.ICE:
			return Color.CYAN
		MonsterData.ElementType.POISON:
			return Color.PURPLE
		_:
			return Color.WHITE

func _physics_process(delta):
	_update_status_effects(delta)
	
	match current_state:
		MonsterState.THROWN:
			_handle_thrown_physics(delta)
		MonsterState.CARRIED:
			_handle_carried_physics(delta)

# 状態変更
func set_state(new_state: MonsterState):
	current_state = new_state
	
	match new_state:
		MonsterState.FREE:
			_set_physics_active(true)
			carrier = null
			stack_position = -1
		MonsterState.PICKED_UP:
			_set_physics_active(false)
			_trigger_skills(MonsterSkill.SkillType.ON_PICKUP)
			monster_picked_up.emit(self)
		MonsterState.CARRIED:
			_set_physics_active(false)
		MonsterState.THROWN:
			_set_physics_active(true)
			_trigger_skills(MonsterSkill.SkillType.ON_THROW)
			monster_thrown.emit(self, linear_velocity)

func _set_physics_active(active: bool):
	if active:
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = false
	else:
		freeze = true

# 拾う処理
func pick_up(player: Node3D) -> bool:
	if current_state != MonsterState.FREE:
		return false
	
	carrier = player
	set_state(MonsterState.PICKED_UP)
	return true

# 担ぐ処理（スタック位置指定）
func carry(player: Node3D, carry_position: Vector3, stack_pos: int):
	if current_state != MonsterState.PICKED_UP or carrier != player:
		return false
	
	global_position = carry_position
	stack_position = stack_pos
	set_state(MonsterState.CARRIED)
	return true

# 投げる処理
func throw_monster(direction: Vector3, power: float, context: Dictionary = {}) -> bool:
	if current_state != MonsterState.CARRIED:
		return false
	
	# 投擲力計算（重量とパワーを考慮）
	var weight_factor = 1.0 / max(monster_data.weight, 0.1)
	var final_power = power * effective_throw_power * weight_factor
	
	# 軌道タイプに応じた調整
	var adjusted_direction = _adjust_trajectory(direction, monster_data.trajectory_type)
	
	var throw_velocity = adjusted_direction.normalized() * final_power
	
	set_state(MonsterState.THROWN)
	linear_velocity = throw_velocity
	
	# 回転追加
	angular_velocity = Vector3(
		randf_range(-5, 5) * monster_data.weight,
		randf_range(-5, 5) * monster_data.weight,
		randf_range(-5, 5) * monster_data.weight
	)
	
	return true

func _adjust_trajectory(direction: Vector3, trajectory_type: MonsterData.TrajectoryType) -> Vector3:
	match trajectory_type:
		MonsterData.TrajectoryType.STRAIGHT:
			return direction  # そのまま
		MonsterData.TrajectoryType.CURVED:
			# 少し上向きに調整
			return direction + Vector3(0, 0.2, 0)
		_:
			return direction

# 投擲中の物理処理
func _handle_thrown_physics(delta):
	if linear_velocity.length() < 1.0 and is_on_floor():
		set_state(MonsterState.FREE)

# 担がれている間の物理処理
func _handle_carried_physics(delta):
	if carrier and carrier.has_method("get_carry_position"):
		var target_pos = carrier.get_carry_position(stack_position)
		global_position = target_pos

# 衝突処理
func _on_body_entered(body: Node):
	if current_state == MonsterState.THROWN:
		var damage = monster_data.calculate_damage(linear_velocity.length())
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
			monster_hit_target.emit(self, body, damage)
		
		# 状態異常適用
		_apply_status_effects_to_target(body)
		
		# 着弾スキル発動
		_trigger_skills(MonsterSkill.SkillType.ON_IMPACT, {"target": body})
		
		# バウンド処理
		linear_velocity *= effective_bounce_factor
		_trigger_skills(MonsterSkill.SkillType.ON_BOUNCE)

# 状態異常を対象に適用
func _apply_status_effects_to_target(target: Node):
	for status_effect in monster_data.status_effects:
		if status_effect and target.has_method("apply_status_effect"):
			target.apply_status_effect(status_effect)

# スキル発動
func _trigger_skills(skill_type: MonsterSkill.SkillType, context: Dictionary = {}):
	for skill in monster_data.special_skills:
		if skill and skill.skill_type == skill_type:
			if skill.can_trigger(context):
				skill.execute_skill(self, context.get("target"), context)
				monster_skill_triggered.emit(self, skill)

# 状態異常更新
func _update_status_effects(delta):
	for i in range(active_status_effects.size() - 1, -1, -1):
		var effect = active_status_effects[i]
		effect["duration"] -= delta
		
		if effect["duration"] <= 0:
			active_status_effects.remove_at(i)
		else:
			_apply_status_effect_tick(effect, delta)

func _apply_status_effect_tick(effect: Dictionary, delta: float):
	# 状態異常の継続効果処理
	pass

# ユーティリティメソッド
func is_available_for_pickup() -> bool:
	return current_state == MonsterState.FREE

func get_weight() -> float:
	return monster_data.weight if monster_data else 1.0

func get_display_name() -> String:
	return monster_data.monster_name if monster_data else "Unknown Monster"

func get_element_type() -> MonsterData.ElementType:
	return monster_data.element_type if monster_data else MonsterData.ElementType.NEUTRAL
