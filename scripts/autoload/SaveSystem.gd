extends Node
## 持久化存档：对应 H5 版的 localStorage。
## 所有数据以 JSON 写入 user://saves/<key>.json。

const SAVE_DIR := "user://saves"

func _ready() -> void:
	_ensure_dir()

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _path_for(key: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, key]

func has(key: String) -> bool:
	_ensure_dir()
	return FileAccess.file_exists(_path_for(key))

func load_data(key: String, default_value: Variant = null) -> Variant:
	_ensure_dir()
	var path := _path_for(key)
	if not FileAccess.file_exists(path):
		return default_value
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return default_value
	var text := f.get_as_text()
	f.close()
	if text.is_empty():
		return default_value
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		return default_value
	return parsed

func save_data(key: String, value: Variant) -> void:
	_ensure_dir()
	var path := _path_for(key)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(value))
	f.close()

func remove(key: String) -> void:
	var path := _path_for(key)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func load_default_json(res_path: String) -> Variant:
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		push_error("SaveSystem: missing default %s" % res_path)
		return null
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)
