extends Control
## 最终大奖编辑：名称 + 图标。

func _ready() -> void:
	var v := EditorUI.make_screen(self, "🏆 最终大奖设定", func(): SceneRouter.goto(SceneRouter.SCENE_MENU))
	var prize: Dictionary = GameStore.get_final_prize()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.4)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pc.add_child(box)
	box.add_child(UIUtil.make_label("游戏结束时，第 1 名将获得：", 18))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	box.add_child(hb)
	hb.add_child(EditorUI.make_label("图标："))
	var icon_in := EditorUI.make_text_input(String(prize.get("icon", "🏆")), "emoji")
	icon_in.custom_minimum_size = Vector2(80, 36)
	hb.add_child(icon_in)
	hb.add_child(EditorUI.make_label("名称："))
	var name_in := EditorUI.make_text_input(String(prize.get("name", "新春大奖")), "如：豪华乐高玩具")
	name_in.custom_minimum_size = Vector2(360, 36)
	hb.add_child(name_in)
	var b_save := UIUtil.styled_button("💾 保存", true, true)
	b_save.pressed.connect(func():
		GameStore.save_final_prize({
			"name": name_in.text.strip_edges(),
			"icon": icon_in.text.strip_edges(),
		})
		UIUtil.toast(self, "已保存", 1.5))
	box.add_child(b_save)
	v.add_child(pc)
