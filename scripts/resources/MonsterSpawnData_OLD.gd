extends Resource
# MonsterSpawnData - モンスターのスポーン情報を定義するリソース

class_name MonsterSpawnData

# スポーンするモンスター
@export var monster_data: MonsterData

# スポーン設定
@export var count: int = 1  # スポーン数
@export var spawn_interval: float = 0.5  # 複数体の場合の間隔
@export var spawn_point: int = -1  # スポーン位置インデックス（-1でランダム）
@export var random_offset: float = 50.0  # スポーン位置のランダムオフセット

# 特殊設定
@export var initial_state: String = "wander"  # 初期AI状態
@export var patrol_path: Array[Vector2] = []  # パトロールルート
@export var buff_multipliers: Dictionary = {
	"health": 1.0,
	"speed": 1.0,
	"damage": 1.0
}
