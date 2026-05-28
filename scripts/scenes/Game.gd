extends Control
## 主游戏场景：棋盘 / 玩家 / 骰子 / 回合 / 事件结算 / 小游戏 / 存档。

const BoardSpecRef := preload("res://scripts/systems/BoardSpec.gd")
const Dice3DScript := preload("res://scripts/ui/Dice3D.gd")

# ===== 配置 =====
const INITIAL_COINS := 5
const STAR_PRICE_DEFAULT := 10
const STAR_PRICE_MAX := 20
const MOVE_STEP_TIME := 0.32
const DICE_ANIM_TIME := 1.6

# ===== 状态 =====
var total_rounds: int = 10
var current_round: int = 1
var current_pi: int = 0
var dice_mode: String = "auto"
var players: Array = []
var npcs_in_play: Array = []
var npc_slot_indices: Array = []
var stars: Array = []  # [{position:int, type:'permanent'|'onetime'}]
var star_price: int = STAR_PRICE_DEFAULT
var bonus_red_packet: int = 0
var is_last_three: bool = false
var phase: String = "idle"  # idle/waiting_dice/rolling/moving/event/minigame/gameover

# 节点引用
var board_root: Control
var token_root: Control
var star_root: Control
var npc_root: Control
var info_panel: VBoxContainer
var players_panel: VBoxContainer
var hint_label: Label
var dice_label: Label
var dice3d: Control
var dice_panel: PanelContainer
var roll_button: Button
var external_input: SpinBox
var modal_root: Control
var board_origin: Vector2
var auto_play: bool = false  # F2 自动驾驶

var tile_positions: Array[Vector2] = []
var tile_visuals: Array = []  # PanelContainer per tile
var token_visuals: Array = []  # tokens for each player
var star_visuals: Array = []
var npc_visuals: Array = []

func _ready() -> void:
	_e2e_log("Game._ready start")
	UIUtil.make_bg(self, "game")
	_build_layout()
	var params: Dictionary = SceneRouter.consume_params()
	_e2e_log("Game params keys=%s" % str(params.keys()))
	auto_play = bool(params.get("auto_play", false))
	if params.has("savedState") and not (params["savedState"] as Dictionary).is_empty():
		_init_from_save(params["savedState"])
	else:
		var chars: Array = params.get("characters", [])
		if chars.is_empty():
			chars = GameStore.get_characters()
		var npcs_in: Array = params.get("npcs", GameStore.get_npcs())
		_init_new_game(int(params.get("rounds", 10)), String(params.get("diceMode", "auto")), chars, npcs_in)
	_build_board()
	_build_players()
	_build_stars_initial()
	_refresh_panels()
	_save_progress()
	AudioBus.play_bgm(1.0)
	_check_last_three(true)
	await get_tree().process_frame
	_enter_waiting_dice()

# ===== UI 布局 =====
func _build_layout() -> void:
	# 主区：左侧棋盘，右侧信息栏
	var hsplit := HBoxContainer.new()
	hsplit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hsplit.add_theme_constant_override("separation", 16)
	hsplit.offset_left = 16
	hsplit.offset_top = 16
	hsplit.offset_right = -16
	hsplit.offset_bottom = -16
	add_child(hsplit)

	# 棋盘区
	var board_wrap := Control.new()
	board_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(board_wrap)

	board_root = Control.new()
	board_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_wrap.add_child(board_root)

	star_root = Control.new()
	star_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	star_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_wrap.add_child(star_root)

	npc_root = Control.new()
	npc_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	npc_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_wrap.add_child(npc_root)

	token_root = Control.new()
	token_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	token_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_wrap.add_child(token_root)

	# 右侧侧栏
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(360, 0)
	side.add_theme_constant_override("separation", 10)
	hsplit.add_child(side)

	# 顶部信息：轮数 / 星价
	info_panel = VBoxContainer.new()
	var info_pc := PanelContainer.new()
	info_pc.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	info_pc.add_child(info_panel)
	side.add_child(info_pc)

	# 玩家列表
	players_panel = VBoxContainer.new()
	players_panel.add_theme_constant_override("separation", 6)
	var p_pc := PanelContainer.new()
	p_pc.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	p_pc.add_child(players_panel)
	side.add_child(p_pc)

	# 提示
	var hint_pc := PanelContainer.new()
	var hint_sb := UIUtil.panel_bg(Color(0.05, 0.05, 0.05, 0.8))
	hint_pc.add_theme_stylebox_override("panel", hint_sb)
	hint_label = UIUtil.make_label("准备开始", 18, UIUtil.C_GOLD, true)
	hint_pc.add_child(hint_label)
	side.add_child(hint_pc)

	# 骰子区
	dice_panel = PanelContainer.new()
	dice_panel.add_theme_stylebox_override("panel", UIUtil.panel_bg(Color(0.16, 0.04, 0.04, 0.85)))
	var dice_v := VBoxContainer.new()
	dice_v.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_panel.add_child(dice_v)

	dice3d = Dice3DScript.new()
	dice3d.custom_minimum_size = Vector2(180, 180)
	dice3d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dice_v.add_child(dice3d)

	dice_label = UIUtil.make_label("🎲 -", 28, UIUtil.C_GOLD, true)
	dice_v.add_child(dice_label)

	roll_button = UIUtil.styled_button("🎲 投骰子", true, true)
	roll_button.pressed.connect(_on_roll_pressed)
	dice_v.add_child(roll_button)

	external_input = SpinBox.new()
	external_input.min_value = 1
	external_input.max_value = 6
	external_input.value = 1
	external_input.step = 1
	external_input.visible = false
	dice_v.add_child(external_input)

	side.add_child(dice_panel)

	# 顶部按钮：返回 / 静音
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_theme_constant_override("separation", 8)
	var b_mute := UIUtil.styled_button("🔇" if AudioBus.is_muted() else "🔊", false, false)
	b_mute.custom_minimum_size = Vector2(56, 38)
	b_mute.pressed.connect(func():
		AudioBus.set_muted(not AudioBus.is_muted())
		b_mute.text = "🔇" if AudioBus.is_muted() else "🔊"
		if not AudioBus.is_muted():
			AudioBus.play_bgm(1.6 if is_last_three else 1.0))
	top.add_child(b_mute)
	var b_back := UIUtil.styled_button("回菜单", false, false)
	b_back.pressed.connect(func():
		_save_progress()
		SceneRouter.goto(SceneRouter.SCENE_MENU))
	top.add_child(b_back)
	side.add_child(top)

	# Modal 浮层
	modal_root = Control.new()
	modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_root)

