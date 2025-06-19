class_name MonsterGroup
extends Resource

# モンスターグループのデータ

@export var monster_data: MonsterData
@export var count: int = 1
@export var spawn_positions: Array[Vector2] = [] # 空の場合はランダム
