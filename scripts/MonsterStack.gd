class_name MonsterStack
extends Node

# スタック管理
var monster_stack: Array[ThrowableMonster] = []
var max_stack_size: int = 2
var stack_owner: Node3D = null

# スタック配置設定
@export var stack_offset: Vector3 = Vector3(0, 0.8, -0.3)  # 各モンスター間のオフセット
@export var carry_base_position: Vector3 = Vector3(0, 1.2, -0.5)  # 基準位置

# シグナル
signal stack_changed(stack: Array[ThrowableMonster])
signal stack_full()
signal monster_added_to_stack(monster: ThrowableMonster, position: int)
signal monster_removed_from_stack(monster: ThrowableMonster, position: int)

func _init(owner: Node3D, max_size: int = 2):
	stack_owner = owner
	max_stack_size = max_size

# スタック容量計算（重量ベース）
func calculate_stack_capacity(base_capacity: int, strength_modifier: float = 1.0) -> int:
	return int(base_capacity * strength_modifier)

# 重量制限チェック
func can_add_monster(monster: ThrowableMonster) -> bool:
	if monster_stack.size() >= max_stack_size:
		return false
	
	var total_weight = get_total_weight()
	var monster_weight = monster.get_weight()
	var weight_limit = max_stack_size * 2.0  # 仮の重量制限
	
	return (total_weight + monster_weight) <= weight_limit

# モンスターをスタックに追加
func add_monster(monster: ThrowableMonster) -> bool:
	if not can_add_monster(monster):
		if monster_stack.size() >= max_stack_size:
			stack_full.emit()
		return false
	
	monster_stack.append(monster)
	var stack_position = monster_stack.size() - 1
	
	# スタック位置を更新
	_update_stack_positions()
	
	monster_added_to_stack.emit(monster, stack_position)
	stack_changed.emit(monster_stack)
	
	return true

# モンスターをスタックから削除
func remove_monster(index: int = -1) -> ThrowableMonster:
	if monster_stack.is_empty():
		return null
	
	# デフォルトは最上位（最後に追加されたもの）
	if index == -1:
		index = monster_stack.size() - 1
	
	if index < 0 or index >= monster_stack.size():
		return null
	
	var removed_monster = monster_stack[index]
	monster_stack.remove_at(index)
	
	# 残りのモンスターの位置を更新
	_update_stack_positions()
	
	monster_removed_from_stack.emit(removed_monster, index)
	stack_changed.emit(monster_stack)
	
	return removed_monster

# スタック内のモンスター順序を入れ替え
func swap_monsters(index1: int, index2: int) -> bool:
	if index1 < 0 or index1 >= monster_stack.size() or 
	   index2 < 0 or index2 >= monster_stack.size():
		return false
	
	if index1 == index2:
		return true
	
	# 位置を交換
	var temp = monster_stack[index1]
	monster_stack[index1] = monster_stack[index2]
	monster_stack[index2] = temp
	
	_update_stack_positions()
	stack_changed.emit(monster_stack)
	
	return true

# 最上位のモンスターを取得（投げる用）
func get_top_monster() -> ThrowableMonster:
	if monster_stack.is_empty():
		return null
	return monster_stack.back()

# 指定インデックスのモンスターを取得
func get_monster_at(index: int) -> ThrowableMonster:
	if index < 0 or index >= monster_stack.size():
		return null
	return monster_stack[index]

# スタックサイズ取得
func get_stack_size() -> int:
	return monster_stack.size()

# 総重量計算
func get_total_weight() -> float:
	var total = 0.0
	for monster in monster_stack:
		total += monster.get_weight()
	return total

# スタック内のモンスター位置を更新
func _update_stack_positions():
	if not stack_owner:
		return
	
	for i in range(monster_stack.size()):
		var monster = monster_stack[i]
		var carry_position = _calculate_carry_position(i)
		
		if monster.current_state == ThrowableMonster.MonsterState.CARRIED:
			monster.global_position = carry_position
		
		monster.stack_position = i

# 担ぎ位置計算
func _calculate_carry_position(stack_index: int) -> Vector3:
	if not stack_owner:
		return Vector3.ZERO
	
	var base_pos = stack_owner.global_position + carry_base_position
	var offset = stack_offset * stack_index
	
	return base_pos + offset

# スタック情報取得（デバッグ用）
func get_stack_info() -> Dictionary:
	var info = {
		"size": monster_stack.size(),
		"max_size": max_stack_size,
		"total_weight": get_total_weight(),
		"monsters": []
	}
	
	for i in range(monster_stack.size()):
		var monster = monster_stack[i]
		info.monsters.append({
			"index": i,
			"name": monster.get_display_name(),
			"weight": monster.get_weight(),
			"element": monster.get_element_type()
		})
	
	return info

# スタック最適化（重量バランス調整）
func optimize_stack_order():
	if monster_stack.size() <= 1:
		return
	
	# 重いモンスターを下に、軽いモンスターを上に
	monster_stack.sort_custom(func(a, b): return a.get_weight() > b.get_weight())
	
	_update_stack_positions()
	stack_changed.emit(monster_stack)

# スタック全体をクリア
func clear_stack():
	for monster in monster_stack:
		if monster:
			monster.set_state(ThrowableMonster.MonsterState.FREE)
	
	monster_stack.clear()
	stack_changed.emit(monster_stack)

# 特定の属性のモンスターを検索
func find_monsters_by_element(element: MonsterData.ElementType) -> Array[ThrowableMonster]:
	var result: Array[ThrowableMonster] = []
	
	for monster in monster_stack:
		if monster.get_element_type() == element:
			result.append(monster)
	
	return result

# スタック内のモンスター移動（上下入れ替え）
func move_monster_up(index: int) -> bool:
	if index <= 0 or index >= monster_stack.size():
		return false
	
	return swap_monsters(index, index - 1)

func move_monster_down(index: int) -> bool:
	if index < 0 or index >= monster_stack.size() - 1:
		return false
	
	return swap_monsters(index, index + 1)
