extends TextureRect
class_name VideoBg
## 用 JPG 帧序列模拟视频背景循环播放（替代 Godot 不能直接读 mp4 的 VideoStream）。

@export var dir_path: String = "res://assets/bg/frames/start"
@export var fps: float = 8.0

var _frames: Array[Texture2D] = []
var _idx: int = 0
var _accum: float = 0.0

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_frames()
	if _frames.is_empty():
		# 兜底：尝试用同名静态图
		var fallback := dir_path.replace("/frames/start", "/start-bg.png").replace("/frames/game", "/bg.png").replace("/frames/ed", "/ed-bg.png")
		if ResourceLoader.exists(fallback):
			texture = load(fallback)
		set_process(false)
		return
	texture = _frames[0]
	set_process(true)

func _load_frames() -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	var names: Array[String] = []
	d.list_dir_begin()
	while true:
		var n := d.get_next()
		if n.is_empty():
			break
		if n.ends_with(".jpg") or n.ends_with(".png"):
			names.append(n)
	d.list_dir_end()
	names.sort()
	for n in names:
		var p := "%s/%s" % [dir_path, n]
		if ResourceLoader.exists(p):
			_frames.append(load(p))

func _process(delta: float) -> void:
	if _frames.is_empty():
		return
	_accum += delta
	var step: float = 1.0 / max(fps, 1.0)
	while _accum >= step:
		_accum -= step
		_idx = (_idx + 1) % _frames.size()
		texture = _frames[_idx]
