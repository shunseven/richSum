extends Control
## NPC 编辑器（与 CharacterEditor 类似）。

const COLORS := ["#636e72", "#b2bec3", "#00b894", "#fdcb6e", "#e17055", "#74b9ff", "#a29bfe"]

var list_root: VBoxContainer

func _ready() -> void:
	var v := EditorUI.make_screen(self, "🧓 NPC编辑", func(): SceneRouter.goto(SceneRouter.SCENE_MENU))
	v.add_child(_build_add_form())
	v.add_child(UIUtil.make_label("现有 NPC", 22, UIUtil.C_GOLD))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	v.add_child(scroll)
	list_root = VBoxContainer.new()
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_root.add_theme_constant_override("separation", 8)
	scroll.add_child(list_root)
	_refresh()

func _build_add_form() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.4)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(UIUtil.make_label("新增 NPC", 22, UIUtil.C_GOLD))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	v.add_child(hb)
	hb.add_child(EditorUI.make_label("名称："))
	var name_input := EditorUI.make_text_input("", "NPC名称")
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
		GameStore.add_npc({"name": n, "avatar": "res://assets/roles/biao.png", "color": pack["ref"]["value"]})
		name_input.text = ""
		_refresh())
	hb.add_child(b_add)
	return pc

func _refresh() -> void:
	for c in list_root.get_children():
		c.queue_free()
	var list: Array = GameStore.get_npcs()
	if list.is_empty():
		list_root.add_child(UIUtil.make_label("暂无 NPC", 16, Color(0.7, 0.7, 0.7)))
		return
	for n in list:
		list_root.add_child(_build_row(n))

func _build_row(n: Dictionary) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.45)))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)
	var av := TextureRect.new()
	av.texture = UIUtil.avatar_texture(String(n.get("avatar", "")))
	av.custom_minimum_size = Vector2(40, 40)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hb.add_child(av)
	var name_input := EditorUI.make_text_input(String(n.get("name", "")), "")
	hb.add_child(name_input)
	var pack := EditorUI.make_color_row(String(n.get("color", COLORS[0])), COLORS)
	hb.add_child(pack["hb"])
	var b_save := UIUtil.styled_button("💾 保存", false, false)
	b_save.pressed.connect(func():
		GameStore.update_npc(String(n.get("id", "")), {
			"name": String(name_input.text).strip_edges(),
			"color": pack["ref"]["value"],
		})
		UIUtil.toast(self, "已保存", 1.0)
		_refresh())
	hb.add_child(b_save)
	var b_del := UIUtil.styled_button("🗑️ 删除", false, false)
	b_del.pressed.connect(func():
		GameStore.delete_npc(String(n.get("id", "")))
		_refresh())
	hb.add_child(b_del)
	return pc
