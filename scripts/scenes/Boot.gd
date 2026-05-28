extends Node2D

func _ready() -> void:
	# 第一次启动确保默认数据已写入
	if not SaveSystem.has(GameStore.KEY_CHARACTERS):
		GameStore.reset_all()
	SceneRouter.goto(SceneRouter.SCENE_MENU)
