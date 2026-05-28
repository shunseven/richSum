extends RefCounted
class_name BoardSpec
## 棋盘静态规格：24 格环形布局 + 格子类型枚举。

const BOARD_SIZE := 24
const TILE_W := 96
const ST := 110
const TOKEN_R := 16

const TYPE_START  := "start"
const TYPE_EVENT  := "event"
const TYPE_SYSTEM := "system"
const TYPE_COIN   := "coin"
const TYPE_NPC    := "npc"
const TYPE_NORMAL := "normal"

# 固定格子类型分配（保持与 H5 版完全一致）
const FIXED_TILES := {
	0:  TYPE_START,
	1:  TYPE_COIN,
	2:  TYPE_EVENT,
	3:  TYPE_SYSTEM,
	5:  TYPE_EVENT,
	7:  TYPE_COIN,
	9:  TYPE_EVENT,
	10: TYPE_SYSTEM,
	12: TYPE_COIN,
	14: TYPE_EVENT,
	15: TYPE_SYSTEM,
	17: TYPE_EVENT,
	19: TYPE_COIN,
	21: TYPE_EVENT,
	22: TYPE_SYSTEM,
}

# 24 格按环形：上 0-7（左→右），右 8-12（上→下），下 13-19（右→左），左 20-23（下→上）
static func get_tile_positions(origin: Vector2) -> Array[Vector2]:
	var arr: Array[Vector2] = []
	# top row: 0..7
	for i in 8:
		arr.append(origin + Vector2(i * ST, 0))
	# right col: 8..12 (5 个)
	for i in 5:
		arr.append(origin + Vector2(7 * ST, (i + 1) * ST))
	# bottom row: 13..19（从右往左 7 个）
	for i in 7:
		arr.append(origin + Vector2((6 - i) * ST, 6 * ST))
	# left col: 20..23（从下往上 4 个）
	for i in 4:
		arr.append(origin + Vector2(0, (5 - i) * ST))
	return arr

static func tile_type_for(idx: int, npc_slot_indices: Array) -> String:
	if FIXED_TILES.has(idx):
		return FIXED_TILES[idx]
	if npc_slot_indices.has(idx):
		return TYPE_NPC
	return TYPE_NORMAL

# NPC 占用空闲格子
static func compute_npc_slots(npc_count: int) -> Array:
	var occupied := PackedInt32Array()
	for k in FIXED_TILES.keys():
		occupied.append(int(k))
	var free: Array = []
	for i in BOARD_SIZE:
		if i == 0:
			continue
		if not occupied.has(i):
			free.append(i)
	var out: Array = []
	for i in min(npc_count, free.size()):
		out.append(free[i])
	return out

static func tile_color_for_type(t: String) -> Color:
	match t:
		TYPE_START: return Color("#ffd700")
		TYPE_EVENT: return Color("#e67e22")
		TYPE_SYSTEM: return Color("#3498db")
		TYPE_COIN: return Color("#f1c40f")
		TYPE_NPC: return Color("#9b59b6")
		_: return Color("#e74c3c")

static func tile_emoji_for_type(t: String) -> String:
	match t:
		TYPE_START: return "🧧"
		TYPE_EVENT: return "❗"
		TYPE_SYSTEM: return "⚡"
		TYPE_COIN: return "💰"
		TYPE_NPC: return "👥"
		_: return ""
