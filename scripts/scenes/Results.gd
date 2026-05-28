extends Control
## 游戏结算页：排名 + 最终大奖 + 加码红包 + 每位玩家事件日志。

func _ready() -> void:
	UIUtil.make_bg(self, "results")
	var params: Dictionary = SceneRouter.consume_params()
	var players: Array = params.get("players", [])
	var bonus: int = int(params.get("bonusRedPacket", 0))
	var prize: Dictionary = GameStore.get_final_prize()
	print("[E2E] RESULTS scene reached, players=%d bonus=%d" % [players.size(), bonus])
	_build(players, bonus, prize)
	AudioBus.stop_bgm()
	AudioBus.play_game_over()

func _build(players: Array, bonus: int, prize: Dictionary) -> void:
	var sorted := players.duplicate(true)
	sorted.sort_custom(func(a, b):
		if int(b.get("stars", 0)) != int(a.get("stars", 0)):
			return int(b.get("stars", 0)) < int(a.get("stars", 0))
		return int(b.get("coins", 0)) < int(a.get("coins", 0)))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	panel.custom_minimum_size = Vector2(820, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	v.add_child(UIUtil.make_label("🏆 游戏结束 🏆", 44, UIUtil.C_GOLD, true))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for i in sorted.size():
		list.add_child(_build_player_row(sorted[i], i, prize, bonus))

	var b_home := UIUtil.styled_button("返回主菜单", true, true)
	b_home.pressed.connect(func():
		AudioBus.play_click()
		AudioBus.play_bgm(1.0)
		SceneRouter.goto(SceneRouter.SCENE_MENU))
	v.add_child(b_home)

func _build_player_row(p: Dictionary, idx: int, prize: Dictionary, bonus: int) -> Control:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.06, 0.06, 0.85)
	sb.border_color = UIUtil.C_GOLD if idx == 0 else Color(0.4, 0.3, 0.1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var medal := ["🥇", "🥈", "🥉"]
	var rank_text: String = medal[idx] if idx < medal.size() else str(idx + 1)
	head.add_child(UIUtil.make_label(rank_text, 32, UIUtil.C_GOLD))

	var avatar := TextureRect.new()
	avatar.texture = UIUtil.avatar_texture(String(p.get("avatar", "")))
	avatar.custom_minimum_size = Vector2(54, 54)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	head.add_child(avatar)

	var info := VBoxContainer.new()
	head.add_child(info)
	info.add_child(UIUtil.make_label(String(p.get("name", "")), 22,
		UIUtil.parse_color(String(p.get("color", "#ffffff")))))
	info.add_child(UIUtil.make_label("⭐ %d 星  |  💰 %d 金币" % [int(p.get("stars", 0)), int(p.get("coins", 0))], 18))

	if idx == 0:
		head.add_child(_spacer_h(20))
		var prize_box := VBoxContainer.new()
		prize_box.alignment = BoxContainer.ALIGNMENT_CENTER
		head.add_child(prize_box)
		prize_box.add_child(UIUtil.make_label("%s %s" % [
			String(prize.get("icon", "🏆")),
			String(prize.get("name", "新春大奖"))
		], 22, UIUtil.C_GOLD, true))
		if bonus > 0:
			prize_box.add_child(UIUtil.make_label("+ %d 元加码红包 🧧" % bonus, 18,
				UIUtil.C_RED, true))

	# 事件日志
	var ev_log: Array = p.get("eventLog", [])
	if ev_log.size() > 0:
		var log_box := VBoxContainer.new()
		v.add_child(log_box)
		var rewards: Array = ev_log.filter(func(e): return String(e.get("type", "")) == "reward")
		var puns: Array = ev_log.filter(func(e): return String(e.get("type", "")) == "punishment")
		if rewards.size() > 0:
			log_box.add_child(UIUtil.make_label("✨ 奖励", 16, Color("#2ecc71")))
			log_box.add_child(_make_event_flow(rewards, true))
		if puns.size() > 0:
			log_box.add_child(UIUtil.make_label("😤 惩罚", 16, Color("#e74c3c")))
			log_box.add_child(_make_event_flow(puns, false))
	else:
		v.add_child(UIUtil.make_label("本局没有触发事件", 14, Color(0.7, 0.7, 0.7)))
	return pc

func _make_event_flow(items: Array, is_reward: bool) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	for ev in items:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#1e3a1e", 0.85) if is_reward else Color("#3a1e1e", 0.85)
		sb.border_color = Color("#2ecc71") if is_reward else Color("#e74c3c")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", sb)
		var label_text: String = "%s %s" % [String(ev.get("icon", "")), String(ev.get("name", ""))]
		if String(ev.get("category", "")) == "npc" and ev.has("npcName"):
			label_text = "%s 从%s获取「%s」" % [String(ev.get("icon", "")), String(ev.get("npcName", "")), String(ev.get("name", ""))]
		p.add_child(UIUtil.make_label(label_text, 14))
		flow.add_child(p)
	return flow

func _spacer_h(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	return c
