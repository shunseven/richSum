extends RefCounted
class_name TileRenderer
## 程序化绘制棋盘瓷砖：带圆角、外阴影、内高光、纹理底色、图标。

const TILE_SIZE := 96
const SHADOW_OFFSET := Vector2(3, 4)
const SHADOW_BLUR := 8

static var _cache: Dictionary = {}

# type_key → 渐变颜色对（顶/底）+ 图标 emoji
const STYLES := {
	"start":  {"top": Color("#fff5b8"), "bot": Color("#f1c40f"), "ring": Color("#c0392b"), "icon": "🧧"},
	"event":  {"top": Color("#ffb87a"), "bot": Color("#d35400"), "ring": Color("#7d3c00"), "icon": "❗"},
	"system": {"top": Color("#7ec8ff"), "bot": Color("#1d6fa5"), "ring": Color("#0c3a5e"), "icon": "⚡"},
	"coin":   {"top": Color("#ffe98a"), "bot": Color("#d4a017"), "ring": Color("#7a5b08"), "icon": "💰"},
	"npc":    {"top": Color("#d6b3ff"), "bot": Color("#7d3cff"), "ring": Color("#3a166d"), "icon": "👥"},
	"normal": {"top": Color("#ff9b95"), "bot": Color("#a0291a"), "ring": Color("#4a0f08"), "icon": ""},
	"hover":  {"top": Color("#ffffff"), "bot": Color("#ffd700"), "ring": Color("#ffd700"), "icon": ""},
}

static func texture_for(type_key: String) -> Texture2D:
	if _cache.has(type_key):
		return _cache[type_key]
	var style: Dictionary = STYLES.get(type_key, STYLES["normal"])
	var tex := _make_tile(style)
	_cache[type_key] = tex
	return tex

static func _make_tile(style: Dictionary) -> Texture2D:
	# 画布稍大一圈给阴影留空间
	var pad := SHADOW_BLUR + 4
	var W: int = TILE_SIZE + pad * 2
	var H: int = TILE_SIZE + pad * 2
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# 1) 阴影（多层模糊圆角矩形）
	for s in range(SHADOW_BLUR, 0, -1):
		var alpha := 0.04 * (1.0 - float(s) / SHADOW_BLUR)
		_draw_round_rect(img,
			pad - s + int(SHADOW_OFFSET.x),
			pad - s + int(SHADOW_OFFSET.y),
			TILE_SIZE + s * 2, TILE_SIZE + s * 2,
			16 + s, Color(0, 0, 0, alpha))

	# 2) 外圈深色描边
	_draw_round_rect(img, pad - 2, pad - 2, TILE_SIZE + 4, TILE_SIZE + 4, 18, Color(style["ring"]))

	# 3) 主体：垂直渐变
	_draw_round_rect_gradient(img, pad, pad, TILE_SIZE, TILE_SIZE, 14,
		Color(style["top"]), Color(style["bot"]))

	# 4) 内圈高光（顶部 30% 弧形高光）
	for y in range(pad + 2, pad + int(TILE_SIZE * 0.4)):
		var t: float = float(y - pad - 2) / float(int(TILE_SIZE * 0.4) - 2)
		var alpha: float = (1.0 - t) * 0.35
		for x in range(pad + 6, pad + TILE_SIZE - 6):
			# 跟随圆角
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.5:
				img.set_pixel(x, y, c.lerp(Color(1, 1, 1, c.a), alpha))

	# 5) 内描边（金色细线）
	_draw_round_rect_outline(img, pad + 4, pad + 4, TILE_SIZE - 8, TILE_SIZE - 8, 10, Color("#ffe28a"), 2)

	return ImageTexture.create_from_image(img)

# === 几何绘制工具 ===
static func _draw_round_rect(img: Image, x: int, y: int, w: int, h: int, r: int, color: Color) -> void:
	for py in h:
		for px in w:
			if _in_round_rect(px, py, w, h, r):
				_blend(img, x + px, y + py, color)

static func _draw_round_rect_gradient(img: Image, x: int, y: int, w: int, h: int, r: int, top: Color, bot: Color) -> void:
	for py in h:
		var t: float = float(py) / float(h - 1)
		var col: Color = top.lerp(bot, t)
		for px in w:
			if _in_round_rect(px, py, w, h, r):
				_blend(img, x + px, y + py, col)

static func _draw_round_rect_outline(img: Image, x: int, y: int, w: int, h: int, r: int, color: Color, thickness: int) -> void:
	for py in h:
		for px in w:
			if _in_round_rect(px, py, w, h, r) and not _in_round_rect(px, py, w, h, r + 0):
				pass
			# 简化：只画边缘像素
			if _on_round_rect_edge(px, py, w, h, r, thickness):
				_blend(img, x + px, y + py, color)

static func _in_round_rect(px: int, py: int, w: int, h: int, r: int) -> bool:
	if px < 0 or py < 0 or px >= w or py >= h:
		return false
	# 角落：检查到圆心的距离
	var cx: int = px
	var cy: int = py
	if px < r and py < r:
		return Vector2(px - r, py - r).length() <= r
	if px >= w - r and py < r:
		return Vector2(px - (w - r - 1), py - r).length() <= r
	if px < r and py >= h - r:
		return Vector2(px - r, py - (h - r - 1)).length() <= r
	if px >= w - r and py >= h - r:
		return Vector2(px - (w - r - 1), py - (h - r - 1)).length() <= r
	return true

static func _on_round_rect_edge(px: int, py: int, w: int, h: int, r: int, thickness: int) -> bool:
	if not _in_round_rect(px, py, w, h, r):
		return false
	# 看周围 thickness 像素是否在外面
	for d in range(1, thickness + 1):
		if not _in_round_rect(px + d, py, w, h, r): return true
		if not _in_round_rect(px - d, py, w, h, r): return true
		if not _in_round_rect(px, py + d, w, h, r): return true
		if not _in_round_rect(px, py - d, w, h, r): return true
	return false

static func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var dst: Color = img.get_pixel(x, y)
	var a: float = c.a + dst.a * (1.0 - c.a)
	if a <= 0.0:
		return
	var r: float = (c.r * c.a + dst.r * dst.a * (1.0 - c.a)) / a
	var g: float = (c.g * c.a + dst.g * dst.a * (1.0 - c.a)) / a
	var b: float = (c.b * c.a + dst.b * dst.a * (1.0 - c.a)) / a
	img.set_pixel(x, y, Color(r, g, b, a))

static func icon_for(type_key: String) -> String:
	return String(STYLES.get(type_key, STYLES["normal"]).get("icon", ""))

static func ring_color_for(type_key: String) -> Color:
	return Color(STYLES.get(type_key, STYLES["normal"]).get("ring", Color.BLACK))
