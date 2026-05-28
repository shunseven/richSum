extends Node
## 场景路由 + 跨场景参数传递。
## 对应 main.js 的 navigate(screen, params)。

var pending_params: Dictionary = {}

const SCENE_BOOT := "res://scenes/Boot.tscn"
const SCENE_MENU := "res://scenes/Menu.tscn"
const SCENE_ROUND_SETUP := "res://scenes/RoundSetup.tscn"
const SCENE_GAME := "res://scenes/Game.tscn"
const SCENE_RESULTS := "res://scenes/Results.tscn"
const SCENE_CHARACTER_EDITOR := "res://scenes/CharacterEditor.tscn"
const SCENE_NPC_EDITOR := "res://scenes/NpcEditor.tscn"
const SCENE_MINIGAME_EDITOR := "res://scenes/MiniGameEditor.tscn"
const SCENE_EVENT_EDITOR := "res://scenes/EventEditor.tscn"
const SCENE_NPC_EVENT_EDITOR := "res://scenes/NpcEventEditor.tscn"
const SCENE_PRIZE_EDITOR := "res://scenes/PrizeEditor.tscn"

func goto(target: String, params: Dictionary = {}) -> void:
	pending_params = params
	get_tree().change_scene_to_file.call_deferred(target)

func consume_params() -> Dictionary:
	var p := pending_params
	pending_params = {}
	return p
