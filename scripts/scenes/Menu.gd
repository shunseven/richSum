extends Control
## 主菜单：标题 + 按钮组 + 静音 + 重置数据。

func _ready() -> void:
	UIUtil.make_bg(self, "menu")
	_build_menu()
	AudioBus.play_bgm(1.0)
	# 自动跑测开关：user://auto_run 存在 → 直接开 3 轮 auto_play 对局
	if FileAccess.file_exists("user://auto_run"):
		DirAccess.remove_absolute("user://auto_run")
		_e2e_log("Menu detected auto_run, launching")
		await get_tree().create_timer(0.4).timeout
		_start_auto_e2e()

func _start_auto_e2e() -> void:
	GameStore.clear_game_progress()
	GameStore.reset_minigame_counts()
	var chars: Array = GameStore.get_characters()
	var npcs: Array = GameStore.get_npcs()
	_e2e_log("Menu starting Game rounds=3 chars=%d npcs=%d auto_play=true" % [chars.size(), npcs.size()])
	SceneRouter.goto(SceneRouter.SCENE_GAME, {
		"rounds": 3,
		"diceMode": "auto",
		"characters": chars,
		"npcs": npcs,
		"auto_play": true,
	})

func _e2e_log(msg: String) -> void:
	var f := FileAccess.open("user://e2e.log", FileAccess.READ_WRITE if FileAccess.file_exists("user://e2e.log") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("[%s] %s" % [Time.get_datetime_string_from_system(), msg])
	f.close()

func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	var sup := UIUtil.make_label("🧧 红包雨3.0 🧧", 32, UIUtil.C_GOLD, true)
	sup.modulate = Color(1, 0.95, 0.6)
	v.add_child(sup)
	var title := UIUtil.make_label("🎉 新春派对大富翁 🎉", 56, UIUtil.C_GOLD, true)
	v.add_child(title)
	var sub := UIUtil.make_label("🧧 恭喜发财 · 万事如意 🧧", 22, Color.WHITE, true)
	v.add_child(sub)
	v.add_child(_spacer(16))

	var has_save: bool = GameStore.has_game_progress()
	if has_save:
		var saved: Dictionary = GameStore.get_game_progress()
		var btn := UIUtil.styled_button("▶  继续游戏  (第 %d/%d 轮 · %d 位玩家)" % [
			int(saved.get("currentRound", 1)),
			int(saved.get("totalRounds", 10)),
			(saved.get("players", []) as Array).size()
		], false, true)
		btn.pressed.connect(func():
			AudioBus.play_click()
			SceneRouter.goto(SceneRouter.SCENE_GAME, {"savedState": saved}))
		v.add_child(btn)

	var b_start := UIUtil.styled_button("🎲  开始游戏", true, true)
	b_start.pressed.connect(func():
		AudioBus.play_click()
		SceneRouter.goto(SceneRouter.SCENE_ROUND_SETUP))
	v.add_child(b_start)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)

	for entry in [
		["👤  角色编辑", SceneRouter.SCENE_CHARACTER_EDITOR],
		["🧓  NPC编辑", SceneRouter.SCENE_NPC_EDITOR],
		["🎮  小游戏编辑", SceneRouter.SCENE_MINIGAME_EDITOR],
		["❗  随机事件编辑", SceneRouter.SCENE_EVENT_EDITOR],
		["👥  NPC事件编辑", SceneRouter.SCENE_NPC_EVENT_EDITOR],
		["🏆  最终大奖设定", SceneRouter.SCENE_PRIZE_EDITOR],
	]:
		var b := UIUtil.styled_button(entry[0], false, false)
		b.pressed.connect(func():
			AudioBus.play_click()
			SceneRouter.goto(entry[1]))
		grid.add_child(b)

	v.add_child(_spacer(20))

	# 顶部：静音 / 恢复默认
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.position = Vector2(0, 12)
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_theme_constant_override("separation", 10)
	add_child(top)

	var b_mute := UIUtil.styled_button("🔇" if AudioBus.is_muted() else "🔊", false, false)
	b_mute.custom_minimum_size = Vector2(60, 44)
	b_mute.pressed.connect(func():
		AudioBus.set_muted(not AudioBus.is_muted())
		b_mute.text = "🔇" if AudioBus.is_muted() else "🔊"
		if not AudioBus.is_muted():
			AudioBus.play_bgm(1.0))
	top.add_child(b_mute)

	var b_clear := UIUtil.styled_button("恢复默认数据", false, false)
	b_clear.pressed.connect(_on_clear_data)
	top.add_child(b_clear)
	var spacer_r := Control.new()
	spacer_r.custom_minimum_size = Vector2(20, 0)
	top.add_child(spacer_r)

func _on_clear_data() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "确定要恢复所有默认数据吗？\n（此操作会清除所有自定义修改和游戏存档）"
	dlg.title = "恢复默认数据"
	add_child(dlg)
	dlg.confirmed.connect(func():
		GameStore.reset_all()
		SceneRouter.goto(SceneRouter.SCENE_MENU))
	dlg.popup_centered()

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
