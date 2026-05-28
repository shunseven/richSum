extends RefCounted
class_name BoardSpec
## 塔防式环形路径棋盘：24 格沿矩形边铺 → 每格除"事件类型"外还带一个"路径方向"。
## 草地背景整屏铺，路径瓷砖按方向（直/弯）选 sprite。

const BOARD_SIZE := 24
const TILE_W := 96  # 单格在屏幕上的最终大小（瓷砖原图 64×64 缩放）
const ST := 96       # 步长 = 瓷砖宽（首尾相接，无间隙，构成完整路径）
const TOKEN_R := 16

# 路径方向类型
const PATH_H := "h"        # 水平直路
const PATH_V := "v"        # 垂直直路
const PATH_TL := "tl"      # 左上拐角
const PATH_TR := "tr"
const PATH_BL := "bl"
const PATH_BR := "br"

# 事件类型（用于事件徽章 / 触发逻辑）
const TYPE_START  := "start"
const TYPE_EVENT  := "event"
const TYPE_SYSTEM := "system"
const TYPE_COIN   := "coin"
const TYPE_NPC    := "npc"
const TYPE_NORMAL := "normal"

# 固定事件分配（与 H5 完全一致）
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
# 路径方向也由此决定，加上 4 个角的拐弯
static func get_tile_positions(origin: Vector2) -> Array[Vector2]:
	var arr: Array[Vector2] = []
	for i in 8:
		arr.append(origin + Vector2(i * ST, 0))                    # 0..7 top
	for i in 5:
		arr.append(origin + Vector2(7 * ST, (i + 1) * ST))         # 8..12 right
	for i in 7:
		arr.append(origin + Vector2((6 - i) * ST, 6 * ST))         # 13..19 bottom
	for i in 4:
		arr.append(origin + Vector2(0, (5 - i) * ST))              # 20..23 left
	return arr

# 路径方向：4 个角 + 直路
const PATH_DIR_FOR_TILE := {
	0:  PATH_TL,    # 左上角（起点）
	7:  PATH_TR,    # 右上角
	13: PATH_BR,    # 右下角（实际为右下转左→是 BR 类型）
	19: PATH_BL,    # 左下角
}

static func path_dir_for(idx: int) -> String:
	if PATH_DIR_FOR_TILE.has(idx):
		return PATH_DIR_FOR_TILE[idx]
	if idx >= 1 and idx <= 6:
		return PATH_H
	if idx >= 8 and idx <= 12:
		return PATH_V
	if idx >= 14 and idx <= 18:
		return PATH_H
	if idx >= 20 and idx <= 23:
		return PATH_V
	return PATH_H

static func tile_type_for(idx: int, npc_slot_indices: Array) -> String:
	if FIXED_TILES.has(idx):
		return FIXED_TILES[idx]
	if npc_slot_indices.has(idx):
		return TYPE_NPC
	return TYPE_NORMAL

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

# 事件徽章颜色（路径上方的小圆标）
static func badge_color_for_type(t: String) -> Color:
	match t:
		TYPE_START:  return Color("#ffd700")
		TYPE_EVENT:  return Color("#e67e22")
		TYPE_SYSTEM: return Color("#3498db")
		TYPE_COIN:   return Color("#f1c40f")
		TYPE_NPC:    return Color("#9b59b6")
		_:           return Color(0, 0, 0, 0)

static func badge_emoji_for_type(t: String) -> String:
	match t:
		TYPE_START:  return "🏁"
		TYPE_EVENT:  return "❗"
		TYPE_SYSTEM: return "⚡"
		TYPE_COIN:   return "💰"
		TYPE_NPC:    return "👥"
		_:           return ""
