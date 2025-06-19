class_name MonsterData
extends Resource

# モンスターの基本データを定義するリソース

@export_group("基本情報")
@export var monster_name: String = "Monster"
@export var monster_type: String = "normal" # normal, rare, boss
@export var description: String = ""

@export_group("ステータス")
@export var max_health: int = 100
@export var attack_power: int = 10
@export var defense: int = 5
@export var move_speed: float = 80.0
@export var weight: float = 1.0 # 投げやすさに影響

@export_group("AI設定")
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var patrol_radius: float = 100.0
@export var ai_type: String = "aggressive" # aggressive, defensive, passive

@export_group("投擲設定")
@export var throw_damage: int = 20 # 投げられた時のダメージ
@export var throw_speed: float = 500.0 # 投げられる速度
@export var bounce_count: int = 2 # 跳ね返り回数
@export var can_be_thrown: bool = true

@export_group("ビジュアル")
@export var sprite_frames: SpriteFrames
@export var color_modulate: Color = Color.WHITE
@export var scale_modifier: float = 1.0

@export_group("サウンド")
@export var idle_sounds: Array[AudioStream] = []
@export var hurt_sounds: Array[AudioStream] = []
@export var death_sounds: Array[AudioStream] = []

@export_group("ドロップ")
@export var experience_value: int = 10
@export var score_value: int = 100
@export var drop_chance: float = 0.2 # アイテムドロップ率

@export_group("特殊能力")
@export var special_abilities: Array[String] = [] # "explode_on_death", "split", "heal_allies"等
@export var status_immunities: Array[String] = [] # "stun", "slow", "poison"等

func get_throw_force() -> float:
	# 重さに基づいて投擲力を計算
	return throw_speed / weight
