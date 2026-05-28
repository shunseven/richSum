extends Control
## 小游戏编辑器：名称 / 图标 / 概率 / 最大次数 / 胜利条件 / 首次保证。

var list_root: VBoxContainer

func _ready() -> void:
	var v := EditorUI.make_screen(self, "🎮 小游戏编辑", func(): SceneRouter.goto(SceneRouter.SCENE_MENU))
	v.add_child(_build_form())
	v.add_child(UIUtil.make_label("现有小游戏", 22, UIUtil.C_GOLD))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	v.add_child(scroll)
	list_root = VBoxContainer.new()
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_root.add_theme_constant_override("separation", 8)
	scroll.add_child(list_root)
	_refresh()

func _build_form() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.4)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	v.add_child(UIUtil.make_label("新增小游戏", 22, UIUtil.C_GOLD))

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var icon_in := EditorUI.make_text_input("🎮", "emoji")
	icon_in.custom_minimum_size = Vector2(60, 32)
	var name_in := EditorUI.make_text_input("", "名称")
	var prob_in := SpinBox.new(); prob_in.min_value = 1; prob_in.max_value = 100; prob_in.value = 50
	var max_in := SpinBox.new(); max_in.min_value = 1; max_in.max_value = 999; max_in.value = 100
	var win_in := EditorUI.make_text_input("", "胜利条件描述")
	win_in.custom_minimum_size = Vector2(260, 32)
	var first_cb := CheckBox.new(); first_cb.text = "首次保证"

	grid.add_child(EditorUI.make_label("图标"))
	grid.add_child(icon_in)
	grid.add_child(EditorUI.make_label("名称"))
	grid.add_child(name_in)
	grid.add_child(EditorUI.make_label("概率"))
	grid.add_child(prob_in)
	grid.add_child(EditorUI.make_label("最大次数"))
	grid.add_child(max_in)
	grid.add_child(EditorUI.make_label("胜利条件"))
	grid.add_child(win_in)
	grid.add_child(EditorUI.make_label(""))
	grid.add_child(first_cb)

	var b_add := UIUtil.styled_button("➕ 添加", true, false)
	b_add.pressed.connect(func():
		var n := String(name_in.text).strip_edges()
		if n.is_empty():
			UIUtil.toast(self, "请输入名称", 1.5); return
		GameStore.add_minigame({
			"name": n,
			"icon": String(icon_in.text).strip_edges() if not String(icon_in.text).is_empty() else "🎮",
			"probability": int(prob_in.value),
			"maxCount": int(max_in.value),
			"winCondition": win_in.text.strip_edges(),
			"guaranteeFirst": first_cb.button_pressed,
		})
		name_in.text = ""; win_in.text = ""
		_refresh())
	v.add_child(b_add)
	return pc

func _refresh() -> void:
	for c in list_root.get_children():
		c.queue_free()
	var list: Array = GameStore.get_minigames()
	for g in list:
		list_root.add_child(_build_row(g))

func _build_row(g: Dictionary) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.45)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	v.add_child(hb)
	var icon_in := EditorUI.make_text_input(String(g.get("icon", "")), "")
	icon_in.custom_minimum_size = Vector2(60, 32)
	hb.add_child(icon_in)
	var name_in := EditorUI.make_text_input(String(g.get("name", "")), "")
	hb.add_child(name_in)
	hb.add_child(EditorUI.make_label("概率"))
	var prob_in := SpinBox.new(); prob_in.min_value = 1; prob_in.max_value = 100; prob_in.value = int(g.get("probability", 50))
	hb.add_child(prob_in)
	hb.add_child(EditorUI.make_label("次数"))
	var max_in := SpinBox.new(); max_in.min_value = 1; max_in.max_value = 999; max_in.value = int(g.get("maxCount", 100))
	hb.add_child(max_in)
	var first_cb := CheckBox.new(); first_cb.text = "首保"; first_cb.button_pressed = bool(g.get("guaranteeFirst", false))
	hb.add_child(first_cb)
	var b_save := UIUtil.styled_button("💾", false, false)
	hb.add_child(b_save)
	var b_del := UIUtil.styled_button("🗑️", false, false)
	hb.add_child(b_del)
	var win_in := EditorUI.make_text_input(String(g.get("winCondition", "")), "胜利条件")
	win_in.custom_minimum_size = Vector2(560, 32)
	v.add_child(win_in)
	b_save.pressed.connect(func():
		GameStore.update_minigame(String(g.get("id", "")), {
			"name": name_in.text.strip_edges(),
			"icon": icon_in.text.strip_edges(),
			"probability": int(prob_in.value),
			"maxCount": int(max_in.value),
			"winCondition": win_in.text.strip_edges(),
			"guaranteeFirst": first_cb.button_pressed,
		})
		UIUtil.toast(self, "已保存", 1.0)
		_refresh())
	b_del.pressed.connect(func():
		GameStore.delete_minigame(String(g.get("id", "")))
		_refresh())
	return pc
