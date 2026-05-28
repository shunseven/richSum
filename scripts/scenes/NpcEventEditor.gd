extends Control
## NPC 事件编辑器（与随机事件编辑器近似）。

const TYPES := ["reward", "punishment", "npc_system"]
const TYPE_LABELS := {
	"reward": "奖励 ✨",
	"punishment": "惩罚 😤",
	"npc_system": "NPC系统 🤖",
}

var list_root: VBoxContainer

func _ready() -> void:
	var v := EditorUI.make_screen(self, "👥 NPC事件编辑", func(): SceneRouter.goto(SceneRouter.SCENE_MENU))
	v.add_child(_build_form())
	v.add_child(UIUtil.make_label("现有 NPC 事件", 22, UIUtil.C_GOLD))
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
	v.add_child(UIUtil.make_label("新增 NPC 事件", 22, UIUtil.C_GOLD))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	v.add_child(hb)
	hb.add_child(EditorUI.make_label("图标："))
	var icon_in := EditorUI.make_text_input("👋", "emoji")
	icon_in.custom_minimum_size = Vector2(60, 32)
	hb.add_child(icon_in)
	hb.add_child(EditorUI.make_label("名称："))
	var name_in := EditorUI.make_text_input("", "事件名")
	hb.add_child(name_in)
	hb.add_child(EditorUI.make_label("类型："))
	var type_op := OptionButton.new()
	for t in TYPES:
		type_op.add_item(TYPE_LABELS[t])
	hb.add_child(type_op)
	hb.add_child(EditorUI.make_label("描述："))
	var desc_in := EditorUI.make_text_input("", "描述")
	hb.add_child(desc_in)
	var b_add := UIUtil.styled_button("➕ 添加", true, false)
	b_add.pressed.connect(func():
		var n := String(name_in.text).strip_edges()
		if n.is_empty():
			UIUtil.toast(self, "请输入名称", 1.5); return
		GameStore.add_npc_event({
			"name": n,
			"icon": String(icon_in.text).strip_edges() if not String(icon_in.text).is_empty() else "👋",
			"type": TYPES[type_op.selected],
			"description": String(desc_in.text).strip_edges(),
		})
		name_in.text = ""; desc_in.text = ""
		_refresh())
	v.add_child(b_add)
	return pc

func _refresh() -> void:
	for c in list_root.get_children():
		c.queue_free()
	var list: Array = GameStore.get_npc_events()
	for ev in list:
		list_root.add_child(_build_row(ev))

func _build_row(ev: Dictionary) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0, 0, 0, 0.45)))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	pc.add_child(hb)
	var icon_in := EditorUI.make_text_input(String(ev.get("icon", "")), "")
	icon_in.custom_minimum_size = Vector2(60, 32)
	hb.add_child(icon_in)
	var name_in := EditorUI.make_text_input(String(ev.get("name", "")), "")
	hb.add_child(name_in)
	var type_op := OptionButton.new()
	for t in TYPES:
		type_op.add_item(TYPE_LABELS[t])
	type_op.selected = TYPES.find(String(ev.get("type", "reward")))
	if type_op.selected < 0: type_op.selected = 0
	hb.add_child(type_op)
	var desc_in := EditorUI.make_text_input(String(ev.get("description", "")), "")
	desc_in.custom_minimum_size = Vector2(260, 32)
	hb.add_child(desc_in)
	var b_save := UIUtil.styled_button("💾", false, false)
	b_save.pressed.connect(func():
		GameStore.update_npc_event(String(ev.get("id", "")), {
			"name": name_in.text.strip_edges(),
			"icon": icon_in.text.strip_edges(),
			"type": TYPES[type_op.selected],
			"description": desc_in.text.strip_edges(),
		})
		UIUtil.toast(self, "已保存", 1.0)
		_refresh())
	hb.add_child(b_save)
	var b_del := UIUtil.styled_button("🗑️", false, false)
	b_del.pressed.connect(func():
		GameStore.delete_npc_event(String(ev.get("id", "")))
		_refresh())
	hb.add_child(b_del)
	return pc
