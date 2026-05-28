extends Control
## 角色编辑器：增删改查 + 颜色选择。

const COLORS := ["#e74c3c", "#3498db", "#2ecc71", "#9b59b6", "#e67e22", "#1abc9c", "#f39c12", "#6c5ce7"]

var list_root: VBoxContainer

func _ready() -> void:
	var v := EditorUI.make_screen(self, "👤 角色编辑", _on_back)
	v.add_child(_build_add_form())
	v.add_child(_section_title("现有角色"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	v.add_child(scroll)
	list_root = VBoxContainer.new()
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_root.add_theme_constant_override("separation", 8)
	scroll.add_child(list_root)
	_refresh()

func _on_back() -> void:
	SceneRouter.goto(SceneRouter.SCENE_MENU)

func _section_title(t: String) -> Label:
	return UIUtil.make_label(t, 22, UIUtil.C_GOLD)

func _build_add_form() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.4)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_section_title("新增角色"))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	v.add_child(hb)
	var name_input := EditorUI.make_text_input("", "角色名")
	hb.add_child(EditorUI.make_label("名称："))
	hb.add_child(name_input)
	hb.add_child(EditorUI.make_label("颜色："))
	var pack := EditorUI.make_color_row(COLORS[0], COLORS)
	hb.add_child(pack["hb"])
	var b_add := UIUtil.styled_button("➕ 添加", true, false)
	b_add.pressed.connect(func():
		var n := String(name_input.text).strip_edges()
		if n.is_empty():
			UIUtil.toast(self, "请输入名称", 1.5)
			return
		GameStore.add_character({"name": n, "avatar": "res://assets/roles/qi.png", "color": pack["ref"]["value"]})
		name_input.text = ""
		_refresh())
	hb.add_child(b_add)
	return pc

func _refresh() -> void:
	for c in list_root.get_children():
		c.queue_free()
	var list: Array = GameStore.get_characters()
	if list.is_empty():
		list_root.add_child(UIUtil.make_label("暂无角色", 16, Color(0.7, 0.7, 0.7)))
		return
	for ch in list:
		list_root.add_child(_build_row(ch))

func _build_row(ch: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := UIUtil.panel_bg(Color(0, 0, 0, 0.45))
	pc.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)
	var av := TextureRect.new()
	av.texture = UIUtil.avatar_texture(String(ch.get("avatar", "")))
	av.custom_minimum_size = Vector2(40, 40)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hb.add_child(av)
	var name_input := EditorUI.make_text_input(String(ch.get("name", "")), "")
	hb.add_child(name_input)
	var pack := EditorUI.make_color_row(String(ch.get("color", COLORS[0])), COLORS)
	hb.add_child(pack["hb"])
	var b_save := UIUtil.styled_button("💾 保存", false, false)
	b_save.pressed.connect(func():
		GameStore.update_character(String(ch.get("id", "")), {
			"name": String(name_input.text).strip_edges(),
			"color": pack["ref"]["value"],
		})
		UIUtil.toast(self, "已保存", 1.0)
		_refresh())
	hb.add_child(b_save)
	var b_del := UIUtil.styled_button("🗑️ 删除", false, false)
	b_del.pressed.connect(func():
		GameStore.delete_character(String(ch.get("id", "")))
		_refresh())
	hb.add_child(b_del)
	return pc
