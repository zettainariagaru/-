extends Area2D

# 爆発樽のギミック

@export var explosion_damage: int = 50
@export var explosion_radius: float = 100.0
@export var trigger_on_hit: bool = true

var is_exploded: bool = false

func _ready() -> void:
	# コリジョンの設定
	if trigger_on_hit:
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") or body.name == "Player":
		explode()

func _on_area_entered(area: Area2D) -> void:
	# 攻撃判定（Hitbox）が当たった場合
	if area.name == "Hitbox":
		explode()

func explode() -> void:
	if is_exploded:
		return
		
	is_exploded = true
	
	# 爆発エフェクト
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.effect_requested.emit("explosion", global_position)
	
	# 範囲内のオブジェクトにダメージ
	var bodies = get_tree().get_nodes_in_group("damageable")
	for body in bodies:
		if body.has_method("take_damage"):
			var distance = global_position.distance_to(body.global_position)
			if distance <= explosion_radius:
				var damage = int(explosion_damage * (1.0 - distance / explosion_radius))
				var knockback = (body.global_position - global_position).normalized() * 300
				body.take_damage(damage, knockback)
	
	# プレイヤーへのダメージ
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		var distance = global_position.distance_to(player.global_position)
		if distance <= explosion_radius:
			var damage = int(explosion_damage * (1.0 - distance / explosion_radius))
			player.take_damage(damage)
	
	# 自身を削除
	queue_free()

func trigger_explosion() -> void:
	# 外部から爆発をトリガー
	explode()
