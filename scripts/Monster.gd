extends CharacterBody2D

# モンスターのAIと動作を制御するスクリプト

# エクスポート変数
@export var monster_data: MonsterData

# 内部変数
var current_health: int
var target: Node2D = null
var home_position: Vector2
var is_highlighted: bool = false
var can_be_picked: bool = true
var current_state: String = "idle"
var state_timer: float = 0.0

# AI関連
var patrol_target: Vector2
var last_direction: Vector2 = Vector2.RIGHT
var attack_cooldown: float = 0.0

# ノード参照
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var state_machine: Node = $StateMachine
@onready var status_effect_container: Node = $StatusEffectContainer
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	if not monster_data:
		push_error("MonsterData not set!")
		queue_free()
		return
		
	_initialize_from_data()
	_setup_connections()
	home_position = global_position
	_set_new_patrol_target()

func _initialize_from_data() -> void:
	# MonsterDataから初期化
	current_health = monster_data.max_health
	
	# スプライト設定
	if monster_data.sprite_frames:
		sprite.sprite_frames = monster_data.sprite_frames
	sprite.modulate = monster_data.color_modulate
	scale *= monster_data.scale_modifier
	
	# 物理設定
	velocity = Vector2.ZERO

func _setup_connections() -> void:
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# プレイヤー検知用のArea2D設定
	var detection_area = Area2D.new()
	var detection_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = monster_data.detection_range
	detection_shape.shape = circle
	detection_area.add_child(detection_shape)
	add_child(detection_area)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	if not can_be_picked:
		return
		
	state_timer += delta
	attack_cooldown = max(0, attack_cooldown - delta)
	
	# AI状態に応じた動作
	match current_state:
		"idle":
			_idle_behavior(delta)
		"patrol":
			_patrol_behavior(delta)
		"chase":
			_chase_behavior(delta)
		"attack":
			_attack_behavior(delta)
		"stunned":
			_stunned_behavior(delta)
	
	move_and_slide()
	_update_animation()

func _idle_behavior(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)
	
	if state_timer > 2.0:
		_change_state("patrol")

func _patrol_behavior(delta: float) -> void:
	var direction = (patrol_target - global_position).normalized()
	velocity = direction * monster_data.move_speed * 0.5
	
	if global_position.distance_to(patrol_target) < 10:
		_set_new_patrol_target()
	
	# ターゲットが見つかったら追跡
	if target:
		_change_state("chase")

func _chase_behavior(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		_change_state("patrol")
		return
		
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target > monster_data.detection_range * 1.5:
		# 範囲外に出たら諦める
		target = null
		_change_state("patrol")
	elif distance_to_target <= monster_data.attack_range:
		# 攻撃範囲内
		if attack_cooldown <= 0:
			_change_state("attack")
	else:
		# 追跡
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * monster_data.move_speed
		last_direction = direction

func _attack_behavior(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
	
	if state_timer > 0.5:
		_perform_attack()
		attack_cooldown = 1.5
		_change_state("chase" if target else "idle")

func _stunned_behavior(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)
	sprite.modulate = Color(1, 1, 1, 0.5 + sin(state_timer * 20) * 0.5)
	
	if state_timer > 2.0:
		sprite.modulate = monster_data.color_modulate
		can_be_picked = true
		_change_state("idle")

func _perform_attack() -> void:
	sprite.play("attack")
	hitbox.set_deferred("monitoring", true)
	
	await get_tree().create_timer(0.2).timeout
	hitbox.set_deferred("monitoring", false)

func _update_animation() -> void:
	if velocity.length() > 10:
		sprite.play("walk")
		sprite.flip_h = velocity.x < 0
	else:
		sprite.play("idle")

func _change_state(new_state: String) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		"attack":
			sprite.play("attack")

func _set_new_patrol_target() -> void:
	var angle = randf() * TAU
	var distance = randf_range(50, monster_data.patrol_radius)
	patrol_target = home_position + Vector2(cos(angle), sin(angle)) * distance

func take_damage(damage: int, knockback: Vector2 = Vector2.ZERO) -> void:
	current_health -= damage
	velocity += knockback
	
	# ダメージエフェクト
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = monster_data.color_modulate
	
	EventBus.effect_requested.emit("hit", global_position)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	EventBus.monster_defeated.emit(monster_data.monster_name, global_position)
	EventBus.score_updated.emit(monster_data.score_value)
	
	# 死亡エフェクト
	EventBus.effect_requested.emit("death", global_position)
	
	# ドロップ処理
	if randf() < monster_data.drop_chance:
		_drop_item()
	
	queue_free()

func _drop_item() -> void:
	# アイテムドロップの実装
	pass

func stun(duration: float) -> void:
	if monster_data.status_immunities.has("stun"):
		return
		
	can_be_picked = false
	_change_state("stunned")

func can_be_picked_up() -> bool:
	return can_be_picked and current_state == "stunned"

func get_monster_data() -> MonsterData:
	return monster_data

func highlight(enabled: bool) -> void:
	is_highlighted = enabled
	if enabled:
		sprite.modulate = Color(1.5, 1.5, 1.5)
	else:
		sprite.modulate = monster_data.color_modulate

# シグナルコールバック
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and monster_data.ai_type == "aggressive":
		target = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		take_damage(area.get_damage())

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(monster_data.attack_power)
