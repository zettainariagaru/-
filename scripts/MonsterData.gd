class_name MonsterData
extends Resource

# 基本特性
@export var monster_id: String = ""
@export var monster_name: String = ""
@export var monster_type: String = ""

# 物理特性
@export var weight: float = 1.0  # 重さ（担げる数に影響、投擲力に影響）
@export var size: float = 1.0    # サイズ（担ぎやすさに影響）
@export var bounce_factor: float = 0.3  # バウンド係数

# 投擲特性
@export var throw_power_multiplier: float = 1.0  # 投擲力倍率
@export var throw_distance_type: ThrowDistanceType = ThrowDistanceType.MEDIUM
@export var trajectory_type: TrajectoryType = TrajectoryType.NORMAL

# 属性・ダメージ
@export var element_type: ElementType = ElementType.NEUTRAL
@export var base_damage: float = 10.0
@export var area_damage_radius: float = 0.0  # 範囲攻撃半径

# 特殊効果
@export var status_effects: Array[StatusEffect] = []
@export var special_skills: Array[MonsterSkill] = []

# 見た目・演出
@export var color: Color = Color.WHITE
@export var mesh_type: MeshType = MeshType.CUBE
@export var particle_effect: String = ""

# 投擲距離適性
enum ThrowDistanceType {
	SHORT,   # 近距離特化
	MEDIUM,  # 中距離万能
	LONG     # 長距離特化
}

# 軌道タイプ
enum TrajectoryType {
	NORMAL,    # 通常の放物線
	STRAIGHT,  # 直線的
	CURVED     # カーブ軌道
}

# 属性タイプ
enum ElementType {
	NEUTRAL,
	FIRE,
	WATER,
	EARTH,
	WIND,
	ELECTRIC,
	ICE,
	POISON
}

# メッシュタイプ
enum MeshType {
	CUBE,
	SPHERE,
	CYLINDER,
	CUSTOM
}

# 重量カテゴリ取得
func get_weight_category() -> String:
	if weight <= 0.5:
		return "Light"
	elif weight <= 1.5:
		return "Medium"
	else:
		return "Heavy"

# 投擲効率計算（重さと距離適性の組み合わせ）
func get_throw_efficiency(distance_type: ThrowDistanceType) -> float:
	var base_efficiency = 1.0
	
	# 距離適性マッチング
	if throw_distance_type == distance_type:
		base_efficiency *= 1.5
	elif abs(throw_distance_type - distance_type) == 2:
		base_efficiency *= 0.7
	
	# 重量による調整
	var weight_factor = 1.0 / max(weight, 0.1)
	
	return base_efficiency * weight_factor * throw_power_multiplier

# ダメージ計算
func calculate_damage(velocity: float, target_weakness: ElementType = ElementType.NEUTRAL) -> float:
	var damage = base_damage
	
	# 速度による追加ダメージ
	damage += velocity * 2.0
	
	# 属性相性
	if _is_element_effective(element_type, target_weakness):
		damage *= 1.5
	elif _is_element_weak(element_type, target_weakness):
		damage *= 0.7
	
	return damage

# 属性相性チェック（簡易版）
func _is_element_effective(attacker: ElementType, defender: ElementType) -> bool:
	var effectiveness = {
		ElementType.FIRE: [ElementType.ICE, ElementType.EARTH],
		ElementType.WATER: [ElementType.FIRE, ElementType.ELECTRIC],
		ElementType.EARTH: [ElementType.ELECTRIC, ElementType.WIND],
		ElementType.WIND: [ElementType.EARTH, ElementType.POISON],
		ElementType.ELECTRIC: [ElementType.WATER, ElementType.WIND],
		ElementType.ICE: [ElementType.WATER, ElementType.POISON],
		ElementType.POISON: [ElementType.FIRE, ElementType.ICE]
	}
	
	return effectiveness.get(attacker, []).has(defender)

func _is_element_weak(attacker: ElementType, defender: ElementType) -> bool:
	return _is_element_effective(defender, attacker)
