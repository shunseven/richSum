extends Node
## 游戏全局状态 + 编辑器数据存取。
## 对应 richRain 的 store.js（rr_* localStorage 键）。

signal data_changed(table: String)

const KEY_CHARACTERS := "rr_characters"
const KEY_NPCS := "rr_npcs"
const KEY_MINIGAMES := "rr_minigames"
const KEY_EVENTS := "rr_events"
const KEY_NPCEVENTS := "rr_npcevents"
const KEY_FINALPRIZE := "rr_finalprize"
const KEY_PROGRESS := "rr_game_progress"
const KEY_SETTINGS := "rr_settings"

const DEFAULT_CHARACTERS := "res://data/default_characters.json"
const DEFAULT_NPCS := "res://data/default_npcs.json"
const DEFAULT_MINIGAMES := "res://data/default_minigames.json"
const DEFAULT_EVENTS := "res://data/default_events.json"
const DEFAULT_NPCEVENTS := "res://data/default_npc_events.json"
const DEFAULT_PRIZE := "res://data/default_prize.json"

func _ready() -> void:
	# 首次启动写入默认数据
	if not SaveSystem.has(KEY_CHARACTERS):
		reset_all()

# ===== Characters =====
func get_characters() -> Array:
	return SaveSystem.load_data(KEY_CHARACTERS, [])

func save_characters(arr: Array) -> void:
	SaveSystem.save_data(KEY_CHARACTERS, arr)
	data_changed.emit("characters")

func add_character(c: Dictionary) -> Array:
	var arr: Array = get_characters()
	c["id"] = _gen_id("ch")
	arr.append(c)
	save_characters(arr)
	return arr

func update_character(id: String, patch: Dictionary) -> Array:
	var arr: Array = get_characters()
	for i in arr.size():
		if String(arr[i].get("id", "")) == id:
			for k in patch.keys():
				arr[i][k] = patch[k]
	save_characters(arr)
	return arr

func delete_character(id: String) -> Array:
	var arr: Array = get_characters().filter(func(c): return String(c.get("id", "")) != id)
	save_characters(arr)
	return arr

# ===== NPCs =====
func get_npcs() -> Array:
	return SaveSystem.load_data(KEY_NPCS, [])

func save_npcs(arr: Array) -> void:
	SaveSystem.save_data(KEY_NPCS, arr)
	data_changed.emit("npcs")

func add_npc(n: Dictionary) -> Array:
	var arr: Array = get_npcs()
	n["id"] = _gen_id("npc")
	arr.append(n)
	save_npcs(arr)
	return arr

func update_npc(id: String, patch: Dictionary) -> Array:
	var arr: Array = get_npcs()
	for i in arr.size():
		if String(arr[i].get("id", "")) == id:
			for k in patch.keys():
				arr[i][k] = patch[k]
	save_npcs(arr)
	return arr

func delete_npc(id: String) -> Array:
	var arr: Array = get_npcs().filter(func(n): return String(n.get("id", "")) != id)
	save_npcs(arr)
	return arr

# ===== MiniGames =====
func get_minigames() -> Array:
	return SaveSystem.load_data(KEY_MINIGAMES, [])

func save_minigames(arr: Array) -> void:
	SaveSystem.save_data(KEY_MINIGAMES, arr)
	data_changed.emit("minigames")

func add_minigame(g: Dictionary) -> Array:
	var arr: Array = get_minigames()
	g["id"] = _gen_id("mg")
	if not g.has("remainingCount"):
		g["remainingCount"] = int(g.get("maxCount", 1))
	g["hasTriggered"] = false
	arr.append(g)
	save_minigames(arr)
	return arr

func update_minigame(id: String, patch: Dictionary) -> Array:
	var arr: Array = get_minigames()
	for i in arr.size():
		if String(arr[i].get("id", "")) == id:
			for k in patch.keys():
				arr[i][k] = patch[k]
			arr[i]["remainingCount"] = int(arr[i].get("maxCount", 1))
	save_minigames(arr)
	return arr

func delete_minigame(id: String) -> Array:
	var arr: Array = get_minigames().filter(func(g): return String(g.get("id", "")) != id)
	save_minigames(arr)
	return arr

