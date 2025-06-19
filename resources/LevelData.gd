class_name GameLevelData  # LevelDataから変更
extends Resource

# レベルの構成データを定義するリソース

@export_group("レベル情報")
@export var level_name: String = "Level 1"
@export var level_description: String = ""
@export var difficulty: int = 1
@export var time_limit: float = 300.0 # 秒単位（0で無制限）

@export_group("背景設定")
@export var background_layers: Array[Texture2D] = []
@export var background_speeds: Array[float] = [0.2, 0.5, 0.8] # パララックス速度
@export var ambient_color: Color = Color.WHITE

@export_group("スポーン設定")
@export var spawn_waves: Array[SpawnWave] = []
@export var spawn_interval: float = 2.0 # 波間の間隔
@export var max_enemies_on_screen: int = 10

@export_group("ギミック配置")
@export var gimmick_positions: Array[GimmickPlacement] = []

@export_group("目標設定")
@export var clear_condition: String = "defeat_all" # defeat_all, survive_time, reach_goal, defeat_boss
@export var target_score: int = 10000
@export var bonus_objectives: Array[String] = [] # "no_damage", "time_limit", "combo_50"

@export_group("報酬")
@export var completion_reward: int = 1000
@export var time_bonus_multiplier: float = 2.0
@export var perfect_clear_bonus: int = 5000
