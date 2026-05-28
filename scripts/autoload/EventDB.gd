extends Node
## 事件库与抽奖逻辑：随机事件 / NPC 事件 / 系统事件 / 金币事件 / 加码红包池 / 迷你游戏选择。
## 对应 game.js 的 SYSTEM_EVENTS / COIN_EVENTS / RED_PACKETS 与小游戏选择算法。

const SYSTEM_EVENTS_PATH := "res://data/system_events.json"

var system_events_cache: Array = []

func _ready() -> void:
	system_events_cache = SaveSystem.load_default_json(SYSTEM_EVENTS_PATH)

# ===== 系统事件池 =====
func get_system_events() -> Array:
	return system_events_cache.duplicate(true)

func roll_system_event(filter: Callable = Callable()) -> Dictionary:
	var pool: Array = system_events_cache.duplicate(true)
	if filter.is_valid():
		pool = pool.filter(filter)
	if pool.is_empty():
		return system_events_cache[0]
	return pool.pick_random()

# ===== 金币事件池 (-3 ~ +8) =====
func roll_coin_event() -> Dictionary:
	var n: int = randi_range(-3, 8)
	if n < 0:
		return {"id": "coin_lose_%d" % -n, "name": "💸 失去 %d 金币" % -n, "icon": "💸", "delta": n}
	return {"id": "coin_get_%d" % n, "name": "💰 获得 %d 金币" % n, "icon": "💰", "delta": n}

func gen_coin_event_pool(size: int = 6) -> Array:
	var arr: Array = []
	for i in size:
		arr.append(roll_coin_event())
	return arr

# ===== 加码红包池 =====
const RED_PACKETS := [
	{"amount": 5,   "name": "🧧 5元红包"},
	{"amount": 10,  "name": "🧧 10元红包"},
	{"amount": 20,  "name": "🧧 20元红包"},
	{"amount": 50,  "name": "🧧 50元红包"},
	{"amount": 100, "name": "🧧 100元红包"}
]

func roll_red_packet() -> Dictionary:
	return RED_PACKETS.pick_random()

# ===== 玩家随机事件 =====
func roll_player_event() -> Dictionary:
	var arr: Array = GameStore.get_events()
	if arr.is_empty():
		return {"id": "ev_none", "name": "无事发生", "icon": "❔", "type": "reward", "description": ""}
	return arr.pick_random()

func gen_player_event_pool(size: int = 6) -> Array:
	var arr: Array = GameStore.get_events()
	if arr.is_empty():
		return []
	var out: Array = []
	for i in size:
		out.append(arr.pick_random())
	return out

# ===== NPC 事件 =====
func roll_npc_event() -> Dictionary:
	var arr: Array = GameStore.get_npc_events()
	if arr.is_empty():
		return {"id": "ne_none", "name": "无事发生", "icon": "❔", "type": "reward", "description": ""}
	return arr.pick_random()

func gen_npc_event_pool(size: int = 6) -> Array:
	var arr: Array = GameStore.get_npc_events()
	if arr.is_empty():
		return []
	var out: Array = []
	for i in size:
		out.append(arr.pick_random())
	return out

# ===== 迷你游戏选择 =====
func pick_minigame() -> Dictionary:
	var games: Array = GameStore.get_minigames()
	if games.is_empty():
		return {}
	# 1) 首次保证
	for g in games:
		if bool(g.get("guaranteeFirst", false)) and not bool(g.get("hasTriggered", false)) and int(g.get("remainingCount", 0)) > 0:
			return g
	# 2) probability=100 且剩余次数>0
	var p100: Array = games.filter(func(g): return int(g.get("probability", 0)) >= 100 and int(g.get("remainingCount", 0)) > 0)
	if p100.size() > 0:
		return p100.pick_random()
	# 3) 加权随机
	var pool: Array = games.filter(func(g): return int(g.get("remainingCount", 0)) > 0)
	if pool.is_empty():
		return games.pick_random()
	var total: float = 0.0
	for g in pool:
		total += float(g.get("probability", 0))
	if total <= 0.0:
		return pool.pick_random()
	var r: float = randf() * total
	var acc: float = 0.0
	for g in pool:
		acc += float(g.get("probability", 0))
		if r <= acc:
			return g
	return pool[-1]

func consume_minigame(id: String) -> void:
	var games: Array = GameStore.get_minigames()
	for i in games.size():
		if String(games[i].get("id", "")) == id:
			games[i]["hasTriggered"] = true
			games[i]["remainingCount"] = max(0, int(games[i].get("remainingCount", 1)) - 1)
	GameStore.save_minigames(games)
