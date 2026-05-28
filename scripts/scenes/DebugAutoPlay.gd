extends Node
## 自动跑测入口：直接启动 3 轮、auto_play 对局，覆盖全部玩法路径。

func _ready() -> void:
	_log("DebugAutoPlay._ready start")
	if not SaveSystem.has(GameStore.KEY_CHARACTERS):
		GameStore.reset_all()
	GameStore.clear_game_progress()
	GameStore.reset_minigame_counts()
	var chars: Array = GameStore.get_characters()
	var npcs: Array = GameStore.get_npcs()
	_log("loaded chars=%d npcs=%d" % [chars.size(), npcs.size()])
	SceneRouter.goto(SceneRouter.SCENE_GAME, {
		"rounds": 3,
		"diceMode": "auto",
		"characters": chars,
		"npcs": npcs,
		"auto_play": true,
	})
	_log("routed to Game")

func _log(msg: String) -> void:
	var f := FileAccess.open("user://e2e.log", FileAccess.READ_WRITE if FileAccess.file_exists("user://e2e.log") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("[%s] %s" % [Time.get_datetime_string_from_system(), msg])
	f.close()
