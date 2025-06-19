extends Resource
# GimmickData - ギミックの配置情報を定義するリソース

class_name GimmickData

# ギミックタイプ
@export var gimmick_type: String = "explosive_barrel"  # explosive_barrel, switch, trap, etc.
@export var gimmick_name: String = "Explosive Barrel"

# 配置情報
@export var position: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE

# ギミック固有のプロパティ
@export var properties: Dictionary = {
	"damage": 50,
	"radius": 100.0,
	"trigger_type": "impact",  # impact, proximity, timer
	"respawn_time": 0.0  # 0で再出現なし
}

# 視覚効果
@export var vfx_on_trigger: String = "explosion"
@export var sound_on_trigger: AudioStream