func reset_minigame_counts() -> Array:
	var arr: Array = get_minigames()
	for i in arr.size():
		arr[i]["remainingCount"] = int(arr[i].get("maxCount", 1))
		arr[i]["hasTriggered"] = false
	save_minigames(arr)
	return arr

# ===== Events =====
func get_events() -> Array:
	return SaveSystem.load_data(KEY_EVENTS, [])

func save_events(arr: Array) -> void:
	SaveSystem.save_data(KEY_EVENTS, arr)
	data_changed.emit("events")

func add_event(ev: Dictionary) -> Array:
	var arr: Array = get_events()
	ev["id"] = _gen_id("ev")
	arr.append(ev)
	save_events(arr)
	return arr

func update_event(id: String, patch: Dictionary) -> Array:
	var arr: Array = get_events()
	for i in arr.size():
		if String(arr[i].get("id", "")) == id:
			for k in patch.keys():
				arr[i][k] = patch[k]
	save_events(arr)
	return arr

func delete_event(id: String) -> Array:
	var arr: Array = get_events().filter(func(e): return String(e.get("id", "")) != id)
	save_events(arr)
	return arr

# ===== NPC Events =====
func get_npc_events() -> Array:
	return SaveSystem.load_data(KEY_NPCEVENTS, [])

func save_npc_events(arr: Array) -> void:
	SaveSystem.save_data(KEY_NPCEVENTS, arr)
	data_changed.emit("npc_events")

func add_npc_event(ev: Dictionary) -> Array:
	var arr: Array = get_npc_events()
	ev["id"] = _gen_id("ne")
	arr.append(ev)
	save_npc_events(arr)
	return arr

func update_npc_event(id: String, patch: Dictionary) -> Array:
	var arr: Array = get_npc_events()
	for i in arr.size():
		if String(arr[i].get("id", "")) == id:
			for k in patch.keys():
				arr[i][k] = patch[k]
	save_npc_events(arr)
	return arr

func delete_npc_event(id: String) -> Array:
	var arr: Array = get_npc_events().filter(func(e): return String(e.get("id", "")) != id)
	save_npc_events(arr)
	return arr

# ===== Final Prize =====
func get_final_prize() -> Dictionary:
	return SaveSystem.load_data(KEY_FINALPRIZE, {"name": "新春大奖", "icon": "🏆"})

func save_final_prize(data: Dictionary) -> void:
	SaveSystem.save_data(KEY_FINALPRIZE, data)
	data_changed.emit("prize")

# ===== Game Progress =====
func save_game_progress(state: Dictionary) -> void:
	SaveSystem.save_data(KEY_PROGRESS, state)

func get_game_progress() -> Dictionary:
	var v: Variant = SaveSystem.load_data(KEY_PROGRESS, null)
	if v == null:
		return {}
	return v

func has_game_progress() -> bool:
	return SaveSystem.has(KEY_PROGRESS)

func clear_game_progress() -> void:
	SaveSystem.remove(KEY_PROGRESS)

# ===== Settings =====
func get_settings() -> Dictionary:
	return SaveSystem.load_data(KEY_SETTINGS, {"muted": false, "bgm_volume": 0.7, "sfx_volume": 0.8})

func save_settings(s: Dictionary) -> void:
	SaveSystem.save_data(KEY_SETTINGS, s)
	data_changed.emit("settings")

# ===== Reset =====
func reset_all() -> void:
	save_characters(SaveSystem.load_default_json(DEFAULT_CHARACTERS))
	save_npcs(SaveSystem.load_default_json(DEFAULT_NPCS))
	var mg: Array = SaveSystem.load_default_json(DEFAULT_MINIGAMES)
	for g in mg:
		g["remainingCount"] = int(g.get("maxCount", 1))
		g["hasTriggered"] = false
	save_minigames(mg)
	save_events(SaveSystem.load_default_json(DEFAULT_EVENTS))
	save_npc_events(SaveSystem.load_default_json(DEFAULT_NPCEVENTS))
	save_final_prize(SaveSystem.load_default_json(DEFAULT_PRIZE))
	clear_game_progress()

func _gen_id(prefix: String) -> String:
	return "%s_%d_%d" % [prefix, Time.get_ticks_msec(), randi() % 100000]
