extends Node2D
class_name PlayerToken
## 棋子：用 AI 生成的 chibi 角色 sprite（已抠白底），idle 浮动 + 移动时左右晃动模拟走路。

const CHIBI_PATHS := [
	"res://assets/store/mp/red.png",
	"res://assets/store/mp/blue.png",
	"res://assets/store/mp/green.png",
]

@export var char_set_index: int = 0
@export var display_name: String = ""

const RENDER_HEIGHT := 80.0

var _t: float = 0.0
var _scale_anim: float = 1.0
var _glow: float = 0.0
var _facing_left: bool = false
var _walk_amount: float = 0.0  # 0 站立、1 走路（走动时增加）

func _ready() -> void:
	z_index = 10
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	# walk 衰减
	_walk_amount = max(0.0, _walk_amount - delta * 3.0)
	queue_redraw()

func play_squash() -> void:
	# 启动一次走路动画（持续 ~0.4 秒）
	_walk_amount = 1.0
	var tw := create_tween()
	tw.tween_property(self, "_scale_anim", 1.06, 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_scale_anim", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_facing(left: bool) -> void:
	_facing_left = left

func set_active(active: bool) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_glow", 1.0 if active else 0.0, 0.25)

func _draw() -> void:
	# idle 浮动 / walk 时上下颠簸更剧烈
	var bob_amp: float = 3.0 + _walk_amount * 5.0
	var bob_freq: float = 2.6 + _walk_amount * 5.0
	var bob: float = sin(_t * bob_freq) * bob_amp
	# walk 时身体左右轻微摇摆
	var sway: float = sin(_t * bob_freq * 0.5) * 4.0 * _walk_amount
	# squash + walk 拉伸
	var sx: float = _scale_anim * (1.0 + sin(_t * bob_freq) * 0.04 * _walk_amount)
	var sy: float = _scale_anim * (1.0 - sin(_t * bob_freq) * 0.04 * _walk_amount)

	# 选中光晕
	if _glow > 0.01:
		for i in 5:
			var rr: float = 30.0 + i * 5.0
			var alpha: float = (1.0 - float(i) / 5.0) * 0.25 * _glow
			draw_circle(Vector2(0, -bob - 30), rr, Color(1, 0.85, 0.3, alpha))

	# 脚下椭圆阴影
	var shadow_pts := PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		shadow_pts.append(Vector2(cos(a) * 24.0, sin(a) * 7.0))
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.4))

	var tex := _current_tex()
	if tex != null:
		var ratio: float = float(tex.get_width()) / float(tex.get_height())
		var h: float = RENDER_HEIGHT * sy
		var w: float = h * ratio * sx / sy
		var x_center: float = sway
		var rect: Rect2
		if _facing_left:
			rect = Rect2(Vector2(x_center + w * 0.5, -h - 4 + bob), Vector2(-w, h))
		else:
			rect = Rect2(Vector2(x_center - w * 0.5, -h - 4 + bob), Vector2(w, h))
		draw_texture_rect(tex, rect, false, Color.WHITE)

	# 名字标签
	if not display_name.is_empty():
		var font: Font = ThemeDB.fallback_font
		var fs: int = 12
		var ts: Vector2 = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var ny: float = -RENDER_HEIGHT - 14 + bob
		# 半透明黑底 + 金边
		draw_rect(Rect2(Vector2(-ts.x * 0.5 - 5, ny - ts.y - 1), Vector2(ts.x + 10, ts.y + 4)),
			Color(0, 0, 0, 0.78), true)
		draw_rect(Rect2(Vector2(-ts.x * 0.5 - 5, ny - ts.y - 1), Vector2(ts.x + 10, ts.y + 4)),
			Color(1, 0.85, 0.3, 0.9), false, 1.0)
		draw_string(font, Vector2(-ts.x * 0.5, ny - 3), display_name,
			HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)

var _tex_cache: Texture2D = null
func _current_tex() -> Texture2D:
	if _tex_cache != null:
		return _tex_cache
	var idx: int = char_set_index % CHIBI_PATHS.size()
	var path: String = CHIBI_PATHS[idx]
	if ResourceLoader.exists(path):
		_tex_cache = load(path)
	return _tex_cache
