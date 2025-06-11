extends Node2D

var score = 0
@onready var score_label = $UI/ScoreLabel
@onready var player = $Player

func _ready():
	# ゲーム開始時の初期化
	update_score_display()

func _process(delta):
	# ゲームのメインループ処理
	pass

func add_score(points):
	score += points
	update_score_display()

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(score)

func game_over():
	print("Game Over! Final Score: ", score)
	# ゲームオーバー処理をここに追加
