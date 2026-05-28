extends Node2D
class_name CoinParticle
## 一次性金币掉落粒子（用 CPUParticles2D 包装），自动 free。

static func emit_at(parent: CanvasItem, world_pos: Vector2, count: int = 12) -> void:
	var p := CPUParticles2D.new()
	p.position = world_pos
	p.amount = count
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 1.2
	p.direction = Vector2(0, -1)
	p.spread = 35.0
	p.gravity = Vector2(0, 600)
	p.initial_velocity_min = 220
	p.initial_velocity_max = 360
	p.scale_amount_min = 1.6
	p.scale_amount_max = 2.4
	p.color = Color("#ffd700")
	# 给粒子贴一个金币纹理（程序生成）
	p.texture = _coin_texture()
	parent.add_child(p)
	p.emitting = true
	# 1.5 秒后清理
	var t: SceneTreeTimer = parent.get_tree().create_timer(1.5)
	t.timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free())

static var _coin_tex_cache: Texture2D = null
static func _coin_texture() -> Texture2D:
	if _coin_tex_cache != null:
		return _coin_tex_cache
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 20:
		for x in 20:
			var d: float = Vector2(x - 10, y - 10).length()
			if d <= 9.0:
				var t: float = d / 9.0
				img.set_pixel(x, y, Color("#ffe98a").lerp(Color("#c19009"), t))
			elif d <= 10.0:
				img.set_pixel(x, y, Color("#7a5b08"))
	_coin_tex_cache = ImageTexture.create_from_image(img)
	return _coin_tex_cache
