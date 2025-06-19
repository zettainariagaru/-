extends CanvasLayer

# UI更新の管理スクリプト

# UI要素の参照
@onready var hud: Control = $HUD
@onready var stack_ui: Control = $StackUI
@onready var combo_vfx: Control = $ComboVFX
@onready var pause_menu: Control = $PauseMenu

# HUD内の要素（後で追加）
var health_bar: ProgressBar
var score_label: Label
var time_label: Label
var combo_label: Label
var position_label: Label  # 追加：位置情報表示用

# 内部変数
var current_score: int = 0
var current_combo: int = 0
var combo_timer: float = 0.0
var game_time: float = 0.0
var is_paused: bool = false

# プレイヤー参照
var player: CharacterBody2D

# コンボ関連
const COMBO_TIMEOUT: float = 2.0
const COMBO_MULTIPLIER_THRESHOLDS: Array[int] = [5, 10, 20, 50]

func _ready() -> void:
	_setup_ui_elements()
	_connect_signals()
	pause_menu.visible = false
	
	# プレイヤーを取得
	player = get_tree().current_scene.get_node_or_null("Player")

func _setup_ui_elements() -> void:
	# HUDの基本構造を作成
	_create_hud_elements()
	_create_stack_ui()
	_create_combo_vfx()

func _create_hud_elements() -> void:
	# メインHUDコンテナ
	var hud_container = VBoxContainer.new()
	hud_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_container.position = Vector2(20, 20)
	hud.add_child(hud_container)
	
	# 体力バー
	var health_container = HBoxContainer.new()
	hud_container.add_child(health_container)
	
	var health_icon = Label.new()
	health_icon.text = "❤️"
	health_container.add_child(health_icon)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(200, 20)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.modulate = Color.RED
	health_container.add_child(health_bar)
	
	# スコア表示
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 24)
	hud_container.add_child(score_label)
	
	# 時間表示
	time_label = Label.new()
	time_label.text = "Time: 0:00"
	time_label.add_theme_font_size_override("font_size", 20)
	hud_container.add_child(time_label)
	
	# 位置情報表示を追加
	position_label = Label.new()
	position_label.text = "Lane: - | Tile: -"
	position_label.add_theme_font_size_override("font_size", 18)
	position_label.modulate = Color(0.8, 0.8, 1.0)
	hud_container.add_child(position_label)
	
	# コンボ表示
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 32)
	combo_label.modulate = Color.YELLOW
	combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	combo_label.position = Vector2(-150, 20)
	hud.add_child(combo_label)

func _create_stack_ui() -> void:
	# スタックUI（担いでいるモンスター表示）
	var stack_container = HBoxContainer.new()
	stack_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stack_container.position = Vector2(20, -100)
	stack_ui.add_child(stack_container)
	
	# スタックアイコンを5個作成
	for i in range(5):
		var stack_icon = TextureRect.new()
		stack_icon.custom_minimum_size = Vector2(48, 48)
		stack_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		stack_icon.modulate = Color(1, 1, 1, 0.3)
		stack_icon.name = "StackIcon" + str(i)
		stack_container.add_child(stack_icon)

func _create_combo_vfx() -> void:
	# コンボエフェクト用のラベル
	var combo_effect_label = Label.new()
	combo_effect_label.name = "ComboEffect"
	combo_effect_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_effect_label.add_theme_font_size_override("font_size", 64)
	combo_effect_label.modulate = Color(1, 1, 0, 0)
	combo_vfx.add_child(combo_effect_label)

func _connect_signals() -> void:
	# EventBusのシグナルに接続
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.player_health_changed.connect(_on_player_health_changed)
		event_bus.score_updated.connect(_on_score_updated)
		event_bus.combo_updated.connect(_on_combo_updated)
		event_bus.monster_defeated.connect(_on_monster_defeated)
		event_bus.game_state_changed.connect(_on_game_state_changed)

func _process(delta: float) -> void:
	if not is_paused:
		game_time += delta
		_update_time_display()
		_update_position_display()
		
		# コンボタイマーの更新
		if combo_timer > 0:
			combo_timer -= delta
			if combo_timer <= 0:
				_reset_combo()

func _update_time_display() -> void:
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	time_label.text = "Time: %d:%02d" % [minutes, seconds]