# ===== 初始化 =====
func _init_new_game(rounds: int, mode: String, chars: Array, in_npcs: Array) -> void:
	total_rounds = rounds
	current_round = 1
	current_pi = 0
	dice_mode = mode
	star_price = STAR_PRICE_DEFAULT
	bonus_red_packet = 0
	npcs_in_play = in_npcs
	npc_slot_indices = BoardSpecRef.compute_npc_slots(npcs_in_play.size())
	is_last_three = total_rounds <= 3
	players = []
	for c in chars:
		players.append({
			"id": c.get("id", ""),
			"name": c.get("name", ""),
			"avatar": c.get("avatar", ""),
			"color": c.get("color", "#e74c3c"),
			"coins": INITIAL_COINS,
			"stars": 0,
			"position": 0,
			"eventLog": []
		})
	# 初始一颗永久星星
	stars = [{"position": _random_star_pos([0]), "type": "permanent"}]

func _init_from_save(s: Dictionary) -> void:
	total_rounds = int(s.get("totalRounds", 10))
	current_round = int(s.get("currentRound", 1))
	current_pi = int(s.get("currentPI", 0))
	dice_mode = String(s.get("diceMode", "auto"))
	players = (s.get("players", []) as Array).duplicate(true)
	stars = (s.get("starsData", []) as Array).duplicate(true)
	star_price = int(s.get("starPrice", STAR_PRICE_DEFAULT))
	bonus_red_packet = int(s.get("bonusRedPacket", 0))
	is_last_three = bool(s.get("isLastThreeRounds", false))
	npcs_in_play = (s.get("npcs", []) as Array).duplicate(true)
	if npcs_in_play.is_empty():
		npcs_in_play = GameStore.get_npcs()
	npc_slot_indices = BoardSpecRef.compute_npc_slots(npcs_in_play.size())

func _save_progress() -> void:
	GameStore.save_game_progress({
		"players": players,
		"currentRound": current_round,
		"currentPI": current_pi,
		"totalRounds": total_rounds,
		"diceMode": dice_mode,
		"starsData": stars,
		"isLastThreeRounds": is_last_three,
		"starPrice": star_price,
		"bonusRedPacket": bonus_red_packet,
		"npcs": npcs_in_play,
	})

