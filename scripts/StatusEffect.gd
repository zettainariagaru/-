class_name StatusEffect
extends Resource

@export var effect_id: String = ""
@export var effect_name: String = ""
@export var duration: float = 5.0
@export var effect_type: StatusType = StatusType.DAMAGE_OVER_TIME
@export var effect_value: float = 1.0
@export var stack_limit: int = 1  # 重複可能回数

enum StatusType {
	DAMAGE_OVER_TIME,  # 継続ダメージ
	SLOW,              # 移動速度低下
	STUN,              # 行動不能
	POISON,            # 毒
	BURN,              # 燃焼
	FREEZE,            # 凍結
	CONFUSION,         # 混乱
	WEAKNESS           # 弱体化
}

func apply_effect(target: Node) -> void:
	# 状態異常の適用処理
	match effect_type:
		StatusType.DAMAGE_OVER_TIME:
			_apply_dot_effect(target)
		StatusType.SLOW:
			_apply_slow_effect(target)
		StatusType.STUN:
			_apply_stun_effect(target)
		# 他の効果も実装...

func _apply_dot_effect(target: Node) -> void:
	if target.has_method("take_damage_over_time"):
		target.take_damage_over_time(effect_value, duration)

func _apply_slow_effect(target: Node) -> void:
	if target.has_method("apply_speed_modifier"):
		target.apply_speed_modifier(1.0 - effect_value, duration)

func _apply_stun_effect(target: Node) -> void:
	if target.has_method("apply_stun"):
		target.apply_stun(duration)
