extends RefCounted
class_name UIUtil
## 通用 UI 辅助：颜色/字体/全屏背景图。

const FONT_SIZE_TITLE := 56
const FONT_SIZE_H1 := 36
const FONT_SIZE_H2 := 26
const FONT_SIZE_BODY := 18

const C_GOLD := Color("#ffd700")
const C_RED := Color("#e74c3c")
const C_DEEP_RED := Color("#2a0a0a")
const C_DARK := Color("#1a0505")
const C_TEXT := Color("#ffffff")

static func make_bg(parent: Control, screen: String) -> void:
	var dir_path := "res://assets/bg/frames/start"
	if screen == "menu" or screen == "round-setup":
		dir_path = "res://assets/bg/frames/start"
	elif screen == "results":
		dir_path = "res://assets/bg/frames/ed"
	elif screen == "game":
		dir_path = "res://assets/bg/frames/game"
	var vb: TextureRect = load("res://scripts/ui/VideoBg.gd").new()
	vb.set("dir_path", dir_path)
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vb)
	parent.move_child(vb, 0)
	# 暗色蒙版
	var mask := ColorRect.new()
	mask.color = Color(0, 0, 0, 0.45)
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(mask)

static func styled_button(text: String, primary: bool = false, big: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220 if big else 180, 56 if big else 44)
	b.add_theme_font_size_override("font_size", 20 if big else 16)
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = C_RED if primary else Color(0, 0, 0, 0.55)
	sb_normal.border_color = C_GOLD
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(12)
	sb_normal.content_margin_left = 16
	sb_normal.content_margin_right = 16
	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color("#c0392b") if primary else Color("#3a1010")
	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color("#a02018") if primary else Color("#1a0606")
	b.add_theme_stylebox_override("normal", sb_normal)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("pressed", sb_pressed)
	b.add_theme_stylebox_override("focus", sb_normal)
	b.add_theme_color_override("font_color", C_GOLD if primary else C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	return b

static func panel_bg(color: Color = Color(0.16, 0.04, 0.04, 0.85), border: Color = C_GOLD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb

static func make_label(text: String, size: int = FONT_SIZE_BODY, color: Color = C_TEXT, align_center: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	if align_center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func avatar_texture(path_or_url: String) -> Texture2D:
	if path_or_url.begins_with("res://") or path_or_url.begins_with("user://"):
		if ResourceLoader.exists(path_or_url):
			return load(path_or_url)
	# data:image / 网络 URL：用占位
	return _placeholder_avatar()

static func _placeholder_avatar() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.4, 0.5))
	return ImageTexture.create_from_image(img)

static func parse_color(hex: String, fallback: Color = Color.WHITE) -> Color:
	if hex.is_empty():
		return fallback
	var s: String = hex
	if not s.begins_with("#"):
		s = "#" + s
	# 去掉可能的 alpha 多字节
	if s.length() == 9:
		s = s.substr(0, 7)
	if Color.html_is_valid(s):
		return Color.html(s)
	return fallback

static func toast(parent: CanvasItem, text: String, duration: float = 2.0) -> void:
	var root: Node = parent
	while root.get_parent() != null:
		root = root.get_parent()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", C_GOLD)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	sb.border_color = C_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(label)
	pc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	pc.position = Vector2(-120, 70)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pc)
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.2).from(0.0)
	tw.tween_interval(duration)
	tw.tween_property(pc, "modulate:a", 0.0, 0.4)
	tw.tween_callback(pc.queue_free)
