extends Node

# 様々なオブジェクトプールを管理する親ノード

@onready var vfx_pool: Node = $VfxPool
@onready var projectile_pool: Node = $ProjectilePool

func _ready() -> void:
	# 各プールの初期化
	_initialize_pools()

func _initialize_pools() -> void:
	# プールの初期化処理
	pass

# VFXを取得
func get_vfx(vfx_type: String) -> Node:
	return vfx_pool.get_instance(vfx_type)

# VFXを返却
func return_vfx(vfx_instance: Node) -> void:
	vfx_pool.return_instance(vfx_instance)

# 投擲物を取得
func get_projectile(projectile_type: String) -> Node:
	return projectile_pool.get_instance(projectile_type)

# 投擲物を返却
func return_projectile(projectile_instance: Node) -> void:
	projectile_pool.return_instance(projectile_instance)