# ===== 棋盘构建 =====
func _build_board() -> void:
	# 居中放置
	var board_size := board_root.size
	if board_size == Vector2.ZERO:
		board_size = get_viewport_rect().size - Vector2(360 + 48, 32)
	var spec_w := 7.0 * BoardSpecRef.ST + BoardSpecRef.TILE_W
	var spec_h := 6.0 * BoardSpecRef.ST + BoardSpecRef.TILE_W
	board_origin = Vector2(
		max(0.0, (board_size.x - spec_w) * 0.5),
		max(0.0, (board_size.y - spec_h) * 0.5)
	)
	tile_positions = BoardSpecRef.get_tile_positions(board_origin)
	for i in BoardSpecRef.BOARD_SIZE:
		var t_type: String = BoardSpecRef.tile_type_for(i, npc_slot_indices)
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = BoardSpecRef.tile_color_for_type(t_type)
		sb.border_color = Color(1, 1, 1, 0.7)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		pc.add_theme_stylebox_override("panel", sb)
		pc.position = tile_positions[i]
		pc.size = Vector2(BoardSpecRef.TILE_W, BoardSpecRef.TILE_W)
		pc.custom_minimum_size = pc.size
		var l := UIUtil.make_label(BoardSpecRef.tile_emoji_for_type(t_type), 28, Color.WHITE, true)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pc.add_child(l)
		var idx_l := UIUtil.make_label(str(i), 12, Color(1, 1, 1, 0.7))
		idx_l.position = Vector2(4, 2)
		pc.add_child(idx_l)
		board_root.add_child(pc)
		tile_visuals.append(pc)

	# NPC 头像贴在格子上方
	for i in npc_slot_indices.size():
		var slot_idx: int = npc_slot_indices[i]
		if i >= npcs_in_play.size():
			continue
		var n: Dictionary = npcs_in_play[i]
		var avatar := TextureRect.new()
		avatar.texture = UIUtil.avatar_texture(String(n.get("avatar", "")))
		avatar.custom_minimum_size = Vector2(36, 36)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.position = tile_positions[slot_idx] + Vector2(BoardSpecRef.TILE_W * 0.5 - 18, -22)
		avatar.size = Vector2(36, 36)
		var ring := Panel.new()
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(0, 0, 0, 0.0)
		rsb.border_color = UIUtil.parse_color(String(n.get("color", "#9b59b6")))
		rsb.set_border_width_all(2)
		rsb.set_corner_radius_all(20)
		ring.add_theme_stylebox_override("panel", rsb)
		ring.position = avatar.position - Vector2(2, 2)
		ring.size = Vector2(40, 40)
		npc_root.add_child(ring)
		npc_root.add_child(avatar)
		npc_visuals.append({"avatar": avatar, "ring": ring, "slot": slot_idx})

# ===== 玩家棋子 =====
func _build_players() -> void:
	for i in players.size():
		var p: Dictionary = players[i]
		var token := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = UIUtil.parse_color(String(p.get("color", "#e74c3c")))
		sb.border_color = Color.WHITE
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(BoardSpecRef.TOKEN_R + 2)
		token.add_theme_stylebox_override("panel", sb)
		token.size = Vector2(BoardSpecRef.TOKEN_R * 2, BoardSpecRef.TOKEN_R * 2)
		token.custom_minimum_size = token.size
		var label := UIUtil.make_label(String(p.get("name", "")).substr(0, 1), 14, Color.WHITE, true)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		token.add_child(label)
		token_root.add_child(token)
		token_visuals.append(token)
	_layout_tokens_at_positions()

func _layout_tokens_at_positions() -> void:
	# 同格内多人偏移
	var pos_to_players: Dictionary = {}
	for i in players.size():
		var pos: int = int(players[i].get("position", 0))
		if not pos_to_players.has(pos):
			pos_to_players[pos] = []
		pos_to_players[pos].append(i)
	for pos in pos_to_players.keys():
		var occupants: Array = pos_to_players[pos]
		for k in occupants.size():
			var pi: int = occupants[k]
			var center := tile_positions[pos] + Vector2(BoardSpecRef.TILE_W * 0.5, BoardSpecRef.TILE_W * 0.5) - Vector2(BoardSpecRef.TOKEN_R, BoardSpecRef.TOKEN_R)
			var offset := Vector2.ZERO
			if occupants.size() == 2:
				offset = Vector2(-12 + 24 * k, 0)
			elif occupants.size() >= 3:
				var x_factor: float = 1.0 if occupants.size() <= 3 else 0.6
				offset = Vector2((-16 + 16 * k) * x_factor, (k % 2) * 12 - 6)
			(token_visuals[pi] as Control).position = center + offset

# ===== 星星 =====
func _build_stars_initial() -> void:
	_rebuild_stars_view()

