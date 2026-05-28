extends RefCounted
class_name TableTopBg
## 桌面背景：木纹底 + 中央红色台布 + 暗角晕。

static var _cache: Texture2D = null

static func make_or_get(size: Vector2i = Vector2i(1280, 800)) -> Texture2D:
	if _cache != null:
		return _cache
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	# 木纹基底
	for y in size.y:
		for x in size.x:
			var n: float = sin(x * 0.04 + y * 0.001) * 0.5 + 0.5
			n += sin(x * 0.13 + y * 0.07) * 0.15
			n = clamp(n, 0.0, 1.0)
			var base: Color = Color(0.18, 0.08, 0.04).lerp(Color(0.32, 0.16, 0.08), n * 0.6 + 0.2)
			img.set_pixel(x, y, base)
	# 中央台布（深红圆角矩形 + 金色边）
	var pad_x := 110
	var pad_y := 40
	var W := size.x - pad_x * 2
	var H := size.y - pad_y * 2
	var r := 36
	for y in H:
		for x in W:
			if _in_round(x, y, W, H, r):
				var t: float = float(y) / H
				var c: Color = Color(0.55, 0.10, 0.10).lerp(Color(0.30, 0.05, 0.05), t)
				img.set_pixel(pad_x + x, pad_y + y, c)
	# 金色边
	for y in H:
		for x in W:
			if _on_edge(x, y, W, H, r, 4):
				img.set_pixel(pad_x + x, pad_y + y, Color("#d4a017"))
	# 中央台布纹理（细金线交叉）
	for y in H:
		for x in W:
			if _in_round(x, y, W, H, r) and ((x + y) % 32 == 0):
				var pp: Color = img.get_pixel(pad_x + x, pad_y + y)
				img.set_pixel(pad_x + x, pad_y + y, pp.lerp(Color(1, 0.85, 0.4), 0.18))
	# 暗角
	var cx: int = size.x / 2
	var cy: int = size.y / 2
	var max_r: float = Vector2(cx, cy).length()
	for y in size.y:
		for x in size.x:
			var d: float = Vector2(x - cx, y - cy).length() / max_r
			var v: float = clamp(pow(d, 2.0) * 0.55, 0.0, 0.55)
			var pp: Color = img.get_pixel(x, y)
			img.set_pixel(x, y, pp.darkened(v))
	_cache = ImageTexture.create_from_image(img)
	return _cache

static func _in_round(x: int, y: int, w: int, h: int, r: int) -> bool:
	if x < r and y < r:
		return Vector2(x - r, y - r).length() <= r
	if x >= w - r and y < r:
		return Vector2(x - (w - r - 1), y - r).length() <= r
	if x < r and y >= h - r:
		return Vector2(x - r, y - (h - r - 1)).length() <= r
	if x >= w - r and y >= h - r:
		return Vector2(x - (w - r - 1), y - (h - r - 1)).length() <= r
	return true

static func _on_edge(x: int, y: int, w: int, h: int, r: int, t: int) -> bool:
	if not _in_round(x, y, w, h, r):
		return false
	for d in range(1, t + 1):
		if not _in_round(x + d, y, w, h, r): return true
		if not _in_round(x - d, y, w, h, r): return true
		if not _in_round(x, y + d, w, h, r): return true
		if not _in_round(x, y - d, w, h, r): return true
	return false
