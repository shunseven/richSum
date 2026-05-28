extends RefCounted
class_name EditorUI
## 编辑器场景共享 UI 构件。

static func make_screen(scene: Control, title: String, on_back: Callable) -> VBoxContainer:
	UIUtil.make_bg(scene, "menu")
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	panel.custom_minimum_size = Vector2(900, 600)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var b_back := UIUtil.styled_button("← 返回菜单", false, false)
	b_back.pressed.connect(on_back)
	head.add_child(b_back)
	var title_l := UIUtil.make_label(title, 32, UIUtil.C_GOLD)
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title_l)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(120, 0)
	head.add_child(spacer)
	return v

static func make_text_input(initial: String, placeholder: String = "") -> LineEdit:
	var le := LineEdit.new()
	le.text = initial
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(220, 32)
	return le

static func make_color_row(initial: String, options: Array) -> Dictionary:
	# 返回 {"hb": HBoxContainer, "selected": StringRef}（通过 Dictionary 引用）
	var ref := {"value": initial}
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	for c in options:
		var b := Button.new()
		b.custom_minimum_size = Vector2(28, 28)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UIUtil.parse_color(c)
		sb.set_corner_radius_all(14)
		sb.border_color = UIUtil.C_GOLD if c == initial else Color(1, 1, 1, 0.3)
		sb.set_border_width_all(3 if c == initial else 1)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.tooltip_text = c
		b.pressed.connect(func():
			ref["value"] = c
			# 重绘所有按钮的边框
			for child in hb.get_children():
				var btn: Button = child
				var newsb := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
				newsb.border_color = UIUtil.C_GOLD if btn.tooltip_text == c else Color(1, 1, 1, 0.3)
				newsb.set_border_width_all(3 if btn.tooltip_text == c else 1)
				btn.add_theme_stylebox_override("normal", newsb)
				btn.add_theme_stylebox_override("hover", newsb)
				btn.add_theme_stylebox_override("pressed", newsb))
		hb.add_child(b)
	return {"hb": hb, "ref": ref}

static func make_label(text: String, size: int = 16) -> Label:
	return UIUtil.make_label(text, size, UIUtil.C_GOLD)
