class_name MonsterSkill
extends Resource

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_type: SkillType = SkillType.ON_IMPACT
@export var trigger_condition: TriggerType = TriggerType.ALWAYS
@export var effect_range: float = 2.0
@export var cooldown: float = 0.0

enum SkillType {
	ON_PICKUP,     # 拾った時
	ON_THROW,      # 投げた時
	ON_IMPACT,     # 着弾時
	ON_BOUNCE,     # バウンド時
	PASSIVE        # 常時発動
}

enum TriggerType {
	ALWAYS,        # 常に発動
	LOW_HEALTH,    # 体力低下時
	CRITICAL_HIT,  # クリティカル時
	CHAIN_HIT,     # 連鎖ヒット時
	ELEMENT_MATCH  # 属性一致時
}

@export var skill_effects: Array[Dictionary] = []

func can_trigger(context: Dictionary) -> bool:
	match trigger_condition:
		TriggerType.ALWAYS:
			return true
		TriggerType.LOW_HEALTH:
			return context.get("target_health_percent", 1.0) < 0.3
		TriggerType.CRITICAL_HIT:
			return context.get("is_critical", false)
		TriggerType.CHAIN_HIT:
			return context.get("chain_count", 0) > 0
		TriggerType.ELEMENT_MATCH:
			return context.get("element_match", false)
	
	return false

func execute_skill(caster: Node, target: Node, context: Dictionary) -> void:
	if not can_trigger(context):
		return
	
	for effect in skill_effects:
		_apply_skill_effect(effect, caster, target, context)

func _apply_skill_effect(effect: Dictionary, caster: Node, target: Node, context: Dictionary) -> void:
	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0.0)
	
	match effect_type:
		"damage":
			if target.has_method("take_damage"):
				target.take_damage(value)
		"heal":
			if target.has_method("heal"):
				target.heal(value)
		"explosion":
			_create_explosion(target.global_position, value)
		"spawn_projectile":
			_spawn_projectile(caster.global_position, target.global_position)

func _create_explosion(position: Vector3, radius: float) -> void:
	# 爆発エフェクトの生成
	pass

func _spawn_projectile(from: Vector3, to: Vector3) -> void:
	# 追加の発射物生成
	pass
