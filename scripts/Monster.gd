extends RigidBody2D
class_name Monster

enum MonsterState {
	IDLE,      # 待機状態
	PATROL,    # 巡回中
	CARRIED,   # 運搬中
	THROWN,    # 投擲済み
	STUNNED    # 気絶中
}

var current_state: MonsterState = MonsterState.IDLE
var monster_type: String = "basic"
var is_being_carried: bool = false

# フィールド参照
var field_manager: FieldManager
var current_tile: Vector2i

func _ready():
	add_to_group("monsters")
	field_manager = get_node("../../FieldManager")
	
	# 物理設定
	set_gravity_scale(0)  # 通常時は重力無効
	set_lock_rotation_enabled(true)

func _process(delta):
	if not is_being_carried:
		update_current_tile()
		handle_ai_behavior(delta)

func update_current_tile():
	if field_manager:
		current_tile = field_manager.world_to_tile(global_position)

func handle_ai_behavior(delta):
	match current_state:
		MonsterState.IDLE:
			# 待機中の挙動
			pass
		MonsterState.PATROL:
			# 巡回中の挙動
			pass

func can_be_picked_up() -> bool:
	return current_state in [MonsterState.IDLE, MonsterState.STUNNED] and not is_being_carried

func set_carried_state(carried: bool):
	is_being_carried = carried
	if carried:
		current_state = MonsterState.CARRIED
		set_freeze_enabled(true)
	else:
		current_state = MonsterState.IDLE
		set_freeze_enabled(false)

func throw_monster(direction: Vector2, force: float):
	current_state = MonsterState.THROWN
	is_being_carried = false
	set_freeze_enabled(false)
	set_gravity_scale(1)
	apply_central_impulse(direction.normalized() * force)

func _on_body_entered(body):
	# 他のオブジェクトとの衝突処理
	if current_state == MonsterState.THROWN:
		print("Monster collision with: ", body.name)
