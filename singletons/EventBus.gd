extends Node

# ゲーム内イベントを中継するシグナルバス
# ノード間の疎結合を促進

# シグナルの定義例
signal player_health_changed(new_health: int)
signal monster_defeated(monster_type: String, position: Vector2)
signal combo_updated(combo_count: int)
signal score_updated(new_score: int)
signal game_state_changed(new_state: String)
signal monster_thrown(monster_data: Resource, from_position: Vector2, to_position: Vector2)
signal effect_requested(effect_type: String, position: Vector2)