func _update_position_display() -> void:
	if not player or not player.has_method("get_current_tile_info"):
		return
		
	var tile_info = player.get_current_tile_info()
	var lane_names = ["Top", "Middle", "Bottom"]
	var lane_index = tile_info.get("lane", -1)
	
	if lane_index >= 0 and lane_index < lane_names.size():
		var lane_name = lane_names[lane_index]
		var tile_x = tile_info.get("position_in_lane", 0)
		position_label.text = "Lane: %s | Tile: %d" % [lane_name, tile_x]
	else:
		position_label.text = "Lane: - | Tile: -"

func _on_player_health_changed(new_health: int) -> void:
	health_bar.value = new_health
	
	# 低体力時の警告
	if new_health <= 20:
		health_bar.modulate = Color(1, 0.3, 0.3)
		_pulse_element(health_bar)

func _on_score_updated(points: int) -> void:
	var bonus = _calculate_combo_bonus(points)
	current_score += points + bonus
	score_label.text = "Score: %d" % current_score
	
	# スコア増加アニメーション
	_show_score_popup(points + bonus)

func _on_combo_updated(stack_count: int) -> void:
	# スタックUIの更新
	var stack_container = stack_ui.get_child(0)
	for i in range(5):
		var icon = stack_container.get_child(i)
		icon.modulate = Color.WHITE if i < stack_count else Color(1, 1, 1, 0.3)

func _on_monster_defeated(monster_name: String, position: Vector2) -> void:
	current_combo += 1
	combo_timer = COMBO_TIMEOUT
	_update_combo_display()
	
	# コンボマイルストーンでの特殊エフェクト
	if current_combo in COMBO_MULTIPLIER_THRESHOLDS:
		_show_combo_milestone(current_combo)

func _update_combo_display() -> void:
	if current_combo > 1:
		combo_label.text = "COMBO x%d" % current_combo
		combo_label.visible = true
		
		# コンボ数に応じて色を変更
		if current_combo >= 50:
			combo_label.modulate = Color.GOLD
		elif current_combo >= 20:
			combo_label.modulate = Color.ORANGE
		elif current_combo >= 10:
			combo_label.modulate = Color.YELLOW
		else:
			combo_label.modulate = Color.WHITE
	else:
		combo_label.visible = false

func _reset_combo() -> void:
	current_combo = 0
	combo_label.visible = false

func _calculate_combo_bonus(base_score: int) -> int:
	if current_combo <= 1:
		return 0
		
	var multiplier = 1.0
	for threshold in COMBO_MULTIPLIER_THRESHOLDS:
		if current_combo >= threshold:
			multiplier += 0.5
	
	return int(base_score * (multiplier - 1))

func _show_score_popup(score: int) -> void:
	var popup = Label.new()
	popup.text = "+%d" % score
	popup.add_theme_font_size_override("font_size", 28)
	popup.modulate = Color.YELLOW
	popup.position = score_label.global_position + Vector2(100, 0)
	hud.add_child(popup)
	
	# アニメーション
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(popup, "position", popup.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup.queue_free)

func _show_combo_milestone(combo: int) -> void:
	var effect_label = combo_vfx.get_node("ComboEffect")
	effect_label.text = "COMBO x%d!" % combo
	effect_label.modulate.a = 1.0
	
	# 画面全体のフラッシュエフェクト
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	combo_vfx.add_child(flash)
	
	var tween = get_tree().create_tween()
	tween.tween_property(effect_label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(effect_label, "scale", Vector2(1, 1), 0.2)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(flash.queue_free)

func _pulse_element(element: Control) -> void:
	var tween = get_tree().create_tween()
	tween.set_loops(3)
	tween.tween_property(element, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(element, "scale", Vector2(1, 1), 0.2)

func _on_game_state_changed(new_state: String) -> void:
	match new_state:
		"paused":
			is_paused = true
			pause_menu.visible = true
		"playing":
			is_paused = false
			pause_menu.visible = false
		"game_over":
			_show_game_over_screen()
		"victory":
			_show_victory_screen()

func _show_game_over_screen() -> void:
	# ゲームオーバー画面の表示
	pause_menu.visible = true
	# 実装は別途

func _show_victory_screen() -> void:
	# 勝利画面の表示
	pause_menu.visible = true
	# 実装は別途
