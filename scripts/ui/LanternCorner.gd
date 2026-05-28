extends Node2D
class_name LanternCorner
## 四角悬挂灯笼装饰：圆灯笼 + 顶部流苏 + 摇摆动画。

@export var size: float = 1.0  # 缩放
var _t: float = 0.0
var _swing: float = 0.0

func _ready() -> void:
	_swing = randf_range(0.0, TAU)
	z_index = 6
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var sw: float = sin(_t * 1.4 + _swing) * 0.08
	# 顶部挂线
	draw_line(Vector2(0, 0), Vector2(0, 18 * size), Color("#3a1a08"), 2)
	# 灯笼主体 (椭圆)
	var c: Vector2 = Vector2(sin(sw) * 4 * size, 18 * size + 28 * size)
	for i in range(20, 0, -1):
		var t: float = float(i) / 20.0
		var col: Color = Color("#ffd700").lerp(Color("#c0392b"), t)
		_draw_ellipse(c, Vector2(28 * size * (1 - t * 0.05), 32 * size * (1 - t * 0.02)), col)
	# 上下金边
	_draw_ellipse(c + Vector2(0, -32 * size), Vector2(20 * size, 5 * size), Color("#7a5b08"))
	_draw_ellipse(c + Vector2(0, 32 * size), Vector2(20 * size, 5 * size), Color("#7a5b08"))
	# 福字
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(20 * size)
	var ch: String = "福"
	var ts: Vector2 = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, c + Vector2(-ts.x * 0.5, ts.y * 0.3), ch,
		HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color("#ffd700"))
	# 流苏
	var t_top: Vector2 = c + Vector2(0, 32 * size)
	for i in 4:
		var x: float = -10 * size + i * 6 * size
		draw_line(t_top + Vector2(x, 0), t_top + Vector2(x + sin(sw + i) * 2, 16 * size),
			Color("#f1c40f"), 2)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var n := 28
	for i in n:
		var a: float = TAU * float(i) / n
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
