extends Node2D

# エフェクトの設定
const RIPPLE_COLOR = Color(1, 1, 1, 0.5)
const RIPPLE_DURATION = 0.5
const PARTICLE_COUNT = 8

# タイルにリップルエフェクトを作成
func create_ripple_effect(position: Vector2, color: Color = RIPPLE_COLOR):
	var ripple = Node2D.new()
	ripple.position = position
	add_child(ripple)
	
	# リップルサークル
	for i in range(3):
		var circle = _create_ripple_circle()
		ripple.add_child(circle)
		
		# アニメーション
		var tween = create_tween()
		tween.set_parallel()
		
		# 遅延
		tween.tween_interval(i * 0.1)
		
		# スケールと透明度
		tween.chain()
		tween.tween_property(circle, "scale", Vector2(2.0, 2.0), RIPPLE_DURATION)
		tween.parallel().tween_property(circle, "modulate:a", 0.0, RIPPLE_DURATION)
		
		# 完了後に削除
		tween.tween_callback(circle.queue_free)
	
	# リップル全体を削除
	await get_tree().create_timer(RIPPLE_DURATION + 0.5).timeout
	ripple.queue_free()

func _create_ripple_circle() -> Node2D:
	var circle = Node2D.new()
	
	# ColorRectで円を近似
	var rect = ColorRect.new()
	rect.size = Vector2(64, 64)
	rect.position = -rect.size / 2
	rect.color = RIPPLE_COLOR
	rect.modulate.a = 0.5
	
	circle.add_child(rect)
	circle.scale = Vector2.ZERO
	
	return circle

# タイル破壊エフェクト
func create_tile_break_effect(position: Vector2, tile_color: Color):
	var particles = Node2D.new()
	particles.position = position
	add_child(particles)
	
	# パーティクルを生成
	for i in range(PARTICLE_COUNT):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = tile_color
		particle.position = -particle.size / 2
		
		var container = Node2D.new()
		container.add_child(particle)
		particles.add_child(container)
		
		# ランダムな方向に飛ばす
		var angle = (PI * 2.0 / PARTICLE_COUNT) * i + randf_range(-0.3, 0.3)
		var velocity = Vector2.from_angle(angle) * randf_range(100, 200)
		
		# アニメーション
		var tween = create_tween()
		tween.set_parallel()
		
		# 位置
		tween.tween_property(container, "position", container.position + velocity, 0.5)
		
		# 回転
		tween.tween_property(container, "rotation", randf_range(-PI, PI), 0.5)
		
		# スケールと透明度
		tween.tween_property(container, "scale", Vector2.ZERO, 0.5).set_delay(0.2)
		tween.tween_property(container, "modulate:a", 0.0, 0.5)
	
	# パーティクル全体を削除
	await get_tree().create_timer(0.6).timeout
	particles.queue_free()

# プレイヤー着地エフェクト
func create_landing_effect(position: Vector2):
	var effect = Node2D.new()
	effect.position = position
	add_child(effect)
	
	# 着地の衝撃波
	var shockwave = ColorRect.new()
	shockwave.size = Vector2(80, 20)
	shockwave.position = Vector2(-40, -10)
	shockwave.color = Color(1, 1, 1, 0.6)
	effect.add_child(shockwave)
	
	# アニメーション
	var tween = create_tween()
	tween.set_parallel()
	
	# 横に広がる
	tween.tween_property(shockwave, "scale:x", 1.5, 0.2)
	tween.tween_property(shockwave, "scale:y", 0.5, 0.2)
	
	# フェードアウト
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.3)
	
	# 削除
	tween.tween_callback(effect.queue_free)

# 敵撃破エフェクト
func create_enemy_defeat_effect(position: Vector2):
	create_tile_break_effect(position, Color.CRIMSON)
	create_ripple_effect(position, Color(1, 0.5, 0.5, 0.5))
