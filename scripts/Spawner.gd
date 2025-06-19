extends Node

# レベルデータに基づく敵生成スクリプト

# エクスポート変数
@export var level_data: GameLevelData  # LevelDataから変更
@export var monster_scene: PackedScene = preload("res://scenes/Monster.tscn")

# 内部変数
var current_wave_index: int = 0
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var active_monsters: Array[Node] = []
var level_started: bool = false
var all_waves_spawned: bool = false

# スポーン位置
var spawn_points: Array[Vector2] = []
var lane_positions: Array[float] = [-200.0, 0.0, 200.0] # 3レーン

# 親ノードの参照
@onready var entities_parent: Node2D = $"../YSort/Entities"
@onready var gimmicks_parent: Node2D = $"../YSort/Gimmicks"

func _ready() -> void:
	if not level_data:
		push_error("LevelData not set in Spawner!")
		return
		
	_setup_spawn_points()
	_setup_gimmicks()
	_connect_signals()

func _setup_spawn_points() -> void:
	# スポーンポイントの設定（画面右端の3レーン）
	var viewport_size = get_viewport().size
	for lane_y in lane_positions:
		spawn_points.append(Vector2(viewport_size.x + 100, viewport_size.y/2 + lane_y))

func _setup_gimmicks() -> void:
	# レベルデータからギミックを配置
	for gimmick_data in level_data.gimmick_positions:
		_spawn_gimmick(gimmick_data)

func _connect_signals() -> void:
	# EventBusが存在する場合のみ接続
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.game_state_changed.connect(_on_game_state_changed)
		event_bus.monster_defeated.connect(_on_monster_defeated)

func _process(delta: float) -> void:
	if not level_started or all_waves_spawned:
		return
		
	wave_timer += delta
	spawn_timer += delta
	
	# 現在のウェーブをチェック
	if current_wave_index < level_data.spawn_waves.size():
		var current_wave = level_data.spawn_waves[current_wave_index]
		
		if wave_timer >= current_wave.wave_time:
			_spawn_wave(current_wave)
			current_wave_index += 1
			
			if current_wave_index >= level_data.spawn_waves.size():
				all_waves_spawned = true
				_check_level_completion()

func _spawn_wave(wave: SpawnWave) -> void:
	print("Spawning wave at time: ", wave.wave_time)
	
	for monster_group in wave.monster_groups:
		_spawn_monster_group(monster_group, wave.spawn_pattern)

func _spawn_monster_group(group: MonsterGroup, pattern: String) -> void:
	var positions = _get_spawn_positions(group.count, pattern, group.spawn_positions)
	
	for i in range(group.count):
		if active_monsters.size() >= level_data.max_enemies_on_screen:
			break
			
		var monster = monster_scene.instantiate()
		monster.monster_data = group.monster_data
		monster.position = positions[i] if i < positions.size() else _get_random_spawn_point()
		
		entities_parent.add_child(monster)
		active_monsters.append(monster)
		
		# モンスターが削除されたときの処理
		monster.tree_exited.connect(_on_monster_removed.bind(monster))

func _get_spawn_positions(count: int, pattern: String, custom_positions: Array) -> Array[Vector2]:
	if not custom_positions.is_empty():
		return custom_positions
		
	var positions: Array[Vector2] = []
	
	match pattern:
		"random":
			for i in count:
				positions.append(_get_random_spawn_point())
		
		"line":
			# 横一列に配置
			var lane = randi() % 3
			for i in count:
				var pos = spawn_points[lane]
				pos.x += i * 50
				positions.append(pos)
		
		"circle":
			# 円形に配置
			var center = _get_random_spawn_point()
			var radius = 100.0
			for i in count:
				var angle = (TAU / count) * i
				var offset = Vector2(cos(angle), sin(angle)) * radius
				positions.append(center + offset)
		
		"sides":
			# 上下のレーンに分散
			for i in count:
				var lane = 0 if i % 2 == 0 else 2
				var pos = spawn_points[lane]
				pos.x += (i / 2) * 50
				positions.append(pos)
		
		_:
			# デフォルトはランダム
			for i in count:
				positions.append(_get_random_spawn_point())
	
	return positions

func _get_random_spawn_point() -> Vector2:
	return spawn_points[randi() % spawn_points.size()]

func _spawn_gimmick(gimmick_data: GimmickPlacement) -> void:
	# ギミックの種類に応じて生成
	var gimmick: Node2D
	
	match gimmick_data.gimmick_type:
		"explosive_barrel":
			gimmick = _create_explosive_barrel()
		"heal_station":
			gimmick = _create_heal_station()
		"speed_boost":
			gimmick = _create_speed_boost()
		_:
			return
	
	if gimmick:
		gimmick.position = gimmick_data.position
		# プロパティの適用
		for key in gimmick_data.properties:
			if gimmick.has_method("set_" + key):
				gimmick.call("set_" + key, gimmick_data.properties[key])
		
		gimmicks_parent.add_child(gimmick)

func _create_explosive_barrel() -> Node2D:
	# 爆発樽のギミック作成
	var barrel = Area2D.new()
	barrel.name = "ExplosiveBarrel"
	
	var sprite = Sprite2D.new()
	sprite.modulate = Color.RED
	barrel.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	barrel.add_child(collision)
	
	# 爆発処理のスクリプトを追加
	barrel.set_script(preload("res://scripts/gimmicks/ExplosiveBarrel.gd"))
	
	return barrel

func _create_heal_station() -> Node2D:
	# 回復ステーション作成
	var station = Area2D.new()
	station.name = "HealStation"
	# 実装は省略
	return station

func _create_speed_boost() -> Node2D:
	# スピードブースト作成
	var boost = Area2D.new()
	boost.name = "SpeedBoost"
	# 実装は省略
	return boost

func _on_monster_removed(monster: Node) -> void:
	active_monsters.erase(monster)
	_check_level_completion()

func _check_level_completion() -> void:
	if not all_waves_spawned:
		return
		
	if level_data.clear_condition == "defeat_all" and active_monsters.is_empty():
		_level_completed()

func _level_completed() -> void:
	print("Level completed!")
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.game_state_changed.emit("victory")

func start_spawning() -> void:
	level_started = true
	wave_timer = 0.0
	print("Spawner started for level: ", level_data.level_name)

func stop_spawning() -> void:
	level_started = false

func _on_game_state_changed(state: String) -> void:
	match state:
		"playing":
			start_spawning()
		"paused", "game_over", "victory":
			stop_spawning()

func _on_monster_defeated(monster_name: String, position: Vector2) -> void:
	# モンスターが倒された時の処理
	pass

# デバッグ用
func get_active_monster_count() -> int:
	return active_monsters.size()

func force_spawn_wave(wave_index: int) -> void:
	if wave_index < level_data.spawn_waves.size():
		_spawn_wave(level_data.spawn_waves[wave_index])
