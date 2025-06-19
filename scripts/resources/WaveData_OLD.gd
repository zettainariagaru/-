extends Resource
# WaveData - 敵の出現ウェーブを定義するリソース

class_name WaveData

# ウェーブ情報
@export var wave_name: String = "Wave 1"
@export var start_time: float = 0.0  # ウェーブ開始時間（秒）
@export var wave_duration: float = 30.0  # ウェーブの継続時間

# モンスタースポーンデータ
@export var monsters: Array[MonsterSpawnData] = []

# ギミックデータ
@export var gimmicks: Array[GimmickData] = []

# 特殊条件
@export var spawn_condition: String = ""  # 特定の条件でのみスポーン
@export var environmental_effect: String = ""  # 霧、雨、暗闇などの環境効果