func _rebuild_stars_view() -> void:
	for v in star_visuals:
		v.queue_free()
	star_visuals.clear()
	for s in stars:
		var pos: int = int(s.get("position", 0))
		var t: String = String(s.get("type", "permanent"))
		var emoji_text: String = "⭐" if t == "permanent" else "🌟"
		var label := UIUtil.make_label(emoji_text, 36, UIUtil.C_GOLD, true)
		label.position = tile_positions[pos] + Vector2(BoardSpecRef.TILE_W * 0.5 - 22, -10)
		label.size = Vector2(44, 44)
		star_root.add_child(label)
		star_visuals.append(label)
		# 浮动动画
		var tw := create_tween().set_loops()
		tw.tween_property(label, "position:y", label.position.y - 6, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(label, "position:y", label.position.y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _random_star_pos(exclude_positions: Array = []) -> int:
	var taken: Array = exclude_positions.duplicate()
	for s in stars:
		taken.append(int(s.get("position", 0)))
	var pool: Array = []
	for i in range(1, BoardSpecRef.BOARD_SIZE):
		if not taken.has(i):
			pool.append(i)
	if pool.is_empty():
		return 1
	return pool.pick_random()

# ===== 信息面板 =====
func _refresh_panels() -> void:
	for c in info_panel.get_children():
		c.queue_free()
	info_panel.add_child(UIUtil.make_label("第 %d / %d 轮" % [current_round, total_rounds], 22, UIUtil.C_GOLD))
	info_panel.add_child(UIUtil.make_label("⭐ 星星价格：%d 金币" % star_price, 16))
	if is_last_three and total_rounds > 3:
		info_panel.add_child(UIUtil.make_label("🔥 最后三轮 加速决战！", 16, Color("#e74c3c")))
	if bonus_red_packet > 0:
		info_panel.add_child(UIUtil.make_label("🧧 加码红包池：%d 元" % bonus_red_packet, 16, Color("#e74c3c")))

	for c in players_panel.get_children():
		c.queue_free()
	for i in players.size():
		var p: Dictionary = players[i]
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.5)
		sb.border_color = UIUtil.C_GOLD if i == current_pi else Color(0, 0, 0, 0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		pc.add_theme_stylebox_override("panel", sb)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		pc.add_child(hb)
		var av := TextureRect.new()
		av.texture = UIUtil.avatar_texture(String(p.get("avatar", "")))
		av.custom_minimum_size = Vector2(36, 36)
		av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hb.add_child(av)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(v)
		v.add_child(UIUtil.make_label(String(p.get("name", "")), 16, UIUtil.parse_color(String(p.get("color", "#ffffff")))))
		v.add_child(UIUtil.make_label("⭐ %d   💰 %d   📍格 %d" % [int(p.get("stars", 0)), int(p.get("coins", 0)), int(p.get("position", 0))], 14))
		players_panel.add_child(pc)

func _set_hint(text: String) -> void:
	hint_label.text = text

# ===== 回合流程 =====
func _enter_waiting_dice() -> void:
	if current_round > total_rounds:
		_game_over()
		return
	phase = "waiting_dice"
	_refresh_panels()
	var p: Dictionary = players[current_pi]
	if auto_play:
		_e2e_log("round=%d/%d pi=%d %s coins=%d stars=%d pos=%d" % [
			current_round, total_rounds, current_pi,
			String(p.get("name", "")), int(p.get("coins", 0)),
			int(p.get("stars", 0)), int(p.get("position", 0))])
	_set_hint("👉 %s 投骰子（按空格或点击 · F2 自动）" % String(p.get("name", "")))
	roll_button.disabled = false
	external_input.visible = (dice_mode == "external")
	if auto_play:
		await get_tree().create_timer(0.2).timeout
		if phase == "waiting_dice":
			_roll_dice()

func _e2e_log(msg: String) -> void:
	var f := FileAccess.open("user://e2e.log", FileAccess.READ_WRITE if FileAccess.file_exists("user://e2e.log") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("[%s] %s" % [Time.get_datetime_string_from_system(), msg])
	f.close()

func _on_roll_pressed() -> void:
	if phase != "waiting_dice":
		return
	_roll_dice()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if phase == "waiting_dice":
				_roll_dice()
		elif event.keycode == KEY_F2:
			auto_play = not auto_play
			UIUtil.toast(self, "自动驾驶：%s" % ("ON" if auto_play else "OFF"), 1.0)
			if auto_play and phase == "waiting_dice":
				_roll_dice()

func _roll_dice() -> void:
	phase = "rolling"
	roll_button.disabled = true
	AudioBus.play_dice()
	var value: int = int(external_input.value) if dice_mode == "external" else randi_range(1, 6)
	dice_label.text = "🎲 ..."
	await dice3d.roll_to(value)
	dice_label.text = "🎲 %d" % value
	await get_tree().create_timer(0.25).timeout
	await _move_player(current_pi, value)
	await _resolve_landing(current_pi)
	_save_progress()
	_advance_turn()

func _move_player(pi: int, steps: int) -> void:
	phase = "moving"
	if steps == 0:
		return
	var direction: int = 1 if steps > 0 else -1
	for _i in range(abs(steps)):
		var p: Dictionary = players[pi]
		var new_pos: int = (int(p.get("position", 0)) + direction) % BoardSpecRef.BOARD_SIZE
		if new_pos < 0:
			new_pos += BoardSpecRef.BOARD_SIZE
		players[pi]["position"] = new_pos
		AudioBus.play_step()
		_animate_token_to(pi, new_pos)
		await get_tree().create_timer(MOVE_STEP_TIME).timeout
		# 经过星星格 → 尝试购买（每步都检查，对应 H5 movePlayer）
		var star_idx: int = _star_at(new_pos)
		if star_idx >= 0:
			await _try_buy_star(pi, star_idx)

func _animate_token_to(pi: int, _pos_idx: int) -> void:
	# 重新布局所有同格 token
	_layout_tokens_at_positions()
	var t: Control = token_visuals[pi]
	var tw := create_tween()
	tw.tween_property(t, "scale", Vector2(1.25, 1.25), MOVE_STEP_TIME * 0.4).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(t, "scale", Vector2(1.0, 1.0), MOVE_STEP_TIME * 0.5).set_trans(Tween.TRANS_QUAD)

# ===== 落地结算 =====
func _resolve_landing(pi: int) -> void:
	phase = "event"
	var pos: int = int(players[pi].get("position", 0))
	var t_type: String = BoardSpecRef.tile_type_for(pos, npc_slot_indices)
	match t_type:
		BoardSpecRef.TYPE_EVENT:
			await _trigger_player_event(pi)
		BoardSpecRef.TYPE_SYSTEM:
			await _trigger_system_event(pi)
		BoardSpecRef.TYPE_COIN:
			await _trigger_coin_event(pi)
		BoardSpecRef.TYPE_NPC:
			var npc_i: int = npc_slot_indices.find(pos)
			if npc_i >= 0 and npc_i < npcs_in_play.size():
				await _trigger_npc_event(pi, npcs_in_play[npc_i])

func _star_at(pos: int) -> int:
	for i in stars.size():
		if int(stars[i].get("position", -1)) == pos:
			return i
	return -1

func _try_buy_star(pi: int, star_idx: int) -> void:
	var p: Dictionary = players[pi]
	if int(p.get("coins", 0)) < star_price:
		await _show_modal("⭐ 经过星星", "%s 经过 ⭐\n但只有 %d 金币（需要 %d）\n看着星星离开了……" % [String(p.get("name", "")), int(p.get("coins", 0)), star_price], 1.6)
		return
	var s_type: String = String(stars[star_idx].get("type", "permanent"))
	var price := star_price
	players[pi]["coins"] = int(p.get("coins", 0)) - price
	players[pi]["stars"] = int(p.get("stars", 0)) + 1
	AudioBus.play_star()
	if s_type == "permanent":
		stars[star_idx]["position"] = _random_star_pos([int(players[pi]["position"])])
	else:
		stars.remove_at(star_idx)
	star_price = STAR_PRICE_DEFAULT
	_rebuild_stars_view()
	_refresh_panels()
	await _show_modal("⭐ 收获星星！", "%s 花费 %d 金币\n收获 1 颗 %s 星星！" % [String(players[pi].get("name", "")), price, "永久" if s_type == "permanent" else "一次性"], 1.6)

# --- 玩家随机事件 ---
func _trigger_player_event(pi: int) -> void:
	AudioBus.play_event()
	var pool: Array = EventDB.gen_player_event_pool(8)
	if pool.is_empty():
		return
	var picked: Dictionary = await _spin_picker("❗ 随机事件", pool, "name")
	_apply_event_to_player(pi, picked, "")

func _apply_event_to_player(pi: int, ev: Dictionary, npc_name: String) -> void:
	var p: Dictionary = players[pi]
	var coins_delta := int(ev.get("coins", 0))
	if String(ev.get("type", "")) == "punishment" and coins_delta == 0:
		coins_delta = 0  # 文案性惩罚
	if coins_delta != 0:
		players[pi]["coins"] = max(0, int(p.get("coins", 0)) + coins_delta)
		if coins_delta > 0:
			AudioBus.play_coin()
		else:
			AudioBus.play_loss()
	var rec := {
		"id": ev.get("id", ""),
		"name": ev.get("name", ""),
		"icon": ev.get("icon", ""),
		"type": ev.get("type", "reward"),
	}
	if not npc_name.is_empty():
		rec["category"] = "npc"
		rec["npcName"] = npc_name
	(players[pi]["eventLog"] as Array).append(rec)
	_refresh_panels()

# --- 系统事件 ---
func _trigger_system_event(pi: int) -> void:
	AudioBus.play_event()
	var pool: Array = []
	for i in 6:
		pool.append(EventDB.roll_system_event(_filter_system_event_for(pi)))
	var picked: Dictionary = await _spin_picker("⚡ 系统事件", pool, "name")
	await _apply_system_event(pi, picked)

func _filter_system_event_for(_pi: int) -> Callable:
	# 必要时过滤掉无意义的事件（玩家不足两人时无法换位置等）
	return func(e: Dictionary) -> bool:
		match String(e.get("id", "")):
			"sys_swap_player": return players.size() >= 2
			"sys_near_star": return stars.size() > 0
			"sys_steal_coins": return players.size() >= 2
			_: return true

func _apply_system_event(pi: int, ev: Dictionary) -> void:
	var p: Dictionary = players[pi]
	match String(ev.get("id", "")):
		"sys_star_move":
			if stars.size() > 0:
				stars[0]["position"] = _random_star_pos([int(p["position"])])
				_rebuild_stars_view()
			await _show_modal("⭐ 星星换位置", "星星挪到了新位置！", 1.4)
		"sys_forward_10":
			await _show_modal("🚀 往前走10格", "冲！", 0.8)
			await _move_player(pi, 10)
			await _resolve_landing(pi)
		"sys_backward_5":
			await _show_modal("🐢 往后走5格", "退！", 0.8)
			await _move_player(pi, -5)
			await _resolve_landing(pi)
		"sys_swap_player":
			var other: int = pi
			while other == pi:
				other = randi() % players.size()
			var pos_a: int = int(players[pi]["position"])
			var pos_b: int = int(players[other]["position"])
			players[pi]["position"] = pos_b
			players[other]["position"] = pos_a
			_layout_tokens_at_positions()
			await _show_modal("🔄 换位置", "%s 与 %s 互换了位置！" % [
				String(players[pi]["name"]), String(players[other]["name"])
			], 1.6)
		"sys_near_star":
			if stars.size() > 0:
				var sp: int = int(stars[0]["position"])
				var target: int = (sp - 2 + BoardSpecRef.BOARD_SIZE) % BoardSpecRef.BOARD_SIZE
				players[pi]["position"] = target
				_layout_tokens_at_positions()
			await _show_modal("🌠 走到星星前两格", "好运降临！", 1.2)
		"sys_random_pos":
			players[pi]["position"] = randi() % BoardSpecRef.BOARD_SIZE
			_layout_tokens_at_positions()
			await _show_modal("🎲 跳到随机位置", "命运的安排！", 1.2)
			await _resolve_landing(pi)
		"sys_steal_coins":
			var victim: int = pi
			while victim == pi:
				victim = randi() % players.size()
			var amt: int = randi_range(1, 8)
			amt = mini(amt, int(players[victim]["coins"]))
			if amt > 0:
				players[victim]["coins"] = int(players[victim]["coins"]) - amt
				players[pi]["coins"] = int(players[pi]["coins"]) + amt
				AudioBus.play_coin()
			await _show_modal("🕵️ 抽取金币", "%s 抽走了 %s 的 %d 金币！" % [
				String(players[pi]["name"]), String(players[victim]["name"]), amt], 1.6)
		"sys_star_price_up":
			star_price = mini(STAR_PRICE_MAX, star_price + 5)
			await _show_modal("📈 星星涨价", "现在每颗星星 %d 金币！" % star_price, 1.4)
		"sys_star_price_down":
			star_price = max(0, star_price - 5)
			await _show_modal("📉 星星降价", "现在每颗星星 %d 金币！" % star_price, 1.4)
		"sys_add_star":
			stars.append({"position": _random_star_pos([int(p["position"])]), "type": "onetime"})
			_rebuild_stars_view()
			await _show_modal("🌟 额外星星", "场上新增一颗一次性星星！", 1.4)
		"sys_get_coin":
			players[pi]["coins"] = int(p["coins"]) + 1
			AudioBus.play_coin()
			await _show_modal("💰 获得 1 金币", "天降金币！", 1.0)
	(players[pi]["eventLog"] as Array).append({
		"id": ev.get("id", ""), "name": ev.get("name", ""),
		"icon": ev.get("icon", ""), "type": "reward",
	})
	_refresh_panels()

# --- 金币事件 ---
func _trigger_coin_event(pi: int) -> void:
	AudioBus.play_event()
	var pool: Array = EventDB.gen_coin_event_pool(6)
	var picked: Dictionary = await _spin_picker("💰 金币事件", pool, "name")
	var d: int = int(picked.get("delta", 0))
	if d != 0:
		players[pi]["coins"] = max(0, int(players[pi]["coins"]) + d)
		if d > 0:
			AudioBus.play_coin()
		else:
			AudioBus.play_loss()
	(players[pi]["eventLog"] as Array).append({
		"id": picked.get("id", ""), "name": picked.get("name", ""),
		"icon": picked.get("icon", ""),
		"type": "reward" if d >= 0 else "punishment",
	})
	_refresh_panels()

# --- NPC 遭遇 ---
func _trigger_npc_event(pi: int, npc: Dictionary) -> void:
	AudioBus.play_event()
	var pool: Array = EventDB.gen_npc_event_pool(6)
	if pool.is_empty():
		return
	var picked: Dictionary = await _spin_picker("👥 遇见 %s" % String(npc.get("name", "")), pool, "name")
	match String(picked.get("id", "")):
		"ne_redice":
			await _show_modal("🎲 NPC 帮忙再摇一次", "%s 替你掷骰子……" % String(npc.get("name", "")), 1.0)
			var v: int = randi_range(1, 6)
			await dice3d.roll_to(v)
			dice_label.text = "🎲 %d" % v
			await _move_player(pi, v)
			await _resolve_landing(pi)
		"ne_jiama":
			var rp: Dictionary = EventDB.roll_red_packet()
			bonus_red_packet += int(rp.get("amount", 0))
			await _show_modal("🎁 加码最终大奖", "%s 加码 %s\n累计 %d 元！" % [
				String(npc.get("name", "")), String(rp.get("name", "")), bonus_red_packet], 1.8)
		_:
			_apply_event_to_player(pi, picked, String(npc.get("name", "")))
			await _show_modal("👥 NPC 遭遇", "%s 触发：%s %s" % [
				String(npc.get("name", "")), String(picked.get("icon", "")), String(picked.get("name", ""))], 1.6)

# ===== 回合切换 =====
func _advance_turn() -> void:
	current_pi += 1
	if current_pi >= players.size():
		current_pi = 0
		await _maybe_minigame_phase()
		current_round += 1
		_check_last_three(false)
	if current_round > total_rounds:
		_game_over()
		return
	_save_progress()
	_enter_waiting_dice()

func _check_last_three(_initial: bool) -> void:
	if total_rounds <= 3:
		is_last_three = true
		AudioBus.speed_up_bgm()
		return
	if current_round >= total_rounds - 2 and not is_last_three:
		is_last_three = true
		AudioBus.speed_up_bgm()
		# 全员获得永久星星 +1（H5 版逻辑）
		for i in players.size():
			players[i]["stars"] = int(players[i].get("stars", 0)) + 1
		_show_modal("🔥 最后三轮", "决战时刻！每人获得 1 颗永久星星！", 2.5)

# ===== 小游戏阶段 =====
func _maybe_minigame_phase() -> void:
	if players.size() < 2:
		return
	var mg: Dictionary = EventDB.pick_minigame()
	if mg.is_empty():
		return
	EventDB.consume_minigame(String(mg.get("id", "")))
	await _show_modal("🎮 小游戏：%s" % String(mg.get("name", "")), "%s\n胜利条件：%s" % [
		String(mg.get("icon", "")), String(mg.get("winCondition", ""))], 2.4)
	# 由用户/家长手动点选胜者（最多 3 人）
	var winners: Array = await _pick_minigame_winners(mg)
	if winners.is_empty():
		return
	var win_coins: int = 5 - (winners.size() - 1)  # 1人=5 / 2人=4 / 3人=3
	for i in players.size():
		var amt: int = win_coins if winners.has(i) else 2
		players[i]["coins"] = int(players[i].get("coins", 0)) + amt
	AudioBus.play_coin()
	var winner_names: Array[String] = []
	for w in winners:
		winner_names.append(String(players[w].get("name", "")))
	await _show_modal("🏅 小游戏结算", "胜者：%s（每人 +%d 💰）\n其他人 +2 💰" % [", ".join(winner_names), win_coins], 2.2)
	_refresh_panels()

func _pick_minigame_winners(mg: Dictionary) -> Array:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	pc.custom_minimum_size = Vector2(560, 0)
	center.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	v.add_child(UIUtil.make_label("%s %s" % [String(mg.get("icon", "🎮")), String(mg.get("name", ""))], 30, UIUtil.C_GOLD, true))
	v.add_child(UIUtil.make_label("🏆 胜利条件：%s" % String(mg.get("winCondition", "")), 18, Color.WHITE, true))
	v.add_child(UIUtil.make_label("👆 点击玩家头像选择胜利者（最多 3 人）", 14, Color(0.85, 0.85, 0.85), true))

	var selected: Array = []
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 16)
	hb.add_theme_constant_override("v_separation", 12)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(hb)

	var update_visual := func(idx: int, btn: Button):
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(3)
		sb.border_color = UIUtil.C_GOLD if selected.has(idx) else Color(1, 1, 1, 0.25)
		sb.bg_color = Color(0.18, 0.10, 0.04, 0.85) if selected.has(idx) else Color(0, 0, 0, 0.45)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)

	for i in players.size():
		var p: Dictionary = players[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 150)
		btn.flat = true
		hb.add_child(btn)
		var inner := VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(inner)
		var av := TextureRect.new()
		av.texture = UIUtil.avatar_texture(String(p.get("avatar", "")))
		av.custom_minimum_size = Vector2(72, 72)
		av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		inner.add_child(av)
		inner.add_child(UIUtil.make_label(String(p.get("name", "")), 18,
			UIUtil.parse_color(String(p.get("color", "#ffffff"))), true))
		var idx := i
		update_visual.call(idx, btn)
		btn.pressed.connect(func():
			AudioBus.play_click()
			if selected.has(idx):
				selected.erase(idx)
			else:
				if selected.size() >= 3:
					UIUtil.toast(self, "最多选择 3 位胜利者！", 1.4)
					return
				selected.append(idx)
			update_visual.call(idx, btn))

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	v.add_child(actions)
	var b_confirm := UIUtil.styled_button("✅ 确认胜利者", true, true)
	actions.add_child(b_confirm)

	var done := [false]
	b_confirm.pressed.connect(func():
		if selected.is_empty():
			UIUtil.toast(self, "请至少选择一位胜利者！", 1.4)
			return
		AudioBus.play_star()
		done[0] = true)

	if auto_play:
		# 自动选第一个玩家为胜者
		await get_tree().create_timer(0.5).timeout
		selected.append(0)
		AudioBus.play_star()
		done[0] = true

	while not done[0]:
		await get_tree().process_frame
	bg.queue_free()
	return selected.duplicate()

# ===== 游戏结束 =====
func _game_over() -> void:
	phase = "gameover"
	print("[E2E] GAME OVER bonusRedPacket=%d" % bonus_red_packet)
	for i in players.size():
		var p: Dictionary = players[i]
		print("[E2E]   %s: stars=%d coins=%d events=%d" % [
			String(p.get("name", "")), int(p.get("stars", 0)),
			int(p.get("coins", 0)), (p.get("eventLog", []) as Array).size()])
	GameStore.clear_game_progress()
	AudioBus.stop_bgm()
	SceneRouter.goto(SceneRouter.SCENE_RESULTS, {
		"players": players.duplicate(true),
		"bonusRedPacket": bonus_red_packet,
	})

# ===== 通用 UI: Modal & Spin Picker =====
func _show_modal(title: String, body: String, dur: float = 1.5) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	pc.custom_minimum_size = Vector2(420, 0)
	center.add_child(pc)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	v.add_child(UIUtil.make_label(title, 28, UIUtil.C_GOLD, true))
	v.add_child(UIUtil.make_label(body, 18, Color.WHITE, true))

	bg.scale = Vector2(0.85, 0.85)
	bg.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(bg, "modulate:a", 1.0, 0.18)
	tw.tween_property(bg, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(dur).timeout
	var tw2 := create_tween()
	tw2.tween_property(bg, "modulate:a", 0.0, 0.2)
	await tw2.finished
	bg.queue_free()

func _spin_picker(title: String, pool: Array, name_key: String) -> Dictionary:
	# 在 modal 中滚动展示 pool, 最后停在 final_index
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIUtil.panel_bg())
	pc.custom_minimum_size = Vector2(440, 0)
	center.add_child(pc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	pc.add_child(v)
	v.add_child(UIUtil.make_label(title, 28, UIUtil.C_GOLD, true))
	var spin_label := UIUtil.make_label("", 32, Color.WHITE, true)
	spin_label.custom_minimum_size = Vector2(0, 60)
	v.add_child(spin_label)
	var sub := UIUtil.make_label("", 16, Color(1, 0.85, 0.4), true)
	v.add_child(sub)

	var t0 := Time.get_ticks_msec()
	var dur := 1500
	var elapsed := 0
	while elapsed < dur:
		var item: Dictionary = pool[randi() % pool.size()]
		spin_label.text = "%s %s" % [String(item.get("icon", "")), String(item.get(name_key, ""))]
		AudioBus.play_step()
		var step: int = clampi(60 + int(elapsed * 0.18), 60, 220)
		await get_tree().create_timer(step / 1000.0).timeout
		elapsed = Time.get_ticks_msec() - t0
	var final_item: Dictionary = pool[randi() % pool.size()]
	spin_label.text = "%s %s" % [String(final_item.get("icon", "")), String(final_item.get(name_key, ""))]
	sub.text = String(final_item.get("description", ""))
	AudioBus.play_event()
	# 高光闪烁
	var tw := create_tween().set_loops(3)
	tw.tween_property(spin_label, "modulate", Color(1.4, 1.2, 0.4), 0.15)
	tw.tween_property(spin_label, "modulate", Color.WHITE, 0.15)
	await get_tree().create_timer(1.0).timeout
	bg.queue_free()
	return final_item
