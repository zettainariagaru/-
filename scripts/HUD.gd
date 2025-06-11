extends CanvasLayer

# UI要素の参照
@onready var score_label: Label = $ScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var stage_label: Label = $StageLabel
@onready var state_label: Label = $StateLabel
@onready var message_container: Control = $MessageContainer
@onready var result_panel: Panel = $ResultPanel

# フォント設定
const FONT_SIZE_NORMAL = 24
const FONT_SIZE_LARGE = 32
const FONT_SIZE_MESSAGE = 48

func _ready():
	# UI要素が存在しない場合は作成
	_ensure_ui_elements()
	
	# GameManagerからのシグナルに接続
	var game_manager = get_node_or_null("../GameManager")
	if game_manager:
		game_manager.score_changed.connect(update_score)
		game_manager.lives_changed.connect(update_lives)
		game_manager.stage_changed.connect(update_stage)
		game_manager.state_changed.connect(update_game_state)

func _ensure_ui_elements():
	# スコアラベル
	if not score_label:
		score_label = _create_label("ScoreLabel", "Score: 0", Vector2(20, 20), FONT_SIZE_LARGE)
	
	# ライフラベル
	if not lives_label:
		lives_label = _create_label("LivesLabel", "Lives: 3", Vector2(20, 60), FONT_SIZE_NORMAL)
	
	# ステージラベル
	if not stage_label:
		stage_label = _create_label("StageLabel", "Stage: 1", Vector2(20, 95), FONT_SIZE_NORMAL)
	
	# 状態ラベル（デバッグ用）
	if not state_label:
		state_label = _create_label("StateLabel", "State: MENU", Vector2(20, 130), 18)
		state_label.modulate = Color(0.7, 0.7, 0.7)
	
	# メッセージコンテナ
	if not message_container:
		message_container = Control.new()
		message_container.name = "MessageContainer"
		message_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		add_child(message_container)
	
	# リザルトパネル
	if not result_panel:
		_create_result_panel()

func _create_label(name: String, text: String, pos: Vector2, font_size: int) -> Label:
	var label = Label.new()
	label.name = name
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func _create_result_panel():
	result_panel = Panel.new()
	result_panel.name = "ResultPanel"
	result_panel.visible = false
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.size = Vector2(400, 300)
	result_panel.position -= result_panel.size / 2
	add_child(result_panel)
	
	# リザルトタイトル
	var title = Label.new()
	title.text = "RESULT"
	title.add_theme_font_size_override("font_size", 36)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 20
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(title)
	
	# スコア表示
	var score_result = Label.new()
	score_result.name = "ScoreResult"
	score_result.add_theme_font_size_override("font_size", 24)
	score_result.position = Vector2(50, 100)
	result_panel.add_child(score_result)
	
	# 指示テキスト
	var instruction = Label.new()
	instruction.text = "Press ENTER to restart"
	instruction.add_theme_font_size_override("font_size", 18)
	instruction.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	instruction.position.y = -50
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(instruction)

func update_score(score: int):
	if score_label:
		score_label.text = "Score: %d" % score

func update_lives(lives: int):
	if lives_label:
		lives_label.text = "Lives: %d" % lives

func update_stage(stage: int):
	if stage_label:
		stage_label.text = "Stage: %d" % stage

func update_game_state(state: GameManager.GameState):
	if state_label:
		state_label.text = "State: %s" % GameManager.GameState.keys()[state]
	
	# リザルトパネルの表示/非表示
	if result_panel:
		result_panel.visible = (state == GameManager.GameState.RESULT)

func show_message(text: String, duration: float = 2.0):
	var message = Label.new()
	message.text = text
	message.add_theme_font_size_override("font_size", FONT_SIZE_MESSAGE)
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# アウトライン効果を追加
	message.add_theme_color_override("font_shadow_color", Color.BLACK)
	message.add_theme_constant_override("shadow_offset_x", 2)
	message.add_theme_constant_override("shadow_offset_y", 2)
	
	message_container.add_child(message)
	
	# フェードインアニメーション
	message.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(message, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration - 0.6)
	tween.tween_property(message, "modulate:a", 0.0, 0.3)
	tween.tween_callback(message.queue_free)

func show_result(final_score: int, final_stage: int):
	if not result_panel:
		return
	
	var score_result = result_panel.get_node_or_null("ScoreResult")
	if score_result:
		score_result.text = "Final Score: %d\nReached Stage: %d" % [final_score, final_stage]
	
	result_panel.visible = true
