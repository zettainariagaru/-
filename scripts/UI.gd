extends CanvasLayer

# UIコンポーネント
var score_label: Label
var lives_label: Label
var stage_label: Label
var message_label: Label
var result_panel: Panel
var state_label: Label  # デバッグ用
var position_label: Label  # プレイヤー位置表示
var controls_panel: Panel  # 操作ガイド

func _ready():
	# UI要素を作成
	_create_ui_elements()
	
	# GameManagerのシグナルに接続
	var gm = get_node_or_null("../GameManager")
	if gm:
		if gm.has_signal("score_changed"):
			gm.connect("score_changed", update_score)
		if gm.has_signal("lives_changed"):
			gm.connect("lives_changed", update_lives)
		if gm.has_signal("stage_changed"):
			gm.connect("stage_changed", update_stage)
		if gm.has_signal("state_changed"):
			gm.connect("state_changed", update_game_state)
	
	# プレイヤーのシグナルに接続
	var player = get_node_or_null("../Game/Player")
	if player:
		if player.has_signal("moved"):
			player.connect("moved", _on_player_moved)

func _create_ui_elements():
	# 基本UI要素
	_create_basic_ui()
	
	# 位置表示ラベル
	position_label = Label.new()
	position_label.name = "PositionLabel"
	position_label.text = "Position: Tile 2, Lane 1"
	position_label.position = Vector2(20, 160)
	position_label.add_theme_font_size_override("font_size", 20)
	position_label.modulate = Color(0.9, 0.9, 1.0)
	add_child(position_label)
	
	# 操作ガイドパネル
	_create_controls_panel()
	
	# メッセージラベル（中央）
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.visible = false
	message_label.add_theme_font_size_override("font_size", 48)
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(message_label)
	
	# リザルトパネル
	_create_result_panel()

func _create_basic_ui():
	# スコアラベル
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", 28)
	add_child(score_label)
	
	# ライフラベル
	lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "♥♥♥"  # ハートで表示
	lives_label.position = Vector2(20, 60)
	lives_label.add_theme_font_size_override("font_size", 32)
	lives_label.modulate = Color(1, 0.3, 0.3)
	add_child(lives_label)
	
	# ステージラベル
	stage_label = Label.new()
	stage_label.name = "StageLabel"
	stage_label.text = "Stage: 1"
	stage_label.position = Vector2(20, 100)
	stage_label.add_theme_font_size_override("font_size", 24)
	add_child(stage_label)
	
	# 状態ラベル（デバッグ用）
	if OS.is_debug_build():
		state_label = Label.new()
		state_label.name = "StateLabel"
		state_label.text = "State: MENU"
		state_label.position = Vector2(20, 130)
		state_label.add_theme_font_size_override("font_size", 18)
		state_label.modulate = Color(0.7, 0.7, 0.7)
		add_child(state_label)

func _create_controls_panel():
	controls_panel = Panel.new()
	controls_panel.name = "ControlsPanel"
	controls_panel.custom_minimum_size = Vector2(200, 120)
	controls_panel.position = Vector2(1050, 20)
	controls_panel.modulate = Color(1, 1, 1, 0.8)
	add_child(controls_panel)
	
	# タイトル
	var title = Label.new()
	title.text = "Controls"
	title.position = Vector2(10, 10)
	title.add_theme_font_size_override("font_size", 20)
	controls_panel.add_child(title)
	
	# 操作説明
	var controls_text = Label.new()
	controls_text.text = "← → : Move Tiles\n↑ ↓ : Change Lanes\nWASD : Alternative"
	controls_text.position = Vector2(10, 40)
	controls_text.add_theme_font_size_override("font_size", 16)
	controls_panel.add_child(controls_text)

func _create_result_panel():
	result_panel = Panel.new()
	result_panel.name = "ResultPanel"
	result_panel.visible = false
	result_panel.custom_minimum_size = Vector2(400, 300)
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(result_panel)
	
	# タイトル
	var title = Label.new()
	title.text = "GAME RESULT"
	title.add_theme_font_size_override("font_size", 36)
	title.position = Vector2(100, 30)
	result_panel.add_child(title)
	
	# 結果テキスト
	var result_text = Label.new()
	result_text.name = "ResultText"
	result_text.add_theme_font_size_override("font_size", 24)
	result_text.position = Vector2(50, 100)
	result_panel.add_child(result_text)
	
	# 指示
	var instruction = Label.new()
	instruction.text = "Press ENTER to play again"
	instruction.add_theme_font_size_override("font_size", 18)
	instruction.position = Vector2(80, 240)
	result_panel.add_child(instruction)

func update_score(score: int):
	if score_label:
		score_label.text = "Score: %d" % score

func update_lives(lives: int):
	if lives_label:
		var hearts = ""
		for i in range(lives):
			hearts += "♥"
		for i in range(3 - lives):
			hearts += "♡"  # 空のハート
		lives_label.text = hearts

func update_stage(stage: int):
	if stage_label:
		stage_label.text = "Stage: %d" % stage

func update_game_state(state: GameManager.State):
	# デバッグ表示を更新
	if state_label:
		var state_names = ["MENU", "STARTING", "PLAYING", "PAUSED", "CLEAR", "OVER", "RESULT"]
		state_label.text = "State: %s" % state_names[state]
	
	# リザルトパネルの表示/非表示
	if result_panel:
		result_panel.visible = (state == GameManager.State.RESULT)
	
	# 操作ガイドの表示/非表示
	if controls_panel:
		controls_panel.visible = (state == GameManager.State.PLAYING or state == GameManager.State.STARTING)
	
	# ゲーム終了時にリザルトを更新
	if state == GameManager.State.RESULT:
		var gm = get_node_or_null("../GameManager")
		if gm:
			show_result(gm.score, gm.stage)

func _on_player_moved(tile_x: int, lane: int):
	if position_label:
		var lane_names = ["Bottom", "Middle", "Top"]
		position_label.text = "Position: Tile %d, %s Lane" % [tile_x, lane_names[lane]]

func show_message(text: String, duration: float = 2.0):
	if not message_label:
		return
	
	message_label.text = text
	message_label.visible = true
	
	# フェードアニメーション
	message_label.modulate.a = 0
	message_label.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	# フェードイン + スケールアップ
	tween.parallel().tween_property(message_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(message_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 待機
	tween.tween_interval(duration - 0.6)
	# フェードアウト
	tween.tween_property(message_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): message_label.visible = false)

func show_result(score: int, stage: int):
	if not result_panel:
		return
	
	var result_text = result_panel.get_node_or_null("ResultText")
	if result_text:
		result_text.text = "Final Score: %d\nReached Stage: %d" % [score, stage]
	
	result_panel.visible = true

func hide_result():
	if result_panel:
		result_panel.visible = false
