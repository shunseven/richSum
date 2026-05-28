extends Node2D
class_name PlayerToken
## 棋子：用 AI 生成的 chibi 角色 sprite，干净的浮动 + 选中光晕。

const CHIBI_PATHS := [
	"res://assets/store/chibi/red.png",
	"res://assets/store/chibi/blue.png",
	"res://assets/store/chibi/green.png",
]

@export var char_set_index: int = 0
@export var display_name: String = ""

const RENDER_HEIGHT := 78.0

var _t: float = 0.0
var _scale_anim: float = 1.0
var _glow: float = 0.0
var _facing_left: bool = false

func _ready() -> void:
	z_index = 10
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func play_squash() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_scale_anim", 1.12, 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_scale_anim", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_facing(left: bool) -> void:
	_facing_left = left

func set_active(active: bool) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_glow", 1.0 if active else 0.0, 0.25)

func _draw() -> void:
	var bob: float = sin(_t * 2.6) * 2.5
	var s: float = _scale_anim

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
		shadow_pts.append(Vector2(cos(a) * 22.0, sin(a) * 7.0))
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.4))

	var tex := _current_tex()
	if tex != null:
		var ratio: float = float(tex.get_width()) / float(tex.get_height())
		var h: float = RENDER_HEIGHT * s
		var w: float = h * ratio
		var rect: Rect2
		if _facing_left:
			rect = Rect2(Vector2(w * 0.5, -h - 4 + bob), Vector2(-w, h))
		else:
			rect = Rect2(Vector2(-w * 0.5, -h - 4 + bob), Vector2(w, h))
		draw_texture_rect(tex, rect, false, Color.WHITE)

	# 名字标签（金底黑字小标牌）
	if not display_name.is_empty():
		var font: Font = ThemeDB.fallback_font
		var fs: int = 12
		var ts: Vector2 = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var ny: float = -RENDER_HEIGHT - 18 + bob
		# 半透明黑底
		draw_rect(Rect2(Vector2(-ts.x * 0.5 - 5, ny - ts.y - 1), Vector2(ts.x + 10, ts.y + 4)),
			Color(0, 0, 0, 0.78), true)
		# 金色细描边
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
