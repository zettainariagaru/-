class_name SpawnWave
extends Resource

# スポーンウェーブのデータ

@export var wave_time: float = 0.0 # いつこの波が始まるか
@export var monster_groups: Array[MonsterGroup] = []
@export var spawn_pattern: String = "random" # random, line, circle, sides
