extends Control
## 轮数 / 角色 / NPC / 骰子模式选择。

var rounds_input: SpinBox
var dice_mode: String = "auto"
var character_checks: Array[CheckBox] = []
var npc_checks: Array[CheckBox] = []
var characters: Array = []
var npcs: Array = []

func _ready() -> void:
	UIUtil.make_bg(self, "round-setup")
	characters = GameStore.get_characters()
	npcs = GameStore.get_npcs()
	_build()

func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	v.add_child(UIUtil.make_label("🎲 游戏设置", 32, UIUtil.C_GOLD, true))

	# 1. 轮数
	v.add_child(_section_label("1. 游戏轮数"))
	rounds_input = SpinBox.new()
	rounds_input.min_value = 1
	rounds_input.max_value = 50
	rounds_input.value = 10
	rounds_input.step = 1
	rounds_input.custom_minimum_size = Vector2(200, 40)
	v.add_child(rounds_input)

	# 2. 角色
	v.add_child(_section_label("2. 选择角色 (%d)" % characters.size()))
	var char_grid := _make_grid(180)
	v.add_child(char_grid)
	for c in characters:
		var item := _make_pick_item(c, true)
		char_grid.add_child(item)

	# 3. NPC
	v.add_child(_section_label("3. 选择NPC (%d)" % npcs.size()))
	var npc_grid := _make_grid(180)
	v.add_child(npc_grid)
	for n in npcs:
		var item := _make_pick_item(n, false)
		npc_grid.add_child(item)

	# 4. 骰子模式
	v.add_child(_section_label("4. 骰子模式"))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	var b_auto := UIUtil.styled_button("🤖  自动", true, false)
	var b_ext := UIUtil.styled_button("🎯  场外", false, false)
	hb.add_child(b_auto)
	hb.add_child(b_ext)
	b_auto.pressed.connect(func():
		dice_mode = "auto"
		b_auto.button_pressed = true
		_set_button_primary(b_auto, true)
		_set_button_primary(b_ext, false))
	b_ext.pressed.connect(func():
		dice_mode = "external"
		_set_button_primary(b_auto, false)
		_set_button_primary(b_ext, true))

	# 操作
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(actions)
	var b_start := UIUtil.styled_button("开始游戏 🎉", true, true)
	b_start.pressed.connect(_start_game)
	actions.add_child(b_start)
	var b_back := UIUtil.styled_button("返回菜单", false, false)
	b_back.pressed.connect(func(): SceneRouter.goto(SceneRouter.SCENE_MENU))
	actions.add_child(b_back)

func _section_label(text: String) -> Label:
	var l := UIUtil.make_label(text, 22, UIUtil.C_GOLD)
	return l

func _make_grid(_min_w: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	return g

func _make_pick_item(data: Dictionary, is_character: bool) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.35)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(hb)

	var cb := CheckBox.new()
	cb.button_pressed = true
	cb.set_meta("data_id", String(data.get("id", "")))
	hb.add_child(cb)

	var tex_rect := TextureRect.new()
	tex_rect.texture = UIUtil.avatar_texture(String(data.get("avatar", "")))
	tex_rect.custom_minimum_size = Vector2(36, 36)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hb.add_child(tex_rect)

	var name_l := UIUtil.make_label(String(data.get("name", "")), 16,
		UIUtil.parse_color(String(data.get("color", "#ffffff"))))
	hb.add_child(name_l)

	if is_character:
		character_checks.append(cb)
	else:
		npc_checks.append(cb)
	return pc

func _set_button_primary(b: Button, primary: bool) -> void:
	var sb_normal := b.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	sb_normal.bg_color = UIUtil.C_RED if primary else Color(0, 0, 0, 0.55)
	b.add_theme_stylebox_override("normal", sb_normal)
	b.add_theme_color_override("font_color", UIUtil.C_GOLD if primary else UIUtil.C_TEXT)

func _start_game() -> void:
	var rounds: int = int(rounds_input.value)
	var sel_chars: Array = []
	for cb in character_checks:
		if cb.button_pressed:
			var id := String(cb.get_meta("data_id"))
			for c in characters:
				if String(c.get("id", "")) == id:
					sel_chars.append(c)
					break
	if sel_chars.is_empty():
		UIUtil.toast(self, "请至少选择一个角色！", 2.0)
		return
	var sel_npcs: Array = []
	for cb in npc_checks:
		if cb.button_pressed:
			var id := String(cb.get_meta("data_id"))
			for n in npcs:
				if String(n.get("id", "")) == id:
					sel_npcs.append(n)
					break
	GameStore.clear_game_progress()
	GameStore.reset_minigame_counts()
	AudioBus.play_click()
	SceneRouter.goto(SceneRouter.SCENE_GAME, {
		"rounds": rounds,
		"diceMode": dice_mode,
		"characters": sel_chars,
		"npcs": sel_npcs,
	})
